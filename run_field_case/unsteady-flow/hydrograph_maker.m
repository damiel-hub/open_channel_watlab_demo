addpath(genpath('functions'))

% Criss, R. E., & Winston, W. E. (2003). 
% Hydrograph for small basins following intense storms. 
% Geophysical Research Letters, 30(6).

% Parameters
time_lag = 7*3600; % Time lag in seconds
b = 1.5*time_lag; % Time constant in seconds
t = (1/(24*6):1/(24*6):10)*3600*24; % Time series in seconds (time steps = 10 mins) 
Qmax = 2383; % Peak flow (cms)

% Hydrograph calculation
Q = Qmax * (2 * exp(1) * b ./ (3 * t)).^(3/2) .* exp(-b ./ t);

% Plot hydrograph
figure
plot(t, Q, 'b-', 'LineWidth', 2)
xlabel('Time (secs)')
ylabel('Discharge (cms)')
title('Hydrograph')
grid on

print('data/txt/hydrograph.png','-dpng','-r300')

write_watlab_hydrograph_correction_off('data/txt/hydrograph.txt', t, Q)