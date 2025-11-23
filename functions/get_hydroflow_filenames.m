function [times_sec, suffixes] = get_hydroflow_filenames(ending_time, n_pic)
    % GET_HYDROFLOW_DATA
    % Inputs:
    %   ending_time (double): e.g., 5.0
    %   n_pic (int): e.g., 50
    %
    % Outputs:
    %   times_sec (double array): The simulation time in seconds.
    %   suffixes (cell array): The 'x_xx' string format (e.g., '4_90').

    % 1. Generate the raw times exactly like Python
    raw_times = linspace(0, ending_time, n_pic);
    
    % 2. Initialize output arrays
    times_sec = [];
    suffixes = {};
    
    % 3. Loop and Filter
    for i = 1:n_pic
        t = raw_times(i);
        
        % --- FINISH LINE FILTER ---
        % If time is equal to or greater than ending_time, 
        % the C++ solver quits before writing.
        if t < (ending_time - 1e-9)
            
            % Save the time (Output 1)
            times_sec(end+1, 1) = t;
            
            % Format the suffix (Output 2)
            % Format as '4.90', then replace dot with underscore -> '4_90'
            t_str = sprintf('%1.2f', t);
            t_clean = strrep(t_str, '.', '_');
            
            suffixes{end+1, 1} = t_clean;
        end
    end
end