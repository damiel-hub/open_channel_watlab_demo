clear; close all; clc;
% DELETE the pool to free all worker memory
delete(gcp('nocreate'));
addpath(genpath('functions'))

%% --- 1. Parameters Setting ---
% Simulation Parameters
sim_ending_time = 3000; % (sec)
n_pic = 51;
msh_path = 'data/msh/laonong_narrow_20m/gmsh.msh';
pic_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/outputs';

% Compute flow relate parameters
resample_grid_dxdy = 10; % (m)
ds_along_section = 5; % (m)
h_threshold = 0.0001; % (m)

% Plotting relate parameters
cmax = 5;
section_path = 'data/shape/cross_section/section_salaawu';
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
quiver_factor = 1;
quiver_sparse = 5;

% Results folder path
result_png_folder = fullfile(fileparts(pic_folder), 'post_process_one_section');
if ~exist(result_png_folder, 'dir'); mkdir(result_png_folder); end

% MP4 parameters
fps = 5;
mp4_name_plane_view = 'plane.mp4';
mp4_name_side_view = 'side.mp4';


%%
bridgeshape = 'D:\YuanHungCHIU\d_Programme\TYLin\SalaawuBridgeVideo\importData\bridgeShapeFile\onlyBridge2';
bridge_cell = m_shaperead(bridgeshape).ncst;

%% --- 2. Pre-computation (Static Data) ---
fprintf('--- Starting Pre-computation ---\n');

% A. Load Geometry
cross_lrxy = m_shaperead(section_path).ncst{1};
d_check = sqrt(sum(diff(cross_lrxy, 1, 1).^2, 2));

% Create a mask to keep the first point AND any point where distance > 0
% (Using a small tolerance 1e-6 to handle floating point issues)
keep_mask = [true; d_check > 1e-6]; 

% Filter the points
cross_lrxy = cross_lrxy(keep_mask, :);
[interp_s, interp_x, interp_y] = interpPolyline_sxy(cross_lrxy, ds_along_section);
num_points_section = length(interp_x);

% B. Get File List
[times_sec, sequence_time] = get_hydroflow_filenames(sim_ending_time, n_pic);

