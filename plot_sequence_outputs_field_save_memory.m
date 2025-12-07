clear; close all; clc;
% DELETE the pool to free all worker memory
delete(gcp('nocreate'));
addpath(genpath('functions'))

%% --- 1. User Parameters ---
simulation_duration = 3000;
pic_n = 51;
msh_path = 'data/msh/laonong_narrow_20m/gmsh.msh';
watlab_output_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/outputs';
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
result_png_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/pngs';

% Computation
resample_grid_dxdy = 5;
h_threshold = 0.0001;

% Plotting
cmax = 10;
quiver_sparse = 6;
quiver_factor = 5;
fps = 5;
mp4_name = 'result.mp4';

if ~exist(result_png_folder, 'dir'); mkdir(result_png_folder); end

%% --- 2. STATIC PRE-COMPUTATION ---
fprintf('--- Starting Pre-computation ---\n');

[time_vals, file_names] = get_hydroflow_filenames(simulation_duration, pic_n);

% A. Terrain Background (Calculate Once)
fprintf('   > Generating static terrain background...\n');
[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(dem_path);
axisXY = [min(xMesh_dem(:)) max(xMesh_dem(:)) min(yMesh_dem(:)) max(yMesh_dem(:))];
TerrainRGB = generate_terrain_rgb(xMesh_dem, yMesh_dem, zMesh_dem);

% B. Build Interpolation Matrix (The Magic Step)
fprintf('   > Building Sparse Interpolation Matrix...\n');
% Read first file for coordinates
first_file = fullfile(watlab_output_folder, ['pic_' file_names{1} '.txt']);
data_master = readmatrix(first_file);
x_in = data_master(:,1);
y_in = data_master(:,2);

% Define Target Grid
margin = resample_grid_dxdy/2;
xg_vec = min(x_in)-margin : resample_grid_dxdy : max(x_in)+margin;
yg_vec = min(y_in)-margin : resample_grid_dxdy : max(y_in)+margin;
[Xq, Yq] = meshgrid(xg_vec, yg_vec);
grid_dims = size(Xq);

% ** Generate the Matrix M **
% M is (NumPixels x NumDataPoints). 
% It maps input data to the grid via linear interpolation.
M_interp = create_sparse_interp_matrix(x_in, y_in, Xq, Yq);

% C. Mesh Masking (Optional but recommended for complex boundaries)
if isfile(msh_path)
    fprintf('   > Creating simulation domain mask...\n');
    [Nodes, Elements] = read_gmsh_triangles(msh_path);
    TR_geo = triangulation(Elements, Nodes(:,1), Nodes(:,2));
    tri_ids = pointLocation(TR_geo, Xq(:), Yq(:));
    valid_mask = ~isnan(tri_ids);
else
    valid_mask = true(size(Xq));
end

%% --- 3. PARALLEL LOOP ---
fprintf('--- Starting Parallel Rendering ---\n');

parfor i_time = 1:length(file_names)
    try
        t_str = num2str(time_vals(i_time));
        pic_path = fullfile(watlab_output_folder, ['pic_' file_names{i_time} '.txt']);
        out_png = fullfile(result_png_folder, ['t_' file_names{i_time} '.png']);
        
        % 1. Read Data (Assume x/y are fixed, we just read columns)
        raw_data = readmatrix(pic_path); 
        h_vals = raw_data(:,5);
        qx_vals = raw_data(:,6);
        qy_vals = raw_data(:,7);
        
        % 2. Interpolate using Sparse Matrix Multiply (Extremely Fast)
        % M_interp (sparse) * Vector (dense) = Vector (dense)
        h_flat = M_interp * h_vals;
        qx_flat = M_interp * qx_vals;
        qy_flat = M_interp * qy_vals;
        
        % Reshape back to 2D grid
        hMesh = reshape(h_flat, grid_dims);
        qxMesh = reshape(qx_flat, grid_dims);
        qyMesh = reshape(qy_flat, grid_dims);
        
        % 3. Masking & Processing
        hMesh(~valid_mask) = NaN;
        
        % Compute Velocity
        uMesh = qxMesh ./ hMesh;
        vMesh = qyMesh ./ hMesh;
        
        hMesh(hMesh <= h_threshold) = NaN;
        
        % 4. Plotting
        f = figure('Visible', 'off', 'Position', [100 100 1200 800]); 
        
        % Background
        imagesc(xMesh_dem(1,:), yMesh_dem(:,1), TerrainRGB);
        hold on;
        
        % Water Depth
        im_h = imagesc(xg_vec, yg_vec, hMesh);
        set(im_h, 'AlphaData', ~isnan(hMesh));
        colormap(gca, 'turbo'); 
        clim([0 cmax]);
        
        % Quivers
        idx_x = 1:quiver_sparse:size(Xq, 2);
        idx_y = 1:quiver_sparse:size(Xq, 1);
        quiver(Xq(idx_y, idx_x), Yq(idx_y, idx_x), ...
               uMesh(idx_y, idx_x) * quiver_factor, ...
               vMesh(idx_y, idx_x) * quiver_factor, ...
               'off', 'color', 'k');
           
        axis equal; axis xy; axis tight; axis(axisXY);
        hcb = colorbar;
        title(hcb, 'h [m]');
        title(['t = ' t_str ' [sec]']);
        
        print(f, out_png, '-dpng', '-r150'); 
        close(f);
        
    catch ME
        fprintf('Error on frame %d: %s\n', i_time, ME.message);
    end
end


pngs2mp4(result_png_folder, 't_*.png', mp4_name, fps);


%% Functions

function M = create_sparse_interp_matrix(x_src, y_src, Xq, Yq)
% Creates a sparse matrix M such that V_grid = M * V_src
% This performs Linear Interpolation (Barycentric).

    % 1. Create Delaunay Triangulation of Source Points
    DT = delaunayTriangulation(x_src, y_src);
    
    % 2. Find which triangle each grid point falls into
    % ti: Triangle Index, bc: Barycentric Coordinates (weights)
    [ti, bc] = pointLocation(DT, Xq(:), Yq(:));
    
    % 3. Filter out points outside the convex hull (ti is NaN)
    valid_idx = ~isnan(ti);
    ti = ti(valid_idx);
    bc = bc(valid_idx, :);
    
    % 4. Build Sparse Indices
    % Grid indices (Rows of M)
    % We need to map the valid_idx back to the original grid indices 1..N
    all_grid_indices = (1:numel(Xq))';
    valid_grid_indices = all_grid_indices(valid_idx);
    
    % Replicate grid indices for the 3 vertices of each triangle
    row_idx = [valid_grid_indices; valid_grid_indices; valid_grid_indices];
    
    % Source Node indices (Cols of M)
    % DT.ConnectivityList(ti, :) gives the 3 node IDs for each triangle
    tri_nodes = DT.ConnectivityList(ti, :);
    col_idx = [tri_nodes(:,1); tri_nodes(:,2); tri_nodes(:,3)];
    
    % Values (Weights)
    vals = [bc(:,1); bc(:,2); bc(:,3)];
    
    % 5. Create Sparse Matrix
    num_grid = numel(Xq);
    num_src = length(x_src);
    M = sparse(row_idx, col_idx, vals, num_grid, num_src);
end

function RGB = generate_terrain_rgb(xMap, yMap, zMesh)
    [nx, ny, nz] = surfnorm(xMap, yMap, zMesh);
    
    lightVector = [0, -1, -1]; 
    L_unit = lightVector / norm(lightVector);
    
    N_flat = [nx(:), ny(:), nz(:)];
    N_len = sqrt(sum(N_flat.^2, 2));
    N_unit = N_flat ./ N_len;
    
    dotProd = N_unit * L_unit'; 
    
    dotProd = max(min(dotProd, 1), -1); 
    angle_flat = acos(dotProd);
    
    angleIndex = 0 : pi/100 : pi;    % Range 0 to pi
    colorIndex = 0 : 1/100 : 1;      % Range 0 to 1
    
    raw_color = interp1(angleIndex, colorIndex, angle_flat, 'linear');
    
    gray_map = reshape(raw_color, size(zMesh));
    
    g_min = min(gray_map(:));
    g_max = max(gray_map(:));
    
    if g_max > g_min
        gray_map = (gray_map - g_min) / (g_max - g_min);
    end
    
    RGB = repmat(gray_map, [1 1 3]);
end