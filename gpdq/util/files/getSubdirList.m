%% getSubdirList
%
% Returns all the subdirectories in a directory as a list (recursively).
%
% Usage
% -----
%
%   subDirList = getSubdirList(directory)
%
% Example
%
%   subDirList = getSubdirList('/.')
%
% Parameters
% ----------
%
%   directory: Base directory
%
% Returns
% -------
%
%   subDirList: List (cell array) with the tree of subdirectories. 
%
% Errors
% ------
%
%   If the directory does not exist returns GPDQStatus.ERROR.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function subDirList = getSubdirList(directory)

  % Get the list of subdirectories
  dirData = dir(directory);
  % If the directory does not exist, reports the error. 
  if isempty(dirData)
      GPDQStatus.repError(['The directory ' directory ' does not exist.'], false, dbstack());
      subDirList = GPDQStatus.ERROR;
      return
  end
  % Gets the list.
  dirFlags = [dirData.isdir];  
  dirNames = {dirData(dirFlags).name}; 
  % Discards '.' and '..'
  dirFlags = ~ismember(dirNames,{'.','..'});  
   
  % Creates the list of sub directories.
  subDirList = {};
  
  % Recursively extracts the list from each subdirectory and adds it.
  for dirIndex=find(dirFlags)
          nextDir = fullfile(directory,dirNames{dirIndex});
          subDirList = [subDirList; nextDir];
          subDirNames =  getSubdirList(nextDir);
          if ~isempty(subDirNames)
              subDirList = [subDirList; subDirNames];
          end
  end
end


