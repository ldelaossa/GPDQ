
%% detectCandidates
%
%  Extracts the candidate circles from an image using imfindcircles.
%  Returns the centers, radii and metrics.
%
% Usage
% -----
%        [cCenters, cRadii, cMetrics] = detectCandidates(image, scale, radius, margin, sensitivity, minMetric, nBest)
%
% Example
% -------
%                           [c, r, m] = detectCandidates('../1.tif', 1.4583, 5, 2, 0.85, 0.4)
%
% Parameters
% ----------
%
%   image:       Name of the file with the image or image object.
%   scale:       Scale of the image (Nm/pixel)
%   radius:      Expected radius of the circles (Nm)
%   margin:      Allowed radius margin (Nm)
%   sensitivity: Sensitivity parameter of imfindcircles
%   metric:      Metric threshold. All circles with metric under this
%                value, are dicarded. The default value is 0.
%   best:        If specified, returns only the nBest circles with highest
%                metric.
%
% Returns
% -------
%
%   cCenters: nx2 matrix with the centers of candidate circles. (Nm)
%   cRadii: n vector with the radii of the detected candidates. (Nm)
%   cMetrics: n vector with the metrics returned by imfindcircles for each candidate.
%
% Errors
% ------
%
% TO BE TESTED

% Author: Luis de la Ossa (luis.delaossa@uclm.es)


function [cCenters, cRadii, cMetrics] = detectCandidates(image, scale, radius, margin, sensitivity, minMetric, nBest)

% Default value for metric.
if nargin<6
    minMetric = 0;
end

% Default value for the number of circles (no limit)
if nargin<7
    nBest = Inf;
end

% Scale for amplification of the image in Nm/pixel. It is necessary to use
% that because imfindcircles does not detect circles with radius smaller than 5.
ampScale = 0.5; 

% Range of radii found in the amplified image.
radii = [radius-margin radius+margin];
ampRadii = radii/ampScale;

% Reads the image if the argument is a string with a file name.
if ischar(image)
    image = imread(image);
end

% This is necessary because imfindcircles sometimes does not work when edges are too sharped. 
image = softenSectionEdges(image);

% Reescales the image to ampScale
ampImage = imresize(image, size(image)*(scale/ampScale));

% Finds the circles
[cCenters, cRadii, cMetrics] = imfindcircles(ampImage, ampRadii,'Method','TwoStage','ObjectPolarity','dark','Sensitivity', sensitivity);

% Selects the circles of interest by threshold/metrix 
cCenters = cCenters(cMetrics>=minMetric,:);
cRadii = cRadii(cMetrics>=minMetric,:);
cMetrics = cMetrics(cMetrics>=minMetric,:);

% Selects the numSelected circles with the best metric. 
% Note: imfind returns the candidates in decreasing order of metric .
numSelected = min(nBest,length(cMetrics));
cCenters = cCenters(1:numSelected,:);
cRadii = cRadii(1:numSelected,:);
cMetrics = cMetrics(1:numSelected,:);

% Reescales the results to 1Nm/pixel
cCenters = cCenters * ampScale;
cRadii = cRadii * ampScale;

% Internal use. 
debug = false;  

% Debug
if debug % Shows the original image and the detected candidates.
    imshow(image);
    markPoints(cCenters/scale, radius/scale, '-', 1, 'yellow', false);
    size(cRadii)
end

end % function

