%% newProjectEdit Allows creating a project. 
% Given a directory, builds a checkboxtree that allows selecting the images
% to be included in the project, and returns a GPDQProject object.
%
% By default, considers one section per image. 
%
% Allows using subfolders as groupnames. Also, calculating and using a
% default scale. 
%
%
% Usage
% -----
%
%       project = newProjectEdit(directory, filter, excludeFilter)
%
% Example
% -------
%
%       project = newProjectEdit('gabab/images', '*.tif', '_sec_')
%
%
% Parameters
% ----------
%
%       directory: Directory containing the images. 
%       filter: Files shown (expects the images).
%       excludeFilter: Files hidden (for discarding sections and csv files). 
%
% Returns
% -------
%
%       project: A GPDQProject object. It can also return GPDQStatus.ERROR,
%       or GPDQStatus.CANCELED.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function project = newProjectEdit(directory, filter, excludeFilter)
import com.mathworks.mwswing.checkboxtree.*
global config;

% Initially, returns error (no project created).
project = GPDQStatus.ERROR;

% Avoids multiple openings of the figure.
windowNewProject = findobj('type', 'figure', 'tag', 'newProject');
if ~isempty(windowNewProject)
    GPDQStatus.repError('Another instance of newProject is already open. It must be closed first', true, dbstack());
    figure(windowNewProject);
    return;
end

% Default arguments.
if nargin<3
    excludeFilter = [];
end
if nargin<2
    filter = '*';
end
% If no directory is provided, opens a dialog.
if nargin<1 || isempty(directory)
    directory = uigetdir();
    % Returns if no directory is privided
    if directory==0
        project = GPDQStatus.CANCELED;
        return;
    end
end

% Figure
HFig = newProjectFig();

% Sets the callback
set(HFig.fileFilterEdit,'CallBack',@genTree);
set(HFig.buttonCancel,'Callback', @cancel);
set(HFig.buttonSelect, 'Callback', @select);
set(HFig.buttonMeasureScale,'Callback', @getScale);

%Creates the checkboxtree
checkBoxTree=[];
treeComponent=[];
genTree();

% Variables
images = [];
groups = [];

% Creates the project
project = GPDQProject;

% Returns then the figure is closed.
waitfor(HFig.mainFigure);


%% Callbacks and auxiliar functions

%% Generates the tree given the file filter.
    function genTree(~,~)
        delete(treeComponent);
        filter = get(HFig.fileFilterEdit, 'String');
        checkBoxTree = getDirectoryCheckBoxTree(directory,filter,excludeFilter);
        scrollPane = com.mathworks.mwswing.MJScrollPane(checkBoxTree);
        treeSizePx = get(HFig.panelProject,'Position');
        treeSizePx = treeSizePx(3:4);
        [~,treeComponent] = javacomponent(scrollPane,[10, 45, treeSizePx(1)-20, treeSizePx(2)-90],HFig.panelProject);
    end

    function getScale(~,~)
        scale = measureScale(directory);
        if ~GPDQStatus.isError(scale)
            set(HFig.editDefScale, 'String', num2str(scale));
        end
    end

%% Returns the selected files.
    function getSelection(varargin)
        % Structures of the selected files and the group names.
        images = cell(1,0);
        groups = cell(1,0);
        
        % Extracts the maes of the files.
        model = checkBoxTree.getModel;
        enumNodes = model.getRoot.depthFirstEnumeration;
        while enumNodes.hasMoreElements
            currentNode = enumNodes.nextElement;
            % Includes the image only if selected.
            selected = char(currentNode.getSelectionState);
            if ~strcmpi(selected,'selected')
                continue
            end
            % Only considers leafs
            if ~currentNode.isLeaf
                continue
            end
            % Discards empty folders
            if currentNode.getAllowsChildren
                continue
            end
            
            % Adds the file
            path = cell(currentNode.getUserObjectPath);
            pathFile = fullfile(path{2:end});
            % Extracts the folder (excluding the root)
            if numel(path)>2
                pathDir = fullfile(path{2:end-1});
            else
                pathDir = [];
            end
            
            if strcmpi(selected,'selected')
                images = [images; pathFile];
                % Assigns a tag to the base group
                if ~isempty(pathDir)
                    groups = [groups; pathDir];
                else
                    groups = [groups; 'BASE'];
                end
            end
        end
    end


%% Closes a returns an empty object.
    function cancel(~,~)
        project = GPDQStatus.CANCELED;
        delete(gcf);
    end

