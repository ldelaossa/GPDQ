function results = exploreNNDs(data, directory)
global config;

% Default parameters.
if nargin<1
    data = [];
end
if nargin<2
    directory=[];
end


% Data used to export and build the plot.
rawInfo = [];     % Raw data
sumInfo =[];      % Summary by experimental serie

% Selected radius
fromRadius = 5;
toRadius = 5;

% Creates the figure
HFig = createFig;
set(HFig.mainFigure, 'Visible','on');
% Set callback functions.
set(HFig.openButton, 'CallBack', @openData);
set(HFig.infoSeriesButton,'Callback',@showSeries);
set(HFig.table,'CellEditCallBack',@updatePlotEvent);
% Radii selection
set(HFig.fromp2_5RadioButton,'CallBack',@selFromRadius);
set(HFig.fromp5RadioButton,'CallBack',@selFromRadius);
set(HFig.frompAllRadioButton,'CallBack',@selFromRadius);
set(HFig.top2_5RadioButton,'CallBack',@selToRadius);
set(HFig.top5RadioButton,'CallBack',@selToRadius);
set(HFig.topAllRadioButton,'CallBack',@selToRadius);
% Export
set(HFig.buttonExportData,'CallBack', @exportData);
set(HFig.buttonExportTable,'CallBack', @exportSummary);
% Plot
set(HFig.plotSelPopUp,'CallBack',@updatePlotEvent);
set(HFig.exportFigure,'CallBack', @exportFigure);
% Close
set(HFig.closeButton,'CallBack', @close);

% Default file
if ~isempty(data)
    set(HFig.expSeriesTitleText,'String', [data.project ' (PROJECT)']);
end

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
        report = GPDQReport({'SERIE','SECTION','NND'},{'%s','%s','%.4f'},rawInfo);
        showReport(report,fullfile(directory,[data.project(1:end-4) ' NND ALL.csv']));
    end

%% Exports the current axes to a new figure.
    function exportFigure(~,~)
        updatePlot(true);
    end

%% Export summary
    function exportSummary(~,~)
        report = GPDQReport({'SERIE', 'SECTIONS', 'MEAN NND' ,'STD NND'},{'%s','%d','%.4f','%.4f'}, sumInfo);
        showReport(report,fullfile(directory,[data.project(1:end-4) ' NND GROUP.csv']));
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
    function selFromRadius(object, ~)
        if strcmp(object.String,'Radius 2.5Nm')
            fromRadius=2.5;
            set(HFig.fromradioButtons(2),'Value',0);
            set(HFig.fromradioButtons(3),'Value',0);
        elseif strcmp(object.String,'Radius 5Nm')
            fromRadius=5;
            set(HFig.fromradioButtons(1),'Value',0);
            set(HFig.fromradioButtons(3),'Value',0);
        else
            fromRadius=[2.5 5];
            set(HFig.fromradioButtons(1),'Value',0);
            set(HFig.fromradioButtons(2),'Value',0);
        end
        updateInfo(false);
    end

%% Selects the current radius
    function selToRadius(object, ~)
        if strcmp(object.String,'Radius 2.5Nm')
            toRadius=2.5;
            set(HFig.toradioButtons(2),'Value',0);
            set(HFig.toradioButtons(3),'Value',0);
        elseif strcmp(object.String,'Radius 5Nm')
            toRadius=5;
            set(HFig.toradioButtons(1),'Value',0);
            set(HFig.toradioButtons(3),'Value',0);
        else
            toRadius=[2.5 5];
            set(HFig.toradioButtons(1),'Value',0);
            set(HFig.toradioButtons(2),'Value',0);
        end
        updateInfo(false);
    end


%% Selects the current categorie
    function updatePlotEvent(~, ~)
        updatePlot();
    end

