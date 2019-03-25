%% nnd2Sets
% Given two sets of points, for each point in the first set, returns the distance
% to its nearest neighbor in the second set.
%
% Assumes that all points are different. 0 distances are considered as NaN.
%
% Usage
% -----
%
%       distances = nnd2Sets(setA, setB)
%
% Parameters
% ----------
%
%   setA:   (n,2) matrix with the coordinates of the n points.
%
%   setB:   (m,2) matrix with the coordinates of the m points.
%
%
% Returns
% -------
%
%   distances:  (n,1) vector. For each one of the points in setA, returns the distance to the closest point in setB.
%
% Errors
% ------
%
%   If setA has no elements, returns [].
%   If setB has no elements, distances for each element in setA are set to NaN

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function distances = nnd2Sets(setA, setB)

% If the first set is empty, returns [].
if size(setA,1)==0
    distances=[];
    return
end

% If the second set is empty, all distances are set to NaN
if size(setB,1)==0
    distances = zeros(size(setA,1),1);
    for nPoint=1:size(setA,1)
        distances(nPoint) = NaN;
    end
    return
end

% Otherwise, calculates the distances
allDistances = pdist2(setA,setB, 'euclidean');

% Set distances of 0 to NaN, as similar points are not allowed.
allDistances(allDistances==0) = NaN;

% If the size of set2 is 1, allDistances has only a column
if size(setB,1)==1
    distances = allDistances;
else
    % The distance is the minimum for each column.
    distances = min(allDistances,[],2);
end
end
