
%% softenSectionEdges
%
%  Slightly softens the borders of the objects in a section image. 
%
% Usage
% -----
%        imageSoftened = softenSectionEdges(image)
%
%
% Parameters
% ----------
%
%   image:  Name of the file with the image or image object.
%
% Returns
% -------
%
%   imageSoftened: Image with object edges softened.
%
% Errors
% ------
%
% TO BE TESTED

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function imageSoftened = softenSectionEdges(image)

% Reads the image if the argument is a string with a file name.
if ischar(image)
    image = imread(image);
end

% Extracts the perimeter of the image
imageBW = imcomplement(imbinarize(image));
objectEdges = bwperim(imageBW,8);
% Dilates the edges
objectEdges = imdilate(objectEdges, strel('disk',1));
% Substitutes the pixels correspondig to the dilated perimeter by
% the values in the gaussian image.
imageSoftened = image;
imageGauss = imgaussfilt(image, 1);
imageSoftened(objectEdges) = imageGauss(objectEdges);

end

