addpath(genpath('functions'))

dem_path = 'data/raster/raw/laonongDEM_5m.tif';
gmsh_path = 'data/msh/laonong_narrow_50m/gmsh.msh';
pic_path = 'results/laonong_unsteady_narrow_50m_cfl05_hydrograph_steep/outputs/pic_2280_00.txt';

% Parameter for resampling the grid
resample_dxdy = 20; % (m)

% Parameters for plotting
cmax = 5; % (m)
pltFlag_mesh = 1;


[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(fullfile(dem_path));
[xMesh, yMesh, hMesh] = valueMeshMapper(pic_path, 'h', resample_dxdy, 'MeshPath', gmsh_path);
data = readmatrix(pic_path);
cell_x = data(:,1);
cell_y = data(:,2);

figure
tiledlayout(1,2,"TileSpacing","none", "Padding","compact")
ax1 = nexttile;
lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
hold on
freezeColors
[Nodes, Elements, values] = valueMeshTriangle(pic_path, 'h', gmsh_path, 1);
colormap("turbo")
clim([0 cmax])
colorbar off
[~, ~] = get_gmsh_mesh(gmsh_path, pltFlag_mesh);
[Qin_x, Qin_y] = get_gmsh_boundary(gmsh_path, 'Qin', pltFlag_mesh);
[Qout_x, Qout_y] = get_gmsh_boundary(gmsh_path, 'Qout', pltFlag_mesh);
[West_x, West_y] = get_gmsh_boundary(gmsh_path, 'West', pltFlag_mesh);
[East_x, East_y] = get_gmsh_boundary(gmsh_path, 'East', pltFlag_mesh);
plot(cell_x, cell_y, 'r.')
title('')


ax2 = nexttile;
lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
freezeColors
imagesc(xMesh(1,:), yMesh(:,1), hMesh, 'AlphaData', ~isnan(hMesh))
colormap("turbo")
clim([0 cmax])
[~, ~] = get_gmsh_mesh(gmsh_path, pltFlag_mesh);
[~, ~] = get_gmsh_boundary(gmsh_path, 'Qin', pltFlag_mesh);
[~, ~] = get_gmsh_boundary(gmsh_path, 'Qout', pltFlag_mesh);
[~, ~] = get_gmsh_boundary(gmsh_path, 'West', pltFlag_mesh);
[~, ~] = get_gmsh_boundary(gmsh_path, 'East', pltFlag_mesh);
plot(cell_x, cell_y, 'r.')
title('')
ylabel('')
yticklabels([])
colorbar


linkaxes([ax1 ax2], 'xy')