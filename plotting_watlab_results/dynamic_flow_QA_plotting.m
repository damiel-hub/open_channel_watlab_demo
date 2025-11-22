cross_section_path = 'shape\cross_section';
dxdy = 10;
ds = dxdy/5;
dem_path = '..\W13_environment_setup\watlab-field-case\raster\raw\laonongDEM_5m.tif';

time_sequence = 0:1800:84600;
Q_all = zeros(size(time_sequence));
A_all = zeros(size(time_sequence));
h_all = zeros(size(time_sequence));
parfor i = 1:length(time_sequence)
    pic_path = ['outputs_unsteady\pic_' num2str(time_sequence(i)) '_00.txt'];
    [Q_all(i),A_all(i),h_all(i)] = computeFlow(pic_path,cross_section_path,dxdy,ds,dem_path,0);
end

figure
plot(Q_all, A_all, 'k.-')
xlabel('Q (cms)')
ylabel('A (m^2)')

figure
plot(Q_all, h_all, 'k.-')
xlabel('Q (cms)')
ylabel('h (m)')


%%
% Errors or delays in synchronizing discharge and area measurements can lead to apparent loops in the chart
tQ = readmatrix("hydrogramme.txt");
tQ(:,2) = tQ(:,2)*(-329.977);
Q_sequence = interp1(tQ(:,1),tQ(:,2),time_sequence);
figure
plot(Q_sequence, A_all, 'k.-')
xlabel('Q (cms)')
ylabel('A (m^2)')

