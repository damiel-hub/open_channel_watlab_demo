function [Nodes, Elements] = get_gmsh_mesh(msh_file, pltFlag)
    % get_gmsh_mesh Reads a Gmsh .msh file and returns geometry data.
    %
    % Inputs:
    %   msh_file (string): Path to the .msh file.
    %   pltFlag (logical, optional): 
    %       - true: Plot the mesh in a new figure.
    %       - false: Do not plot (default).
    %
    % Outputs:
    %   Nodes: N x 3 matrix of node coordinates [x, y, z].
    %   Elements: M x 3 matrix of triangle node indices.
    %
    % Example (Plot outside the function):
    %   [Nodes, Elements] = get_gmsh_mesh('laonong.msh', false);
    %   figure; 
    %   triplot(Elements, Nodes(:,1), Nodes(:,2), 'k');

    %
    % 1. Get data
    % [Nodes, Elements] = get_gmsh_mesh('laonong_gmsh_size_10.msh', false);
    % 
    % 2. Plot
    % figure
    % triplot(Elements, Nodes(:,1), Nodes(:,2), 'Color', 'blue');
    % axis equal


    % --- Default Arguments ---
    if nargin < 2; pltFlag = false; end

    % --- 1. Read Mesh ---
    if ~isfile(msh_file)
        error('File not found: %s', msh_file);
    end
    
    fprintf('Reading mesh: %s...\n', msh_file);
    [Nodes, Elements] = read_gmsh_triangles(msh_file);
    
    % --- 2. Plotting (Optional) ---
    if pltFlag
        
        % Create triangulation object for easy plotting
        TR = triangulation(Elements, Nodes(:,1), Nodes(:,2));
        
        % Plot wireframe
        triplot(TR, 'Color', 'k', 'LineWidth', 0.5);
        
        axis equal;
        title('Triangular Mesh Structure');
        xlabel('E');
        ylabel('N');
        box on;
    end
end