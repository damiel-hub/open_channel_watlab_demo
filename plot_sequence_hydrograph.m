clear; close all; clc;

addpath(genpath('functions'))

% Inherit the parameters and files from Watlab
simulation_duration = 3000; % (sec)
pic_n = 51;
hydrograph_path = 'data/txt/steep/hydrograph.txt';


% Results folder path
result_png_folder = 'results/laonong_unsteady_narrow_20m_cfl05_hydrograph_steep/pngs_hrdrograph';
mkdir(result_png_folder)

% MP4 relate parameters
fps = 5; % frame per second
mp4_name = 'result.mp4';

%%

tQ = readmatrix(hydrograph_path);
[time_vals, file_names] = get_hydroflow_filenames(simulation_duration, pic_n);
pics_Q = interp1(tQ(:,1), tQ(:,2), time_vals);

parfor i_time = 1:length(file_names)
    figure('Visible','off')
    plot(tQ(:,1), tQ(:,2), 'b-')
    hold on
    plot(time_vals(i_time), pics_Q(i_time), 'b.', 'MarkerSize', 15)
    title(['t = ' num2str(time_vals(i_time)) ' [sec], Qin = ' num2str(pics_Q(i_time)) '[cms]'])
    xlabel('time [sec]')
    ylabel('discharge [cms]')

    print(fullfile(result_png_folder, ['t_' file_names{i_time} '.png']), '-dpng', '-r300')
end


pngs2mp4(result_png_folder, 't_*.png', mp4_name, fps) % Export sequences images to mp4