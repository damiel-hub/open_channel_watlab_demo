function colmapNew = powlawColormap(colmap,alpha,dispflag)

numCol = size(colmap,1);
coord = (0:(numCol-1))/(numCol-1);
coordNew = coord.^alpha;
for l = 1:3
    colmapNew(:,l) = interp1(coord,colmap(:,l),coordNew);
end

if dispflag
    [xMesh,yMesh] = meshgrid(0:1:10,0:1:5);
    zMesh = xMesh*2.5;
    
    figure
    subplot(2,1,1)
    pcolor(xMesh,yMesh,zMesh)
    shading flat
    colormap(colmap)
    freezeColors
    
    subplot(2,1,2)
    pcolor(xMesh,yMesh,zMesh)
    shading flat
    colormap(colmapNew)
end
end