%% getDirectoryCheckBoxTree
%
% Returns the structure of a directory as a CheckBoxTree component. It uses 
% the package: com.mathworks.mwswing.checkboxtree.*
%
% Usage
% -----
%
%       root = getDirectoryCheckBoxTreeNodes(directory, nameFilter, excludeFilter)
%
% Example:
% --------
%
%       root = getDirectoryCheckBoxTreeNodes('./','*.tif','_sec_')
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
% Returns
% -------
%
%   checkBoxTree: CheckBoxTree with the structure of the directory.
%
% Errors
% ------
%
% If directory does not exist.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function checkBoxTree = getDirectoryCheckBoxTree(directory, nameFilter, excludeFilter)
import com.mathworks.mwswing.checkboxtree.*;
    % Default parameters
    if nargin<2
        nameFilter = '*';
    end
    if nargin<3
        excludeFilter = [];
    end
    % Gets the nodes
    root = getDirectoryCheckBoxTreeNodes(directory,nameFilter, excludeFilter, true);    
    tree = com.mathworks.mwswing.MJTree(root,true);
    treeModel = tree.getModel;
    % Builds the tree.
    checkBoxTree = CheckBoxTree(treeModel);    
end

