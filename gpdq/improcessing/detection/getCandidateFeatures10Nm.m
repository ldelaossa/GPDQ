
%% getCandidateFeatures10Nm
%
%  Extracts a vector with features for each candidate point in an image. For each one, 
%  takes a 20x20Nm image and calculates some features of interest. 
% 
%
% Usage
% -----
%        [validCandidates, features] = getCandidateFeatures10Nm(image, scale, centers, radii, metrics)
%
%
% Parameters
% ----------
%
%   image:          Image with the section. It is important to use the
%                   base image, not the section with the mask.
%
%   scale:          Scale of the image
%
%   candCenters:    nx2 matrix with the coordinates of the centers (1 Nm/pixel)
%
%   radii:          n-vector with the radii of each candidate. 
%
%   metrics:        n-vector with the metrics of each candidate. 
%
% Returns
% -------
%
%   validCandidates:    nx1 boolean vector that representes if features have actually been obtained. 
%
%   features:           nx404 matrix with the intensities of the images for each candidate. 
% 
% Errors
% ------
%
% TO BE TESTED

% Author: Luis de la Ossa (luis.delaossa@uclm.es)


function [validCandidates, features] = getCandidateFeatures10Nm(image, scale, candCenters, candRadii, candMetrics)

% It uses an scale of 0.5Nm/píxel to improve detection.
ampScale = 0.5;
radiusNm = 5;

% Size of the subimage used for each candidate.
candImgSizeNm = 20;                            
candImgSizePx = candImgSizeNm/ampScale;   % 40 Pixels
candOuterImgSizePx = candImgSizePx * 1.5; % 60 Pixels

% Scales radius to ampScale Nm/pixel
radiusPx = radiusNm/ampScale;                  % 10 Pixels

% Resizes the image to 0.5Nm/pixel
imageSizePx = size(image)*(scale/ampScale);
imageScaled = imresize(image, imageSizePx);

% Scales radius to ampScale Nm/pixel
candCentersScaled = candCenters/ampScale;

% Features
numCandidates = size(candCenters,1);
features = zeros(numCandidates, 404);

% Detects the points in the margins.
nonValidCandidates = candCentersScaled(:,1) < candOuterImgSizePx/2 | candCentersScaled(:,2) < candOuterImgSizePx/2;
nonValidCandidates = nonValidCandidates | candCentersScaled(:,1) > imageSizePx(2)-candOuterImgSizePx/2 ...
                                        | candCentersScaled(:,2) > imageSizePx(1)-candOuterImgSizePx/2 ;
validCandidates = ~nonValidCandidates;

% Extracts features from each valid candidate. 
for idPoint=find(validCandidates)'
    % Extracts the outer image.
    outerImageCand = imcrop(imageScaled, [round(candCentersScaled(idPoint,1))-candOuterImgSizePx/2, round(candCentersScaled(idPoint,2))-candOuterImgSizePx/2, ...
                                          candOuterImgSizePx-1, candOuterImgSizePx-1]);
    % Detects the circle
    [center, actRadiusPx, metric] = getMainCircle(outerImageCand, radiusPx, 2, 0.95);
    % If there is no circle, continues
    if isempty(center)
        validCandidates(idPoint)=false;
        continue;
    end
    
    % Crops the 20x20Nm image with the particle centered.
    imageCand = imcrop(outerImageCand, [round(center(1))-candImgSizePx/2, round(center(2))-candImgSizePx/2, candImgSizePx-1, candImgSizePx-1]);

   
    % Tests if the image is valid. If not, continues;
    if size(imageCand,1)~=candImgSizePx || size(imageCand,2)~=candImgSizePx
        validCandidates(idPoint)=false;
        continue;
    end

    imageCand = imresize(imageCand, [20,20]);
    
    % ----- Features---------
    try
    candFeatures = zeros(404,1);
    candFeatures(1:400) = imageCand(:);
    candFeatures(401) = candMetrics(idPoint);
    candFeatures(402) = metric;  
    candFeatures(403) = candRadii(idPoint);
    candFeatures(404) = actRadiusPx*ampScale;
    catch
        disp('veamos');
    end

    features(idPoint,:) = candFeatures;
    
    % Internal use
    debug = false;
    
    %% Shows the figure if debugging.
    if (debug)
        figure('OuterPosition',[0 0 600 400]), subplot(1,2,1), imshow(imageCand);
        subplot(1,2,2), imshow(imageCand);
        viscircles([20,20],radiusPx*0.65,'LineWidth',1, 'LineStyle','-','EdgeColor', 'white');
        viscircles([20,20],radiusPx*1,'LineWidth',1, 'LineStyle','-','EdgeColor', 'white');
        viscircles([20,20],radiusPx*1.5,'LineWidth',1, 'LineStyle','--','EdgeColor', 'white');    
        viscircles([20,20],actRadiusPx*1,'LineWidth',1, 'LineStyle','-','EdgeColor', 'red');     
    end    

end
end