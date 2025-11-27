function [interp_s, interp_x, interp_y, interp_m] = interpPolyline_sxy(lineXY, ds, m)
    % interpPolyline_sxy interpolates a polyline with given x and y coordinates 
    % and optionally magnitudes (m) at each point.
    %
    % INPUTS:
    %   lineXY: Nx2 array where each row represents (x, y) coordinates.
    %   ds: The spacing for interpolation.
    %   m: (Optional) Nx1 array of magnitudes corresponding to lineXY.
    %
    % OUTPUTS:
    %   interp_s: Cumulative arc length values at interpolated points.
    %   interp_x: Interpolated x coordinates.
    %   interp_y: Interpolated y coordinates.
    %   interp_m: (Optional) Interpolated magnitudes.
    
    % Compute cumulative arc length
    s = [0; cumsum(sqrt(sum(diff(lineXY).^2, 2)))];
    
    % Interpolated cumulative arc length
    interp_s = 0:ds:s(end);
    
    % Interpolate x and y coordinates
    interp_x = interp1(s, lineXY(:,1), interp_s);
    interp_y = interp1(s, lineXY(:,2), interp_s);
    
    % Interpolate m values if provided
    if nargin > 2 && ~isempty(m)
        interp_m = interp1(s, m, interp_s);
    else
        interp_m = []; % Return empty if m is not provided
    end
end
