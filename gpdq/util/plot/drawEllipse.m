%% drawEllipse
%
% Draws an ellipse in the axes passed as parameter. If no axes are passed,
% draws it in the current figure.
%    
%       drawEllipse(x, y, majR, minR, angle, style, width, color, axes)
%
% Example
% -------
%       drawEllipse(0, 0, 100, 20, 45,  '-', 3, 'red')
%
% Parameters
% ----------
%
%   x, y: Coordinates of the center.
%
%   majR, minR: Major and minor radii.
%
%   angle: Orientation of the ellipse.
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
% Unknown line styles or colors.
%
% If the number of points is smaller than 2, returns error.
%
% Unexisting axes.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function ref = drawEllipse(x, y, majR, minR, angle, style, width, color, axes) 

    % Number of points used to paint the ellipse.
    numPoints = 200;

    % Generates the ellipse.
    theta = linspace(0,2*pi,numPoints);
    ptEllipse(1,:) = majR*cos(theta);
    ptEllipse(2,:) = minR*sin(theta);
    
    % Rotates the ellipse.
    angle = angle*pi/180; % deg->rad 
    % Rotation matrix: 
    Q = [cos(angle) -sin(angle)
         sin(angle)  cos(angle)];
    ptEllipse = Q*ptEllipse;

    % Moves it to the desired location.
    ptEllipse(1,:) = ptEllipse(1,:) + x;
    ptEllipse(2,:) = ptEllipse(2,:) + y;
    
    % Determines the axes the circle must be drawn into
    if nargin<9
        axes = gca;
    end    
    
    % Plots it
    ref = plot(ptEllipse(1,:),ptEllipse(2,:), 'LineStyle', style, 'LineWidth', width, 'Color', color, 'Parent', axes);
end

