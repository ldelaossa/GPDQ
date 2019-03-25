function results = exploreClustersBU(directory, expSeries, distance)
global config;

% Default parameters.
if nargin<1
    directory=[];
end
if nargin<2
    expSeries = [];
end

if nargin<3
distance = 50;
end

seriesFile = [];

serieNames = [];                        % Serie names
serieIdSection = [];                    % Id of the serie for each section.

% Current State
currentSerieIds = [];                   % Selected serie. Name and ids.
currentSerieNames =  [];

currentIdSection = [];                  % Id (position) of the sections.
currentSerieIdSection = [];             % Current serie id for each section.

currentRadius = 5;                      % Paremeters (others than the series)
currentMinDistance = [];
currentMinParticles = [];

currentParticles = [];                  % Extracted data from the experimental series
currentClusters = [];
currentAreas = [];
currentNumParticles = [];

currentPlot = [];                       % Reference to the plot.


rawData = [];                           % Data used to export and build the plot.
rawDataSummary=[];                      % Only changes with cluster parameters.

% Creates the figure
HFig = createFig;
set(HFig.mainFigure, 'Visible','on');
% Set callback functions.
set(HFig.openButton, 'CallBack', @openExpSeries);
set(HFig.table,'CellEditCallBack',@updateEvent);
set(HFig.p2_5RadioButton,'CallBack',@selRadius);
set(HFig.p5RadioButton,'CallBack',@selRadius);
set(HFig.pAllRadioButton,'CallBack',@selRadius);
set(HFig.minDistanceEdit,'Callback',@updateEvent);
set(HFig.minParticlesEdit,'Callback',@updateEvent);
set(HFig.infoSeriesButton,'Callback',@showSeries);
set(HFig.plotSelPopUp,'CallBack',@updateEvent);
set(HFig.exportFigure,'CallBack', @exportFigure);
set(HFig.closeButton,'CallBack', @close);
set(HFig.buttonExportData,'CallBack', @exportData);
set(HFig.buttonExportTable,'CallBack', @exportSummary);


% Updates
updateExpSeries();

% Waits for the main figure to return results.
waitfor(HFig.mainFigure);

%% -----------------------------------------------------------
%  Callbacks and functions (alphabetical order)
% ------------------------------------------------------------

%% Closes the figure
    function close(~,~)
        delete(gcf);
    end

%% Export data
    function exportData(~,~)
        data = num2cell(rawData(:,[1,4,2,3]));
        names = arrayfun(@(x) secImageFile(x.image, x.section),expSeries.sections,'UniformOutput',false);
        for idParticle=1:size(data,1)
            data{idParticle,1} = expSeries.definition{rawData(idParticle,1),1};
            data{idParticle,2} = names{data{idParticle,2}};
        end
        report = GPDQReport({'SERIE', 'SECTION', 'AREA','NUM PARTICLES'},{'%s','%s','%.4f','%d'},data);
        showReport(report,fullfile(directory,[seriesFile(1:end-4) ' CLUSTERS ALL.csv']));
    end
%% Export data
    function exportSummary(~,~)
        report = GPDQReport({'SERIE', 'SECTIONS', 'MEAN AREA','STD AREA','MEAN NUM PARTICLES','STD NUM PARTICLES'},{'%d','%s','%.4f','%.4f','%.4f','%.4f'},rawDataSummary);
        showReport(report,fullfile(directory,[seriesFile(1:end-4) ' CLUSTERS GROUP.csv']));
    end

%% Exports the current axes to a new figure.
    function exportFigure(~,~)
        updatePlot(true);
    end

%% Opens an object Containing experimental series.
    function openExpSeries(~,~)
        % Opens the file
        if isempty(directory)
            [seriesFile, directory] = uigetfile('*.mat');
        else
            [seriesFile, directory] = uigetfile(fullfile(directory,'*.mat'));
        end
        % If no file has been selected, returns.
        if seriesFile==0
            return;
        end
        % Otherwise loads the file.
        tmpExpSeries = GPDQExpSeries.load(fullfile(directory,seriesFile));
        if GPDQStatus.isError(tmpExpSeries)
            GPDQStatus.repError(['Unable to load ' fullfile(directory,seriesFile) 'as experimental series'], true, dbstack());
        else
            expSeries = tmpExpSeries;
        end
        set(HFig.expSeriesTitleText,'String', fullfile(directory,seriesFile));
        % Update the experimental series
        updateExpSeries();
    end

