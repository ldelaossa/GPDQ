%% renameGroups
%
% Renames the groups in a project.
%
% Usage
% -----
%
%   project = renameGroups(project)
%
% Parameters
% ----------
%
%   project: GPDQProject whose groups must be renamed.
%
% Returns
% ----------
%
%   project: GPDQProject whose groups must be renamed.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function project = renameGroups(project)
global config;
% Avoids multiple openings of the figure. If it is already open, shows it.
windowAbout = findobj('type', 'figure', 'tag', 'renamegroups');
if ~isempty(windowAbout)
    figure(windowAbout);
    return;
end

groups = project.groups;
nGroups = numel(groups);

screenSize = get(0,'Screensize');
figureWidthPx = 800;
buttonHeightPx = 25;
buttonWidthPx = 80;
borderWidthPx = 10;
figureHeightPx = nGroups*(buttonHeightPx+1)+buttonHeightPx+3*borderWidthPx;
figurePosXPx = (screenSize(3)-figureHeightPx)/2;
figurePosYPx = (screenSize(4)-figureWidthPx)/2;
mainFigure = figure('tag','renamegroups','NumberTitle','off','Units', 'pixels', 'resize','on','menubar', 'none', 'Position',[figurePosXPx figurePosYPx figureWidthPx, figureHeightPx]);
set(mainFigure, 'Name', ['GPDQ v' config.version ' Rename groups']);


% Generates the table.
columnformat = {'char', 'char'};
columneditable =  [false, true];
columnname =   {'OLD GROUP NAME', 'NEW GROUP NAME'};
columnwidth = (figureWidthPx-2*borderWidthPx-buttonWidthPx/2)/2;    
table = uitable('parent', mainFigure, 'ColumnName', columnname, 'ColumnEditable', columneditable, 'ColumnWidth', {columnwidth, columnwidth}, ...
                'Position', [borderWidthPx, buttonHeightPx+2*borderWidthPx, figureWidthPx-2*borderWidthPx, figureHeightPx-buttonHeightPx-3*borderWidthPx]);                            
 
tableData = cell(nGroups,2);
tableData(:,1)=groups;
tableData(:,2)=groups;  

% Sets the data.
set(table,'Data',tableData);

    
    
resetButton = uicontrol('Style', 'pushbutton', 'String', 'Reset', 'Callback',@reset, ...
                       'Position', [borderWidthPx borderWidthPx, buttonWidthPx, buttonHeightPx]);
saveButton = uicontrol('Style', 'pushbutton', 'String', 'Save', 'Callback',@save, ...
                       'Position', [figureWidthPx-1*buttonWidthPx-1*borderWidthPx borderWidthPx, buttonWidthPx, buttonHeightPx]);
cancelButton = uicontrol('Style', 'pushbutton', 'String', 'Close','Callback',@cancel, ...
                       'Position', [figureWidthPx-2*buttonWidthPx-2*borderWidthPx borderWidthPx, buttonWidthPx, buttonHeightPx]);

set(saveButton,'fontSize', config.fontSize);
set(cancelButton,'fontSize', config.fontSize);

% Returns when the figure is closed.
    waitfor(mainFigure);
  
    
%% Cancels
    function cancel(~,~)
        project = GPDQStatus.CANCELED;
        delete(mainFigure);
    end

%% Resets
    function reset(~,~)
        % Although table is update, tableData is not. 
        set(table,'Data',tableData);
    end


%% Saves
    function save(~, ~)
        valid = true;
        groupData = get(table,'Data');
        groupToGroup = containers.Map('KeyType','char', 'ValueType','char');
        % Processes each group
        for idGroup=1:nGroups
            newGroupName = strtrim(groupData{idGroup,2});  % Removes spaces
            % Adds the entry when the new group is not empty
            if ~isempty(newGroupName)
                groupToGroup(groupData{idGroup,1})=newGroupName;
            % Otherwise marks it as non valid
            else
                groupData{idGroup,2} = colorString('#FFBBBB',' -- ');
                valid = false;
            end
        end
        % Ir there is no valid groups, returns. 
        if ~valid
            GPDQStatus.repError('New group names can not be empty',true);
            set(table,'Data', groupData);
            return;
        end
        % Renames the groups.
        for idSection=1:project.numSections
            if groupToGroup.isKey(project.data{idSection,3}) %Skips empty groups.
                project.data{idSection,3}=groupToGroup(project.data{idSection,3});
            end
        end
        delete(mainFigure);
    end
    


end

