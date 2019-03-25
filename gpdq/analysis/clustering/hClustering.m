%% hClustering Groups points in clusters with hierarchical clustering.
% For each point it returns the index of the cluster it belongs to.
%
% Parameters
% ----------
% points: (n,2) matrix with the coordinates of the points.
%
% minIntraClusterDistance: Minimum distance between clusters. The default metric used
%          to measure the distance between clusters is 'single', which is the minimum distance
%          between any pair of points from different clusters. When the distance between two clusters is smaller
%          than minIntraClusterDistance, they are merged.
% 
% minNumPointsPerCluster: The minimum number of points that a cluster must have. Clusters with less
%          points than this parameter will be omitted.
%
% Returns
% ------
%
% clusters: (n,1) integer vector with the cluster each point belongs to. Outliers are set to 0.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function [clusters] = hClustering(points, minIntraClusterDistance, minNumPointsPerCluster)


%% Intially, all points are labeled as outliers.
clusters = zeros(size(points,1),1);

%% The number of points must be greater then the minimum number of points per cluster (or 2).
if size(points,1)<2 || size(points,1)<minNumPointsPerCluster
    return;
end

%% This function calculates the hierarchical clustering represented as an array.
link = linkage(points,'single','euclidean');
initialClusters = cluster(link,'cutoff',minIntraClusterDistance,'criterion','distance');

%% Now discards the outliers and reassigns cluster numbers. 
numInitialClusters = max(initialClusters);
% Index of the first definitive cluster.
defClusterIdx = 1;
% Treats each cluster
for initialClusterIdx=1:numInitialClusters,
    % If the cluster does not have the minimum number of points, it preserves the 0 value (outlier).
    elementsCluster = find(initialClusters==initialClusterIdx);
    if numel(elementsCluster)<minNumPointsPerCluster,
        continue
    end
    % Otherwise reasigns cluster numbers
    clusters(elementsCluster) = defClusterIdx;
    defClusterIdx = defClusterIdx + 1;
end
end

