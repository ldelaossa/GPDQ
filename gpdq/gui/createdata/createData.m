%% createData
%
% Creates a GPDQData object from a GPDQProject. Allows configuring tag,
% minimum number of particles, and series. 
%
% Usage
% -----
%
%   data = createData(project)
%
% Parameters
% ----------
%
%   project: GPDQProject
%
% Returns
% ----------
%
%   data: GPDQData

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function data = createData(project)
global config;
% Avoids multiple openings of the figure. If it is already open, shows it.
windowAbout = findobj('type', 'figure', 'tag', 'createdata');
if ~isempty(windowAbout)
    figure(windowAbout);
    return;
end

% Reads the groups.
groups = project.groups;
nGroups = numel(groups);

tableData = cell(nGroups,2);
tableData(:,1)=groups;
tableData(:,2)=groups;
        
% Creates the figure
HFig = [];
createFig();



% Returns when the figure is closed.
waitfor(HFig.mainFigure);
  
    
%% Cancels
    function cancel(~,~)
        data = GPDQStatus.CANCELED;
        delete(HFig.mainFigure);
    end

%% Resets
    function reset(~,~)
        % Although table is update, tableData is not. 
        set(HFig.table,'Data',tableData);
        set(HFig.tagText, 'String', 'Default data');
        set(HFig.tagText,'Max', 5);
    end


%% Returns the data
    function ok(~, ~)
        valid = true;
         % Obtains the experimental series
        groupSerieData = get(HFig.table,'Data');
        serieGroups = containers.Map('KeyType','char', 'ValueType','Any');
        for idGroup=1:nGroups
            serieName = strtrim(groupSerieData{idGroup,2});  % Removes spaces
            % Some groups are not considered.
            if isempty(serieName)
                continue;
            end
            % If there is no entry creates it with the group.
            if ~serieGroups.isKey(serieName)
                serieGroups(serieName)=groupSerieData(idGroup,1);
            else
                serieGroups(serieName)=[serieGroups(serieName),groupSerieData(idGroup,1)];
            end
        end
        expSeries = [serieGroups.keys', serieGroups.values'];
        % Creates the data
        data = GPDQData(project, expSeries, 'MinParticles', str2num(get(HFig.minParticleText,'String')), 'Tag', get(HFig.tagText, 'String'));
        % Returns
        delete(HFig.mainFigure);
    end
    
%% Creates the Fig.
    function createFig
        screenSize = get(0,'Screensize');
        figureWidthPx = 800;
        buttonHeightPx = 25;
        buttonWidthPx = 80;
        borderWidthPx = 10;
        textHeightPx = 100;
        figureHeightPx = (nGroups+1)*(buttonHeightPx)+4*buttonHeightPx+8*borderWidthPx+textHeightPx;
        figurePosXPx = (screenSize(3)-figureHeightPx)/2;
        figurePosYPx = (screenSize(4)-figureWidthPx)/2;
        HFig.mainFigure = figure('tag','createdata','NumberTitle','off','Units', 'pixels', 'resize','on','menubar', 'none', 'Position',[figurePosXPx figurePosYPx figureWidthPx, figureHeightPx]);
        set(HFig.mainFigure, 'Name', ['GPDQ v' config.version ' -  Project data creation']);
        figureColor = get(HFig.mainFigure, 'color');
        
        % Generates the table.
        columnformat = {'char', 'char'};
        columneditable =  [false, true];
        columnname =   {'GROUP NAME', 'SERIES'};
        columnwidth = (figureWidthPx-2*borderWidthPx-buttonWidthPx/2)/2;
        HFig.table = uitable('parent', HFig.mainFigure, 'ColumnName', columnname, 'ColumnEditable', columneditable, 'ColumnWidth', {columnwidth, columnwidth}, ...
                             'Position', [borderWidthPx, buttonHeightPx+2*borderWidthPx, figureWidthPx-2*borderWidthPx, figureHeightPx-5*buttonHeightPx-4*borderWidthPx-textHeightPx]);
        
        % Sets the data.
        set(HFig.table,'Data',tableData);
        
        HFig.projectTitle = uicontrol('Style', 'Text', 'String', 'Project','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderWidthPx, figureHeightPx-buttonHeightPx-borderWidthPx-3, 0.5*buttonWidthPx, buttonHeightPx]);
        HFig.projectTitleText = uicontrol('Style', 'Edit', 'Enable', 'inactive', 'String', '','HorizontalAlignment','left','backgroundcolor','white','Enable', 'inactive',...
            'Position', [2*borderWidthPx+0.5*buttonWidthPx, figureHeightPx-buttonHeightPx-borderWidthPx, figureWidthPx-0.5*buttonWidthPx-3*borderWidthPx, buttonHeightPx]);
        
        HFig.tagTitle = uicontrol('Style', 'Text', 'String', 'Project Tag','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderWidthPx, figureHeightPx-2*buttonHeightPx-2*borderWidthPx-3, buttonWidthPx, buttonHeightPx]);
        
        HFig.tagText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', '','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [borderWidthPx, figureHeightPx-2*buttonHeightPx-3*borderWidthPx-textHeightPx, figureWidthPx-2*borderWidthPx, textHeightPx]);
        
        set(HFig.tagText, 'String', 'Default data');
        set(HFig.tagText,'Max', 5);

        HFig.minParticleTitle = uicontrol('Style', 'Text', 'String', 'Minimum number of particles','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [figureWidthPx-3*buttonWidthPx-2*borderWidthPx, figureHeightPx-2*buttonHeightPx-2*borderWidthPx-3, 2*buttonWidthPx, buttonHeightPx]);
        HFig.minParticleText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', '','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [figureWidthPx-1*buttonWidthPx-1*borderWidthPx, figureHeightPx-2*buttonHeightPx-2*borderWidthPx, buttonWidthPx, buttonHeightPx]);
        
        HFig.seriesTitle = uicontrol('Style', 'Text', 'String', 'Series','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderWidthPx, figureHeightPx-3*buttonHeightPx-4*borderWidthPx-3-textHeightPx, buttonWidthPx, buttonHeightPx]);
            
        HFig.resetButton = uicontrol('Style', 'pushbutton', 'String', 'Reset', 'Callback',@reset, ...
            'Position', [borderWidthPx borderWidthPx, buttonWidthPx, buttonHeightPx]);
        HFig.okButton = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Callback',@ok, ...
            'Position', [figureWidthPx-1*buttonWidthPx-1*borderWidthPx borderWidthPx, buttonWidthPx, buttonHeightPx]);
        HFig.cancelButton = uicontrol('Style', 'pushbutton', 'String', 'Cancel','Callback',@cancel, ...
            'Position', [figureWidthPx-2*buttonWidthPx-2*borderWidthPx borderWidthPx, buttonWidthPx, buttonHeightPx]);
        
        set(HFig.projectTitleText, 'String', fullfile(project.workingDirectory, project.fileName));
        set(HFig.minParticleText, 'String', '0');
        
        setFonts(HFig);
        
    end

end