% C. Terrain & Background
fprintf('   > Generating static terrain background...\n');
[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(fullfile(dem_path));
TerrainRGB = generate_terrain_rgb(xMesh_dem, yMesh_dem, zMesh_dem);
axisXY_dem = [min(xMesh_dem(:)) max(xMesh_dem(:)) min(yMesh_dem(:)) max(yMesh_dem(:))];

% D. Build Sparse Interpolation Matrix
fprintf('   > Building Sparse Interpolation Matrix...\n');
first_pic = fullfile(pic_folder, ['pic_' sequence_time{1} '.txt']);
data_master = readmatrix(first_pic);
x_in = data_master(:,1);
y_in = data_master(:,2);

% Define Target Grid
margin = resample_grid_dxdy/2;
xg_vec = min(x_in)-margin : resample_grid_dxdy : max(x_in)+margin;
yg_vec = min(y_in)-margin : resample_grid_dxdy : max(y_in)+margin;
[xMesh, yMesh] = meshgrid(xg_vec, yg_vec);
grid_dims = size(xMesh);

% Create Sparse Matrix M
M_interp = create_sparse_interp_matrix(x_in, y_in, xMesh, yMesh);

% E. GMSH Masking
if isfile(msh_path)
    fprintf('   > Creating simulation domain mask...\n');
    [Nodes, Elements] = read_gmsh_triangles(msh_path);
    TR_geo = triangulation(Elements, Nodes(:,1), Nodes(:,2));
    tri_ids = pointLocation(TR_geo, xMesh(:), yMesh(:));
    valid_mask = reshape(~isnan(tri_ids), grid_dims);
else
    valid_mask = true(grid_dims);
end

%% --- 3. Parallel Processing ---

try 
    load(fullfile(result_png_folder, 'Q_h_A_zb_h.mat'))
catch
    
    % Initialize storage
    Q_all = zeros(length(sequence_time), 1);
    h_max_all = zeros(length(sequence_time), 1);
    A_all = zeros(length(sequence_time), 1);
    
    % Pre-allocate 2D arrays
    zb_all = nan(length(times_sec), num_points_section);
    h_all = nan(length(times_sec), num_points_section);
    
    colmapNew = powlawColormap(turbo(100), 0.5, 0);
    
    idx_quiver = 1:quiver_sparse:length(interp_x);
    
    fprintf('--- Starting Plane View Rendering ---\n');
    
    parfor i_time = 1:length(sequence_time)
        
        % Initialize Temporary Rows
        zb_row = nan(1, num_points_section);
        h_row  = nan(1, num_points_section);
        
        % 1. Read Data
        pic_path = fullfile(pic_folder, ['pic_' sequence_time{i_time} '.txt']);
        raw_data = readmatrix(pic_path);
        
        % Hydroflow columns: 3:zb, 5:h, 6:qx, 7:qy
        zb_vals = raw_data(:,3);
        h_vals  = raw_data(:,5);
        qx_vals = raw_data(:,6);
        qy_vals = raw_data(:,7);
        
        % 2. Fast Interpolation
        zbMesh   = reshape(M_interp * zb_vals, grid_dims);
        hMesh_t  = reshape(M_interp * h_vals, grid_dims);
        qxMesh_t = reshape(M_interp * qx_vals, grid_dims);
        qyMesh_t = reshape(M_interp * qy_vals, grid_dims);
        
        % 3. Apply Mask
        hMesh_t(~valid_mask) = NaN;
        
        % 4. Visualization
        f = figure('Visible','off'); 
        imagesc(xMesh_dem(1,:), yMesh_dem(:,1), TerrainRGB);
        hold on
        
        im_h = imagesc(xg_vec, yg_vec, hMesh_t);
        mask_plot = (hMesh_t <= h_threshold | isnan(hMesh_t));
        set(im_h, 'AlphaData', ~mask_plot);
        colormap(gca, colmapNew);
        clim([0 cmax]);
        
        plot(cross_lrxy(:,1), cross_lrxy(:,2), 'w-', 'LineWidth', 1.5)
        
        % 5. Compute Profile
        [x_prof, y_prof, zb_prof, h_prof, q_x_prof, q_y_prof] = computeFlow_lrxy_profile(cross_lrxy, ds_along_section, xMesh, yMesh, zbMesh, hMesh_t, qxMesh_t, qyMesh_t);
        
        [Q_sum, A_sum, h_max] = computeFlow_lrxy_stats(x_prof, y_prof, h_prof, q_x_prof, q_y_prof);
        
    
        xq = x_prof(idx_quiver);
        yq = y_prof(idx_quiver);
        uq = q_x_prof(idx_quiver);
        vq = q_y_prof(idx_quiver);
        
        quiver(xq(:), yq(:), uq(:)*quiver_factor, vq(:)*quiver_factor, 'off', 'Color', 'k')
    
        
        % Store stats
        Q_all(i_time) = Q_sum;
        h_max_all(i_time) = h_max;
        A_all(i_time) = A_sum;
        
        % Store profiles to temporary rows
        zb_row(1,:) = zb_prof;
        h_row(1,:)  = h_prof;
        
        axis equal; axis tight; axis(axisXY_dem);
        hcb = colorbar(); title(hcb, 'h [m]');
        title(['t = ' num2str(times_sec(i_time)) ' [sec]'])
        set(gca, 'YDir', 'normal');
        print(fullfile(result_png_folder, ['t_' sequence_time{i_time} '.png']), '-dpng', '-r150');
        close(f)
        
        % Assign rows to main array
        zb_all(i_time, :) = zb_row;
        h_all(i_time, :)  = h_row;
    end
    
    pngs2mp4(result_png_folder, 't_*.png', mp4_name_plane_view, fps);
    save(fullfile(result_png_folder, 'Q_h_A_zb_h.mat'), "Q_all", "h_max_all", "A_all", "zb_all", 'h_all')
end

%% --- 4. Post-Process Statistics ---
figure
tiledlayout(3,1, 'Padding', 'compact');
nexttile; plot(times_sec, A_all, 'k.-'); ylabel('A [m^2]'); xticklabels([]); grid on;
nexttile; plot(times_sec, h_max_all, 'k.-'); ylabel('h_{max} [m]'); xticklabels([]); grid on;
nexttile; plot(times_sec, Q_all, 'k.-'); ylabel('Q [cms]'); xlabel('t [sec]'); grid on;
print(fullfile(result_png_folder, 'time_A_h_Q.png'), '-dpng', '-r300')
close all

%% --- 5. Parallel Processing (Side View) ---
fprintf('--- Starting Side View Rendering ---\n');

% Calculate fixed axis limits
z_min = min(zb_all(:));
z_max = max(zb_all(:) + h_all(:));
z_range = z_max - z_min;
fixed_axis = [min(interp_s), max(interp_s), z_min - 0.1*z_range, z_max + 0.1*z_range];

parfor i = 1:size(h_all,1)
    f = figure('Visible', 'off'); 
    for j = 1:length(bridge_cell)
        plot(bridge_cell{j}(:,1)+170.25, bridge_cell{j}(:,2), 'k-')
        hold on
    end
    water_surface = h_all(i,:) + zb_all(i,:);
    plot(interp_s, zb_all(i,:), 'k-', 'LineWidth', 1.5)
    plot(interp_s, water_surface, 'b.-', 'LineWidth', 1)
    
    title(['time = ' num2str(times_sec(i)) ' [sec]'])
    xlabel('s [m]')
    ylabel('z [m]')
    axis(fixed_axis)
    grid on
    xlim([-65 332.75]+170.25)
    ylim([510 575])
    daspect([2 1 1])
    print(fullfile(result_png_folder, ['section_' sequence_time{i} '.png']), '-dpng', '-r150');
    close(f)
end

pngs2mp4(result_png_folder, 'section_*.png', mp4_name_side_view, fps);

%% --- 6. Helper Functions ---
function M = create_sparse_interp_matrix(x_src, y_src, Xq, Yq)
    DT = delaunayTriangulation(x_src, y_src);
    [ti, bc] = pointLocation(DT, Xq(:), Yq(:));
    valid_idx = ~isnan(ti);
    ti = ti(valid_idx);
    bc = bc(valid_idx, :);
    all_grid_indices = (1:numel(Xq))';
    valid_grid_indices = all_grid_indices(valid_idx);
    row_idx = [valid_grid_indices; valid_grid_indices; valid_grid_indices];
    tri_nodes = DT.ConnectivityList(ti, :);
    col_idx = [tri_nodes(:,1); tri_nodes(:,2); tri_nodes(:,3)];
    vals = [bc(:,1); bc(:,2); bc(:,3)];
    M = sparse(row_idx, col_idx, vals, numel(Xq), length(x_src));
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