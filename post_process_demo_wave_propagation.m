clear; close all; clc;
% DELETE the pool to free all worker memory
delete(gcp('nocreate'));
addpath(genpath('functions'))

%% --- 1. Parameters Setting ---
% Cross section relate parameters
distance_between_sections = 100; % (m)
central_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_central')).ncst{1};
right_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_right')).ncst{1};
left_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_left')).ncst{1};
cross_section_sys_export_path = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/cross_section_sys';

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
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
quiver_factor = 1;
quiver_sparse = 5;

% Results folder path
result_png_folder = fullfile(fileparts(pic_folder),'post_process_demo_wave_propagation');
if ~exist(result_png_folder, 'dir'); mkdir(result_png_folder); end

% MP4 parameters
fps = 5;
mp4_name = 'result.mp4';

%% --- 2. Static Pre-computation ---
fprintf('--- Starting Pre-computation ---\n');

% A. Prepare Cross Sections
[interp_x, interp_y, interp_R_x, interp_R_y, interp_L_x, interp_L_y, interp_s, ~] = ...
    long_profile_system_maker_without_crosssection(distance_between_sections, central_xy, left_xy, right_xy, 0);
write_cross_section_system2shp(cross_section_sys_export_path, interp_x, interp_y, interp_L_x, interp_L_y, interp_R_x, interp_R_y, interp_s, 3826);
interp_RL_xy = [interp_R_x interp_R_y interp_L_x interp_L_y];

% B. Get File List
[times_sec, sequence_time] = get_hydroflow_filenames(sim_ending_time, n_pic);

