function results = exploreClusters(data, directory, distance)
global config;

% Default parameters.
if nargin<1
    data = [];
end
if nargin<2
    directory=[];
end
if nargin<3
    distance = 50;
end

% Data used to export and build the plot.
rawInfo = [];     % Raw data
sumInfo =[];      % Summary by experimental serie

% Selected radius
radius = 5;

% Creates the figure
HFig = createFig;
set(HFig.mainFigure, 'Visible','on');
% Set callback functions.
set(HFig.openButton, 'CallBack', @openData);
set(HFig.infoSeriesButton,'Callback',@showSeries);
set(HFig.table,'CellEditCallBack',@updatePlotEvent);
% Radii selection
set(HFig.p2_5RadioButton,'CallBack',@selRadius);
set(HFig.p5RadioButton,'CallBack',@selRadius);
set(HFig.pAllRadioButton,'CallBack',@selRadius);
% Clusters
set(HFig.maxDistanceEdit,'Callback',@updateClusterEvent);
set(HFig.minParticlesEdit,'Callback',@updateClusterEvent);
% Export
set(HFig.buttonExportData,'CallBack', @exportData);
set(HFig.buttonExportTable,'CallBack', @exportSummary);
% Plot
set(HFig.plotSelPopUp,'CallBack',@updatePlotEvent);
set(HFig.exportFigure,'CallBack', @exportFigure);
% Close
set(HFig.closeButton,'CallBack', @close);

% Updates the info 
updateInfo(true); %true because updates due to new data

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
        report = GPDQReport({'SERIE', 'SECTION', 'NUM PARTICLES', 'AREA'},{'%s','%s','%.4f','%.4f'}, rawInfo);
        showReport(report, fullfile(directory,[data.project(1:end-4) ' CLUSTERS ALL.csv']));
    end

%% Exports the current axes to a new figure.
    function exportFigure(~,~)
        updatePlot(true);
    end

%% Export summary
    function exportSummary(~,~)
        report = GPDQReport({'SERIE', 'SECTIONS', 'TOTAL N CLUSTERS' ,'MEAN NUM CL','STD NUM CL',...
                                                                      'MEAN AREA CL','STD AREA CL', ...
                                                                      'MEAN PART CL','STD PART CL'}, ...
                            {'%s','%d','%.4f','%.4f','%.4f','%.4f','%.4f','%.4f','%.4f'}, sumInfo);
        showReport(report,fullfile(directory,[data.project(1:end-4) ' CLUSTERS GROUP.csv']));
    end

%% Opens an object Containing experimental series.
    function openData(~,~)
        % Opens the file
        if isempty(directory)
            [dataFile, directory] = uigetfile('*.mat');
        else
            [dataFile, directory] = uigetfile(fullfile(directory,'*.mat'));
        end
        % If no file has been selected, returns.
        if dataFile==0
            return;
        end
        % Otherwise loads the file.
        tmpData = GPDQData.load(fullfile(directory,dataFile));
        if GPDQStatus.isError(tmpData)
            GPDQStatus.repError(['Unable to load ' fullfile(directory,dataFile) 'as experimental series'], true, dbstack());
        else
            data = tmpData;
        end
        set(HFig.expSeriesTitleText,'String', fullfile(directory,dataFile));
        % Update the data and the table
        updateInfo(true);
    end

%% Selects the current radius
    function selRadius(object, ~)
        if strcmp(object.String,'Radius 2.5Nm')
            radius=2.5;
            set(HFig.radioButtons(2),'Value',0);
            set(HFig.radioButtons(3),'Value',0);
        elseif strcmp(object.String,'Radius 5Nm')
            radius=5;
            set(HFig.radioButtons(1),'Value',0);
            set(HFig.radioButtons(3),'Value',0);
        else
            radius=[2.5 5];
            set(HFig.radioButtons(1),'Value',0);
            set(HFig.radioButtons(2),'Value',0);
        end
        updateInfo(false);
    end

%% Update clustering
    function updateClusterEvent(~, ~)
        updateInfo(false);
    end

%% Updates the current data.
    function updateInfo(isNewData)
        % newData true if data (and therefore series) has changed. 
        % Returns if data is empty
        if isempty(data)
            return
        end
        % Extracts the data
        maxDistance = str2double(get(HFig.maxDistanceEdit,'String'));
        minParticles = str2double(get(HFig.minParticlesEdit,'String'));
        [rawInfo, sumInfo] = clusterSummary(data, radius, maxDistance, minParticles, true);
        % Updates the table
        updateTable(isNewData);
        % Updates the plot
        updatePlot();
    end

%% Selects the current categorie
    function updatePlotEvent(~, ~)
        updatePlot();
    end


