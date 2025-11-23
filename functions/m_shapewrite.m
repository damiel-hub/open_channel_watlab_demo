function m_shapewrite(x, y, shapefileName, geometryType, epsgCode, attributes)
    % m_shapewrite: Write a shapefile with specified geometry type and optional CRS.
    %   Damiel 2024/11
    % INPUTS:
    %   x             - X-coordinates
    %   y             - Y-coordinates (structured similarly to x)
    %   shapefileName - Name of the shapefile (without extension)
    %   geometryType  - Type of geometry ('Point', 'Line', 'Polygon')
    %   epsgCode      - EPSG code for CRS (optional)
    %   attributes    - (Optional) A structure containing attribute fields
    %
    % OUTPUT:
    %   Creates a .shp file and an optional .prj file for CRS information.
    

    % EXAMPLE:

    % Define point coordinates
    % x = {
    %     x1,    % Point 1
    %     x2,    % Point 2
    %     x3     % Point 3
    % };
    % y = {
    %     y1,    % Point 1
    %     y2,    % Point 2
    %     y3     % Point 3
    % };

    % Define line coordinates
    % x = {
    %     [0, 1, 2],    % Line 1
    %     [3, 4, 5],    % Line 2
    %     [6, 7, 8]     % Line 3
    % };
    % y = {
    %     [0, 1, 0],    % Line 1
    %     [1, 0, -1],   % Line 2
    %     [2, 3, 4]     % Line 3
    % };

    % Define polygon coordinates
    % x = {
    %     x1,                   % Polygon 1
    %     {x2_outer, x2_inner}, % Polygon 2 with hole
    %     x3                    % Polygon 3
    % };
    % y = {
    %     y1,                   % Polygon 1
    %     {y2_outer, y2_inner}, % Polygon 2 with hole
    %     y3                    % Polygon 3
    % };

    % Ensure the shapefile name has no extension
    [~, shapefileName, ~] = fileparts(shapefileName);

    % Set default values if not provided
    if nargin < 4 || isempty(geometryType)
        geometryType = 'Line'; % Default to 'Line' if not specified
    end

    if nargin < 5
        epsgCode = [];
    end

    if nargin < 6
        attributes = [];
    end

    % Initialize the structure array S
    S = [];

    if iscell(x) && iscell(y)
        % Multiple features
        numFeatures = numel(x);
        S = repmat(struct('Geometry', geometryType, 'X', [], 'Y', []), numFeatures, 1);
        for i = 1:numFeatures
            S(i).Geometry = geometryType;
            if strcmp(geometryType, 'Polygon')
                % Process polygon rings and ensure correct orientation
                [S(i).X, S(i).Y] = processPolygonRings(x{i}, y{i});
            else
                % Single-part geometry
                S(i).X = double(x{i}(:));
                S(i).Y = double(y{i}(:));
            end

            % Assign attributes
            if ~isempty(attributes)
                attributeFields = fieldnames(attributes);
                for j = 1:numel(attributeFields)
                    attrValue = attributes.(attributeFields{j});
                    if iscell(attrValue)
                        S(i).(attributeFields{j}) = attrValue{i};
                    elseif numel(attrValue) == numFeatures
                        S(i).(attributeFields{j}) = attrValue(i);
                    else
                        S(i).(attributeFields{j}) = attrValue;
                    end
                end
            end
        end
    else
        % Single feature
        S.Geometry = geometryType;
        if strcmp(geometryType, 'Polygon')
            [S.X, S.Y] = processPolygonRings(x, y);
        else
            S.X = double(x(:));
            S.Y = double(y(:));
        end

        % Assign attributes
        if ~isempty(attributes)
            attributeFields = fieldnames(attributes);
            for j = 1:numel(attributeFields)
                S.(attributeFields{j}) = attributes.(attributeFields{j});
            end
        end
    end

    % Write the shapefile using MATLAB's shapewrite
    shapefilePath = [shapefileName, '.shp'];
    shapewrite(S, shapefilePath);
    disp(['Shapefile "', shapefilePath, '" has been created.']);

    % Write the .prj file if EPSG code is provided
    if ~isempty(epsgCode)
        % Attempt to use projcrs (for projected CRS) or geocrs (for geographic CRS)
        try
            crs = projcrs(epsgCode);
        catch
            crs = geocrs(epsgCode);
        end

        % Extract the WKT string using wktstring
        wktString = wktstring(crs);

        % Write the .prj file
        prjFilePath = [shapefileName, '.prj'];
        fid = fopen(prjFilePath, 'w');
        fprintf(fid, '%s', wktString);
        fclose(fid);

        disp(['Projection file "', prjFilePath, '" created for EPSG code ', num2str(epsgCode), '.']);
    else
        disp('No EPSG code provided. .prj file not created.');
    end
end

function [Xout, Yout] = processPolygonRings(Xin, Yin)
    % Process polygon rings to ensure correct orientation and format
    % Rings are concatenated with NaN separators

    if iscell(Xin) && iscell(Yin)
        numRings = numel(Xin);
        Xout = [];
        Yout = [];
        for k = 1:numRings
            xRing = double(Xin{k}(:));
            yRing = double(Yin{k}(:));

            % Ensure the ring is closed
            if xRing(1) ~= xRing(end) || yRing(1) ~= yRing(end)
                xRing(end+1) = xRing(1);
                yRing(end+1) = yRing(1);
            end

            % Correct ring orientation
            area = polygonArea(xRing, yRing);
            if k == 1
                % Outer ring should be clockwise (positive area)
                if area < 0
                    xRing = flipud(xRing);
                    yRing = flipud(yRing);
                end
            else
                % Inner rings (holes) should be counter-clockwise (negative area)
                if area > 0
                    xRing = flipud(xRing);
                    yRing = flipud(yRing);
                end
            end

            % Concatenate rings with NaN separators
            Xout = [Xout; xRing; NaN];
            Yout = [Yout; yRing; NaN];
        end

        % Remove trailing NaNs
        if ~isempty(Xout) && isnan(Xout(end))
            Xout(end) = [];
            Yout(end) = [];
        end
    else
        % Single ring polygon
        xRing = double(Xin(:));
        yRing = double(Yin(:));

        % Ensure the ring is closed
        if xRing(1) ~= xRing(end) || yRing(1) ~= yRing(end)
            xRing(end+1) = xRing(1);
            yRing(end+1) = yRing(1);
        end

        % Correct ring orientation
        area = polygonArea(xRing, yRing);
        if area < 0
            xRing = flipud(xRing);
            yRing = flipud(yRing);
        end

        Xout = xRing;
        Yout = yRing;
    end
end

function area = polygonArea(x, y)
    % Calculate the signed area of a polygon
    x = x(:);
    y = y(:);
    area = 0.5 * sum(x(1:end-1).*y(2:end) - x(2:end).*y(1:end-1));
end
