

function sizes = sizeClusters(points, clusters)

if(isempty(clusters))
    sizes = [];
    return;
end

% Extracts the number of clusters.
numClusters = max(clusters);

% If all points are outliers, it does not return anything.
if numClusters==0,
    sizes = [];
else  % Otherwise, calculates the areas.
    sizes = zeros(numClusters,1);
    for cluster=1:numClusters
        sizes(cluster) = size(points(clusters==cluster,:),1);
    end
end

end

