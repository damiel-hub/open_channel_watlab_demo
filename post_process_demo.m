addpath(genpath('functions'))

%% Parameters setting

% Cross section relate parameters
distance_between_sections = 20; % (m)
central_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_central')).ncst{1};
right_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_right')).ncst{1};
left_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_left')).ncst{1};

% Watlab relate parameters
sim_ending_time = 1000; % (sec)
n_pic = 26;
pic_folder = 'results/laonong_steady/outputs';

% Compute flow relate patameters
resample_grid_dxdy = 10; % (m)
ds_along_section = 5; % (m)

% Plotting relate parameters
cmax = 5;
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
quiver_factor = 1;
quiver_sparse = 5;

% Results folder path
result_png_folder = 'results/laonong_steady/post_process_demo';
mkdir(fullfile(result_png_folder))

% MP4 relate parameters
fps = 5; % frame per second
mp4_name = 'result.mp4';

%%
[~, ~, interp_R_x, interp_R_y, interp_L_x, interp_L_y, interp_s, ~] = long_profile_system_maker_without_crosssection(distance_between_sections, central_xy, left_xy, right_xy, 0);
[times_sec, sequence_time] = get_hydroflow_filenames(sim_ending_time, n_pic);

interp_RL_xy = [interp_R_x interp_R_y interp_L_x interp_L_y];
Q_all = zeros(length(sequence_time), length(interp_s));
h_max_all = zeros(length(sequence_time), length(interp_s));
A_all = zeros(length(sequence_time), length(interp_s));

[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(fullfile(dem_path));

for i_time = 1:length(sequence_time)
    figure('Visible','off')
    pic_path = fullfile(pic_folder , ['pic_' sequence_time{i_time} '.txt']);
    
    [xMesh, yMesh, hMesh] = valueMeshMapper_nan(pic_path, 'h', resample_grid_dxdy);
    [~, ~, qxMesh] = valueMeshMapper_nan(pic_path, 'qx', resample_grid_dxdy);
    [~, ~, qyMesh] = valueMeshMapper_nan(pic_path, 'qy', resample_grid_dxdy);
    [~, ~, zbMesh] = valueMeshMapper_nan(pic_path, 'zb', resample_grid_dxdy);

    hMesh(hMesh<0) = 0;
    colmapNew = powlawColormap(turbo(100),0.5,0);

    lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
    freezeColors
    imagesc(xMesh(1,:), yMesh(:,1) , hMesh, 'AlphaData', ~isnan(hMesh))
    colormap(colmapNew)
    clim([0 cmax])

    plot([interp_R_x interp_L_x]', [interp_R_y interp_L_y]', 'w-')
    for i_s = 1:size(interp_RL_xy,1)
        cross_lrxy = [interp_RL_xy(i_s,1:2); interp_RL_xy(i_s,3:4)];
        [x, y, zb, h, q_x, q_y] = computeFlow_lrxy_profile(cross_lrxy, ds_along_section, xMesh, yMesh, zbMesh, hMesh, qxMesh, qyMesh);
        [Q_sum, A_sum, h_max] = computeFlow_lrxy_stats(x, y, h, q_x, q_y);
        quiver(x(1:quiver_sparse:end), y(1:quiver_sparse:end), q_x(1:quiver_sparse:end), q_y(1:quiver_sparse:end), quiver_factor, 'k')
        Q_all(i_time, i_s) = Q_sum;
        h_max_all(i_time, i_s) = h_max;
        A_all(i_time, i_s) = A_sum;
    end
    axis tight
    hcb = colorbar();
    title(hcb, 'h [m]')
    title(['t = ' num2str(times_sec(i_time)) ' [sec]'])
    print(fullfile(result_png_folder, ['t_' sequence_time{i_time} '.png']), '-dpng', '-r300')

end


pngs2mp4(result_png_folder, 't_*.png', mp4_name, fps) % Export sequences images to mp4

%%
figure
tiledlayout(3,1, "TileSpacing","tight", "Padding","compact")
nexttile
plot(interp_s, Q_all, 'k.-')
xlabel('x [m]')
ylabel('Q [cms]')
xticklabels([])
xlabel([])

nexttile
plot(interp_s, h_max_all, 'k.-')
xlabel('x [m]')
ylabel('h_{max} [m]')
xticklabels([])
xlabel([])

nexttile
plot(interp_s, A_all, 'k.-')
xlabel('x [m]')
ylabel('A [m^2]')