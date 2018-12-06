%% minBoundingBox
%
% Given a set of 2D points, returns the minimal bounding box enclosing
% them. It can be oriented or parallel to the x axis. 
%
% Based on de code of Julien Diener
% http://www.mathworks.com/matlabcentral/fileexchange/31126-2d-minimal-bounding-box
%
%       minBoundingBox( points, oriented )
%
% Example:
% --------
%
%       minBoundingBox(points, true)
%
%
% Parameters
% ----------
%
%   points: (n,2) matrix with the coordinates of the n points.
%
%   oriented: True if the bounding box must have the optimal orientation.
%
% Returns
% -------
%
%   rect: (4,2) matrix with the coordinates of the corners of the
%         rectangle. Segments sharing a point are adjactent in the matrix.
%
% Errors
% ------
%
%   If the number of points is smaller than 3, returns error.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)
function mbb = minBoundingBox(points, oriented)

% If it is not oriented, returns the rectangle parallel to the axis.
if ~oriented
    minX = min(points(:,1));
    maxX = max(points(:,1));
    minY = min(points(:,2));
    maxY = max(points(:,2));
    mbb = [minX minY; minX maxY; maxX maxY; maxX minY];
    return
end

% To use the same format for points than GPDQ
points = points';

% Compute the convex hull (CH is a 2*k matrix subset of X)
k = convhull(points(1,:),points(2,:));
CH = points(:,k);

% Compute the angle to test, which are the angle of the CH edges as:
%   "one side of the bounding box contains an edge of the convex hull"
E = diff(CH,1,2);           % CH edges
T = atan2(E(2,:),E(1,:));   % angle of CH edges (used for rotation)
T = unique(mod(T,pi/2));    % reduced to the unique set of first quadrant angles

% Create rotation matrix which contains
% the 2x2 rotation matrices for *all* angles in T
% R is a 2n*2 matrix
R = cos( reshape(repmat(T,2,2),2*length(T),2) ... % duplicate angles in T
       + repmat([0 -pi ; pi 0]/2,length(T),1));   % shift angle to convert sine in cosine

% Rotate CH by all angles
RCH = R*CH;

% Compute border size  [w1;h1;w2;h2;....;wn;hn]
% and area of bounding box for all possible edges
bsize = max(RCH,[],2) - min(RCH,[],2);
area  = prod(reshape(bsize,2,length(bsize)/2));

% Find minimal area, thus the index of the angle in T 
[~,i] = min(area);

% Compute the bound (min and max) on the rotated frame
Rf    = R(2*i+[-1 0],:);   % rotated frame
bound = Rf * CH;           % project CH on the rotated frame
bmin  = min(bound,[],2);
bmax  = max(bound,[],2);

% Compute the corner of the bounding box
Rf = Rf';
mbb(:,4) = bmax(1)*Rf(:,1) + bmin(2)*Rf(:,2);
mbb(:,1) = bmin(1)*Rf(:,1) + bmin(2)*Rf(:,2);
mbb(:,2) = bmin(1)*Rf(:,1) + bmax(2)*Rf(:,2);
mbb(:,3) = bmax(1)*Rf(:,1) + bmax(2)*Rf(:,2);

% To use the same format for points than GPDQ
mbb = mbb';
