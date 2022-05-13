%% distances1Set
% Given a set of points, calculates the distances between each pair.
%
% Usage
% -----
%
%       distances = distances1Set(points)
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


function distances = distances1Set(points)

% If there is only one point, it returns NaN
if size(points,1) <=1
    distances = NaN;
    return
end

% The dist function works considers each column as a point. It is applied over the transpose
allDistances=dist(points');     

% Takes only the upper triangle
allDistances=triu(allDistances);    

% Takes non-zero elements
distances=nonzeros(allDistances); 
end