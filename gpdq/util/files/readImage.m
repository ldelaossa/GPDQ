%% readImage 
%
% Reads an image given its name. Returns the image or GPDQStatus.ERROR in case of error. 
%
% Usage
% -----
%
%       image = readImage(imageName)
%
% Example
% -------
%
%       image = readImage(../AXON/1_sec_1.tif')
%
% Parameters
% ----------
%
%   imageName: Name of the file to be read.
%
% Returns
% -------
%
%   image: Array with the image.
%
% Errors
% ------
%
%   If there is an exception returns GPDQStatus.ERROR.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function image = readImage(imageName)
    try
        image =imread(imageName);
    catch
        GPDQStatus.repError(['There has been a problem when opening image'  imageName '.'], false, dbstack());
        image = GPDQStatus.ERROR;
        return;
    end                 
end

