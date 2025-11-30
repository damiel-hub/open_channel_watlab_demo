function [b_x, b_y] = get_gmsh_boundary(msh_file, target_name, pltFlag)
    % plot_gmsh_boundary Extracts and plots a specific boundary by name.
    %
    % Inputs:
    %   msh_file (string): Path to .msh file.
    %   target_name (string): Name of the boundary (e.g., 'Qin', 'Wall').
    %   pltFlag (logical): true = plot immediately; false = quiet.
    %
    % Outputs:
    %   b_x, b_y: Vectors of coordinates ready for plotting.
    %             They contain NaNs to separate line segments.
    %             Usage: plot(b_x, b_y)
    %
    % Example:
    %   [x, y] = plot_gmsh_boundary('laonong.msh', 'Qin', false);
    %   plot(x, y, 'r-', 'LineWidth', 2);

    % --- Defaults ---
    if nargin < 3; pltFlag = true; end
    if ~isfile(msh_file); error('File not found.'); end

    % --- 1. Find the Tag for the Name ---
    [target_dim, target_phys_tag] = get_physical_tag(msh_file, target_name);
    if target_phys_tag == -1
        error('Physical name "%s" not found in file.', target_name);
    end
    
    % --- 2. Find Associated Entities ---
    target_entity_tags = get_entity_tags(msh_file, target_dim, target_phys_tag);
    if isempty(target_entity_tags)
        warning('No geometry entities found for "%s".', target_name);
        b_x = []; b_y = []; return;
    end

    % --- 3. Extract Nodes and Elements ---
    [Nodes, Elements] = read_gmsh_subset(msh_file, target_dim, target_entity_tags);
    if isempty(Elements)
        warning('No elements found for "%s".', target_name);
        b_x = []; b_y = []; return;
    end

    % --- 4. Prepare X, Y Output (NaN Separated) ---
    % Elements is M x NodesPerElem (e.g., M x 2 for lines)
    num_elems = size(Elements, 1);
    nodes_per_elem = size(Elements, 2);
    
    % We build a matrix [x1, x2, ... xN, NaN; ...] and flatten it
    X_mat = NaN(num_elems, nodes_per_elem + 1);
    Y_mat = NaN(num_elems, nodes_per_elem + 1);
    
    for k = 1:nodes_per_elem
        node_indices = Elements(:, k);
        X_mat(:, k) = Nodes(node_indices, 1);
        Y_mat(:, k) = Nodes(node_indices, 2);
    end
    
    % Flatten to vectors: [x1a x1b NaN x2a x2b NaN ...]
    % Transpose first so we read row-by-row
    b_x = X_mat'; b_x = b_x(:);
    b_y = Y_mat'; b_y = b_y(:);

    % --- 5. Plotting ---
    if pltFlag
        if target_dim == 1
            % It's a line/curve boundary
            plot(b_x, b_y, 'b-', 'LineWidth', 1.5);
            title(sprintf('Boundary: %s', target_name));
        elseif target_dim == 2
            % It's a surface/domain
            patch('Faces', Elements, 'Vertices', Nodes, ...
                  'FaceColor', 'cyan', 'EdgeColor', 'k', 'FaceAlpha', 0.5);
            title(sprintf('Domain: %s', target_name));
        end
        axis equal
        xlabel('E'); ylabel('N');
    end
end

% -------------------------------------------------------------------------
%                           HELPER FUNCTIONS
% -------------------------------------------------------------------------

function [dim, phys_tag] = get_physical_tag(filename, name)
    fid = fopen(filename, 'rt');
    dim = -1; phys_tag = -1;
    while ~feof(fid)
        line = fgetl(fid);
        if contains(line, '$PhysicalNames')
            numNames = fscanf(fid, '%d', 1);
            for i = 1:numNames
                l = fgetl(fid);
                % Parse: dim tag "Name"
                % Handle quotes robustly
                q_indices = strfind(l, '"');
                if length(q_indices) >= 2
                    c_name = l(q_indices(1)+1 : q_indices(end)-1);
                    if strcmp(c_name, name)
                        data = sscanf(l(1:q_indices(1)-1), '%d %d');
                        dim = data(1); phys_tag = data(2);
                        fclose(fid); return;
                    end
                end
            end
        end
    end
    fclose(fid);
end

function entity_tags = get_entity_tags(filename, target_dim, target_phys_tag)
    fid = fopen(filename, 'rt');
    entity_tags = [];
    while ~feof(fid)
        line = fgetl(fid);
        if contains(line, '$Entities')
            counts = fscanf(fid, '%d', 4);
            nP=counts(1); nC=counts(2); nS=counts(3); nV=counts(4);
            
            fgetl(fid); 
   
            % Loop through all entities to find matches
            for d = 0:3
                count = 0;
                if d==0; count=nP; elseif d==1; count=nC; elseif d==2; count=nS; elseif d==3; count=nV; end
                
                for k = 1:count
                    if d == target_dim
                        entity_tags = [entity_tags, parse_entity_line(fid, d, target_phys_tag)];
                    else
                        fgetl(fid); % Skip line
                    end
                end
            end
            fclose(fid); return;
        end
    end
    fclose(fid);
end

function match_tag = parse_entity_line(fid, dim_idx, target_phys_tag)
    match_tag = [];
    % Read tag
    tag = fscanf(fid, '%d', 1);
    % Skip bounding box
    if dim_idx == 0; fscanf(fid, '%f', 3); else; fscanf(fid, '%f', 6); end
    % Read phys tags
    numPhys = fscanf(fid, '%d', 1);
    physTags = fscanf(fid, '%d', numPhys);
    
    if ismember(target_phys_tag, physTags)
        match_tag = tag;
    end
    fgetl(fid); % Consume rest
end

function [Nodes, Elements] = read_gmsh_subset(filename, target_dim, target_entities)
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
                bInfo = fscanf(fid, '%d', 4); 
                eDim=bInfo(1); eTag=bInfo(2); eType=bInfo(3); nElems=bInfo(4);
                
                if eDim == target_dim && ismember(eTag, target_entities)
                    nPe = 0;
                    if eType==1; nPe=2; elseif eType==2; nPe=3; elseif eType==15; nPe=1; end
                    
                    if nPe > 0
                        d = fscanf(fid, '%d', [1+nPe, nElems]);
                        Elements = [Elements; d(2:end, :)'];
                    else
                        fgetl(fid);
                    end
                else
                    % Skip logic
                    skip = 0;
                    if eType==1; skip=3; elseif eType==2; skip=4; elseif eType==15; skip=2; end
                    if skip>0; fscanf(fid, '%d', [skip, nElems]); else; fgetl(fid); end
                end
            end
            fgetl(fid);
        end
    end
    fclose(fid);
end