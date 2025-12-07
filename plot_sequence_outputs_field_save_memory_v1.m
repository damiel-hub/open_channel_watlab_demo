clear; close all; clc;
addpath(genpath('functions'))

tic
%% --- 1. User Parameters ---
simulation_duration = 3000; % (sec)
pic_n = 51;
msh_path = 'data/msh/laonong_narrow_20m/gmsh.msh';
watlab_output_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/outputs';
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
result_png_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/pngs';

% Computation Parameters
resample_grid_dxdy = 5;
h_threshold = 0.0001; % Depth threshold to hide dry areas

% Visualization Parameters
cmax = 10; % Maximum color range for depth
quiver_sparse = 6;
quiver_factor = 5;
fps = 5;
mp4_name = 'result.mp4';

% Ensure output folder exists
if ~exist(result_png_folder, 'dir'); mkdir(result_png_folder); end

%% --- 2. STATIC PRE-COMPUTATION (The "Heavy Lifting") ---
fprintf('--- Starting Pre-computation ---\n');

% A. Get File List
[time_vals, file_names] = get_hydroflow_filenames(simulation_duration, pic_n);

% B. Pre-compute Terrain RGB (Hillshade)
% We calculate the lighting ONCE here, not in the loop.
fprintf('   > Generating static terrain background...\n');
[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(dem_path);
axisXY = [min(xMesh_dem(:)) max(xMesh_dem(:)) min(yMesh_dem(:)) max(yMesh_dem(:))];
TerrainRGB = generate_terrain_rgb(xMesh_dem, yMesh_dem, zMesh_dem);

% C. Setup Master Interpolant & Grid
% We read the first file to get the XY coordinates and build the triangulation ONCE.
fprintf('   > Building master interpolant structure...\n');
first_file = fullfile(watlab_output_folder, ['pic_' file_names{1} '.txt']);
data_master = readmatrix(first_file);
x_nodes = data_master(:,1);
y_nodes = data_master(:,2);

% Define the target grid based on the node extents
margin = resample_grid_dxdy/2;
xg_vec = min(x_nodes)-margin : resample_grid_dxdy : max(x_nodes)+margin;
yg_vec = min(y_nodes)-margin : resample_grid_dxdy : max(y_nodes)+margin;
[Xq, Yq] = meshgrid(xg_vec, yg_vec);

% Create the Master ScatteredInterpolant (Linear is faster than natural)
F_master = scatteredInterpolant(x_nodes, y_nodes, x_nodes, 'linear', 'none');

% D. Pre-compute Mask (Mesh Boundaries)
% We check which grid points are inside the .msh file ONCE.
if isfile(msh_path)
    fprintf('   > Creating simulation domain mask...\n');
    [Nodes, Elements] = read_gmsh_triangles(msh_path);
    TR_geo = triangulation(Elements, Nodes(:,1), Nodes(:,2));
    tri_ids = pointLocation(TR_geo, Xq(:), Yq(:));
    valid_mask = ~isnan(tri_ids); % Logical mask: true = inside mesh
else
    warning('Mesh file not found. Masking skipped.');
    valid_mask = true(size(Xq));
end

%% --- 3. PARALLEL PROCESSING LOOP ---
fprintf('--- Starting Parallel Rendering (%d frames) ---\n', length(file_names));

parfor i_time = 1:length(file_names)
    try
        % Define paths and names for this worker
        t_current = time_vals(i_time);
        t_str = num2str(t_current);
        pic_path = fullfile(watlab_output_folder, ['pic_' file_names{i_time} '.txt']);
        out_png = fullfile(result_png_folder, ['t_' file_names{i_time} '.png']);
        
        % 1. Read Data (Only values needed, coordinates are assumed static)
        % optimization: readmatrix is slow on text; specialized readers are faster, 
        % but this is the current bottleneck.
        raw_data = readmatrix(pic_path); 
        h_in  = raw_data(:,5);
        qx_in = raw_data(:,6);
        qy_in = raw_data(:,7);
        
        % 2. Fast Interpolation (Using F.Values)
        % We copy the master structure (lightweight) and just swap the value array.
        F_worker = F_master; 
        
        % Interpolate H
        F_worker.Values = h_in;
        hMesh = F_worker(Xq, Yq);
        
        % Interpolate Qx
        F_worker.Values = qx_in;
        qxMesh = F_worker(Xq, Yq);
        
        % Interpolate Qy
        F_worker.Values = qy_in;
        qyMesh = F_worker(Xq, Yq);
        
        % 3. Masking & Calculation
        hMesh(~valid_mask) = NaN;
        qxMesh(~valid_mask) = NaN;
        qyMesh(~valid_mask) = NaN;
        
        uMesh = qxMesh ./ hMesh;
        vMesh = qyMesh ./ hMesh;
        
        hMesh(hMesh <= h_threshold) = NaN; % Thresholding
        
        % 4. Plotting
        % Create invisible figure with specific size to ensure consistent output
        f = figure('Visible', 'off', 'Position', [100 100 1200 800]); 
        
        % A. Background (Instant plot of pre-computed RGB)
        imagesc(xMesh_dem(1,:), yMesh_dem(:,1), TerrainRGB);
        hold on
        
        % B. Water Depth
        % We use 'AlphaData' to handle transparency efficiently
        im_h = imagesc(xg_vec, yg_vec, hMesh);
        set(im_h, 'AlphaData', ~isnan(hMesh));
        colormap(gca, 'turbo'); % Or your preferred map
        clim([0 cmax]);
        
        % C. Quivers
        % Subsample to avoid clutter
        idx_x = 1:quiver_sparse:size(Xq, 2);
        idx_y = 1:quiver_sparse:size(Xq, 1);
        
        quiver(Xq(idx_y, idx_x), Yq(idx_y, idx_x), ...
               uMesh(idx_y, idx_x) * quiver_factor, ...
               vMesh(idx_y, idx_x) * quiver_factor, ...
               'off', 'color', 'k');
           
        % D. Decoration
        axis equal; axis xy; axis tight;
        axis(axisXY);
        hcb = colorbar;
        title(hcb, 'h [m]');
        title(['t = ' t_str ' [sec]']);
        set(gca, 'Layer', 'top'); % Keeps grid/ticks on top of images
        
        % 5. Save
        print(f, out_png, '-dpng', '-r150'); 
        close(f);
        
    catch ME
        fprintf('Error on frame %d: %s\n', i_time, ME.message);
    end
end

fprintf('--- Rendering Complete ---\n');

% Export Video
if exist('pngs2mp4', 'file')
    pngs2mp4(result_png_folder, 't_*.png', mp4_name, fps);
end
toc
%% --- HELPER FUNCTIONS ---

function RGB = generate_terrain_rgb(xMap, yMap, zMesh)
% GENERATE_TERRAIN_RGB 
% Replicates the exact logic of lightterrain2D_imagesc but returns 
% a static RGB image to save memory and allow independent colormaps.

    % 1. Calculate Normals
    [nx, ny, nz] = surfnorm(xMap, yMap, zMesh);
    
    % 2. Normalize Surface Normals (Nx3 matrix)
    % Reshape to columns for vectorized dot product
    sz = size(nz);
    N_flat = [nx(:), ny(:), nz(:)];
    N_len = sqrt(sum(N_flat.^2, 2));
    N_flat = N_flat ./ N_len; % Normalize
    
    % 3. Define Light Vector (Matched to your code: [0, -1, -1])
    L = [0, -1, -1];
    L = L / norm(L); % Normalize light vector
    
    % 4. Calculate Angle (acos of dot product)
    % Dot product: sum(A .* B) row-wise. 
    % Since L is constant, it's just N_flat * L'
    dotProd = N_flat * L';
    
    % Clamp values to [-1, 1] to prevent complex numbers from precision errors
    dotProd = max(min(dotProd, 1), -1);
    
    angle_rad = acos(dotProd); % Result is 0 to pi
    
    % 5. Map Angle to Color
    % This is mathematically identical to: color = angle / pi
    gray_val = angle_rad / pi;
    
    % 6. Create RGB Array
    % We replicate the gray value into 3 channels (R, G, B)
    gray_grid = reshape(gray_val, sz);
    
    RGB = zeros([sz, 3]);
    RGB(:,:,1) = gray_grid;
    RGB(:,:,2) = gray_grid;
    RGB(:,:,3) = gray_grid;
end