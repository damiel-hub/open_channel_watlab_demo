function [Q_sum, A_sum, h_max] = computeFlow_lrxy_stats(x, y, h, q_x, q_y)
% computeFlow_lrxy_stats calculates total flow and area from profile data.
%
% Inputs:
%   x, y     - Coordinates along the cross-section.
%   h        - Water depth vector.
%   q_x, q_y - Unit flow vector components.
%
% Output:
%   Q_sum    - Total flow across the cross-section.
%   A_sum    - Total area of cross-section.
%   h_max    - Maximum water depth.

    % 1. Reconstruct distance vector (s) from x and y for integration
    % Calculate distance between consecutive points
    dx_seg = diff(x);
    dy_seg = diff(y);
    ds_seg = sqrt(dx_seg.^2 + dy_seg.^2);
    % Cumulative sum to get s, starting at 0
    s = [0; cumsum(ds_seg)];

    % 2. Compute velocities
    % Avoid division by zero if h is 0
    h_safe = h;
    h_safe(h_safe == 0) = NaN; 
    
    v_x = q_x ./ h_safe;
    v_y = q_y ./ h_safe;
    
    % Fill NaNs where depth was 0
    v_x(isnan(v_x)) = 0;
    v_y(isnan(v_y)) = 0;
    
    v = sqrt(v_x.^2 + v_y.^2);

    % 3. Compute flow angle relative to the cross-section line
    % Pad differences to match array length (method from original code)
    diff_x_padded = [dx_seg(1); dx_seg];
    diff_y_padded = [dy_seg(1); dy_seg];
    
    % Calculate angle
    theta = atan2(diff_x_padded .* v_y - diff_y_padded .* v_x, ...
                  diff_x_padded .* v_x + diff_y_padded .* v_y);

    % 4. Compute flow per unit width perpendicular to cross-section
    q_unsolved = v .* sin(theta) .* h;
    q_unsolved(isnan(q_unsolved)) = 0;
    
    % 5. Integrate to get totals
    Q_sum = abs(trapz(s, q_unsolved));
    A_sum = trapz(s, h);
    h_max = max(h);
end