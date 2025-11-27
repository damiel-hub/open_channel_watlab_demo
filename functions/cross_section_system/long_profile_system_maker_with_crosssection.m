function [interp_x, interp_y, interp_R_x, interp_R_y, interp_L_x, interp_L_y, interp_s, interp_vertical_theta] = long_profile_system_maker_with_crosssection(ds, point_xy, extra_cross_section_Lx_Ly_Rx_Ry, point_L_xy, point_R_xy, pltFlag)
% long_profile_system_maker_with_crosssection
%
% This function creates an interpolated longitudinal profile system, incorporating
% user-defined cross-sections.The left and right boundaries are used to trim the cross-section's extent, and finally
% interpolates these lines at a specified sampling interval `ds`.
%
% Inputs:
%   ds                           - Scalar, the desired sampling interval for interpolation.
%   point_xy                     - Nx2 matrix of [x, y] coordinates defining the initial centerline of the profile.
%   extra_cross_section_Lx_Ly_Rx_Ry - Px4 matrix where each row defines an
%                                    additional cross-section as [Lx Ly Rx Ry].
%                                    These cross-sections are used to influence
%                                    the along-profile orientation.
%   point_L_xy                   - Mx2 matrix of [x, y] coordinates defining the left bank boundary of the profile.
%   point_R_xy                   - Qx2 matrix of [x, y] coordinates defining the right bank boundary of the profile.
%   pltFlag                      - Boolean flag, if true, generates a plot of the input points and
%                                  the interpolated profile with its boundaries and cross-sections.
%
% Outputs:
%   interp_x           - Kx1 vector of interpolated x-coordinates of the centerline.
%   interp_y           - Kx1 vector of interpolated y-coordinates of the centerline.
%   interp_R_x         - Kx1 vector of interpolated x-coordinates of the right bank boundary.
%   interp_R_y         - Kx1 vector of interpolated y-coordinates of the right bank boundary.
%   interp_L_x         - Kx1 vector of interpolated x-coordinates of the left bank boundary.
%   interp_L_y         - Kx1 vector of interpolated y-coordinates of the left bank boundary.
%   interp_s           - Kx1 vector of interpolated arc lengths along the centerline.
%   interp_vertical_theta - Kx1 vector of interpolated angles (in radians)
%                          representing the perpendicular (vertical) direction at each interpolated point.
%
% Dependencies:
%   line_segment_intersect
%
% Example:
%   % Define some example points
%   point_xy = [0 0; 10 5; 20 2; 30 8];
%   extra_cross_section_Lx_Ly_Rx_Ry = [5 7 5 3; 15 0 15 6];
%   point_L_xy = [-2 2; 8 7; 18 4; 28 10];
%   point_R_xy = [2 -2; 12 3; 22 0; 32 6];
%   ds = 1;
%   pltFlag = true;
%
%   % Generate the long profile system
%   [interp_x, interp_y, interp_R_x, interp_R_y, interp_L_x, interp_L_y, interp_s] = ...
%       long_profile_system_maker_with_crosssection(ds, point_xy, extra_cross_section_Lx_Ly_Rx_Ry, point_L_xy, point_R_xy, pltFlag);
%
% See also: interp1, cumsum, atan2, plot, line_segment_intersect
    point_x = point_xy(:,1);
    point_y = point_xy(:,2);
    
    middle_vector_xy = diff(point_xy);
    middle_along_theta = atan2(middle_vector_xy(:,2), middle_vector_xy(:,1));
    point_s = [0; cumsum(sqrt(sum(diff(point_xy).^2,2)))];
    
    
    % We didn't use the unit vector to prevent the small segment from having rapid turning
    % effect on the long segments vector direction
    unit_middle_vector_xy = middle_vector_xy;%./(sqrt(middle_vector_xy(:,1).^2+middle_vector_xy(:,2).^2)+eps);
    point_vector_xy = unit_middle_vector_xy(1:end-1,:)+unit_middle_vector_xy(2:end,:);


    point_along_theta = [middle_along_theta(1); atan2(point_vector_xy(:,2), point_vector_xy(:,1)); middle_along_theta(end)];
    % --- End of Fix 1 ---

    extra_cross_section_verticaltheta = atan2(extra_cross_section_Lx_Ly_Rx_Ry(:,4) - extra_cross_section_Lx_Ly_Rx_Ry(:,2), extra_cross_section_Lx_Ly_Rx_Ry(:,3) - extra_cross_section_Lx_Ly_Rx_Ry(:,1));
    extra_cross_section_alongtheta = extra_cross_section_verticaltheta + pi/2;
    extra_cross_section_alongtheta = mod(extra_cross_section_alongtheta + pi, 2*pi) - pi;
    
    %%
    
    intersections_found = line_segment_intersect(point_xy, extra_cross_section_Lx_Ly_Rx_Ry);
    point_extent_x_y_s_alongtheta = [[point_x;intersections_found(:,1)] [point_y ;intersections_found(:,2)] [point_s; intersections_found(:,3)] [point_along_theta; extra_cross_section_alongtheta]];
    point_extent_x_y_s_alongtheta_sort = sortrows(point_extent_x_y_s_alongtheta, 3);
    
    
    %%
    point_extent_x = point_extent_x_y_s_alongtheta_sort(:,1);
    point_extent_y = point_extent_x_y_s_alongtheta_sort(:,2);
    cum_extent_s = point_extent_x_y_s_alongtheta_sort(:,3);
    point_extent_along_theta = point_extent_x_y_s_alongtheta_sort(:,4);
    
    % --- FIX 2: Unwrap angles before interpolation ---
    % This prevents interp1 from interpolating "the wrong way" around the circle
    unwrapped_along_theta = unwrap(point_extent_along_theta);
    % --- End of Fix 2 ---
    
    interp_s = (0:ds:cum_extent_s(end))';
    interp_x = interp1(cum_extent_s, point_extent_x, interp_s);
    interp_y = interp1(cum_extent_s, point_extent_y, interp_s);
    
    % --- FIX 2 (continued): Interpolate the UNWRAPPED angles ---
    interp_along_theta = interp1(cum_extent_s, unwrapped_along_theta, interp_s);
    % --- End of Fix 2 ---

    interp_vertical_theta = interp_along_theta + pi/2;
    interp_vertical_unit_vector_x = cos(interp_vertical_theta);
    interp_vertical_unit_vector_y = sin(interp_vertical_theta);
    
    interp_R_x = interp_x - interp_vertical_unit_vector_x.*cum_extent_s(end);
    interp_R_y = interp_y - interp_vertical_unit_vector_y.*cum_extent_s(end);
    interp_L_x = interp_x + interp_vertical_unit_vector_x.*cum_extent_s(end);
    interp_L_y = interp_y + interp_vertical_unit_vector_y.*cum_extent_s(end);
    
    intersections_found_R = line_segment_intersect(point_R_xy, [interp_R_x interp_R_y interp_L_x interp_L_y]);
    intersections_found_L = line_segment_intersect(point_L_xy, [interp_R_x interp_R_y interp_L_x interp_L_y]);
    
    interp_xy = [interp_x interp_y];
    intersections_found_R_xy = nan(length(interp_R_x), 2);
    intersections_found_L_xy = nan(length(interp_L_x), 2);
    
    % --- Process Right Bank Intersections ---
    unique_S_indices_R = unique(intersections_found_R(:, 5));
    for i = 1:length(unique_S_indices_R)
        k = unique_S_indices_R(i); 
        rows_for_k = find(intersections_found_R(:, 5) == k);
        
        if isscalar(rows_for_k)
            intersections_found_R_xy(k, :) = intersections_found_R(rows_for_k, 1:2);
        else
            candidate_points = intersections_found_R(rows_for_k, 1:2);
            centerline_point = interp_xy(k, :);
            distances_sq = sum((candidate_points - centerline_point).^2, 2);
            [~, min_dist_idx] = min(distances_sq);
            intersections_found_R_xy(k, :) = candidate_points(min_dist_idx, :);
        end
    end
    
    % --- Process Left Bank Intersections (same logic) ---
    unique_S_indices_L = unique(intersections_found_L(:, 5));
    for i = 1:length(unique_S_indices_L)
        k = unique_S_indices_L(i);
        rows_for_k = find(intersections_found_L(:, 5) == k);
        
        if isscalar(rows_for_k)
            intersections_found_L_xy(k, :) = intersections_found_L(rows_for_k, 1:2);
        else
            candidate_points = intersections_found_L(rows_for_k, 1:2);
            centerline_point = interp_xy(k, :);
            distances_sq = sum((candidate_points - centerline_point).^2, 2);
            [~, min_dist_idx] = min(distances_sq);
            intersections_found_L_xy(k, :) = candidate_points(min_dist_idx, :);
        end
    end
    interp_distance_to_L = sqrt(sum((intersections_found_L_xy - interp_xy).^2,2));
    interp_distance_to_R = sqrt(sum((intersections_found_R_xy - interp_xy).^2,2));
    interp_distance_to_L_fillnan = interp_distance_to_L;
    interp_distance_to_R_fillnan = interp_distance_to_R;
    interp_distance_to_L_fillnan(isnan(interp_distance_to_L)) = interp1(interp_s(~isnan(interp_distance_to_L)), interp_distance_to_L(~isnan(interp_distance_to_L)), interp_s(isnan(interp_distance_to_L)), "linear", 'extrap');
    interp_distance_to_R_fillnan(isnan(interp_distance_to_R)) = interp1(interp_s(~isnan(interp_distance_to_R)), interp_distance_to_R(~isnan(interp_distance_to_R)), interp_s(isnan(interp_distance_to_R)), "linear", 'extrap');
    
    
    interp_R_x = interp_x - interp_vertical_unit_vector_x.*interp_distance_to_R_fillnan;
    interp_R_y = interp_y - interp_vertical_unit_vector_y.*interp_distance_to_R_fillnan;
    interp_L_x = interp_x + interp_vertical_unit_vector_x.*interp_distance_to_L_fillnan;
    interp_L_y = interp_y + interp_vertical_unit_vector_y.*interp_distance_to_L_fillnan;
    
    %%
    if pltFlag
        plot(point_xy(:,1),point_xy(:,2),'bo-')
        hold on
        plot(point_L_xy(:,1), point_L_xy(:,2), 'bo-')
        plot(point_R_xy(:,1), point_R_xy(:,2), 'bo-')
        for i = 1:length(point_xy)
            text(point_xy(i,1),point_xy(i,2),num2str(i))
        end
        plot(point_xy(1,1),point_xy(1,2),'go')
        
        plot(extra_cross_section_Lx_Ly_Rx_Ry(:,[1,3])', extra_cross_section_Lx_Ly_Rx_Ry(:,[2,4])', 'bo-')
        plot([interp_R_x interp_L_x]', [interp_R_y interp_L_y]', 'r.-')
        
        shading flat
        axis equal
        axis tight
    end
