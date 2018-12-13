%% areaSection
% Given an image and its scale in Nm/pixel, returns its area in squared micrometers. 
% If the image corresponds to a binary mask (default), only considers nonzero pixels. 
% Otherwise, considers the whole size of the image. 
%
% IMPORTANT: The mask must be a local or binary image.
%
% Usage
% -----
%
%       area = areaSection(image, scale, isMask)
%
% Example
% -------
%
%       area = areaSection(image ,1.5824, false)
%
%
% Parameters
% ----------
%
%       image: Ubject (array) containing the matrix. 
%       scale: Scale of the image (Nm/pixel).
%       isMask: Whether the image is a mask or not. 
%
% Returns
% -------
%
%       The area of the image in squared micrometers. 

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function area = areaSection(image, scale, isMask)
    if nargin<2
        Status.repError('Scale is necessary to calculate the area.', false, dbstack());
        area = Status.ERROR;
        return;
    end
    
    % The image is a mask unless otherwise indicate. 
    if nargin<3
        isMask = true;
    end
    
    areaPixelNm = scale^2;
    
    if isMask
        areaNm = numel(find(image==1))*areaPixelNm;
    else
        areaNm = numel(image)*areaPixelNm;
    end
    
    area = areaNm/10^6;
end

