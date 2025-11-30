
figure
plot_flood_map()

grid_with_nan_mask()

smooth_masked_flood_map()


function smooth_masked_flood_map()
    % --- Settings ---
    msh_file = 'laonong_gmsh_size_10.msh';
    txt_file = 'pic_1380_00.txt';
    dxdy = 10; % High resolution for smoothness
    
    % --- 1. Load Data ---
    fprintf('Reading files...\n');
    [Nodes, Elements] = read_gmsh_triangles(msh_file);
    T = readtable(txt_file);
    
    % Get data columns (Auto-detect 'h')
    if ismember('h', T.Properties.VariableNames)
        x = T.x; y = T.y; h = T.h;
    else
        raw = table2array(T);
        x = raw(:,1); y = raw(:,2); h = raw(:,5);
    end
    
    % --- 2. Create Smooth Interpolant ---
    fprintf('Interpolating smoothly...\n');
    % 'natural' gives the smoothest curve (C1 continuity)
    % 'linear' connects points with flat planes (C0 continuity)
    F = scatteredInterpolant(x, y, h, 'linear', 'none');
    
    % --- 3. Generate Rectangular Grid ---
    margin = 50;
    x_min = min(Nodes(:,1)) - margin; x_max = max(Nodes(:,1)) + margin;
    y_min = min(Nodes(:,2)) - margin; y_max = max(Nodes(:,2)) + margin;
    
    
    [Xq, Yq] = meshgrid(x_min:dxdy:x_max, ...
                        y_min:dxdy:y_max);
    
    % Calculate smooth values everywhere (fills the bounding box)
    Hq = F(Xq, Yq);
    
    % --- 4. Create Mask (The Magic Step) ---
    fprintf('Applying boundary mask...\n');
    % Create triangulation object from the MESH, not the data points
    TR = triangulation(Elements, Nodes(:,1), Nodes(:,2));
    
    % Check every pixel in the grid: Is it inside a mesh triangle?
    % pointLocation returns NaN for points outside the mesh
    tri_ids = pointLocation(TR, Xq(:), Yq(:));
    
    % Create a mask: 1 if inside, 0 if outside
    mask = ~isnan(tri_ids);
    mask = reshape(mask, size(Xq));
    
    % Apply mask: Set outside pixels to NaN
    Hq(~mask) = NaN;
    
    % --- 5. Plot ---
    fprintf('Plotting...\n');
    figure('Color', 'w');
    
    % Use pcolor with 'shading interp' for maximum smoothness
    imagesc(Xq(1,:),Yq(:,1), Hq, 'AlphaData', ~isnan(Hq))
    shading flat; % This blends the colors between grid pixels
    
    colormap(jet);
    c = colorbar;
    c.Label.String = 'Water Depth (h)';
    
    axis equal;
    axis xy
    xlim([x_min x_max]);
    ylim([y_min y_max]);
    title('Flood Map: Smooth Interpolation + Exact Boundaries');
    xlabel('X'); ylabel('Y');
    
    fprintf('Done.\n');
end



function grid_with_nan_mask()
    % --- Settings ---
    msh_file = 'laonong_gmsh_size_10.msh';
    txt_file = 'pic_1380_00.txt';
    resolution = 1000; % Higher resolution = sharper edges
    
    % --- 1. Read Mesh (Connectivity) ---
    fprintf('Reading mesh geometry...\n');
    [Nodes, Elements] = read_gmsh_triangles(msh_file);
    
    % --- 2. Read Data (Water Depth) ---
    fprintf('Reading water depth data...\n');
    T = readtable(txt_file);
    
    % Auto-detect 'h' column
    if ismember('h', T.Properties.VariableNames)
        h_vals = T.h;
    else
        % Fallback to 4th column if header is missing
        raw = table2array(T);
        h_vals = raw(:, 5);
    end
    
    % Verify sizes
    if length(h_vals) ~= size(Elements, 1)
        warning('Data length (%d) does not match Number of Elements (%d).', length(h_vals), size(Elements,1));
        % Proceeding might cause errors if sizes differ, but we assume 1-to-1 mapping here.
    end

    % --- 3. Create Triangulation Object ---
    % This object understands the geometry of your domain
    TR = triangulation(Elements, Nodes(:,1), Nodes(:,2));
    
    % --- 4. Create Rectangular Grid ---
    margin = 50;
    x = Nodes(:,1); y = Nodes(:,2);
    x_min = min(x) - margin; x_max = max(x) + margin;
    y_min = min(y) - margin; y_max = max(y) + margin;
    
    aspect = (y_max - y_min) / (x_max - x_min);
    nx = resolution;
    ny = round(nx * aspect);
    
    fprintf('Creating %dx%d grid...\n', nx, ny);
    [Xq, Yq] = meshgrid(linspace(x_min, x_max, nx), ...
                        linspace(y_min, y_max, ny));
    
    % --- 5. The "Magic" Step: Point Location ---
    % pointLocation returns the Index of the triangle that contains each point (Xq, Yq).
    % If a point is not in any triangle, it returns NaN.
    fprintf('Masking invalid regions (this may take a moment)...\n');
    tri_indices = pointLocation(TR, Xq(:), Yq(:));
    
    % --- 6. Map Values ---
    % Create a canvas of NaNs
    Hq = nan(size(Xq));
    
    % Identify which grid points are valid (inside a triangle)
    valid_mask = ~isnan(tri_indices);
    
    % For every valid grid point, look up the 'h' value of the triangle it landed in
    % tri_indices(valid_mask) gives us the list of Triangle IDs
    % h_vals(...) gets the depth for those IDs
    Hq(valid_mask) = h_vals(tri_indices(valid_mask));
    
    % --- 7. Plotting ---
    figure('Color', 'w');
    
    % Use pcolor (flat shading) for the grid
    hSurf = pcolor(Xq, Yq, Hq);
    set(hSurf, 'EdgeColor', 'none'); % Turn off grid lines
    
    colormap(jet);
    c = colorbar;
    c.Label.String = 'Water Depth (h)';
    
    % Set background color to something distinct (e.g., grey) to show NaNs clearly?
    % Or keep white. MATLAB plots NaNs as transparent (white background).
    set(gca, 'Color', [0.9 0.9 0.9]); % Light grey background for empty areas
    
    axis equal;
    xlim([x_min x_max]);
    ylim([y_min y_max]);
    title('Rectangular Grid with Exact Boundary Masking');
    xlabel('X'); ylabel('Y');
    
    fprintf('Done.\n');
