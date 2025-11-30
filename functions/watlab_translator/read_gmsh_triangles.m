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