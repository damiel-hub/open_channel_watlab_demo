function m_shapewrite(x, y, shapefileName, geometryType, epsgCode, attributes)
    % m_shapewrite: Write a shapefile with specified geometry type and optional CRS.
    %   Damiel 2024/12
    
    % --- FIX: Properly handle path and filename ---
    [filePath, fileName, ~] = fileparts(shapefileName);
    if isempty(filePath)
        baseName = fileName;
    else
        baseName = fullfile(filePath, fileName);
    end
    % ----------------------------------------------

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
    shapefilePath = [baseName, '.shp']; % FIX: Use baseName (which includes path)
    shapewrite(S, shapefilePath);
    disp(['Shapefile "', shapefilePath, '" has been created.']);
    
    % Write the .prj file if EPSG code is provided
    if ~isempty(epsgCode)
        try
            crs = projcrs(epsgCode);
        catch
            crs = geocrs(epsgCode);
        end
        wktString = wktstring(crs);
        
        prjFilePath = [baseName, '.prj']; % FIX: Use baseName
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