clear; close all; clc;

addpath(genpath('functions'))
watlab_output_folder = 'results/Simple_Dam_Break/outputs';
result_png_folder = 'results/Simple_Dam_Break/pngs';


%%
dxdy = 0.01;
simulation_duration = 5;
pic_n = 51;
[time_vals, file_names] = get_hydroflow_filenames(simulation_duration, pic_n);
quiver_sparse = 2;
quiver_factor = 1;
cmax = 0.15; % maximum color range

parfor i_time = 1:length(file_names)

    pic_path = fullfile(watlab_output_folder, ['pic_' file_names{i_time} '.txt']);
    
    [xMesh, yMesh, hMesh] = valueMeshMapper(pic_path, 'h', dxdy);
    [~, ~, qxMesh] = valueMeshMapper(pic_path, 'qx', dxdy);
    [~, ~, qyMesh] = valueMeshMapper(pic_path, 'qy', dxdy);
    
    uMesh = qxMesh./hMesh;
    vMesh = qyMesh./hMesh;
    

    figure('Visible','off')
    imagesc(xMesh(1,:), yMesh(:,1) , hMesh, 'AlphaData', ~isnan(hMesh))
    hold on
    quiver(xMesh(1:quiver_sparse:end,1:quiver_sparse:end), yMesh(1:quiver_sparse:end,1:quiver_sparse:end), uMesh(1:quiver_sparse:end,1:quiver_sparse:end), vMesh(1:quiver_sparse:end,1:quiver_sparse:end), quiver_factor, 'k')
    clim([0 cmax]) % Setting the colorbar range
    axis tight
    hcb = colorbar();
    title(hcb, 'h [m]')
    title(['t = ' num2str(time_vals(i_time)) ' [sec]'])
    writefigure(fullfile(result_png_folder, ['t_' file_names{i_time} '.png']))
end

fps = 5; % frame per second
mp4_name = 'result.mp4';
pngs2mp4(result_png_folder, 't_*.png', mp4_name, fps) % Export sequences images to mp4


function writefigure(filename)

    % Get folder path from filename
    [folderPath, ~, ~] = fileparts(filename);

    % Create folder if it doesn't exist (and if path is not empty)
    if ~isempty(folderPath) && ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end

    print(filename, '-dpng', '-r300')
end