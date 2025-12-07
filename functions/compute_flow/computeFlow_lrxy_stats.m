function [Q_sum, A_sum, h_max] = computeFlow_lrxy_stats(x, y, h, q_x, q_y)
% computeFlow_lrxy_stats calculates total flow and area from profile data.
% Uses the cross-product method (Flux = qx*dy - qy*dx) for stability.

    % 1. Calculate segment geometry (distance between points)
    dx = diff(x);
    dy = diff(y);
    ds = sqrt(dx.^2 + dy.^2);
    
    % 2. Calculate Flow (Q) using the Mean Value Theorem on segments
    % We average the unit flow (q) at the two nodes of each segment
    qx_mid = 0.5 * (q_x(1:end-1) + q_x(2:end));
    qy_mid = 0.5 * (q_y(1:end-1) + q_y(2:end));
    
    % The Cross Product: Flow normal to the segment
    % Flux = q_x * dy - q_y * dx
    q_normal_segment = qx_mid .* dy - qy_mid .* dx;
    
    % Sum all segments to get Total Discharge
    Q_sum = abs(sum(q_normal_segment, 'all', 'omitmissing'));
    
    % 3. Calculate Area (A) using Trapezoidal Rule
    % Average depth * width of segment
    h_mid = 0.5 * (h(1:end-1) + h(2:end));
    A_sum = sum(h_mid .* ds);
    
    % 4. Max Depth
    h_max = max(h);
end