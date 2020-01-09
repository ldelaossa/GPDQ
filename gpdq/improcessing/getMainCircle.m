%% getMainCircle
%
% Finds a (dark) circle with the given radius in the image. In case there 
% are many, returns the closest to the center.
%
% Usage
% -----
%        [center, actRadiusPx, metric] = getMainCircle(image, 5, 0.85)
%
% Parameters
% ----------
%
%   imageDot:       Image containing the circle.
%   radiusPx:       Expected radius of the circle (Px) 
%   marginPx:       Margin of the expected radius (Px)
%   sensitivity:    Sensitivity passed to imfindcircles (hough)
%
% Returns
% -------
%
%   center:         Center of the circle (row,column)
%   actRadiusPx:    Actual radius of the circle, or 0 
%                   if the circle does not exist. (pixels)
%   metric:         Metric returned by imagefindcircles 
%
% Errors
% ------
%
% TO BE TESTED

% Author: Luis de la Ossa (luis.delaossa@uclm.es)


function [center, actRadiusPx, metric] = getMainCircle(imageDot, radiusPx, marginPx, sensitivity)

% Size and center of the image.
imgSize = size(imageDot);

% Points are expressed as X,Y, but size as rows,cols
imgCenter = imgSize./2;
imgCenter = [imgCenter(2), imgCenter(1)];

% Detects circles
[centers, radii, metrics] = imfindcircles(imageDot, [radiusPx-marginPx, radiusPx+marginPx], ...
                                         'Method','TwoStage','ObjectPolarity','dark','Sensitivity',sensitivity);

% Number of circles detected
numCircles = numel(radii); 

% If there are no circles, it returns empty variables.
if (numCircles==0)
    center = [];
    actRadiusPx = [];
    metric = 0;
    return;
end

% If there is only one, it is chosen.
if (numCircles==1)
    center = centers(1,:);
    actRadiusPx = radii(1);
    metric = metrics(1);
    
% Otherwise, determines which circle which is closest to the center.
% (This could be vectorized, but it is not worth it).
elseif (numCircles>1)
    minDist = Inf;
    for circ=1:numCircles
        dist = sqrt((centers(circ,1)-imgCenter(1))^2+(centers(circ,2)-imgCenter(2))^2);
        if (dist<minDist)
            minDist = dist;
            center = centers(circ,:);
            actRadiusPx = radii(circ);
            metric = metrics(circ);
        end
    end
end
end

