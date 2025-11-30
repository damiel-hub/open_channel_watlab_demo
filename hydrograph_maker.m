addpath(genpath('functions'))

% Criss, R. E., & Winston, W. E. (2003). 
% Hydrograph for small basins following intense storms. 
% Geophysical Research Letters, 30(6).

% Parameters
time_lag = 50; % (sec)
t = 1:10:3000; % Time series in seconds (time steps = 10 mins) 
Qmax = 50000; % Peak flow (cms)

% Hydrograph calculation
b = 1.5*time_lag; % Time constant in seconds
Q = Qmax * (2 * exp(1) * b ./ (3 * t)).^(3/2) .* exp(-b ./ t);

% Plot hydrograph
figure
plot(t, Q, 'b-', 'LineWidth', 2)
xlabel('Time (secs)')
ylabel('Discharge (cms)')
title('Hydrograph')
grid on

print('data/txt/steep/hydrograph.png','-dpng','-r300')

write_watlab_hydrograph_correction_off('data/txt/steep/hydrograph.txt', t, Q)

%%
% Parameters
time_lag = 150; % (sec)
t = 1:10:3000; % Time series in seconds (time steps = 10 mins) 
Qmax = 2000; % Peak flow (cms)

% Hydrograph calculation
b = 1.5*time_lag; % Time constant in seconds
Q = Qmax * (2 * exp(1) * b ./ (3 * t)).^(3/2) .* exp(-b ./ t);

% Plot hydrograph
figure
plot(t, Q, 'b-', 'LineWidth', 2)
xlabel('Time (secs)')
ylabel('Discharge (cms)')
title('Hydrograph')
grid on

print('data/txt/gentle/hydrograph.png','-dpng','-r300')

write_watlab_hydrograph_correction_off('data/txt/gentle/hydrograph.txt', t, Q)