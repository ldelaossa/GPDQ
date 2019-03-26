%% areaSection
%
% Given an image and its scale in Nm/pixel, returns its area in squared micrometers. 
% If the image corresponds to a binary mask (default), only considers nonzero pixels. 
% Otherwise, considers the whole size of the image. 
%
% IMPORTANT: The mask must be a local or binary image.
%
% Usage
% -----
%
%       areaSqMc = areaSection(image, scale)
%
% Example
% -------
%
%       area = areaSection(image,1.5824)
%
%
% Parameters
% ----------
%
%       image: object (array) containing the matrix. 
%       scale: scale of the image (Nm/pixel).
%
% Returns
% -------
%
%       The area of the image in squared micrometers. 

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function areaSqMc = areaSection(image, scale)
    if nargin<2
        GPDQStatus.repError('Scale is necessary to calculate the area.', false, dbstack());
        areaSqMc = GPDQStatus.ERROR;
        return;
    end
    
    % Gets the mask if necessary
    if all(image(:)==0 | image(:)==1) % Is a binary mask
        mask = image;
    else
        mask = getSectionMask(image); % Gets the binary mask
    end
    
    % Calculates the area
    areaPixelNm = scale^2;            
    numPixels = numel(find(mask==1));
    areaNm = numPixels * areaPixelNm;
    areaSqMc = areaNm/10^6;
end

