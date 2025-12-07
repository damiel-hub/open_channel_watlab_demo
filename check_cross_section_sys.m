% Load DEM
dem_path = 'data/raster/raw/laonongDEM_5m.tif';
[xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(dem_path);

%% Approach 1
distance_between_sections = 50; % (m)
central_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_central')).ncst{1};
right_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_right')).ncst{1};
left_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_left')).ncst{1};
cross_section_sys_export_path = 'results/check_cross_section_sys/approach1';
mkdir(fileparts(cross_section_sys_export_path))
[interp_x, interp_y, interp_R_x, interp_R_y, interp_L_x, interp_L_y, interp_s, ~] = ...
    long_profile_system_maker_without_crosssection(distance_between_sections, central_xy, left_xy, right_xy, 0);
write_cross_section_system2shp(cross_section_sys_export_path, interp_x, interp_y, interp_L_x, interp_L_y, interp_R_x, interp_R_y, interp_s, 3826);


figure
lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
plot(interp_x,interp_y,'b-')
hold on
plot([interp_L_x interp_R_x]', [interp_L_y interp_R_y]', 'r-')



%% Approach 2

distance_between_sections = 50; % (m)
central_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_central')).ncst{1};
right_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_right')).ncst{1};
left_xy = m_shaperead(fullfile('data/shape/cross_sections_system/laonong_left')).ncst{1};
extrac_section = m_shaperead(fullfile('data/shape/cross_section/section')).ncst;

extra_cross_section_Lx_Ly_Rx_Ry = nan(length(extrac_section),4);

for i = 1:length(extrac_section)
    extra_cross_section_Lx_Ly_Rx_Ry(i,:) = [extrac_section{i}(1,:) extrac_section{i}(2,:)];
end

cross_section_sys_export_path = 'results/check_cross_section_sys/approach2';
mkdir(fileparts(cross_section_sys_export_path))
[interp_x, interp_y, interp_R_x, interp_R_y, interp_L_x, interp_L_y, interp_s, ~] = ...
    long_profile_system_maker_with_crosssection(distance_between_sections, central_xy, extra_cross_section_Lx_Ly_Rx_Ry, left_xy, right_xy, 0);
write_cross_section_system2shp(cross_section_sys_export_path, interp_x, interp_y, interp_L_x, interp_L_y, interp_R_x, interp_R_y, interp_s, 3826);


figure
lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
plot(interp_x, interp_y, 'b-')
hold on
plot([interp_L_x interp_R_x]', [interp_L_y interp_R_y]', 'r-')
for i = 1:length(extrac_section)
    plot(extrac_section{i}(:,1), extrac_section{i}(:,2), 'g-', 'LineWidth',1.5);
end
