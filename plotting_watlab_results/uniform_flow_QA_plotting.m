path(path,'funs')
demPath = '..\W13_environment_setup\watlab-field-case\raster\raw\laonongDEM_5m.tif';
crossSectionPath = 'shape\cross_section';
lineXY = m_shaperead(crossSectionPath).ncst{1};
[xMesh,yMesh,zMesh] = readGeoTiff(demPath);

lightterrain2D_imagesc(xMesh,yMesh,zMesh)
hold on
plot(lineXY(:,1),lineXY(:,2),'r.-')


[lineS_resample, lineX_resample, lineY_resample, ~] = interpPolyline_sxy(lineXY,5);

plot(lineX_resample,lineY_resample,'b.-')

lineZ_resample = interp2(xMesh,yMesh,zMesh,lineX_resample,lineY_resample);

figure
plot(lineS_resample, lineZ_resample, 'k-')

zb_min = min(lineZ_resample(:));

waterdepth = 0:0.1:30;

waterlevel = waterdepth + zb_min;
%%
% Parameters
n = 0.05;
C = 17.2;
S = (556-547.8)/450;
waterdepth_matrix = waterlevel' - lineZ_resample;
waterdepth_matrix(waterdepth_matrix<0) = 0;
A = trapz(lineS_resample, waterdepth_matrix, 2);

waterdepth_mid_matrix = (waterdepth_matrix(:,1:end-1)+waterdepth_matrix(:,2:end))/2;
u_mid_matrix = (1/n)*waterdepth_mid_matrix.^(2/3)*S^0.5; % Manning
% u_mid_matrix = C*sqrt(waterdepth_mid_matrix*S); % Chezy
dA_mid_matrix = diff(cumtrapz(lineS_resample,waterdepth_matrix,2),1,2);
dQ_mid_matrix = u_mid_matrix.*dA_mid_matrix;

Q = sum(dQ_mid_matrix,2);

figure
plot(Q,A,'k-')
xlabel('Q (cms)')
ylabel('A (m^2)')

figure
plot(Q,waterdepth,'k-')
xlabel('Q (cms)')
ylabel('h (m)')