% C. Pre-load Terrain and Create Static RGB Background
fprintf('   > Generating static terrain background...\n');
[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(fullfile(dem_path));
TerrainRGB = generate_terrain_rgb(xMesh_dem, yMesh_dem, zMesh_dem); 
axisXY = [min(xMesh_dem(:)) max(xMesh_dem(:)) min(yMesh_dem(:)) max(yMesh_dem(:))];

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

% Create the sparse matrix M
M_interp = create_sparse_interp_matrix(x_in, y_in, xMesh, yMesh);

% Interpolate zb (Bed elevation)
zb_vals = data_master(:,4);
zbMesh = reshape(M_interp * zb_vals, grid_dims);

% E. Creating Simulation Domain Mask (Your requested addition)
if isfile(msh_path)
    fprintf('   > Creating simulation domain mask from GMSH...\n');
    [Nodes, Elements] = read_gmsh_triangles(msh_path);
    TR_geo = triangulation(Elements, Nodes(:,1), Nodes(:,2));
    tri_ids = pointLocation(TR_geo, xMesh(:), yMesh(:));
    valid_mask = reshape(~isnan(tri_ids), grid_dims);
else
    fprintf('   > No GMSH file found, skipping mask...\n');
    valid_mask = true(grid_dims);
end

%% --- 3. Main Processing Loop ---

try 
    load(fullfile(result_png_folder, 'Q_h_A.mat'))
catch
    Q_all = zeros(length(sequence_time), length(interp_s));
    h_max_all = zeros(length(sequence_time), length(interp_s));
    A_all = zeros(length(sequence_time), length(interp_s));
    
    colmapNew = powlawColormap(turbo(100), 0.5, 0);
    num_sections = size(interp_RL_xy, 1);
    
    fprintf('--- Starting Parallel Loop ---\n');
    
    parfor i_time = 1:length(sequence_time)
        
        % 1. Temporary Row Vectors
        Q_row = zeros(1, num_sections);
        h_max_row = zeros(1, num_sections);
        A_row = zeros(1, num_sections);
        
        % Read Data
        pic_path = fullfile(pic_folder, ['pic_' sequence_time{i_time} '.txt']);
        raw_data = readmatrix(pic_path);
        
        h_vals  = raw_data(:,5);
        qx_vals = raw_data(:,6);
        qy_vals = raw_data(:,7);
        
        % Interpolation
        hMesh_t  = reshape(M_interp * h_vals, grid_dims);
        qxMesh_t = reshape(M_interp * qx_vals, grid_dims);
        qyMesh_t = reshape(M_interp * qy_vals, grid_dims);
        
        % --- APPLY MASK  ---
        hMesh_t(~valid_mask) = NaN; % Cut off data outside the GMSH domain
        
        % Visualization
        f = figure('Visible','off', 'Position', [100 100 1000 800]); 
        imagesc(xMesh_dem(1,:), yMesh_dem(:,1), TerrainRGB);
        hold on
        
        im_h = imagesc(xg_vec, yg_vec, hMesh_t);
        % Update alpha mask to hide NaN values (masked areas)
        mask_plot = (hMesh_t <= h_threshold | isnan(hMesh_t));
        set(im_h, 'AlphaData', ~mask_plot);
        
        colormap(gca, colmapNew);
        clim([0 cmax]);
        plot([interp_R_x interp_L_x]', [interp_R_y interp_L_y]', 'w-', 'LineWidth', 0.5)
        
        % Cross Section Analysis
        for i_s = 1:num_sections
            cross_lrxy = [interp_RL_xy(i_s,1:2); interp_RL_xy(i_s,3:4)];
            
            [x, y, ~, h, q_x, q_y] = computeFlow_lrxy_profile(cross_lrxy, ds_along_section, xMesh, yMesh, zbMesh, hMesh_t, qxMesh_t, qyMesh_t);
            [Q_sum, A_sum, h_max] = computeFlow_lrxy_stats(x, y, h, q_x, q_y);
            
            quiver(x(1:quiver_sparse:end), y(1:quiver_sparse:end), q_x(1:quiver_sparse:end)*quiver_factor, q_y(1:quiver_sparse:end)*quiver_factor, 'off', 'Color', 'k')
            
            % Store to temporary row
            Q_row(i_s) = Q_sum;
            h_max_row(i_s) = h_max;
            A_row(i_s) = A_sum;
        end
        
        axis equal; axis tight; axis(axisXY);
        hcb = colorbar(); title(hcb, 'h [m]');
        title(['t = ' num2str(times_sec(i_time)) ' [sec]']);
        set(gca, 'YDir', 'normal');
        print(fullfile(result_png_folder, ['t_' sequence_time{i_time} '.png']), '-dpng', '-r150');
        close(f)
        
        % Final Atomic Assignment (Solves Sliced Variable Error)
        Q_all(i_time, :) = Q_row;
        h_max_all(i_time, :) = h_max_row;
        A_all(i_time, :) = A_row;
    end
    
    % Create Video
    pngs2mp4(result_png_folder, 't_*.png', mp4_name, fps)
    save(fullfile(result_png_folder, 'Q_h_A.mat'), 'A_all', "h_max_all", "Q_all")
end
%% --- 4. Final Plots ---
sequence_plot_time = 10:60:800;
cmap = parula(length(sequence_plot_time));
legend_name = {};

% x-Q plot
figure
for i_time = 1:length(sequence_plot_time)
    time_differences = abs(times_sec - sequence_plot_time(i_time));
    [~, closest_index] = min(time_differences);
    plot(interp_s, Q_all(closest_index,:), '-', 'Color',cmap(i_time,:))
    hold on
    legend_name{end+1} = ['t = ' num2str(times_sec(closest_index)) ' [sec]'];
end
legend(legend_name, 'Location','best')
ylabel('Q [cms]'); xlabel('x [m]')


% x-h plot
legend_name = {};
figure
for i_time = 1:length(sequence_plot_time)
    time_differences = abs(times_sec - sequence_plot_time(i_time));
    [~, closest_index] = min(time_differences);
    plot(interp_s, h_max_all(closest_index,:), '-', 'Color',cmap(i_time,:))
    hold on
    legend_name{end+1} = ['t = ' num2str(times_sec(closest_index)) ' [sec]'];
end
legend(legend_name, 'Location','best')
ylabel('h_{max} [m]'); xlabel('x [m]')
ylim([0 30])


% x-A plot
legend_name = {};
figure
for i_time = 1:length(sequence_plot_time)
    time_differences = abs(times_sec - sequence_plot_time(i_time));
    [~, closest_index] = min(time_differences);
    plot(interp_s, A_all(closest_index,:), '-', 'Color',cmap(i_time,:))
    hold on
    legend_name{end+1} = ['t = ' num2str(times_sec(closest_index)) ' [sec]'];
end
legend(legend_name, 'Location','best')
ylabel('A [m^2]'); xlabel('x [m]')
ylim([0 10000])




%% 

sequence_plot_x = 50:500:2000;
cmap = turbo(length(sequence_plot_x));

% t-h plot
legend_name = {};
figure
for i_x = 1:length(sequence_plot_x)
    s_differences = abs(interp_s - sequence_plot_x(i_x));
    [~, closest_index] = min(s_differences);
    plot(times_sec, h_max_all(:,closest_index), '.-', 'color', cmap(i_x,:))
    hold on
    legend_name{end+1} = ['x = ' num2str(sequence_plot_x(i_x)) ' [m]'];
end
legend(legend_name, 'Location','best')
xlabel('time [sec]')
ylabel('h_{max} [m]')

% t-Q plot
legend_name = {};
figure
for i_x = 1:length(sequence_plot_x)
    s_differences = abs(interp_s - sequence_plot_x(i_x));
    [~, closest_index] = min(s_differences);
    plot(times_sec, Q_all(:,closest_index), '.-', 'color', cmap(i_x,:))
    hold on
    legend_name{end+1} = ['x = ' num2str(sequence_plot_x(i_x)) ' [m]'];
end
legend(legend_name, 'Location','best')
xlabel('time [sec]')
ylabel('Q [cms]')

%%
has_Q = (Q_all~=0);
has_Q = cummax(double(has_Q),1);
initial_Q = [zeros(1, length(interp_s)); diff(has_Q, [], 1)];


[ini_row, ini_col, ~] = find(initial_Q==1);

ini_t = times_sec(ini_row);
ini_x = interp_s(ini_col);

[~, time_index_peak] = max(Q_all,[],1);

% x-t plot
figure
plot(interp_s, ini_t, 'ko')
hold on
plot(interp_s, times_sec(time_index_peak), 'ro')
xlabel('x [m]')
ylabel('t [sec]')
legend({'front wave arrival time', 'peak arrival time'}, 'Location','northwest')


%% --- 5. Helper Functions ---
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