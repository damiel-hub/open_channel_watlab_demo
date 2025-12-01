addpath(genpath('functions'))

dem_path = 'data/raster/raw/laonongDEM_5m.tif';
gmsh_path = 'data/msh/laonong_narrow_50m/gmsh.msh';
plt_mesh = 1;

[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(dem_path);

figure
lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
[~, ~] = get_gmsh_mesh(gmsh_path, plt_mesh);
[~, ~] = get_gmsh_boundary(gmsh_path, 'Qin', plt_mesh);
[~, ~] = get_gmsh_boundary(gmsh_path, 'Qout', plt_mesh);
[~, ~] = get_gmsh_boundary(gmsh_path, 'West', plt_mesh);
[~, ~] = get_gmsh_boundary(gmsh_path, 'East', plt_mesh);
title('')
xlabel('')
ylabel('')