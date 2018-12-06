%% markPoints
%
% Marks a set of points (generally particles) with circles, either in the 
% axes specified or in the current figure.
%    
%       markPoints(points, radius, style, width, color, filled, axes)
%
% Example
% -------
%      markPoints(points, 5, '-', 3, 'red', true)
%
% Parameters
% ----------
%
%   points: Coordinates of the marks
%
%   radius: Radius of the circle.
%
%   style: Type of line. Example: '--'. (see rectangle - LineStyle)
% 
%   width: Width of the line.
%
%   color: Color of the line. Example: 'red'. 
%
%   filled: If true, the circle is filled with the specified color.
%
%   axes: Axes where the circles are marked (optional)
%
% Returns
% -------
%
%   marks: objects containing the references to the marks.
%
% Errors
% ------
%
%   Unknown line styles or colors.
%
%   Unexisting axes.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function marks = markPoints(centers, radius, style, width, color, filled, axes)
    % Uses the active axes unless other option has been chosen.
    if nargin<7
        axes = gca;
    end
    
    % Gets the number of points.
    numMarks = size(centers,1);
    
    % Array containing the marks.
    marks = gobjects(numMarks,1);
    
    % Marks each point
    for idMark=1:numMarks
        marks(idMark) = drawCircle(centers(idMark,1), centers(idMark,2), radius, style, width, color, filled, axes);
    end



        
            

