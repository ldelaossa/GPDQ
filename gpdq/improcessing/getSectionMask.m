%% getSectionMask
%
% Reads the image of a section (with discarded regions in white) and
% returns the logical mask of the section. Performs some basic operations
% as softening borders or discarding clear regions.
%    
% Usage
% -----
%
%       mask = getSectionMask(imageSection)
%
% Example
% -------
%
%       mask = getSectionMask(image);
%
% Parameters
% ----------
%
%   imageSection: Binary image containing the section.
%
% Returns
% -------
%
%   mask: A mask with the size of the image. 

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function mask = getSectionMask(imageSection)

    % Identifies the discarded areas (initially white)
    mask = im2bw(imageSection, 0.97); 
    
    % Removes clear spots
    mask = bwareaopen(mask,150);
    
    % Makes a dilatation in order to soften borders.
    element = strel('disk',5);
    mask = imdilate(mask,element);
    
    % Selected areas are true
    mask = ~mask;
    
    % Removes remaining spots
    mask = bwareaopen(mask,150);
    
end

