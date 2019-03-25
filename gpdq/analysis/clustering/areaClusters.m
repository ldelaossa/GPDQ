

function areas = areaClusters(points, clusters)
%% Gets the area of each cluster in 2D points. Calculates the convex hull and returns its area.

% points: (nx2) matrix with the points.
% cluster: (nx1) vector with the clusters.

% area: (numClusters, 1) vector with the area of each cluster.
% areaStats: (5x1 vector) with the statistic information of the areas:
%            [total mean standard max min]

% If there is no cluster, it does not return anything.
if(isempty(clusters))
    areas = [];
    return;
end

% Extracts the number of clusters.
numClusters = max(clusters);

% If all points are outliers, it does not return anything.
if numClusters==0,
    areas = [];
else  % Otherwise, calculates the areas.
    areas = zeros(numClusters,1);
    for cluster=1:numClusters
        % Gets the points
        pointsCluster = points(clusters==cluster,:);
        if size(pointsCluster,1)>=3,
            % Calculates the convex hull
            ch = convhull(pointsCluster(:,1), pointsCluster(:,2));
            % Calculates the area
            areas(cluster) = polyarea(pointsCluster(ch,1), pointsCluster(ch,2));
            % Some cases, where the points are aligned, there can be problems.
            minimumArea = pi* (2.5^2) * size(pointsCluster,1);
            if areas(cluster)<minimumArea,
                areas(cluster) = minimumArea;
            end
        else
            % If there are less than three points, the area is not valid.
            areas(cluster) = NaN;
        end
    end
end

end

