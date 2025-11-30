clear; close all; clc;

addpath(genpath('functions'))

% Inherit the parameters and files from Watlab
simulation_duration = 3000; % (sec)
pic_n = 51;
msh_path = 'data/msh/laonong_narrow_20m/gmsh.msh';
watlab_output_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/outputs';

% Compute flow relate patameters
resample_grid_dxdy = 5;

% Plotting relate parameters
cmax = 10; % maximum color range
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
quiver_sparse = 6;
quiver_factor = 5;

% Results folder path
result_png_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/pngs';
mkdir(result_png_folder)

% MP4 relate parameters
fps = 5; % frame per second
mp4_name = 'result.mp4';


%%
[time_vals, file_names] = get_hydroflow_filenames(simulation_duration, pic_n);
[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(fullfile(dem_path));

axisXY = [min(xMesh_dem(:)) max(xMesh_dem(:)) min(yMesh_dem(:)) max(yMesh_dem(:))];

parfor i_time = 1:length(file_names)

    pic_path = fullfile(watlab_output_folder, ['pic_' file_names{i_time} '.txt']);
    
    [xMesh, yMesh, hMesh] = valueMeshMapper(pic_path, 'h', resample_grid_dxdy, 'MeshPath', msh_path);
    [~, ~, qxMesh] = valueMeshMapper(pic_path, 'qx', resample_grid_dxdy, 'MeshPath', msh_path);
    [~, ~, qyMesh] = valueMeshMapper(pic_path, 'qy', resample_grid_dxdy, 'MeshPath', msh_path);
    
    uMesh = qxMesh./hMesh;
    vMesh = qyMesh./hMesh;
    
    hMesh(hMesh<=0.0001) = nan;

    figure('Visible','off')
    lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
    freezeColors
    imagesc(xMesh(1,:), yMesh(:,1) , hMesh, 'AlphaData', ~isnan(hMesh))
    colormap('turbo')
    hold on
    quiver(xMesh(1:quiver_sparse:end,1:quiver_sparse:end), yMesh(1:quiver_sparse:end,1:quiver_sparse:end), uMesh(1:quiver_sparse:end,1:quiver_sparse:end)*quiver_factor, vMesh(1:quiver_sparse:end,1:quiver_sparse:end)*quiver_factor, 'off', 'color', 'k')
    clim([0 cmax]) % Setting the colorbar range
    axis tight
    axis xy
    axis equal
    hcb = colorbar();
    title(hcb, 'h [m]')
    title(['t = ' num2str(time_vals(i_time)) ' [sec]'])
    axis(axisXY)
    print(fullfile(result_png_folder, ['t_' file_names{i_time} '.png']), '-dpng', '-r300')
end


pngs2mp4(result_png_folder, 't_*.png', mp4_name, fps) % Export sequences images to mp4