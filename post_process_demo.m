addpath(genpath('functions'))

%% --- 1. Global Simulation Parameters ---
% Parameters shared by all models
sim_ending_time = 3000;
n_pic = 51;
pic_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/outputs';
msh_path = 'data/msh/laonong_narrow_20m/gmsh.msh';
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
resample_grid_dxdy = 10; 
ds_along_section = 5; 

% Plotting appearance
cmax = 5;
quiver_factor = 1;
quiver_sparse = 5;
fps = 5;

% Output folder
result_folder = 'results/combined_script_output';
mkdir(result_folder);

%% --- 2. Section Definition (Flexible Input) ---
% Choose ONE method below and comment out the other.

% === METHOD A: Single Section (Import Shapefile) ===
% central_xy = []; % Unused in this mode
% sections_geometry = m_shaperead('data/shape/cross_section/section').ncst;
% section_names = {'SingleSection'};

% === METHOD B: Multiple Sections (Generate from System) ===
distance_between_sections = 20; 
central_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_central')).ncst{1};
right_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_right')).ncst{1};
left_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_left')).ncst{1};

[~, ~, interp_R_x, interp_R_y, interp_L_x, interp_L_y, interp_s_sys, ~] = ...
    long_profile_system_maker_without_crosssection(distance_between_sections, central_xy, left_xy, right_xy, 0);

% Convert the system arrays into a Cell Array of geometries {N x 1}
num_sections = length(interp_R_x);
sections_geometry = cell(num_sections, 1);
section_names = cell(num_sections, 1);
for i = 1:num_sections
    % Build the [Rx Ry; Lx Ly] format for each section
    sections_geometry{i} = [interp_R_x(i), interp_R_y(i); interp_L_x(i), interp_L_y(i)];
    section_names{i} = ['Sec_' num2str(i)];
end

%% --- 3. User Choice: Side View Selection ---
% Enter the INDICES of the sections you want to plot side views for.
% Examples:
%   side_view_target_indices = [1];            % Just the first one
%   side_view_target_indices = [1, 10, 20];    % Specific sections
%   side_view_target_indices = 1:num_sections; % ALL sections (Wait time will be long!)
%   side_view_target_indices = [];             % NONE (Only calculate Q/A stats)

side_view_target_indices = [1, round(num_sections/2), num_sections]; % Example: Start, Middle, End
draw_all_sections_quiver = 0;


%% --- 4. Main Processing Loop ---
[times_sec, sequence_time] = get_hydroflow_filenames(sim_ending_time, n_pic);
n_time = length(sequence_time);
n_total_sections = length(sections_geometry);

% Pre-allocate Stats Matrices (Time x Sections)
Q_all = zeros(n_time, n_total_sections);
A_all = zeros(n_time, n_total_sections);
h_max_all = zeros(n_time, n_total_sections);

% Pre-allocate Profile Data for Side Views (Cell array because lengths vary)
% Structure: stored_profiles{time_step, idx_in_target_list}
stored_h_profiles = cell(n_time, length(side_view_target_indices));
stored_zb_profiles = cell(n_time, length(side_view_target_indices));
stored_s_coords = cell(1, length(side_view_target_indices)); % Store 's' coordinate once per target

