%% secDataFileName
%
% Returns the name of the file containing the data related to a section, 
% which is calculated from the name of the original image, and the id of 
% the section. as file_sec_id.csv. For example, the data relative to the 
% section 1 of the image  'AXON/23.tif' must be stored in the file 
% 'AXON/23_sec_1.csv' It can take either two or three arguments. If the 
% basePath is passed as parameter, appends it to the resulting file name. 
%
% Usage
% -----
%  
%       fileName = secDataFileName(imageName, sectionNumber, basePath)
%
% Example
% -------
% 
%       dataFile = secDataFileName('AXON/23.tif', 1)
%
%
% Parameters
% ----------
%
%       imageName: Name of the file contaning the image.
%
%       sectionName: Number of section.
%
%       basePath: Path to the image (optional). 
%
% Returns
% -------
%
%       fileName: Name of the file with the data of the section.
%
% Errors
% ------
%       Wrong file name. In this case returns GPDQStatus.ERROR.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)
function fileName = secDataFileName(imageName, sectionNumber, basePath)
    try
        % Gets the parts of the full file name.
        [path, name, ~] = fileparts(imageName);
        % Creates the name of the file.
        fileName = [name '_sec_' num2str(sectionNumber) '.csv'];
        
        % If the path to the original image was not empty, adds it to the
        % section file name.
        if ~isempty(path)
            fileName = fullfile(path, fileName);
        end        
        % If there is a base path,  concatenates it. 
        if nargin==3
            fileName = fullfile(basePath, fileName);
        end        
    catch
        % If there has been some mistake, returns GPDQStatus.ERROR
        GPDQStatus.repError(['There has been an error obtaining the section data file name for ' name 'and' str(sectionNumber)], false, dbstack());
        fileName = GPDQStatus.ERROR;
        return;
    end
end

