function [Nodes, Elements, values] = valueMeshTriangle(txt_file, variable_name, msh_file, pltFlag)
    % valueMeshTriangle Reads simulation data and returns mesh/values for plotting.
    %
    % Usage:
    %   [Nodes, Elements, values] = valueMeshTriangle('pic_1380.txt', 'h', 'laonong.msh', true);
    %
    % Inputs:
    %   txt_file (string): Path to .txt result file.
    %   variable_name (string): 'h', 'zb', 'qx', 'qy', or 'zw'.
    %   msh_file (string): Path to .msh file.
    %   pltFlag (logical): true = plot inside function; false = just return data.
    %
    % Outputs:
    %   Nodes: N x 3 matrix of node coordinates.
    %   Elements: M x 3 matrix of triangle indices.
    %   values: M x 1 vector of values for each triangle.

    % --- Default Arguments ---
    if nargin < 4; pltFlag = true; end
    if nargin < 3; msh_file = 'laonong_gmsh_size_10.msh'; end
    if nargin < 2; variable_name = 'h'; end

    % --- File Check ---
    if ~isfile(msh_file) || ~isfile(txt_file)
        error('Files not found. Please ensure both .msh and .txt files are in the current folder.');
    end

    % --- 1. Read Mesh Data (.msh) ---
    fprintf('Reading mesh file: %s...\n', msh_file);
    [Nodes, Elements] = read_gmsh_triangles(msh_file);
    
    % --- 2. Read Simulation Result (.txt) ---
    fprintf('Reading result file: %s...\n', txt_file);
    
    % --- USER PROVIDED DATA READING BLOCK ---
    % Using readmatrix as requested (handles numeric conversion automatically)
    data = readmatrix(txt_file);
    
    % (Optional) Filter out rows that might be all NaNs if readmatrix captures empty lines
    % data = data(~any(isnan(data), 2), :); 

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
    
    % Assign to output variable
    values = value;
    % ----------------------------------------

    % --- 3. Consistency Check ---
    num_elements = size(Elements, 1);
    num_data = length(values);
    
    if num_elements ~= num_data
        warning('Mismatch: Mesh has %d triangles but data has %d points.', num_elements, num_data);
        min_len = min(num_elements, num_data);
        Elements = Elements(1:min_len, :);
        values = values(1:min_len);
    else
        fprintf('Data verified: %d elements match %d data points.\n', num_elements, num_data);
    end

    % --- 4. Plotting (Optional) ---
    if pltFlag
        
        patch('Faces', Elements, 'Vertices', Nodes, ...
              'FaceVertexCData', values, ...
              'FaceColor', 'flat', ...
              'EdgeColor', 'none'); 
          
        colormap(turbo);
        c = colorbar;
        c.Label.String = variable_name;
        
        axis equal;
        title(variable_name);
        xlabel('E [m]');
        ylabel('N [m]');
    end
end