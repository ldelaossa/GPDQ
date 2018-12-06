%% drawRectangle
%
% Draws a rectangle in the axes passed as parameter. If no axes are passed,
% draws it in the current figure.
%
% Contiguous coordinates in rect must represent sides of the rectangle.
%    
%       drawRectangle(rect, style, width, color, axes)
%
% Example
% -------
%       drawRectangle([0 0; 0 2; 1 2; 1 0], '--', 3, 'red')
%
%
% Parameters
% ----------
%
%   rect: (4,2) matrix with the coordinates of the corners of the rectangle (plotted clockwise).
%
%   style: Type of line. Example: '--'. (see line - LineStyle)
% 
%   width: Width of the line.
%
%   color: Color of the line. Example: 'red'. 
%
%   axes: Axes where the rectangle is drawn into (optional)
%
% Returns
% -------
%
%   ref: A reference to the graphical object.
%
% Errors
% ------
%
%   If rect is not a (4,2) matrix.
%
%   If points are not clockwise the plot can not be a rectangle.
%
%   Unknown line styles or colors.
%
%   Unexisting axes.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function ref = drawRectangle(rect,  style, width, color, axes)

% Checks for the error.
if ~isequal(size(rect),[4,2])
    msg = 'The specification of the rectangle is not valid';
    GPDQStatus.repError(msg, false, dbstack());
    ref = GPDQStatus.ERROR;
    return;
end

% Determines the axes the circle must be drawn into
if nargin<5
    axes = gca;
end

% Draws the rectangle as four lines.
ref = line ([rect(1,1) rect(2,1) rect(3,1) rect(4,1) rect(1,1)], ...
            [rect(1,2) rect(2,2) rect(3,2) rect(4,2) rect(1,2)], ...
            'LineStyle', style, 'LineWidth', width, 'Color', color, 'Parent', axes);
end