% Load DEM once
[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(fullfile(dem_path));
colmapNew = powlawColormap(turbo(100),0.5,0);

parfor i_time = 1:n_time
    % -- A. Load Data --
    pic_path = fullfile(pic_folder , ['pic_' sequence_time{i_time} '.txt']);
    
    % Map heavy data (Only once per time step)
    [xMesh, yMesh, hMesh] = valueMeshMapper(pic_path, 'h', resample_grid_dxdy, 'MeshPath', msh_path);
    [~, ~, qxMesh] = valueMeshMapper(pic_path, 'qx', resample_grid_dxdy, 'MeshPath', msh_path);
    [~, ~, qyMesh] = valueMeshMapper(pic_path, 'qy', resample_grid_dxdy, 'MeshPath', msh_path);
    [~, ~, zbMesh] = valueMeshMapper(pic_path, 'zb', resample_grid_dxdy, 'MeshPath', msh_path);
    
    % -- B. Plot Top View Map (Visual Check) --
    f = figure('Visible','off');
    lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
    freezeColors
    imagesc(xMesh(1,:), yMesh(:,1) , hMesh, 'AlphaData', ~(hMesh<=0.0001 | isnan(hMesh)))
    colormap(colmapNew); clim([0 cmax]);
    
    % Plot all section lines nicely in white
    hold on
    for k = 1:n_total_sections
        plot(sections_geometry{k}(:,1), sections_geometry{k}(:,2), 'w-', 'LineWidth', 0.5)
    end
    
    % -- C. Compute Hydraulics for ALL Sections --
    % We need temporary vectors for slicing in parfor
    tmp_Q = zeros(1, n_total_sections);
    tmp_A = zeros(1, n_total_sections);
    tmp_hmax = zeros(1, n_total_sections);
    
    % We also need a temp cell for the profiles we want to save
    tmp_h_prof = cell(1, length(side_view_target_indices));
    tmp_zb_prof = cell(1, length(side_view_target_indices));
    
    for k = 1:n_total_sections
        % 1. Extract profile
        [x_curr, y_curr, zb_curr, h_curr, qx_curr, qy_curr] = computeFlow_lrxy_profile(sections_geometry{k}, ds_along_section, xMesh, yMesh, zbMesh, hMesh, qxMesh, qyMesh);
        
        % 2. Calculate Stats
        [Q_sum, A_sum, h_max_val] = computeFlow_lrxy_stats(x_curr, y_curr, h_curr, qx_curr, qy_curr);
        tmp_Q(k) = Q_sum;
        tmp_A(k) = A_sum;
        tmp_hmax(k) = h_max_val;
        
        % 3. If this section is selected for Side View, store the data
        % Check if 'k' is in our target list
        idx_in_target = find(side_view_target_indices == k);
        if ~isempty(idx_in_target)
            tmp_h_prof{idx_in_target} = h_curr;
            tmp_zb_prof{idx_in_target} = zb_curr;
        end

        if draw_all_sections_quiver
            quiver(x_curr(1:quiver_sparse:end), y_curr(1:quiver_sparse:end), qx_curr(1:quiver_sparse:end), qy_curr(1:quiver_sparse:end), quiver_factor, 'k');
        elseif ~isempty(idx_in_target)
            quiver(x_curr(1:quiver_sparse:end), y_curr(1:quiver_sparse:end), qx_curr(1:quiver_sparse:end), qy_curr(1:quiver_sparse:end), quiver_factor, 'k');
        end
    end
    
    % Assign temp vars to global sliced vars
    Q_all(i_time, :) = tmp_Q;
    A_all(i_time, :) = tmp_A;
    h_max_all(i_time, :) = tmp_hmax;
    
    if ~isempty(side_view_target_indices)
        stored_h_profiles(i_time, :) = tmp_h_prof;
        stored_zb_profiles(i_time, :) = tmp_zb_prof;
    end
    
    axis tight
    title(['t = ' num2str(times_sec(i_time)) ' [sec]'])
    print(fullfile(result_folder, ['map_t_' sequence_time{i_time} '.png']), '-dpng', '-r300')
    close(f)
end

% Create Map Video
pngs2mp4(result_folder, 'map_t_*.png', 'Result_Map.mp4', fps)

%% --- 5. Post-Process 1: Overall Statistics ---
% Plot Q, A, h_max for *all* sections (Topological heatmap or lines)

figure
tiledlayout(3,1, "TileSpacing","tight", "Padding","compact")
nexttile
plot(interp_s_sys, Q_all, 'k.-')
xlabel('x [m]')
ylabel('Q [cms]')
xticklabels([])
xlabel([])

nexttile
plot(interp_s_sys, h_max_all, 'k.-')
xlabel('x [m]')
ylabel('h_{max} [m]')
xticklabels([])
xlabel([])

nexttile
plot(interp_s_sys, A_all, 'k.-')
xlabel('x [m]')
ylabel('A [m^2]')

%% --- 6. Post-Process 2: Side View Animations ---
% Only runs if the user selected indices

if ~isempty(side_view_target_indices)
    
    % Pre-calculate 's' coordinates for the targets (geometry doesn't change over time)
    target_s_coords = cell(1, length(side_view_target_indices));
    for i = 1:length(side_view_target_indices)
        idx_real = side_view_target_indices(i);
        [target_s_coords{i}, ~, ~] = interpPolyline_sxy(sections_geometry{idx_real}, ds_along_section);
    end

    % Loop through each REQUESTED side view
    for i_target = 1:length(side_view_target_indices)
        real_idx = side_view_target_indices(i_target);
        section_name = section_names{real_idx};
        
        fprintf('Generating Side View Animation for %s...\n', section_name);
        
        % Generate frames
        parfor i_t = 1:n_time
            f = figure('Visible','off');
            
            % Get data for this specific target and time
            s_plot = target_s_coords{i_target};
            zb_plot = stored_zb_profiles{i_t, i_target};
            h_plot = stored_h_profiles{i_t, i_target};
            
            % Plot
            plot(s_plot, zb_plot, 'k.-', 'LineWidth', 1.5)
            hold on
            plot(s_plot, zb_plot + h_plot, 'b.-');
            
            title(['t = ' num2str(times_sec(i_t)) ' [sec]']);
            xlabel('s [m]'); ylabel('z [m]');
            axis tight;
            
            % Save frame
            fname = sprintf('Side_%d_t_%s.png', real_idx, sequence_time{i_t});
            print(fullfile(result_folder, fname), '-dpng', '-r150');
            close(f);
        end
        
        % Convert to MP4 specific to this section
        mp4_name = sprintf('SideView_Section_%d.mp4', real_idx);
        wildcard = sprintf('Side_%d_t_*.png', real_idx);
        pngs2mp4(result_folder, wildcard, mp4_name, fps);
        
        % Cleanup pngs for this section to save space? (Optional)
        % delete(fullfile(result_folder, wildcard));
    end
end

disp('All processing complete.');
