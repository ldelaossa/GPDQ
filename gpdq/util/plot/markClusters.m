%% This function allows marking clusters in the current figure. It does not use scale. 

% points:   (n,2) vector containing the coordinates of the points.
% clusters: (n,1) vector containing the cluster each point belongs to.
% type: Type of mark
%       - Ellipse: Ellipse.
%       - Rectangle: Rectangle.
%       - ConvexHull: Convex Hull.
% lineStyle: Style of the line surrounding the clusters.
% lineWidth: Width of the line surrounding the clusters.
% lineColor: Color of the line surrounding the clusters.



% Cambiar a grupos de puntos
function marks = markClusters(points, clusters, type, lineStyle, lineWidth, lineColor, axes)

if nargin<7
    axes = gca;
end

% Marks the clusters
numClusters = max(clusters);
lowerType = lower(type);

% References to the marks
marks = [];

% The mark is the convex hull.
if strcmp(lowerType,'convexhull'),
    for idxCluster=1:numClusters,
        marks(idxCluster) = drawConvHullFromPoints(points(clusters==idxCluster,:),lineStyle, lineWidth,lineColor, axes);
    end
% The mark is a rectangle.    
elseif strcmp(lowerType,'rectangle'),
    for idxCluster=1:numClusters,
        marks(idxCluster) = drawRectangleFromPoints(points(clusters==idxCluster,:), true, lineStyle, lineWidth,lineColor, axes);
    end
% The mark is an ellipse.
else
    for idxCluster=1:numClusters,
        marks(idxCluster) = drawEllipseFromPoints(points(clusters==idxCluster,:),10, lineStyle, lineWidth,lineColor, axes);
    end
end
        
            

