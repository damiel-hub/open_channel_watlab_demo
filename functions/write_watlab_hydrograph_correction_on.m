function write_watlab_hydrograph_correction_on(filename, t, Q, inflowLength)
% WRITE_WATLAB_HYDROGRAPH Exports hydrograph data to a specific text format.
%
% Inputs:
%   filename     - Name of the output file (e.g., 'hydrogramme.txt')
%   t            - Time vector (seconds)
%   Q            - Discharge vector (cms)
%   inflowLength - Scaling parameter for discharge (meter)

    % Ensure inputs are column vectors for consistent processing
    t = t(:);
    Q = Q(:);

    % Check if vectors are the same length
    if length(t) ~= length(Q)
        error('Time and Discharge vectors must have the same length.');
    end

    % Prepare the data matrix
    % Column 1: Time shifted to start at 0
    % Column 2: Scaled and negated Discharge
    time_shifted = t - t(1); 
    Q_scaled = -Q / inflowLength;
    
    % Combine into a matrix
    clipA = [time_shifted, Q_scaled];

    % Open file for writing
    fileID = fopen(filename, 'w');
    
    if fileID == -1
        error('Cannot open file: %s', filename);
    end

    % Write the header (number of data points)
    % \r\n is used for Windows-style line endings as per original code
    fprintf(fileID, '%d\r\n', length(clipA));

    % Write the data
    % Note: Transpose clipA' is necessary because fprintf reads column-wise
    % Format: Integer time, Float discharge (7 decimal places)
    fprintf(fileID, '%d % .7f\n', clipA');

    % Close file
    fclose(fileID);

    fprintf('Successfully wrote data to %s\n', filename);
end