end  % <-- This is the end for the main function

function intersections_found = line_segment_intersect(L_points, S_segments_matrix)
% Assuming L_points is an Nx2 matrix [x1 y1; x2 y2; ...]
% Assuming S_segments_matrix is an Mx4 matrix [Ax Ay Bx By; ...]
intersections_found = []; % To store [Ix, Iy, cumulative_dist_L, L_segment_idx, S_segment_idx]
% --- Pre-calculate cumulative distances for L segments (optional but efficient) ---
% This part can be complex if not done carefully within the main loop,
% so I'll show the direct calculation within the loop for clarity.
for i = 1:(size(L_points, 1) - 1) % Iterate through segments of L (P_i, P_{i+1})
    P1 = L_points(i, :);     % Start of L segment (x1, y1)
    P2 = L_points(i+1, :);   % End of L segment (x2, y2)
    % Calculate cumulative distance to the START of the current L segment (P1)
    dist_at_start_of_L_segment = 0;
    if i > 1
        for k_L_dist = 1:(i-1)
            dist_at_start_of_L_segment = dist_at_start_of_L_segment + norm(L_points(k_L_dist+1,:) - L_points(k_L_dist,:));
        end
    end
    for k = 1:size(S_segments_matrix, 1) % Iterate through rows (segments) in S_segments_matrix
        % Extract segment Sk from the current row
        Ak = S_segments_matrix(k, 1:2); % Start of S segment (x3, y3)
        Bk = S_segments_matrix(k, 3:4); % End of S segment (x4, y4)
        % Line Segment Intersection Algorithm
        x1 = P1(1); y1 = P1(2);
        x2 = P2(1); y2 = P2(2);
        x3 = Ak(1); y3 = Ak(2);
        x4 = Bk(1); y4 = Bk(2);
        den = (x1 - x2)*(y3 - y4) - (y1 - y2)*(x3 - x4);
        if den == 0
            % Lines are parallel or collinear.
            continue; % Skip for simplicity, or add collinear check
        end
        t_num = (x1 - x3)*(y3 - y4) - (y1 - y3)*(x3 - x4);
        u_num = -((x1 - x2)*(y1 - y3) - (y1 - y2)*(x1 - x3)); % Original formula for u had a different sign convention, this is common.
        t = t_num / den;
        u = u_num / den;
        
        % Check if intersection point is within both segments
        if (t >= 0 && t <= 1) && (u >= 0 && u <= 1)
            % Intersection exists
            Ix = x1 + t*(x2 - x1);
            Iy = y1 + t*(y2 - y1);
            % Calculate Cumulative Distance on Line L
            dist_on_L_segment = norm([Ix, Iy] - P1); % Distance from P1 to Intersection
            total_cumulative_dist_L = dist_at_start_of_L_segment + dist_on_L_segment;
            intersections_found(end+1, :) = [Ix, Iy, total_cumulative_dist_L, i, k];
            % Store: Ix, Iy, CumulativeDist_L, Index of L segment (P_i P_{i+1}), Index of S segment (row k)
        end
    end
end
% Sort intersections by cumulative distance if needed
if ~isempty(intersections_found)
    intersections_found = sortrows(intersections_found, 3);
end
end