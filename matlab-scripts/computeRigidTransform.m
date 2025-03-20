function [tform, R, T] = computeRigidTransform(P, Q)
%COMPUTERIGIDTRANSFORM Compute rigid transform between two sets of points.
%
% DESCRIPTION:
%     computeRigidTransform computes a rigid transform between two
%     coordinate systems given a set of three points in both coordinate
%     systems. The points must not be collinear.
%
%     The function calculates the centroids of the point sets, recenters
%     them, and then computes the Singular Value Decomposition (SVD) of the
%     cross-covariance matrix to obtain the rotation matrix R. Finally, it
%     calculates the translation vector T.
%
% USAGE:
%     [tform, R, T] = computeRigidTransform(P, Q)
%
% INPUTS:
%     P, Q          - [numeric] 3 x 3 matrices with matched points given as
%                     columns. Each column represents the 3D coordinates of
%                     a point.
%
% OUTPUTS:
%     tform         - [numeric] 4 x 4 rigid transform between the two
%                     coordinate systems.
%     R             - [numeric] 3 x 3 rotation matrix.
%     T             - [numeric] 3 x 1 translation vector.
%
% ABOUT:
%     author        - Bradley E. Treeby
%     date          - 16th March 2023
%     last update   - 16th March 2023

arguments
    P (3,3) {mustBeNumeric}
    Q (3,3) {mustBeNumeric}
end

% Check points are not collinear.
if checkCollinearity(P) || checkCollinearity(Q)
    error('Input points must not be collinear.');
end

% Calculate centroids.
centroid_P = mean(P, 2);
centroid_Q = mean(Q, 2);

% Center the point sets.
P_centered = P - centroid_P;
Q_centered = Q - centroid_Q;

% Calculate the cross-covariance matrix.
H = P_centered * Q_centered';

% Compute the Singular Value Decomposition (SVD).
[U, ~, V] = svd(H);

% Calculate the rotation matrix R.
R = V * U';

% Ensure R is a proper rotation matrix (det(R) = 1).
if det(R) < 0
    V(:, 3) = -V(:, 3);
    R = V * U';
end

% Calculate the translation vector T.
T = centroid_Q - R * centroid_P;

% Build transform.
tform = eye(4);
tform(1:3, 1:3) = R;
tform(1:3, 4) = T;

function isCollinear = checkCollinearity(P)
% checkCollinearity checks if the provided points are collinear, where P is
% a 3x3 matrix with the points as columns. Calculates the area of the
% triangle formed by the three points. If the area is zero (or very close
% to), the points are collinear.

    % Calculate the vectors between the points.
    v1 = P(:, 2) - P(:, 1);
    v2 = P(:, 3) - P(:, 1);
    
    % Calculate the cross product of the vectors.
    crossProduct = cross(v1, v2);
    
    % If the magnitude of the cross product is close to zero, the points
    % are collinear.
    isCollinear = norm(crossProduct) < 1e-8;

end

end