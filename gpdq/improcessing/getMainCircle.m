%% getMainCircle
% Finds a circle with the given radius in the image. In case there are
% many, returns the closest to the center. This function is designed to
% work with small images (20 x 20, for example).
%    
%       getMainCircle(image, radiusPx, sensitivity, marginPx)
%
% Example
% -------
%
%       getMainCircle(imDot, 5, 0.9, 1);
%
% Parameters
% ----------
%
%   image: Image
%
%   radiusPx: Radius of the circles searched. In pixels.
%
%   sensitivity: (0,1] Sensitivity parameter for findcircles.
% 
%   margin: Searches circles with radius [radiusPx-marginPx radiusPx+marginPx]
%
%   Returns
%
%   centerPx: Center fo the circle closest to the center of the image.
%
%   actRadiusPx: Detected radius of the circle.
%
%   metric: Metric for the circle returned by imfindcircles.
%
% Errors
% ------
%
%   Non valid image.
%
%   Parameters out of range.

% Author: Luis de la Ossa (luis.delaossa@uclm.es).

function [centerPx, actRadiusPx, metric] = getMainCircle(image, radiusPx, sensitivity, marginPx)
  
    %% Gets values from the image.
    imgSide = size(image,1);
    imgCenter = size(image)./2;

    %% Validates the values of the parameters
    if (radiusPx*2>imgSide)
        fprintf('Radius %.2fPx is too big for an image with side %dpx.\n',radiusPx, imgSide);
        return;
    end
    if (sensitivity<=0 || sensitivity >1),
        fprintf('Sensitivity must be in (0,1] (currently %.2f).\n',sensitivity);
        return;
    end

    if (marginPx<=0),
        fprintf('Margin must be greater than 0 (currently %.2f).\n',marginPx);
        return;
    end

    % Due to changes in intensity and resolution of the images, it becomes necessary
    % to consider some margin in the expected radius.
    lowerMargin = radiusPx - marginPx;
    if lowerMargin<1
        lowerMargin=1;
    end
    upperMargin = radiusPx + marginPx;

    %% Detects circles
    [centers, radii, metrics] = imfindcircles(image, [floor(lowerMargin) ceil(upperMargin)] ,'Method','TwoStage','ObjectPolarity','dark','Sensitivity',sensitivity);

    %% Returns the circle of interest.
    % Number of circles detected
    numCircles = numel(radii);

    % If there are no circles, it returns empty variables.
    if (numCircles==0)
        centerPx = [];
        actRadiusPx = [];
        metric = 0;
        return;
    end

    % If there is only one, it is chosen.
    if (numCircles==1)
        centerPx = centers(1,:);
        actRadiusPx = radii(1);
        metric = metrics(1);

    % Otherwise, determines which circle which is closest to the center.
    elseif (numCircles>1)
        distances = sqrt(sum(bsxfun(@minus, centers, imgCenter).^2,2));
        closest = find(distances==min(distances));
        centerPx = centers(closest,:);
        actRadiusPx = radii(closest);
        metric = metrics(closest);
    end

end

