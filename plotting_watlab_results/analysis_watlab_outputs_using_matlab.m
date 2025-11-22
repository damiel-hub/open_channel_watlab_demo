path(path,'funs')
pic_path = 'outputs_unsteady\pic_7200_00.txt';
variable_name = 'h';
dem_path = '..\W13_environment_setup\watlab-field-case\raster\raw\laonongDEM_5m.tif';
dxdy = 10;
pltFlag = 1;
[xMesh, yMesh, hMesh] = valueMeshMapper(pic_path, 'h', dxdy, pltFlag, dem_path);
[~, ~, qxMesh] = valueMeshMapper(pic_path, 'qx', dxdy, pltFlag, dem_path);
[~, ~, qyMesh] = valueMeshMapper(pic_path, 'qy', dxdy, pltFlag, dem_path);
[~, ~, zwMesh] = valueMeshMapper(pic_path, 'zw', dxdy, pltFlag, dem_path);
[~, ~, zbMesh] = valueMeshMapper(pic_path, 'zb', dxdy, pltFlag, dem_path);
% writeGeoTiff(hMesh, 'hMesh.tif', 3826, min(xMesh(:)), max(xMesh(:)), min(yMesh(:)), max(yMesh(:)), 'south', 'west')

%%
ds = dxdy/2;
lineXY = m_shaperead('..\W13_environment_setup\watlab-field-case\shape\plotting\profile_polyline\polyline').ncst{1};
[interp_s, interp_x, interp_y, ~] = interpPolyline_sxy(lineXY,ds);

interp_zw = interp2(xMesh,yMesh,zwMesh,interp_x,interp_y);
interp_zb = interp2(xMesh,yMesh,zbMesh,interp_x,interp_y);
figure
plot(interp_s,interp_zw,'b-')
hold on
plot(interp_s,interp_zb,'k-')

%%
cross_section_path = 'shape\cross_section';

[xMesh_dem,yMesh_dem,zMesh_dem] = readGeoTiff(dem_path);
crossXY = m_shaperead(cross_section_path).ncst{1};
[interp_s, interp_x, interp_y, ~] = interpPolyline_sxy(crossXY,ds);
interp_qx = interp2(xMesh,yMesh,qxMesh,interp_x,interp_y,'nearest');
interp_qy = interp2(xMesh,yMesh,qyMesh,interp_x,interp_y,'nearest');
interp_h = interp2(xMesh,yMesh,hMesh,interp_x,interp_y,'nearest');
interp_zb = interp2(xMesh,yMesh,zbMesh,interp_x,interp_y,'nearest');
interp_zw = interp2(xMesh,yMesh,zwMesh,interp_x,interp_y,'nearest');
interp_z_dem = interp2(xMesh_dem,yMesh_dem,zMesh_dem,interp_x,interp_y);

s = interp_s';
q_x = interp_qx';
q_y = interp_qy';
h = interp_h';
v_x = q_x./h;
v_y = q_y./h;
v = (v_x.^2+v_y.^2).^0.5;
x = interp_x';
y = interp_y';

diff_x = diff(x);
diff_y = diff(y);
diff_x = [diff_x(1);diff_x];
diff_y = [diff_y(1);diff_y];
theta = atan2(diff_x.*v_y-diff_y.*v_x, diff_x.*v_x+diff_y.*v_y);

q_unsolved = v.*sin(theta).*h;
q_unsolved(isnan(q_unsolved)) = 0;
q_unsolved = abs(q_unsolved);
Q_sum = trapz(interp_s,q_unsolved);

figure
plot(interp_s,q_unsolved,'b-')
title(['Q = ' num2str(Q_sum) '[cms]'])
xlabel('s [m]')
ylabel('q [cms/m]')

[~, ~, ~] = valueMeshMapper(pic_path, 'h', dxdy, pltFlag, dem_path);
hold on
plot(interp_x,interp_y,'k.-')
quiver(x,y,q_x,q_y)
axis equal

figure
plot(interp_s,interp_zb,'k-')
hold on
plot(interp_s,interp_zw,'b-')
plot(interp_s,interp_z_dem,'k--')
xlabel('s [m]')
ylabel('z [m]')

figure
interp_h(isnan(interp_h)) = 0;
plot(interp_s,interp_h,'b-')
xlabel('s [m]')
ylabel('h [m]')

%%
[Q,A,h_max] = computeFlow(pic_path,cross_section_path,dxdy,ds,dem_path,1);