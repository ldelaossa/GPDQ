%% drawEllipseFromPoints
%
% Given a set of 2D points, draws a ellipse which surrounds them. It first finds 
% the rectangle corresponding with the oriented minimal bounding box
% Afterwards, draws the minimal ellipse surrounding the rectangle. It
% receives as parameter a margin, which is added to both radii.
%
%       drawEllipseFromPoints(points, margin, style, width, color, axes)
%
% Example
% -------
%
%       drawEllipseFromPoints(points, 5, '-', 3, 'red')
%
%
% Parameters
% ----------
%
%   points: (n,2) matrix with the coordinates of the n points.
%
%   margin: Number of pixels added to both radii of the ellipse.
%
%   style: Type of line. Example: '--'. (see rectangle - LineStyle)
% 
%   width: Width of the line.
%
%   color: Color of the line. Example: 'red'. 
%
%   axes: Axes where the ellipse is drawn into (optional)
%
% Returns
% -------
%
%   ref: A reference to the graphical object.
%
% Errors
% ------
%
%   Incorrect or empty set of points.
%
%   Unknown line styles or colors.
%
%   Unexisting axes.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function ref = drawEllipseFromPoints(points, margin, style, width, color, axes)

% Calculates the rectangle
rect  = minBoundingBox(points,true);

% Calculates and draws the ellipse surrounding the rectangle

% Center
x = (rect(1,1)+rect(3,1))/2;
y = (rect(1,2)+rect(3,2))/2;

% Radii
minR = sqrt((rect(1,1)-rect(2,1))^2 +(rect(1,2)-rect(2,2))^2) / sqrt(2);
majR = sqrt((rect(2,1)-rect(3,1))^2 +(rect(2,2)-rect(3,2))^2) / sqrt(2);

% Angle
slope = (rect(2,2)-rect(3,2)) /(rect(2,1)-rect(3,1));
angle = atand(slope);

% Determines the axes the ellpse must be drawn into
if nargin<6
    axes = gca;
end

% Draws the ellipse
ref = drawEllipse(x, y, majR+margin, minR+margin, angle, style, width, color, axes);
end

