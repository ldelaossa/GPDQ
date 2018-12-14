%% nnDistances
% Given a set of points, calculates the distance of each point to its
% nearest neighbor. Assumes that all points are different. Distances equal 
% to 0 are considered as NaN and discarded.
%
% Usage
% -----
%
%       distances = nnDistances(points)
%
% Parameters
% ----------
%
%       points:   (n,2) matrix with the coordinates of the n points.
%
%
% Returns
% -------
%
%       distances: (n,1) vector with the resulting distances.
%
% Errors
% ------
%
%       If the number of points is not greater than 1, returns NaN.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function distances = nnDistances(points)

% If there is only one point, it returns NaN
if size(points,1) <=1
    distances = NaN;
    return
end

% The dist function works considers each column as a point, so we apply the traspose
allDistances = dist(points');

% Sets the diagonal and equivalent points (distance from the point p to itself) to NaN.
allDistances(allDistances==0) = NaN;

% Obtains the distance to the closest point.
distances = min(allDistances);

% Returns a row vector;
distances = distances';

end