%% Selects the current radius
    function selRadius(object, ~)
        if strcmp(object.String,'Radius 2.5Nm')
            currentRadius=2.5;
            set(HFig.radioButtons(2),'Value',0);
            set(HFig.radioButtons(3),'Value',0);
        elseif strcmp(object.String,'Radius 5Nm')
            currentRadius=5;
            set(HFig.radioButtons(1),'Value',0);
            set(HFig.radioButtons(3),'Value',0);
        else
            currentRadius=[2.5 5];
            set(HFig.radioButtons(1),'Value',0);
            set(HFig.radioButtons(2),'Value',0);
        end
        updateData();
    end


%% Selects the current categorie
    function updateEvent(~, ~)
        updateData();
    end

%% Updates the current data.
    function updateData()
        % If the serie is empty, returns.
        if isempty(expSeries)
            return
        end
        
        % Names and id's of the series considered.
        currentSerieIds = find([HFig.table.Data{:,1}]);
        currentSerieNames =  serieNames(currentSerieIds);
        
        % Filters the sections by serie Id.
        currentIdSection = find(ismember(serieIdSection, currentSerieIds));
        currentSerieIdSection  = serieIdSection(currentIdSection);
        
        % Extracts the information.
        currentMinDistance = str2double(get(HFig.minDistanceEdit,'String'));
        currentMinParticles = str2double(get(HFig.minParticlesEdit,'String'));
        currentParticles = expSeries.particles(currentRadius);
        %currentParticles = currentParticles(currentIdSection);
        
        function res = aux(p)
            if isempty(p) || size(p,1)<2
                res = [];
            else
                res = p(:,1:2);
            end   
        end
        particlePositions = cellfun(@(p) aux(p), currentParticles, 'UniformOutput',false);
        
        
        currentClusters = cellfun(@(p) hClustering(p,currentMinDistance,currentMinParticles), particlePositions, 'UniformOutput',false);
        currentAreas = cellfun(@(p,c) areaClusters(p,c), currentParticles, currentClusters, 'UniformOutput',false);
        currentNumParticles = cellfun(@(p,c) sizeClusters(p,c), currentParticles, currentClusters, 'UniformOutput',false);
        empty = cellfun('isempty',currentNumParticles);
        
        selSections = find(~empty);
        numClusterSections = cellfun(@(p) size(p,1), currentAreas, 'UniformOutput',false);
        numClusterSections = numClusterSections(~empty);
        selSectionsIds = cell2mat(arrayfun(@(v,r)repmat(v,1,r),selSections,cell2mat(numClusterSections), 'UniformOutput',false));

        % Updates the data.
        rawData = [];
        rawDataSummary = cell(expSeries.numSeries,6);
        for serieId=1:expSeries.numSeries
            % Extracts data
            sectionsSerie = (serieIdSection==serieId);
            sectionsSerie(empty)=0;
            rawDataAreas = cell2mat(currentAreas(sectionsSerie)');
            rawDataNumParticles = cell2mat(currentNumParticles(sectionsSerie)');
            % Adds mark of serie and adds to the data to be used with the plot and export.
            rawData = [rawData;  [serieId*ones(numel(rawDataAreas),1), rawDataAreas, rawDataNumParticles]];
            % Summary.
            rawDataSummary{serieId,1} = expSeries.definition{serieId,1};
            rawDataSummary{serieId,2} = sum((serieIdSection==serieId) & (~empty'));
            rawDataSummary{serieId,3} = mean(rawDataAreas);
            rawDataSummary{serieId,4} = std(rawDataAreas);
            rawDataSummary{serieId,5} = mean(rawDataNumParticles);
            rawDataSummary{serieId,6} = std(rawDataNumParticles);
        end
        rawData = [rawData, selSectionsIds'];
        % Updates data in the table
        HFig.table.Data(:,3:end) = rawDataSummary(:,2:end);
        %Plot
        updatePlot();
    end

%% Updates the plots
    function updatePlot(newFigure)
        % Deletes (THERE ARE SOME PROBLEMS TO REMOVE VIOLIN PLOT)
        if nargin<1 || ~newFigure
            axes(HFig.axesPlot);
            delete(HFig.axesPlot.Children);
        else
            figure;
        end
        
        dataPlot = rawData(ismember(rawData(:,1),currentSerieIds),:);
        % Determines title and origin of data.
        if strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot (Area)') || strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Violin plot (Area)')
            titleText = 'Area / cluster';
            ylabelText = 'Sq. Nanometers';
            col = 2;
        else
            titleText = 'Number of particles / cluster';
            ylabelText = 'Particles';
            col = 3;
        end
        
        try
            % Plot
            if strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot (Area)') || strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot (Particles)')
                currentPlot = boxplot(dataPlot(:,col), dataPlot(:,1), 'Labels', currentSerieNames');
            else
                currentPlot = violinplot(dataPlot(:,col), dataPlot(:,1));
                set(gca, 'xticklabels', currentSerieNames);
                set(gca,'ylim',[0.9*min(dataPlot(:,col)),1.1*max(dataPlot(:,col))])

            end
        catch
            GPDQStatus.repError('There are no data corresponding to this category', true, dbstack());
        end
        % Complete the plot.
        ylabel(ylabelText , 'FontSize',14);
        xlabel('Group', 'FontSize',14);
        title(titleText, 'FontSize',15);
    end

%% Updates the experimental series.
    function updateExpSeries()
        if isempty(expSeries)
            return
        end
        % Serie name for each section
        serieIdSection = expSeries.idSeries;
        serieNames = expSeries.serieNames(true);
        % Updates the table
        updateTable();
        % Updates the information.
        updateData();
    end

%% Updates the table
    function updateTable()
        checkBoxes=num2cell(false(expSeries.numSeries,1));
        data = cell(numel(serieNames), 5);
        tableData =[checkBoxes serieNames data];
        set(HFig.table,'Data',tableData);
    end

%% Creates the figure
    function HFig = createFig
        % Actual size of the image
        screenSize = get(0,'Screensize');
        % Sizes of the components. Used for layout
        borderPx = 10;
        buttonHeightPx = 25;
        buttonWidthPx = 80;
        axesPlotHeightPx = 300;
        axesPlotWidthPx = 700;
        panelWidthPx = axesPlotWidthPx;
        panelPlotHeightPx = axesPlotHeightPx+3*borderPx+buttonHeightPx;
        panelSeriesHeightPx = 13*buttonHeightPx+6*borderPx;
        figureWidthPx= panelWidthPx+2*borderPx;
        figureHeightPx = panelPlotHeightPx+panelSeriesHeightPx+4*borderPx+buttonHeightPx;
        figurePosYPx = (screenSize(4)-figureHeightPx)/2;
        figurePosXPx = (screenSize(3)-figureWidthPx)/2;
        
        
        % Figure
        HFig.mainFigure = figure('NumberTitle','off','Units', 'pixels', 'resize','off','menubar', 'none', 'DockControls','off','Visible','off');
        set(HFig.mainFigure,'Position', [figurePosXPx figurePosYPx figureWidthPx figureHeightPx]);
        set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version '. Clustering']);
        figureColor = get(HFig.mainFigure, 'color');
        
        % Panel expSeries
        HFig.panelExpSeries = uipanel(HFig.mainFigure,'Units','pixels','Title','Experimental series','FontSize',12);
        set(HFig.panelExpSeries,'Position',[borderPx,panelPlotHeightPx+2*borderPx+buttonHeightPx, panelWidthPx, panelSeriesHeightPx])
        
        % Open experimental series
        HFig.openButton = uicontrol('Parent', HFig.panelExpSeries, 'Style', 'pushbutton', 'String', 'Open');
        set(HFig.openButton, 'Position', [borderPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx, buttonWidthPx buttonHeightPx]);
        HFig.expSeriesTitleText = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Edit', 'Enable', 'inactive', 'String', '','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [2*borderPx+buttonWidthPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx, panelWidthPx-4*borderPx-2*buttonWidthPx buttonHeightPx]);
        HFig.infoSeriesButton = uicontrol('Parent', HFig.panelExpSeries,'Style', 'pushbutton', 'String', 'Info',...
            'Position', [panelWidthPx-1*borderPx-buttonWidthPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx,buttonWidthPx buttonHeightPx]);
        
        % Table
        columnformat = {'logical', 'char', 'numeric','numeric', 'numeric', 'numeric', 'numeric'};
        columneditable =  [true false false false false false false];
        columnname =   {'Select', 'Series', 'Num Sections', 'Avg. Area', 'Std. Area', 'Avg. Size', 'Std.Size'};
        HFig.table = uitable('Parent', HFig.panelExpSeries,'Units','Pixels', 'ColumnName', columnname, 'ColumnFormat', columnformat, 'ColumnEditable', columneditable,...
            'Position', [borderPx 2*buttonHeightPx+3*borderPx axesPlotWidthPx-2*borderPx 10*buttonHeightPx]);
        %set (HFig.table,'ColumnWidth', {buttonWidthPx/2,3*buttonWidthPx})  %'RowName',[] ,'BackgroundColor',[.7 .9 .8],'ForegroundColor',[0 0 0]);
        
        %Radius selection
        HFig.p2_5RadioButton = uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'Radius 2.5Nm','Value',0,...
            'Position', [panelWidthPx-3.5*borderPx-3.5*buttonWidthPx,2*borderPx+buttonHeightPx, 1.25*buttonWidthPx buttonHeightPx]);
        HFig.p5RadioButton = uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'Radius 5Nm', 'Value',1,...
            'Position', [panelWidthPx-2*borderPx-2.25*buttonWidthPx,2*borderPx+buttonHeightPx, 1.25*buttonWidthPx buttonHeightPx]);
        HFig.pAllRadioButton= uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'All particles','HorizontalAlignment','Right', 'Value',0,...
            'Position', [panelWidthPx-borderPx-1*buttonWidthPx,2*borderPx+buttonHeightPx, 1*buttonWidthPx buttonHeightPx]);
        
        HFig.radioButtons = [HFig.p2_5RadioButton, HFig.p5RadioButton, HFig.pAllRadioButton]; % Ugly radio button grouup. Not available with guide (I think)
        
        % Clustering
        HFig.clustSelText = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Text', 'String', 'Clustering method','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx buttonHeightPx+2*borderPx-5 1.5*buttonWidthPx buttonHeightPx]);
        HFig.clustSelPopUp = uicontrol('Parent', HFig.panelExpSeries,'Style', 'popup', ...
            'Position', [2*borderPx+1.5*buttonWidthPx buttonHeightPx+2*borderPx-5 (axesPlotWidthPx/2)-2*buttonWidthPx buttonHeightPx]);
        set(HFig.clustSelPopUp,'String',{'Agglomerative clustering'});
        HFig.minDistanceText = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Text', 'String', 'Min distance (inter, Nm)','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx borderPx-5 1.5*buttonWidthPx buttonHeightPx]);
        HFig.minDistanceEdit = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Edit', 'String', num2str(distance),'HorizontalAlignment','center','backgroundcolor',figureColor,...
            'Position', [2*borderPx+1.5*buttonWidthPx borderPx 0.5*buttonWidthPx buttonHeightPx]);
        HFig.minParticlesText = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Text', 'String', 'Min. Particles','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [2*buttonWidthPx+3*borderPx borderPx-5 1*buttonWidthPx buttonHeightPx]);
        HFig.minParticlesEdit = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Edit', 'String', '3','HorizontalAlignment','center','backgroundcolor',figureColor,...
            'Position', [3*buttonWidthPx+3*borderPx borderPx 0.5*buttonWidthPx buttonHeightPx]);
        
        
        % Export button
        HFig.buttonExportData = uicontrol('Parent',HFig.panelExpSeries,'Style', 'pushbutton', 'String', 'Export data');
        set(HFig.buttonExportData, 'Position', [panelWidthPx-borderPx-buttonWidthPx, 1*borderPx, buttonWidthPx buttonHeightPx]);
        HFig.buttonExportTable = uicontrol('Parent',HFig.panelExpSeries,'Style', 'pushbutton', 'String', 'Export table');
        set(HFig.buttonExportTable, 'Position', [panelWidthPx-2*borderPx-2*buttonWidthPx, 1*borderPx, buttonWidthPx buttonHeightPx]);
        
        % Panel Plot
        HFig.panelPlot = uipanel(HFig.mainFigure,'Units','pixels');
        set(HFig.panelPlot,'Position',[borderPx,2*borderPx+buttonHeightPx, panelWidthPx, panelPlotHeightPx])
        
        % Axes
        HFig.axesPlot = axes('Parent',HFig.panelPlot,'units','pixels','visible','off');
        set(HFig.axesPlot, 'Position', [buttonWidthPx +3*buttonHeightPx+borderPx, axesPlotWidthPx-2*buttonWidthPx, axesPlotHeightPx-3*buttonHeightPx]);
        
        % Plot selection
        HFig.plotSelText = uicontrol('Parent', HFig.panelPlot,'Style', 'Text', 'String', 'Plot type ','HorizontalAlignment','left','backgroundcolor',figureColor,'Position', [borderPx borderPx buttonWidthPx buttonHeightPx]);
        HFig.plotSelPopUp = uicontrol('Parent', HFig.panelPlot,'Style', 'popup', 'Position', [2*borderPx+buttonWidthPx borderPx (axesPlotWidthPx/2)-buttonWidthPx buttonHeightPx]);
        set(HFig.plotSelPopUp,'String',{'Box plot (Area)', 'Box plot (Particles)', 'Violin plot (Area)', 'Violin plot (Particles)'});
        
        HFig.exportFigure = uicontrol('Parent', HFig.panelPlot, 'Style', 'pushbutton', 'String', 'Figure', 'Position', [panelWidthPx-borderPx-buttonWidthPx, borderPx buttonWidthPx buttonHeightPx]);
        
        % Close button.
        HFig.closeButton = uicontrol('Parent', HFig.mainFigure, 'Style', 'pushbutton', 'String', 'Close');
        set(HFig.closeButton, 'Position', [figureWidthPx-borderPx-buttonWidthPx, borderPx, buttonWidthPx buttonHeightPx]);
    end

