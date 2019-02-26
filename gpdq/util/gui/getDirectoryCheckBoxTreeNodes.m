%% getDirectoryCheckBoxTreeNodes
%
% Returns the structure of a directory as a tree of DefaultCheckBoxNode
% objects (returns the root). It uses the package:
%
%   com.mathworks.mwswing.checkboxtree.*
%
% Usage
% -----
%
%       root = getDirectoryCheckBoxTreeNodes(directory, nameFilter, excludeFilterm, completePath)
%
% Example
% -------
%       root = getDirectoryCheckBoxTreeNodes('./', '*.tif' , '_sec_' , true)
%
%
% Parameters
% ----------
%
%   directory: Name of the directory
%
%   nameFilter: Names of the files to be included. Ex: '*.tif'.
%
%   excludeFilter: Filter of the files to be excluced.
%
%   completePath: Includes the complete path as the name of the returned node (root).
%
% Returns
% -------
%
%   root: DefaultCheckBoxNode with the root of the tree.
%
% Errors
% ------
%
%   If directory does not exist.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function root = getDirectoryCheckBoxTreeNodes(directory, nameFilter, excludeFilter, completePath)
    import com.mathworks.mwswing.checkboxtree.*;

    % Creates the root.
    if nargin<4 || ~completePath
        [~ , name , ~] = fileparts(directory);
        root = DefaultCheckBoxNode(name);        
    else
        root = DefaultCheckBoxNode(directory);
    end

    % Processes folders and files separately (in order to use nameFilter).

    % Get the list of subdirectories
    dirData = dir(directory);
    dirFlags = [dirData.isdir];
    dirNames = {dirData(dirFlags).name};
    % Discards '.' and '..'.
    dirFlags =  ~ismember(dirNames,{'.','..'});
    % Recursively extracts the list from each subdirectory and adds it.
    for dirIndex=find(dirFlags)
        nodeDir = getDirectoryCheckBoxTreeNodes(fullfile(directory,dirNames{dirIndex}), nameFilter, excludeFilter);
        root.add(nodeDir);
    end

    
    % Get the list of files (using the nameFilter)
    fileData = dir(fullfile(directory, nameFilter));
    fileNames = {fileData.name};
    % Remove directories
    fileFlags = ~[fileData.isdir];
    % Remove files that match the exclude filter
    if ~isempty(excludeFilter)
        fileFlags = fileFlags & cellfun(@isempty,(strfind(fileNames,'._')));
        fileFlags = fileFlags & cellfun(@isempty,(strfind(fileNames,excludeFilter)));
    end
    % Adds the files.
    for fileIndex=find(fileFlags)
        fileName =fileNames{fileIndex};
        fileNode = DefaultCheckBoxNode(fileName);
        root.add(fileNode);
        fileNode.setAllowsChildren(false);
    end
end

