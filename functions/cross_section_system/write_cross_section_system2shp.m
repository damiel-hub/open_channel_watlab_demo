function write_cross_section_system2shp(shapefileName, interp_x, interp_y, interp_L_x, interp_L_y, interp_R_x, interp_R_y, interp_s, EPSG_code)
    % Export cross-sections to shapefile
    % Made by Yuan-Hung Chiu
    
    arguments
        shapefileName 
        interp_x 
        interp_y 
        interp_L_x 
        interp_L_y 
        interp_R_x 
        interp_R_y 
        interp_s = [];
        EPSG_code = 3826; % TWD97
    end

    x_cell = num2cell([interp_R_x interp_L_x],2);
    y_cell = num2cell([interp_R_y interp_L_y],2);
    x_cell{end+1} = interp_x;
    y_cell{end+1} = interp_y;

    if isempty(interp_s)
        interp_s = [0;cumsum(sqrt(diff(interp_x).^2 + diff(interp_y).^2))];
    end
    Attribute.s = num2cell(interp_s);
    Attribute.s{end+1} = -1;
    m_shapewrite(x_cell, y_cell, shapefileName, 'Line', EPSG_code, Attribute)

end