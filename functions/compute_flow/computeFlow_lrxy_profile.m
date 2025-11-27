function [x, y, zb, h, q_x, q_y] = computeFlow_lrxy_profile(crossXY, ds, xMesh, yMesh, zbMesh, hMesh, qxMesh, qyMesh)
% computeFlow_lrxy_profile extracts profile data along a cross-section.
%
% Inputs:
%   crossXY  - Cross-section coordinates.
%   ds       - Spacing along the cross-section.
%   xMesh, yMesh, hMesh       - Mapped water depth data.
%   qxMesh, qyMesh            - Mapped flow data.
%   xMesh_dem, yMesh_dem, zMesh_dem - DEM data.
%
% Output:
%   x, y     - Coordinates along the cross-section.
%   zb       - Bed elevation.
%   h        - Water depth.
%   q_x, q_y - Unit flow components.

    % Interpolate along cross-section to get coordinates
    [~, interp_x, interp_y] = interpPolyline_sxy(crossXY, ds);
    
    % Interpolate values along cross-section from the meshes
    % Note: Preserving the negative sign logic from original code
    interp_qx = interp2(xMesh, yMesh, qxMesh, interp_x, interp_y, 'nearest');
    interp_qy = interp2(xMesh, yMesh, qyMesh, interp_x, interp_y, 'nearest');
    interp_h  = interp2(xMesh, yMesh, hMesh, interp_x, interp_y, 'nearest');
    interp_zb = interp2(xMesh, yMesh, zbMesh, interp_x, interp_y, 'nearest');
    
    % Handle NaNs in depth immediately (common issue in dry areas)
    interp_h(isnan(interp_h)) = 0;

    % Transpose and assign outputs to match requested format
    q_x = interp_qx';
    q_y = interp_qy';
    h   = interp_h';
    zb  = interp_zb';
    x   = interp_x';
    y   = interp_y';
end