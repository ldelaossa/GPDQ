%% drawRectangleFromPoints
%
% Given a set of 2D points, draws the minimal bounding box enclosing
% them in the axes passed as parameter. If no axes are passed,
% draws it in the current figure. It can be oriented or parallel to the x axis. 
%
%       drawRectangleFromPoints( points, oriented, style, width, color, axes)
%
% Example
% -------
%
%       drawRectangleFromPoints(points, true, '--', 3, 'red')
%
% Parameters
% ----------
%
% 	points: (n,2) matrix with the coordinates of the n points.
%
%   oriented: True if the bounding box must have the optimal orientation.
%
%   style: Type of line. Example: '--'. (see line - LineStyle)
% 
%   width: Width of the line.
%
%   color: Color of the line. Example: 'red'. 
%
%   axes: Axes where the circle is drawn into (optional)
%
% Returns
% -------
%
%   ref: A reference to the graphical object.
%
% Errors
% ------
%
%   If the number of points is smaller than 2, returns error.
%
%   Unknown line styles or colors.
%
%   Unexisting axes.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function ref = drawRectangleFromPoints( points, oriented, style, width, color, axes)

% Tests the number of points
if size(points,1)<3
    msg = 'Rectangle drawing requires at least 3 different points.';
    GPDQStatus.repError(msg, false, dbstack());
    ref = GPDQStatus.ERROR;   
    return;
end

% Gets the rectangle
rect = minBoundingBox(points, oriented);

% Determines the axes the circle must be drawn into
if nargin<6
    axes = gca;
end

% Draws a rectangle
ref = drawRectangle(rect, style, width, color, axes);
end

