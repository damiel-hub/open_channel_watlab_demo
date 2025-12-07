addpath(genpath('functions'))

%% Parameters setting

% Inherit the parameters from Watlab
sim_ending_time = 3000; % (sec)
n_pic = 51;
msh_path = 'data/msh/laonong_narrow_20m/gmsh.msh';
pic_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/outputs';

% Compute flow relate patameters
resample_grid_dxdy = 10; % (m)
ds_along_section = 5; % (m)

% Plotting relate parameters
cmax = 5;
section_path = 'data/shape/cross_section/section';
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
quiver_factor = 1;
quiver_sparse = 5;

% Results folder path
result_png_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/post_process_one_section';
mkdir(fullfile(result_png_folder))

% MP4 relate parameters
fps = 5; % frame per second
mp4_name_plane_view = 'plane.mp4';
mp4_name_side_view = 'side.mp4';

%%

cross_lrxy = m_shaperead(section_path).ncst{1};
[times_sec, sequence_time] = get_hydroflow_filenames(sim_ending_time, n_pic);

Q_all = zeros(length(sequence_time), 1);
h_max_all = zeros(length(sequence_time), 1);
A_all = zeros(length(sequence_time), 1);

[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(fullfile(dem_path));
[interp_s, interp_x, interp_y] = interpPolyline_sxy(cross_lrxy, ds_along_section);

zb_all = nan(length(times_sec), length(interp_x));
h_all = nan(length(times_sec), length(interp_x));

parfor i_time = 1:length(sequence_time)
    f = figure('Visible','off');
    pic_path = fullfile(pic_folder , ['pic_' sequence_time{i_time} '.txt']);
    
    [xMesh, yMesh, hMesh] = valueMeshMapper(pic_path, 'h', resample_grid_dxdy, 'MeshPath', msh_path);
    [~, ~, qxMesh] = valueMeshMapper(pic_path, 'qx', resample_grid_dxdy, 'MeshPath', msh_path);
    [~, ~, qyMesh] = valueMeshMapper(pic_path, 'qy', resample_grid_dxdy, 'MeshPath', msh_path);
    [~, ~, zbMesh] = valueMeshMapper(pic_path, 'zb', resample_grid_dxdy, 'MeshPath', msh_path);

    
    colmapNew = powlawColormap(turbo(100),0.5,0);

    lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
    freezeColors
    imagesc(xMesh(1,:), yMesh(:,1) , hMesh, 'AlphaData', ~(hMesh<=0.0001 | isnan(hMesh)))
    colormap(colmapNew)
    clim([0 cmax])

    plot(cross_lrxy(:,1), cross_lrxy(:,2), 'w-')

    [interp_x, interp_y, zb, h, q_x, q_y] = computeFlow_lrxy_profile(cross_lrxy, ds_along_section, xMesh, yMesh, zbMesh, hMesh, qxMesh, qyMesh);
    [Q_sum, A_sum, h_max] = computeFlow_lrxy_stats(interp_x, interp_y, h, q_x, q_y);
    quiver(interp_x(1:quiver_sparse:end), interp_y(1:quiver_sparse:end), q_x(1:quiver_sparse:end), q_y(1:quiver_sparse:end), quiver_factor, 'k')
    
    zb_all(i_time, :) = zb;
    h_all(i_time, :) = h;

    Q_all(i_time, 1) = Q_sum;
    h_max_all(i_time, 1) = h_max;
    A_all(i_time, 1) = A_sum;

    axis tight
    hcb = colorbar();
    title(hcb, 'h [m]')
    title(['t = ' num2str(times_sec(i_time)) ' [sec]'])
    print(fullfile(result_png_folder, ['t_' sequence_time{i_time} '.png']), '-dpng', '-r300')
    close(f)
end


pngs2mp4(result_png_folder, 't_*.png', mp4_name_plane_view, fps) % Export sequences images to mp4

%%
figure
plot(times_sec, A_all, 'k.-')
xlabel('t [sec]')
ylabel('A [m^2]')


figure
plot(times_sec, h_max_all, 'k.-')
xlabel('t [sec]')
ylabel('h_{max} [m]')

figure
plot(times_sec, Q_all, 'k.-')
xlabel('t [sec]')
ylabel('Q [cms]')


cmap = parula(size(h_all,1));
figure
plot(interp_s, zb_all(1,:), 'k.-')
hold on
for i = 1:size(h_all,1)
    plot(interp_s, h_all(i,:) + zb_all(1,:), '.-', 'Color',cmap(i,:))
    title(['time = ' num2str(times_sec(i)) ' [sec]'])
    xlabel('s [m]')
    ylabel('z [m]')
end
axisXY = axis;


parfor i = 1:size(h_all,1)
    f = figure;
    plot(interp_s, zb_all(1,:), 'k.-')
    hold on
    plot(interp_s, h_all(i,:) + zb_all(1,:), 'b.-')
    title(['time = ' num2str(times_sec(i)) ' [sec]'])
    xlabel('s [m]')
    ylabel('z [m]')
    axis(axisXY)
    print(fullfile(result_png_folder, ['section_' sequence_time{i} '.png']), '-dpng', '-r300')
    close(f)
end
pngs2mp4(result_png_folder, 'section_*.png', mp4_name_side_view, fps) % Export sequences images to mp4