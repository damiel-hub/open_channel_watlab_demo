function [xMesh, yMesh, valueMesh] = valueMeshMapper(pic_path, variable_name, dxdy, varargin)
% valueMeshMapper Maps values from triangular mesh centroids to a rectangular grid.
%
% This function reads simulation data, interpolates it onto a grid, and 
% optionally masks the result using the original .msh geometry.
%
% Inputs (Required):
%   pic_path (string): Path to the .txt data file.
%   variable_name (string): Variable to extract ('zb', 'h', 'qx', 'qy', 'zw').
%   dxdy (scalar): Grid spacing for interpolation.
%
% Inputs (Name-Value Pairs):
%   'Plot' (logical): Whether to plot the result. Default: false.
%   'DEMPath' (string): Path to GeoTIFF DEM. Default: '' (none).
%   'MeshPath' (string): Path to .msh file for masking. Default: '' (none).
%
% Example:
%   [x, y, v] = valueMeshMapper('data.txt', 'h', 10, 'MeshPath', 'mesh.msh');

    % --- 1. Parse Inputs ---
    p = inputParser;
    
    % Define required arguments
    addRequired(p, 'pic_path');
    addRequired(p, 'variable_name');
    addRequired(p, 'dxdy');
    
    % Define optional Name-Value pairs with defaults
    addParameter(p, 'Plot', false, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'DEMPath', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'MeshPath', '', @(x) ischar(x) || isstring(x));
    
    % Parse the inputs
    parse(p, pic_path, variable_name, dxdy, varargin{:});
    
    % Extract values for easier use
    opts = p.Results;
    
    % Read data
    data = readmatrix(pic_path);

    x = data(:,1);
    y = data(:,2);

    switch variable_name
        case 'zb'
            value = data(:,3);
            % value(data(:,5) == 0) = nan;
        case 'h'
            value = data(:,5);
            % value(data(:,5) == 0) = nan;
        case 'qx'
            value = data(:,6);
            % value(data(:,5) == 0) = nan;
        case 'qy'
            value = data(:,7);
            % value(data(:,5) == 0) = nan;
        case 'zw'
            value = data(:,3) + data(:,5);
            % value(data(:,5) == 0) = nan;
        otherwise
            error('Invalid variable_name. Choose from ''zb'', ''h'', ''qx'', ''qy'', or ''zw''.');
    end
    
    % --- 3. Create Grid ---
    margin = dxdy/2;
    xMesh_coordinate = min(x)-margin : dxdy : max(x)+margin;
    yMesh_coordinate = min(y)-margin : dxdy : max(y)+margin;
    [xMesh, yMesh] = meshgrid(xMesh_coordinate, yMesh_coordinate);
    
    % --- 4. Interpolation ---
    valueMesh = griddata(x, y, value, xMesh, yMesh);
    
    % --- 5. Apply MSH Mask (Using opts.MeshPath) ---
    if ~strcmp(opts.MeshPath, "") && isfile(opts.MeshPath)
        % Read mesh
        [Nodes, Elements] = read_gmsh_triangles(opts.MeshPath);
        TR = triangulation(Elements, Nodes(:,1), Nodes(:,2));
        
        % Mask
        tri_ids = pointLocation(TR, xMesh(:), yMesh(:));
        valueMesh(isnan(tri_ids)) = NaN;
    elseif ~strcmp(opts.MeshPath, "") && ~isfile(opts.MeshPath)
        warning('Mesh file not found: %s', opts.MeshPath);
    end

    % --- 6. Plotting (Using opts.Plot) ---
    if opts.Plot

        
        % Check DEM Path
        if ~strcmp(opts.DEMPath, "") && isfile(opts.DEMPath)
            try
                [xMesh_dem, yMesh_dem, zMesh_dem] = readGeoTiff(opts.DEMPath);
                lightterrain2D_imagesc(xMesh_dem, yMesh_dem, zMesh_dem);
                freezeColors;
                hold on
            catch
                warning('Could not plot DEM.');
            end
        end
        
        hIm = imagesc(xMesh_coordinate, yMesh_coordinate, valueMesh);
        set(hIm, 'AlphaData', ~isnan(valueMesh));
        
        colormap(gca, turbo);
        hcb = colorbar();
        title(hcb, variable_name);
        
        v_valid = valueMesh(~isnan(valueMesh));
        if ~isempty(v_valid), clim([min(v_valid), max(v_valid)]); end
        
        axis xy; axis equal; axis tight;
    end
end

