plot_gmsh()

function plot_gmsh()
    filename = 'laonong_gmsh_size_10.msh';
    
    if ~isfile(filename)
        error('File not found: %s', filename);
    end
    
    fid = fopen(filename, 'rt');
    
    Nodes = [];     % To store [x, y, z]
    Elements = [];  % To store [node1, node2, node3]
    
    % Node map to handle non-contiguous node IDs if necessary
    % For this script, we assume max node ID determines array size for speed
    MaxNodeID = 0; 
    
    currentLine = fgetl(fid);
    while ischar(currentLine)
        if contains(currentLine, '$Nodes')
            % Read header: numEntityBlocks numNodes minNodeTag maxNodeTag
            info = fscanf(fid, '%d', 4);
            numEntityBlocks = info(1);
            numNodesTotal = info(2);
            MaxNodeID = info(4);
            
            % Pre-allocate coordinate array (Index is Node ID)
            Nodes = zeros(MaxNodeID, 3);
            
            for i = 1:numEntityBlocks
                % Block header: entityDim entityTag parametric numNodesInBlock
                blockInfo = fscanf(fid, '%d', 4);
                numNodesInBlock = blockInfo(4);
                
                % Read Node IDs in this block
                nodeIDs = fscanf(fid, '%d', numNodesInBlock);
                
                % Read Coordinates (x, y, z) for these nodes
                % Reshape because fscanf reads column-wise
                coords = fscanf(fid, '%f', [3, numNodesInBlock]);
                coords = coords'; % Transpose to get N x 3
                
                % Store in global Nodes array at indices corresponding to IDs
                Nodes(nodeIDs, :) = coords;
            end
            fgetl(fid); % Consume newline after last block
            
        elseif contains(currentLine, '$Elements')
            % Read header: numEntityBlocks numElements minElementTag maxElementTag
            info = fscanf(fid, '%d', 4);
            numEntityBlocks = info(1);
            
            for i = 1:numEntityBlocks
                % Block header: entityDim entityTag elementType numElementsInBlock
                blockInfo = fscanf(fid, '%d', 4);
                elementType = blockInfo(3);
                numElementsInBlock = blockInfo(4);
                
                % elementType 2 is a 3-node triangle
                if elementType == 2
                    % Read element data: elementTag node1 node2 node3
                    % Data comes in sets of 4 integers
                    data = fscanf(fid, '%d', [4, numElementsInBlock]);
                    % We only need rows 2, 3, 4 (the node IDs)
                    newTris = data(2:4, :)'; 
                    Elements = [Elements; newTris];
                else
                    % Skip other element types (lines, points, etc.)
                    % Each element usually has (1 + num_nodes) integers
                    % Approximating skip based on type is risky, but in Gmsh 4.1
                    % we generally just consume the known amount of integers.
                    % Line (type 1) = 1 tag + 2 nodes = 3 ints
                    % Point (type 15) = 1 tag + 1 node = 2 ints
                    nodesPerElem = 0;
                    if elementType == 15; nodesPerElem = 1; end
                    if elementType == 1;  nodesPerElem = 2; end
                    if elementType == 3;  nodesPerElem = 4; end % Quad
                    
                    if nodesPerElem > 0
                         fscanf(fid, '%d', [(1 + nodesPerElem), numElementsInBlock]);
                    else
                         % Fallback: if unknown type, reading might desync. 
                         % For your specific file, mostly lines (type 1) and tris (type 2) exist.
                         warning('Skipping unknown or unhandled element type: %d', elementType);
                    end
                end
            end
            fgetl(fid); 
        end
        currentLine = fgetl(fid);
    end
    fclose(fid);
    
    % --- Plotting ---
    if isempty(Nodes) || isempty(Elements)
        disp('No mesh data found to plot.');
        return;
    end
    
    figure;
    % trimesh plots the connectivity
    trimesh(Elements, Nodes(:,1), Nodes(:,2), Nodes(:,3), ...
        'EdgeColor', 'k', 'FaceColor', 'cyan', 'FaceAlpha', 0);
    
    axis equal;
    title('Gmsh Triangular Mesh');
    xlabel('X Coordinate');
    ylabel('Y Coordinate');
    grid on;
    
    disp(['Plotted ' num2str(size(Elements,1)) ' triangular elements.']);
end