%% Shows the series definition.
    function showSeries(~, ~)
        screenSize = get(0,'Screensize');
        figureHeightPx = 600; % Dimmension
        figureWidthPx = 600;
        figurePosXPx = (screenSize(3)-figureHeightPx)/2;
        figurePosYPx = (screenSize(4)-figureWidthPx)/2;
        infoFigure = figure('tag','about','NumberTitle','off','Units', 'pixels', 'resize','on','menubar', 'none', ...
            'Position',[figurePosXPx figurePosYPx figureWidthPx, figureHeightPx]);
        set(infoFigure, 'Name', ['GPDQ v' config.version]);
        
        closeButton = uicontrol('Style', 'pushbutton', 'String', 'Close', 'Position', [270 10, 60, 25],'Callback',@close);
        set(closeButton,'fontSize', config.fontSize);
        
        infoText=uicontrol('Style', 'Edit', 'String','','Enable','inactive', 'HorizontalAlignment','Left','backgroundcolor','white', 'Position', [10, 45, 580, 545]);
        set(infoText,'fontSize', config.fontSize);
        set(infoText,'Max', 20);
        text='EXPERIMENTAL SERIES';
        text = strvcat(text, sprintf('\n%s', expSeries.tag));
        numSeries = size(expSeries.definition,1);
        for idSerie=1:numSeries
            text = strvcat(text, sprintf('\n%s', expSeries.definition{idSerie,1}));
            numGroupsSerie = size(expSeries.definition{idSerie,2},1);
            for groupSerie=1:numGroupsSerie
                text = strvcat(text, sprintf('\n\t%s', expSeries.definition{idSerie,2}{groupSerie}));
            end
        end
        set(infoText,'String',text);
        function close(~,~)
            delete(gcf);
        end
    end
end

