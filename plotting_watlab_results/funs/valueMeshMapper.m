function [xMesh, yMesh, valueMesh] = valueMeshMapper(pic_path, variable_name, dxdy, pltFlag, dem_path)
% valueMeshMapper Maps values from a centroid of triangular mesh to a grid mesh.
%
% This function reads centroid of triangular mesh data from a file, interpolates 
% the specified variable onto a grid mesh, and optionally plots the result.
%
% Inputs:
%   pic_path (string): Path to the data file containing the triangular mesh data.
%   variable_name (string): Variable to extract and map to the grid mesh. Options:
%       - 'zb': Bed elevation
%       - 'h': Water depth
%       - 'qx': Discharge in x-direction
%       - 'qy': Discharge in y-direction
%       - 'zw': Water surface elevation (zb + h)
%   dxdy (scalar): Grid spacing for interpolation.
%   dem_path (string, optional): Path to a GeoTIFF file for the DEM data.
%       - If empty or not provided, the DEM will not be loaded or plotted.
%   pltFlag (logical, optional): Whether to plot the interpolated grid mesh. Default is true.
%
% Outputs:
%   xMesh (matrix): X-coordinates of the grid mesh.
%   yMesh (matrix): Y-coordinates of the grid mesh.
%   valueMesh (matrix): Interpolated values on the grid mesh.
%
% Example:
%   dem_path = 'raster\raw\laonongDEM_2010.tif'; % Optional
%   pic_path = 'outputs_laonong\pic_1050_00.txt';
%   variable_name = 'h'; % Water depth
%   dxdy = 10; % Grid spacing
%   pltFlag = true; % Plot the result
%
%   [xMesh, yMesh, valueMesh] = valueMeshMapper(pic_path, variable_name, dxdy, dem_path, pltFlag);


    % Handle optional arguments
    if nargin < 5 || isempty(dem_path)
        dem_path = '';
    end
    if nargin < 4 || isempty(pltFlag)
        pltFlag = False;
    end

    % Read data
    data = readmatrix(pic_path);

    x = data(:,1);
    y = data(:,2);

    switch variable_name
        case 'zb'
            value = data(:,3);
            value(data(:,5) == 0) = nan;
        case 'h'
            value = data(:,5);
            value(data(:,5) == 0) = nan;
        case 'qx'
            value = data(:,6);
            value(data(:,5) == 0) = nan;
        case 'qy'
            value = data(:,7);
            value(data(:,5) == 0) = nan;
        case 'zw'
            value = data(:,3) + data(:,5);
            value(data(:,5) == 0) = nan;
        otherwise
            error('Invalid variable_name. Choose from ''zb'', ''h'', ''qx'', ''qy'', or ''zw''.');
    end
    

    % Create grid
    xMesh_coordinate = min(x)-dxdy/2 : dxdy : max(x)+dxdy/2;
    yMesh_coordinate = min(y)-dxdy/2 : dxdy : max(y)+dxdy/2;
    [xMesh, yMesh] = meshgrid(xMesh_coordinate, yMesh_coordinate);

    % Grid the data
    valueMesh = griddata(x, y, value, xMesh, yMesh);

    % Plotting
    if pltFlag
        % Custom colormap function (ensure this function is on your MATLAB path)
        colmapNew = powlawColormap(parula(100), 0.5, 0);

        
        if ~isempty(dem_path)
            % Custom function to read GeoTIFF data (ensure this function is on your MATLAB path)
            [xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(dem_path);
            % Custom function to plot terrain data (ensure this function is on your MATLAB path)
            lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem)
            % Custom function to freeze colors (ensure this function is on your MATLAB path)
            freezeColors
            hold on
        else
            figure
        end
        
        imagesc(xMesh_coordinate, yMesh_coordinate, valueMesh, 'AlphaData', ~isnan(valueMesh));
        colormap(colmapNew);
        hcb = colorbar();
        title(hcb, variable_name);
        clim([min(valueMesh(:)), max(valueMesh(:))]);
        axis xy;
        axis equal;
        axis tight;
    end
end
