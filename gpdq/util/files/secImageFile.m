%% secImageFile
%
% Returns the name of the file containing a section, which is calculated
% from the name of the original image, and the id of the section. as
% file_sec_id.tif For example, the section 1 of the image 'AXON/23.tif'
% must be stored in the file 'AXON/23_sec_1.tif It can take either two or 
% three arguments. 
%
% Usage
% -----
%   
%       fullImageFileName = secImageFile(imageName, sectionNumber, basePath)
%
% Example
% -------
%
%       sectionImage = secImageFile('AXON/23.tif', 1)
%
%
% Parameters
% ----------
%
%       imageName: Name of the file contaning the image.
%
%       sectionName: Number of section.
%
%       basePath: Path to the image. 
%
% Returns
% -------
%
%       fullImageFileName: Name of the file with the data of the section.
%
% Errors
% ------
%
%       Wrong file name. In this case returns GPDQStatus.ERROR.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function fullImageFileName = secImageFile(imageName, sectionNumber, basePath)
    try
        % Gets the parts of the full file name.
        [path, name, ext] = fileparts(imageName);
        % Creates the name of the file.
        fullImageFileName = [name '_sec_' num2str(sectionNumber) ext];
        
        % If the path to the original image was not empty, adds it to the
        % section file name.
        if ~isempty(path)
            fullImageFileName = fullfile(path, fullImageFileName);
        end        
        % If there is a base path,  concatenates it. 
        if nargin==3
            fullImageFileName = fullfile(basePath, fullImageFileName);
        end        
    catch
        % If there has been some mistake, returns GPDQStatus.ERROR.
        GPDQStatus.repError(['There has been an error obtaining the section image name for ' name 'and' str(sectionNumber)], false, dbstack());
        fullImageFileName = GPDQStatus.ERROR;
        return
    end
end

