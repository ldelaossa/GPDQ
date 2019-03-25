%% drawConvHullFromPoints
%
% Given a set of points, draws the convex hull in the axes passed as
% parameter. If no axes are passed, draws it in the current figure.
%
%       drawConvHullFromPoints(points, style, width, color, axes)
%
% Example
% -------
%
%       drawConvHullFromPoints(points, '-', 3, 'red')
%
% Parameters
% ----------
%
%   points: (n,2) matrix with the coordinates of the n points.
%
%   style: Type of line. Example: '--'. (see plot - LineStyle)
% 
%   width: Width of the line.
%
%   color: Color of the line. Example: 'red'. 
%
%   axes: Axes where the convex hull is drawn into (optional)
%
% Returns
% -------
%
%   ref: A reference to the graphical object. Or GPDQStatus.ERROR if the 
%        number of points is smaller than 3.
%
% Errors
% ------
%
%   Number of different points must be equal or greater than 3.
%
%   Unknown line styles or colors.
%
%   Unexisting axes.


% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function ref = drawConvHullFromPoints(points, style, width, color, axes)
% Calculates the convex hull.
try
    ch = convhull(points(:,1), points(:,2));
catch 
    msg = 'Convex hull can not be calculated because it requires at least 3 different points.';
    GPDQStatus.repError(msg, false, dbstack());
    ref = GPDQStatus.ERROR;
    return;
end

% Determines the axes the polygon must be drawn into
if nargin<5
    axes = gca;
end

% Draws it.
ref = plot(points(ch,1),points(ch,2), 'LineStyle', style, 'LineWidth', width, 'Color', color, 'Parent', axes);
end