end





function plot_flood_map()
    % --- File Names ---
    msh_file = 'laonong_gmsh_size_10.msh';
    txt_file = 'pic_1380_00.txt';

    if ~isfile(msh_file) || ~isfile(txt_file)
        error('Files not found. Please ensure both .msh and .txt files are in the current folder.');
    end

    % --- 1. Read Mesh Data (.msh) ---
    fprintf('Reading mesh file...\n');
    [Nodes, Elements] = read_gmsh_triangles(msh_file);
    
    % --- 2. Read Simulation Result (.txt) ---
    fprintf('Reading result file...\n');
    
    % FIXED: Use readtable instead of readmatrix
    % This handles headers automatically and is less prone to type errors.
    T = readtable(txt_file);
    
    % Access the 'h' column directly by name
    if ismember('h', T.Properties.VariableNames)
        h_values = T.h;
    else
        % Fallback if the header is missing or named differently
        warning('Column "h" not found by name. Assuming it is the 4th column.');
        raw_data = table2array(T); 
        h_values = raw_data(:, 5); 
    end

    % --- 3. Consistency Check ---
    num_elements = size(Elements, 1);
    num_data = length(h_values);
    
    if num_elements ~= num_data
        warning('Mismatch: Mesh has %d triangles but result file has %d data points.', num_elements, num_data);
        min_len = min(num_elements, num_data);
        Elements = Elements(1:min_len, :);
        h_values = h_values(1:min_len);
    else
        fprintf('Data verified: %d elements match %d data points.\n', num_elements, num_data);
    end

    % --- 4. Plotting ---
    fprintf('Plotting...\n');
    figure('Color', 'w');
    
    % Plot the mesh with colors based on 'h_values'
    patch('Faces', Elements, 'Vertices', Nodes, ...
          'FaceVertexCData', h_values, ...
          'FaceColor', 'flat', ...
          'EdgeColor', 'none'); 
      
    % Aesthetic settings
    colormap(jet);       
    c = colorbar;
    c.Label.String = 'Water Depth (h)';
    
    axis equal;
    title('Flood Simulation Result: Water Depth');
    xlabel('X Coordinate');
    ylabel('Y Coordinate');
    grid on;
    
    fprintf('Done.\n');
end


% --- Helper to read Gmsh ---
function [Nodes, Elements] = read_gmsh_triangles(filename)
    fid = fopen(filename, 'rt');
    Nodes = []; Elements = [];
    MaxNodeID = 0;
    while ~feof(fid)
        line = fgetl(fid);
        if contains(line, '$Nodes')
            info = fscanf(fid, '%d', 4);
            numBlocks = info(1); MaxNodeID = info(4);
            Nodes = zeros(MaxNodeID, 3);
            for i=1:numBlocks
                bInfo = fscanf(fid, '%d', 4); nInBlock = bInfo(4);
                ids = fscanf(fid, '%d', nInBlock);
                coords = fscanf(fid, '%f', [3, nInBlock]);
                Nodes(ids, :) = coords';
            end
            fgetl(fid);
        elseif contains(line, '$Elements')
            info = fscanf(fid, '%d', 4);
            numBlocks = info(1);
            for i=1:numBlocks
                bInfo = fscanf(fid, '%d', 4); type=bInfo(3); nInBlock=bInfo(4);
                if type==2
                    d = fscanf(fid, '%d', [4, nInBlock]);
                    Elements = [Elements; d(2:4, :)'];
                else
                    skip = 0;
                    if type==15, skip=2; elseif type==1, skip=3; end
                    if skip>0, fscanf(fid, '%d', [skip, nInBlock]); end
                end
            end
            fgetl(fid);
        end
    end
    fclose(fid);
end