%% Updates the current data.
    function updateInfo(isNewData)
        % newData true if data (and therefore series) has changed. 
        % Returns if data is empty
        if isempty(data)
            return
        end
        % Extracts the data
        [rawInfo, sumInfo] = nndSummary(data, fromRadius, toRadius, true);
        % Updates the table
        updateTable(isNewData);
        % Updates the plot
        updatePlot();
    end

%% Updates the plots
    function updatePlot(newFigure)
         % Selected series ids. 
        selectedSerieIds = find([HFig.table.Data{1:end,1}]);
        selectedAll = HFig.table.Data{end,1};
        
        % Returns if raw info es empty or no serie is selected
        if isempty(rawInfo) || isempty(selectedSerieIds) 
            delete(HFig.axesPlot.Children)
            return
        end
        
        % Selects axes in the window or a new figure
        if nargin<1 || ~newFigure
            axes(HFig.axesPlot);
        else
            figure;
        end

        % Names of the selected series
        selectedSerieNames = HFig.table.Data(selectedSerieIds, 2);
        
        % Extracts the data as a matrix
        [rawInfoMat, ~] = nndSummary(data, fromRadius, toRadius, false); % Extracts current data as numerical matrix
        rawInfoMat = rawInfoMat(:,[1,3]);
        % Data of the selected series
        rawInfoPlot = rawInfoMat(ismember(rawInfoMat(:,1),selectedSerieIds),:);
        % Adds all data as one serie if necessary
        if selectedAll
            rawInfoMat(:,1) = data.numSeries+1;
            rawInfoPlot = [rawInfoPlot; rawInfoMat];
        end
  
        % Draws the boxplot if selected
        if strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot')
            try
                boxplot(rawInfoPlot(:,2), rawInfoPlot(:,1), 'Labels', selectedSerieNames);
                ylabel('Nanometers' , 'FontSize',config.fontSize+2);
                xlabel('Group', 'FontSize',config.fontSize+2);
            catch
                delete(HFig.axesPlot.Children)
                GPDQStatus.repError('There is no data corresponding to this category', true, dbstack());
                return
            end
        % Draws histogram if selected
        elseif strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value}(1:9),'Histogram')
            % Kind of histogram
            if strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Histogram (counts)')
                norm = 'count';
            else
                norm = 'probability';
            end
            try
                for selSerieId=1:numel(selectedSerieIds)
                    serieId = selectedSerieIds(selSerieId);
                    histogram(rawInfoPlot(rawInfoPlot(:,1)==serieId,2), 100, 'edgealpha',0.5, 'normalization', norm, 'BinLimits',[0,500]);
                    hold on;
                end           
                xlabel('Nanometer', 'FontSize',config.fontSize+2);
                ylabel('Probability', 'FontSize',config.fontSize+2);
                legend(selectedSerieNames);
                hold off;
            catch
                delete(HFig.axesPlot.Children)
                GPDQStatus.repError('There is no data corresponding to this category', true, dbstack());
                return
            end
        else % Cumulative distribution function.
            try
                colors = colormap('lines');
                for selSerieId=1:numel(selectedSerieIds)
                    serieId = selectedSerieIds(selSerieId);
                    [f,x] = ecdf(rawInfoPlot(rawInfoPlot(:,1)==serieId,2));
                    plot(x,f, '-','LineWidth',1, 'Color', colors(serieId,:));
                    hold on;
                end           
                xlabel('Nm','FontSize',config.fontSize+2);
                ylabel('Cumulative density', 'FontSize',config.fontSize+2);
                legend(selectedSerieNames);
                hold off;
            catch
                delete(HFig.axesPlot.Children)
                GPDQStatus.repError('There is no data corresponding to this category', true, dbstack());
                return
            end            
        end
        % Title
        if isscalar(fromRadius)
            fromRadiusString = num2str(fromRadius)
        else
            fromRadiusString = sprintf('%.1f - ' , fromRadius)
            fromRadiusString = fromRadiusString(1:end-2)
        end
        if isscalar(toRadius)
            toRadiusString = num2str(toRadius)
        else
            toRadiusString = sprintf('%.1f - ' , toRadius)
            toRadiusString = toRadiusString(1:end-2)
        end        
        titleText = ['NND: from ' fromRadiusString 'Nm  to  ' toRadiusString 'Nm.'];
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
        set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version '. NNDs']);
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
        columnformat = {'logical', 'char', 'numeric', 'numeric', 'numeric'};
        columneditable =  [true false false false false];
        columnname =   {'Select', 'Series', 'Num Sections', 'Avg. NND', 'Std. NND'};
        HFig.table = uitable('Parent', HFig.panelExpSeries,'Units','Pixels', 'ColumnName', columnname, 'ColumnFormat', columnformat, 'ColumnEditable', columneditable,...
            'Position', [borderPx 2*buttonHeightPx+3*borderPx axesPlotWidthPx-2*borderPx 10*buttonHeightPx]);
        set (HFig.table,'ColumnWidth', {buttonWidthPx/2,4.5*buttonWidthPx});% , 'RowName',[] ,'BackgroundColor',[.7 .9 .8],'ForegroundColor',[0 0 0]);
        
        %Radius selection
        HFig.fromp2_5RadioButton = uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'Radius 2.5Nm','Value',0,...
            'Position', [borderPx, 2*borderPx+buttonHeightPx, 1.25*buttonWidthPx buttonHeightPx]);
        HFig.fromp5RadioButton = uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'Radius 5Nm', 'Value',1,...
            'Position', [2*borderPx+1.25*buttonWidthPx,2*borderPx+buttonHeightPx, 1.25*buttonWidthPx buttonHeightPx]);
        HFig.frompAllRadioButton= uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'All particles','HorizontalAlignment','Right', 'Value',0,...
            'Position', [3*borderPx+2.5*buttonWidthPx,2*borderPx+buttonHeightPx, 1*buttonWidthPx buttonHeightPx]);
        HFig.fromradioButtons = [HFig.fromp2_5RadioButton, HFig.fromp5RadioButton, HFig.frompAllRadioButton]; % Ugly radio button grouup. Not available
        
        HFig.top2_5RadioButton = uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'Radius 2.5Nm','Value',0,...
            'Position', [panelWidthPx-3.5*borderPx-3.5*buttonWidthPx,2*borderPx+buttonHeightPx, 1.25*buttonWidthPx buttonHeightPx]);
        HFig.top5RadioButton = uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'Radius 5Nm', 'Value',1,...
            'Position', [panelWidthPx-2*borderPx-2.25*buttonWidthPx,2*borderPx+buttonHeightPx, 1.25*buttonWidthPx buttonHeightPx]);
        HFig.topAllRadioButton= uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'All particles','HorizontalAlignment','Right', 'Value',0,...
            'Position', [panelWidthPx-borderPx-1*buttonWidthPx,2*borderPx+buttonHeightPx, 1*buttonWidthPx buttonHeightPx]);
        HFig.toradioButtons = [HFig.top2_5RadioButton, HFig.top5RadioButton, HFig.topAllRadioButton]; % Ugly radio button grouup. Not available with guide (I think)
        
        
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
        set(HFig.plotSelPopUp,'String',{'Cumulative distribution function','Box plot', 'Histogram (counts)', 'Histogram (densities)'});
        
        HFig.exportFigure = uicontrol('Parent', HFig.panelPlot, 'Style', 'pushbutton', 'String', 'Figure', 'Position', [panelWidthPx-borderPx-buttonWidthPx, borderPx buttonWidthPx buttonHeightPx]);
        
        % Close button.
        HFig.closeButton = uicontrol('Parent', HFig.mainFigure, 'Style', 'pushbutton', 'String', 'Close');
        set(HFig.closeButton, 'Position', [figureWidthPx-borderPx-buttonWidthPx, borderPx, buttonWidthPx buttonHeightPx]);
    end % createFig

end