%% Closes and returns the list of selected files.
    function select(~,~)
        getSelection();
        % Stores the data
        project.workingDirectory = directory;
        % Creates the project structure
        project.data = cell(numel(images),4);
        % Add the files
        project.data(:,1) = images;
        % The scale
        strScale = get(HFig.editDefScale,'String');
        % If empty, leaves it empty.
        if isempty(strScale)
            defaultScale = [];
            % Otherwise
        else
            defaultScale = str2num(strScale);
            % If the scale is not valid, does not close (to prevent from losing information)
            if isempty(defaultScale) || numel(defaultScale)>1
                GPDQStatus.repError([strScale ' is not a valid number format. You must correct the value or leave it empty.'], true, dbstack());
                return;
            end
        end
        % Name of the project. It corresponds to the name of the file where
        % it should be stored, and not include a path, as it will be stored
        % in the same folder than the images. 
        strFile = get(HFig.fileEdit,'String');
        [path, name, ext] = fileparts(strFile);
        if isempty(name)
            GPDQStatus.repError('Warning: The name is empty. A name must be assigned before saving the project.', false, dbstack());
        else
            if isempty(ext)
                ext ='.csv';
            end   
            strFile = [name, ext];
            if ~isempty(path)
                GPDQStatus.repError(['The name of the project corresponds to a file that must be placed in the same folder than the project. Naming the project as ' strFile], true, dbstack());
            end   
            project.fileName = strFile;
        end
        % Stores the images        
        for imageId=1:numel(images)
            project.data{imageId,2}=uint32(1);
            project.data{imageId,4}=defaultScale;
        end
        if get(HFig.checkDefGroup,'Value')==0
            for imageId=1:numel(images)
                project.data{imageId,3}=[];
            end
        else
            project.data(:,3) = groups;
        end
        delete(gcf);
    end

%% Creates the figure.
    function HFig = newProjectFig
        % Gets the screen size
        screenSize = get(0,'Screensize');
        
        % Initial size and position
        figureHeightPx = screenSize(4)*0.6;
        figureWidthPx =  600;
        figurePosXPx = (screenSize(3)-figureWidthPx)/2;
        figurePosYPx = (screenSize(4)-figureHeightPx)/2;
        
        % Creates the figure.
        positionFigure =  [figurePosXPx figurePosYPx figureWidthPx figureHeightPx];
        HFig.mainFigure = figure('OuterPosition', positionFigure,'menubar', 'none','resize','off','DockControls','off', 'NumberTitle', 'off');
        set(HFig.mainFigure,'tag','newProject');
        set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version ': Select files and parameters for new project']);
        
        panelHeightPx = figureHeightPx-85;
        panelWidthPx = figureWidthPx-20;
        HFig.panelProject = uipanel(HFig.mainFigure,'Units', 'pixels', 'Position',[10 45 580 panelHeightPx]);
        
        
        HFig.fileFilterLabel = uicontrol(HFig.panelProject,'Style','Text','String', 'Filter by name/extension', 'Position', [10 panelHeightPx-40 180 25], 'HorizontalAlignment','left');
        HFig.fileFilterEdit = uicontrol(HFig.panelProject,'Style','Edit','String', '*.tif', 'Position', [200 panelHeightPx-35 370 25], 'HorizontalAlignment','Left');
        
        HFig.textDefScale = uicontrol(HFig.panelProject,'Style','Text','String','Default scale (optional)','Position', [260 5 150 25], 'HorizontalAlignment','right');
        HFig.editDefScale = uicontrol(HFig.panelProject,'Style','Edit','String','','Position', [420 10 60 25],'HorizontalAlignment','left');
        HFig.buttonMeasureScale = uicontrol(HFig.panelProject,'Style', 'pushbutton', 'String', 'Measure', 'Tooltipstring','Opens an image and measures the scale', 'Position', [490 10 80 25]);
        
        HFig.checkDefGroup= uicontrol(HFig.panelProject,'Style','check','String','Use subfolder name as group','Position', [10 10 210 25],'Value',1);
        
        HFig.buttonCancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel', 'Tooltipstring','Cancel', 'Position', [420 10 80 25]);
        HFig.buttonSelect = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Tooltipstring','Returns the project definition', 'Position', [510 10 80 25]);
        HFig.fileLabel = uicontrol(HFig.mainFigure, 'Style','Text','String', 'Name', 'Position', [20 5 80 25], 'HorizontalAlignment','left');
        HFig.fileEdit = uicontrol(HFig.mainFigure,'Style','Edit','String', 'project.csv', 'Position', [110 10 290 25], 'HorizontalAlignment','Left');
        
        HFig  = setFonts(HFig);
        
    end

end

