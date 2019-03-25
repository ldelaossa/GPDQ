%% readCSV 
%
% Reads a CSV file (numerical) and returns an array with the data.
% This function is mostly used to read the information about particles in a
% section. Each row corresponds to a particle an includes the x,y position 
% (nanometers), the actual radius, and the expected radius. The size of the 
% array can be 0 (also if the file does not exist, as this case is very frequent).
% If there is a fail in reading, returns GPDQStatus.ERROR. 
%
% Usage
% -----
%
%       data = readCSV(fileName)
%
% Example
% -------
%
%       particles = readCSV('../AXON/1_sec_1.csv')
%
%
% Parameters
% ----------
%
%       filename: Name of the file to be read.
%
% Returns
% -------
%
%       data: Array with the numerical data in the csv file (can be empty).
%
% Errors
% ------
%
%       If there is an exception returns GPDQStatus.ERROR.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)
function data = readCSV(fileName)
    
    % Name of the file containing the csv.
    [path, file, ext] = fileparts(fileName);    
    if ~strcmp(ext,'csv')
        fileName = fullfile(path,[file '.csv']);
    end

    % Reads the file. Only reports error when there is an error, as it is
    % very common that the file does not exist. 
    if exist(fileName,'file')
        try
            data = csvread(fileName);
        catch
            GPDQStatus.repError(['Error reading the csv file '  fileName '.'], false, dbstack());  
            data = GPDQStatus.ERROR;
        end
    else
        data = [];
    end
end

