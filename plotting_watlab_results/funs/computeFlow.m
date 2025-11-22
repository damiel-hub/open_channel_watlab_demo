function [Q_sum, A_sum, h_max] = computeFlow(pic_path, shp_path, dxdy, ds, dem_path, pltFlag)
% computeFlow calculates the total flow across a cross-section.
%
% Inputs:
%   pic_path - Path to the data files.
%   shp_path - Path to the cross section shape files.
%   dxdy     - Resolution parameter.
%   dem_path - Path to the DEM data.
%   ds       - Spacing along the cross-section.
%   pltFlag  - Boolean flag to control plotting (true/false).
%
% Output:
%   Q_sum    - Total flow across the cross-section.
%   A_sum    - Total area of cross-section.

    % Map values for h, qx, qy using valueMeshMapper
    [xMesh, yMesh, hMesh] = valueMeshMapper(pic_path, 'h', dxdy, false, dem_path);
    [~, ~, qxMesh] = valueMeshMapper(pic_path, 'qx', dxdy, false, dem_path);
    [~, ~, qyMesh] = valueMeshMapper(pic_path, 'qy', dxdy, false, dem_path);

    % Read DEM data
    [xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(dem_path);

    % Read cross-section shapefile
    crossXY = m_shaperead(shp_path).ncst{1};

    % Interpolate along cross-section
    [interp_s, interp_x, interp_y, ~] = interpPolyline_sxy(crossXY, ds);

    % Interpolate values along cross-section
    interp_qx = interp2(xMesh, yMesh, qxMesh, interp_x, interp_y, 'nearest');
    interp_qy = interp2(xMesh, yMesh, qyMesh, interp_x, interp_y, 'nearest');
    interp_h = interp2(xMesh, yMesh, hMesh, interp_x, interp_y, 'nearest');
    interp_z_dem = interp2(xMesh_dem, yMesh_dem, zMesh_dem, interp_x, interp_y);

    % Compute velocities and other variables
    q_x = interp_qx';
    q_y = interp_qy';
    h = interp_h';
    v_x = q_x ./ h;
    v_y = q_y ./ h;
    v = sqrt(v_x.^2 + v_y.^2);
    x = interp_x';
    y = interp_y';

    % Compute differences along cross-section
    diff_x = diff(x);
    diff_y = diff(y);
    diff_x = [diff_x(1); diff_x];
    diff_y = [diff_y(1); diff_y];
    theta = atan2(diff_x .* v_y - diff_y .* v_x, diff_x .* v_x + diff_y .* v_y);

    % Compute flow per unit width
    q_unsolved = v .* sin(theta) .* h;
    q_unsolved(isnan(q_unsolved)) = 0;
    q_unsolved = abs(q_unsolved);
    
    interp_h(isnan(interp_h)) = 0;
    % Integrate to get total flow
    Q_sum = trapz(interp_s, q_unsolved);
    A_sum = trapz(interp_s, interp_h);
    h_max = max(interp_h);

    % Plotting if pltFlag is true
    if pltFlag
        figure;
        plot(interp_s, q_unsolved, 'b-');
        title(['Q = ' num2str(Q_sum) ' [cms]']);
        xlabel('s [m]');
        ylabel('q [cms/m]');

        % Plot h field and cross-section
        [~, ~, ~] = valueMeshMapper(pic_path, 'h', dxdy, true, dem_path);
        hold on;
        plot(interp_x, interp_y, 'k.-');
        quiver(x, y, q_x, q_y);
        axis equal;

        figure;
        [xMesh_zb, yMesh_zb, zbMesh] = valueMeshMapper(pic_path, 'zb', dxdy, false, dem_path);
        interp_zb = interp2(xMesh_zb, yMesh_zb, zbMesh, interp_x, interp_y, 'nearest');
        [xMesh_zw, yMesh_zw, zwMesh] = valueMeshMapper(pic_path, 'zw', dxdy, false, dem_path);
        interp_zw = interp2(xMesh_zw, yMesh_zw, zwMesh, interp_x, interp_y, 'nearest');
        plot(interp_s, interp_zb, 'k-');
        hold on;
        plot(interp_s, interp_zw, 'b-');
        plot(interp_s, interp_z_dem, 'k--');
        xlabel('s [m]');
        ylabel('z [m]');

        figure;
        plot(interp_s, interp_h, 'b-');
        xlabel('s [m]');
        ylabel('h [m]');
    end
end
