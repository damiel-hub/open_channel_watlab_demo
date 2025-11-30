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

pic_path = fullfile(watlab_output_folder, ['pic_' file_names{1} '.txt']);
[xMesh, yMesh, hMesh] = valueMeshMapper(pic_path, 'h', resample_grid_dxdy, 'MeshPath', msh_path);

hMeshMax = zeros(size(hMesh));


parfor i_time = 1:length(file_names)

    pic_path = fullfile(watlab_output_folder, ['pic_' file_names{i_time} '.txt']);
    
    [~, ~, hMesh] = valueMeshMapper(pic_path, 'h', resample_grid_dxdy, 'MeshPath', msh_path);    
    
    hMesh(hMesh<=0.0001) = nan;
    
    hMeshMax = max(hMeshMax, hMesh);
    
end


hMeshMax(hMeshMax<=0.0001) = nan;
figure
lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
freezeColors
imagesc(xMesh(1,:), yMesh(:,1) , hMeshMax, 'AlphaData', ~isnan(hMeshMax))
colormap('turbo')
clim([0 cmax]) % Setting the colorbar range
axis tight
axis xy
axis equal
hcb = colorbar();
title(hcb, 'h [m]')

axis(axisXY)