%% Updates the plots
    function updatePlot(newFigure)
         % Selected series ids. 
        selectedSerieIds = find([HFig.table.Data{1:end,1}]);
        selectedAll = HFig.table.Data{end,1};
        
        % Returns if raw info es empty or no serie is selected
        if isempty(rawInfo) || isempty(selectedSerieIds) 
            delete(HFig.axesPlot.Children);
            return
        end
        
        % Deletes (THERE ARE SOME PROBLEMS TO REMOVE VIOLIN PLOT)
        if nargin<1 || ~newFigure
            axes(HFig.axesPlot);
            delete(HFig.axesPlot.Children);
        else
            figure;
        end
        
        % Names of the selected series
        selectedSerieNames = HFig.table.Data(selectedSerieIds, 2);
         
        % Extracts the data as a matrix
        maxDistance = str2double(get(HFig.maxDistanceEdit,'String'));
        minParticles = str2double(get(HFig.minParticlesEdit,'String'));
        [rawInfoMat, ~] = clusterSummary(data, radius, maxDistance, minParticles, false);
        
        % Data of the selected series
        rawInfoPlot = rawInfoMat(ismember(rawInfoMat(:,1), selectedSerieIds),:);
        % Adds all data as one serie if necessary
        if selectedAll                                        %%% THIS IS CORRECT BUT MUST BE CLEANED
            rawInfoMat(:,1) = data.numSeries+1;
            rawInfoPlot = [rawInfoPlot; rawInfoMat];
        end
        
        % Determines title and origin of data.
        if strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot (Particles)') || strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Violin plot (Particles)')
            titleText = 'Number of particles / cluster';
            ylabelText = 'Amount of particles';
            col = 3;
        elseif strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot (Area)') || strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Violin plot (Area)')
            titleText = 'Area / cluster';
            ylabelText = 'Sq Micra';
            col = 4;
        end  
        
        try
            % Plot
            if strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot (Area)') || strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot (Particles)') ||  strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot (Density)')
                currentPlot = boxplot(rawInfoPlot(:,col), rawInfoPlot(:,1), 'Labels', selectedSerieNames);
            else
                currentPlot = violinplot(rawInfoPlot(:,col), rawInfoPlot(:,1));
                set(gca, 'xticklabels', selectedSerieNames);
                set(gca,'ylim',[0.9*min(rawInfoPlot(:,col)),1.1*max(rawInfoPlot(:,col))])
                
            end
        catch
            GPDQStatus.repError('There are no data corresponding to this category', true, dbstack());
        end
        % Complete the plot.
        ylabel(ylabelText , 'FontSize',config.fontSize+2);
        xlabel('Group', 'FontSize',config.fontSize+2);
        title(titleText, 'FontSize',config.fontSize+3);        

    end

%% Updates the table
    function updateTable(newTable)
        if newTable
            checkBoxes=num2cell(false(size(sumInfo,1),1));
            tableData = [checkBoxes sumInfo];
            set(HFig.table,'Data',tableData);
        else
            HFig.table.Data(:,2:end) =  sumInfo;
        end
    end

%% Shows the series definition.
    function showSeries(~, ~)
        infoText(data.descriptionString, 'Data description')
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
        axesPlotWidthPx = 900;
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
        HFig.panelExpSeries = uipanel(HFig.mainFigure,'Units','pixels','Title','Experimental series');
        set(HFig.panelExpSeries,'Position',[borderPx,panelPlotHeightPx+2*borderPx+buttonHeightPx, panelWidthPx, panelSeriesHeightPx])
        
        % Open experimental series
        HFig.openButton = uicontrol('Parent', HFig.panelExpSeries, 'Style', 'pushbutton', 'String', 'Open');
        set(HFig.openButton, 'Position', [borderPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx, buttonWidthPx buttonHeightPx]);
        HFig.expSeriesTitleText = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Edit', 'Enable', 'inactive', 'String', '','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [2*borderPx+buttonWidthPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx, panelWidthPx-4*borderPx-2*buttonWidthPx buttonHeightPx]);
        HFig.infoSeriesButton = uicontrol('Parent', HFig.panelExpSeries,'Style', 'pushbutton', 'String', 'Info',...
            'Position', [panelWidthPx-1*borderPx-buttonWidthPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx,buttonWidthPx buttonHeightPx]);
        
% Table
        columnformat = {'logical', 'char', 'numeric','numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric','numeric'};
        columneditable =  [true false false false false false false false false false];
        columnname =   {'Select', 'Series', 'Sections', 'Num Cl.', 'Mean Cl.', 'Std Cl.', 'Mean Area.', 'Std Area.', 'Mean Part.', 'Std Part.'};
        HFig.table = uitable('Parent', HFig.panelExpSeries,'Units','Pixels', 'ColumnName', columnname, 'ColumnFormat', columnformat, 'ColumnEditable', columneditable,...
            'Position', [borderPx 2*buttonHeightPx+3*borderPx axesPlotWidthPx-2*borderPx 10*buttonHeightPx]);
        set (HFig.table,'ColumnWidth', {buttonWidthPx/2,3.75*buttonWidthPx,0.75*buttonWidthPx, ...
             0.75*buttonWidthPx, 0.75*buttonWidthPx, 0.75*buttonWidthPx,...
             0.75*buttonWidthPx, 0.75*buttonWidthPx,...
             0.75*buttonWidthPx, 0.75*buttonWidthPx});% , 'RowName',[] ,'BackgroundColor',[.7 .9 .8],'ForegroundColor',[0 0 0]);
        
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
        HFig.maxDistanceText = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Text', 'String', 'Min distance (inter, Nm)','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx borderPx-5 1.5*buttonWidthPx buttonHeightPx]);
        HFig.maxDistanceEdit = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Edit', 'String', num2str(distance),'HorizontalAlignment','center','backgroundcolor',figureColor,...
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
end

