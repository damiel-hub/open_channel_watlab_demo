function pngs2mp4(imageFolder, imageName, videoName, fps)
    outputVideoPath = fullfile(imageFolder, videoName);
    
    if ~isfolder(imageFolder)
        error('Folder not found: %s', imageFolder);
    end
    
    % 1. Find all files matching the pattern (e.g., t_*.png)
    imageFiles = dir(fullfile(imageFolder, imageName));
    if isempty(imageFiles)
        error('No images found matching %s', imageName);
    end
    
    % 2. SMART SORTING (The Fix)
    % We extract the "Number_Number" pattern (e.g., 4_90) from filenames.
    % We treat the underscore as a dot for sorting purposes.
    fileNames = {imageFiles.name};
    timeValues = zeros(length(fileNames), 1);
    
    for i = 1:length(fileNames)
        fname = fileNames{i};
        
        % Regex: Find digits, underscore, digits (e.g., 0_00 or 15_50)
        tokens = regexp(fname, '(\d+_\d+)', 'tokens');
        
        if ~isempty(tokens)
            % Take the string "4_90"
            timeStr = tokens{1}{1};
            % Replace underscore with dot: "4.90"
            timeStr = strrep(timeStr, '_', '.');
            % Convert to number for math sorting
            timeValues(i) = str2double(timeStr);
        else
            timeValues(i) = NaN; % Handle files that don't match
        end
    end
    
    % Sort based on the extracted time values
    [~, sortedIndices] = sort(timeValues);
    sortedImageFiles = imageFiles(sortedIndices);
    
    % 3. Write Video (Resizing included)
    v = VideoWriter(outputVideoPath, 'MPEG-4');
    v.FrameRate = fps;
    v.Quality = 95;
    open(v);
    
    % Read first image to set dimensions
    firstImg = imread(fullfile(imageFolder, sortedImageFiles(1).name));
    [h, w, ~] = size(firstImg);
    % Ensure Even Dimensions (Important for MP4)
    if mod(h, 2) ~= 0, h = h - 1; end
    if mod(w, 2) ~= 0, w = w - 1; end
    
    fprintf('Creating video from %d sorted frames...\n', length(sortedImageFiles));
    
    for k = 1:length(sortedImageFiles)
        currentFile = sortedImageFiles(k).name;
        img = imread(fullfile(imageFolder, currentFile));
        img = img(1:h, 1:w, :); % Crop to standard size
        writeVideo(v, img);
    end
    
    close(v);
    fprintf('Video saved: %s\n', outputVideoPath);
end