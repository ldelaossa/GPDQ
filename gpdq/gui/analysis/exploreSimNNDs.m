function results = exploreSimNNDs(simData)
global config;

% Default parameters.
if nargin<1
    simData = [];
end
if nargin<2
    directory=[];
end


%% Current simulation. Used to build the plot.


% Data for reports
sectionsData = [];      % Data per section

seriesData = [];        % Summary by experimental serie
serieNames = [];        % Names of the series
numSeries = 0;

% Data for plotting
realNDDs = [];
simNNDs = [];

%% Selected radius
fromRadius = 5;
toRadius = 5;
simRadius = 5;

% Creates the figure
HFig = createFig;
set(HFig.mainFigure, 'Visible','on');
% % Set callback functions.
set(HFig.openButton, 'CallBack', @openData);
set(HFig.infoSeriesButton,'Callback',@showSimulation);
set(HFig.table,'CellEditCallBack',@updatePlotEvent);

% % Radii selection
set(HFig.top2_5RadioButton,'CallBack',@selToRadius);
set(HFig.top5RadioButton,'CallBack',@selToRadius);

% % Export
set(HFig.buttonExportData,'CallBack', @exportData);
set(HFig.buttonExportTable,'CallBack', @exportSummary);

% % Plot
set(HFig.plotSelPopUp,'CallBack',@updatePlotEvent);
set(HFig.buttonExportFigure,'CallBack', @exportFigure);

% % Close
set(HFig.closeButton,'CallBack', @close);

% Default file
if ~isempty(simData)
    set(HFig.expSeriesTitleText,'String', [simData.data.workingDirectory simData.data.project]);
end

% % Updates the info 
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
        report = GPDQReport( ...
            {'SERIE','SECTION','NUM PART FROM', 'NUM PART TO','AVG NND (REAL)','STD NND (REAL)','AVG NND (SIM)', 'LOW CI NND (SIM)', 'UPPER CI NND (SIM)','ASOC','DISOC'},...
            {'%s','%s','%d','%d','%.3f','%.3f','%.3f','%.3f','%.3f','%d','%d'},...
            sectionsData);
        showReport(report,fullfile(directory,[simData.data.project(1:end-4) ' SIM NND SECTION.csv']));
    end

%% Exports the current axes to a new figure.
    function exportFigure(~,~)
        updatePlot(true);

    end

%% Export summary
    function exportSummary(~,~)
        report = GPDQReport({'SERIE', 'NUM SECTIONS', 'AVG NND (REAL)' ,'AVG NND (SIM)', 'P-VALUE', 'NUM ASOC', 'NUM DISOC'}, ...
                            {'%s','%d','%.4f','%.4f','%e','%d','%d'}, seriesData);
        showReport(report,fullfile(directory,[simData.data.project(1:end-4) ' SIM NND GROUP.csv']));
    end

%% Opens an object Containing the simulation
    function openData(~,~)
        % Opens the file
        if isempty(directory)
            [simDataFile, directory] = uigetfile('*.mat');
        else
            [simDataFile, directory] = uigetfile(fullfile(directory,'*.mat'));
        end
        % If no file has been selected, returns.
        if simDataFile==0
            return;
        end
        % Otherwise loads the file.
        tmpSimData = GPDQSimulation.load(fullfile(directory,simDataFile));
        if GPDQStatus.isError(tmpSimData)
            GPDQStatus.repError(['Unable to load ' fullfile(directory,simDataFile) 'as experimental series'], true, dbstack());
        else
            simData = tmpSimData;
        end
        set(HFig.expSeriesTitleText,'String', fullfile(directory,simDataFile));
        % Update the data and the table
        updateInfo(true);
    end


%% Selects the current radius
    function selToRadius(object, ~)
        if object==HFig.top2_5RadioButton
           set(HFig.top5RadioButton,'Value',0)
           set(HFig.top2_5RadioButton,'Enable','inactive')
           set(HFig.top5RadioButton,'Enable','on')
           toRadius = 2.5;
        else
           set(HFig.top2_5RadioButton,'Value',0)
           set(HFig.top5RadioButton,'Enable','inactive')
           set(HFig.top2_5RadioButton,'Enable','on')
           toRadius = 5;        
        end
        % Updates the label
        set(HFig.frompLabel, 'String',['From ', num2str(toRadius) 'Nm (Real / Simulated)'])
        % Shows message while updating
        msgBox = GPDQStatus.repInfo('Recalculating ... wait some seconds');
        updateInfo(false);
        delete(msgBox);
    end


%% Selects the current categorie
    function updatePlotEvent(~, ~)
        updatePlot();
    end


%% Updates the current data.
    function updateInfo(isNewSimulation)
        % newData true if data (and therefore series) has changed. 
        % Returns if the simulation is empty
        if isempty(simData)
            return
        end

        if isNewSimulation
            simRadius = simData.simradius;
            fromRadius = simRadius;
            set(HFig.frompLabel, 'String', ['From  ' num2str(simRadius) 'Nm (Real / Simulated)']);
        end
        
        % Extracts the data
        [rawNNDs, sumSection, sumSeries, rawSimNNDs, sumSimSection, sumSimSeries, serieNames, sectionNames] = nndSummarySim(simData, fromRadius, toRadius, false);

        % Updates the table data
        seriesData = num2cell(sumSimSeries(:,[1,2,3,5,6,7,8]));
        seriesData(:,1) = serieNames;
        numSeries = size(serieNames, 1);
        % Updates the data
        sectionsData = num2cell(sumSimSection);
        sectionsData(:,1:2) = sectionNames;

        % Updates data for plotting
        realNDDs = rawNNDs;
        simNNDs = rawSimNNDs;

        % Updates the table
        updateTable(isNewSimulation);
        % Updates the plot
        updatePlot();
    end

%% Updates the plots
    function updatePlot(newFigure)
        % Selected series ids. 
        selectedSerieIds = find([HFig.table.Data{1:end,1}]);
        
        % Returns if raw info es empty or no serie is selected
        if isempty(seriesData) || isempty(selectedSerieIds) 
            %delete(HFig.axesPlot.Children);
            delete(HFig.axesPlot);
            HFig.axesPlot = axes('Parent',HFig.panelPlot,'units','pixels','visible','off','Position', HFig.axesDims);
            return
        end

        if nargin==1 && newFigure
            figure
        else
            %delete(HFig.axesPlot.Children);
            delete(HFig.axesPlot);
            HFig.axesPlot = axes('Parent',HFig.panelPlot,'units','pixels','visible','off','Position', HFig.axesDims);
            axes(HFig.axesPlot);
        end

        % Names of the selected series
        selectedSerieNames = serieNames(selectedSerieIds);

        % Draws the Cumulative distribution function if selected
        if strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Cumulative distribution function')
            try
                lines_r = zeros(numel(selectedSerieIds),1);
                lines_s = zeros(numel(selectedSerieIds),1); 
                colors = colormap('lines');
                for selSerieId=1:numel(selectedSerieIds)
                    serieId = selectedSerieIds(selSerieId);
                    if serieId~=numSeries
                        [f,x] = ecdf(realNDDs(realNDDs(:,1)==serieId,3));
                        lines_r(selSerieId) = plot(x,f, '-','LineWidth',1, 'Color', colors(serieId,:));
                        hold on;
    
                        [f,x] = ecdf(simNNDs(simNNDs(:,1)==serieId,3));
                        lines_s(selSerieId) = plot(x,f, '--','LineWidth',1, 'Color', colors(serieId,:));
                        hold on;
                    else % ALL
                        [f,x] = ecdf(realNDDs(:,3));
                        lines_r(selSerieId) = plot(x,f, '-','LineWidth',1, 'Color', colors(serieId,:));
                        hold on; 

                        [f,x] = ecdf(simNNDs(:,3));
                        lines_s(selSerieId) = plot(x,f, '--','LineWidth',1, 'Color', colors(serieId,:));
                        hold on;                        
                    end
                end  

                % Fake lines used to customize the legend.
                leg_line_w = plot([0 100],[0 1],'LineStyle','none','Marker','none');
                leg_line_r = plot(0,1,'-','LineWidth',1, 'Color','black');
                leg_line_s = plot(0,1,'--','LineWidth',1, 'Color','black');
                % Legend.
                legendText = horzcat(selectedSerieNames',{'', 'real','simulated'});
                legendLines = [lines_r; leg_line_w; leg_line_r; leg_line_s];
                legend(legendLines, legendText, 'location', 'southeast');
                hold on;
                xlabel('Nearest Neighbour Distance (Nm)','FontSize',config.fontSize+2);
                ylabel('Cumulative density', 'FontSize',config.fontSize+2);
            catch
                delete(HFig.axesPlot.Children)
                GPDQStatus.repError('Something went wrong while making the plot', true, dbstack());
                return
            end  
        % Draws the boxplot if selected
        elseif strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value},'Box plot')
            % This is unefficient and a bit tricky, but it is clearer

            % Extracts raw real NNDs and adds a 0 column (to flag real)
            realNNDsPlot = [realNDDs, zeros(size(realNDDs,1),1)];
            realNNDsPlot = realNNDsPlot(ismember(realNNDsPlot(:,1),selectedSerieIds),:); 
            % Extracts simulated NNDs and adds a 1 column (to flag simulation)
            simNNDsPlot = [simNNDs, ones(size(simNNDs,1),1)];
            simNNDsPlot = simNNDsPlot(ismember(simNNDsPlot(:,1),selectedSerieIds),:); 
            % Appends both datasets
            auxDataBoxPlot = [realNNDsPlot;simNNDsPlot];

            if ismember(numSeries, selectedSerieIds)
               allAuxDataBoxPlot = auxDataBoxPlot;
               allAuxDataBoxPlot(:,1)=numSeries;
               auxDataBoxPlot = [auxDataBoxPlot; allAuxDataBoxPlot];
            end
              

            groups = categorical(auxDataBoxPlot(:,1), selectedSerieIds, serieNames(selectedSerieIds));
            factor = categorical(auxDataBoxPlot(:,4), [0,1], {'Real', 'Simulated'});
            try
                boxchart(groups, auxDataBoxPlot(:,3), 'GroupByColor',factor, 'MarkerStyle','none');
                legend()
                hold on;
                ylabel('Nearest Neighbour Distance (Nm)','FontSize',config.fontSize+2);
                xlabel('Group', 'FontSize',config.fontSize+2); 
            catch
                delete(HFig.axesPlot.Children)
                GPDQStatus.repError('Something went wrong while making the plot', true, dbstack());
                return
            end

         % Draws histogram if selected
         elseif strcmp(HFig.plotSelPopUp.String{HFig.plotSelPopUp.Value}(1:9),'Histogram')
            % Kind of histogram
            norm = 'probability';
            try
                colors = colormap('lines');
                for selSerieId=1:numel(selectedSerieIds)
                    serieId = selectedSerieIds(selSerieId);
                    if serieId~=numSeries
                        histogram(realNDDs(realNDDs(:,1)==serieId,3), 100, 'facealpha',0.75, 'normalization', norm, 'BinLimits',[0,500], 'FaceColor', colors(serieId,:));
                        hold on;
                    else
                        histogram(realNDDs(:,3), 100, 'facealpha',0.75, 'normalization', norm, 'BinLimits',[0,500], 'FaceColor', colors(serieId,:));
                        hold on;                   
                    end
                end   
                histogram([], 100, 'normalization', norm, 'lineStyle','none','FaceColor','#FFFFFF');
                hold on;                     
                for selSerieId=1:numel(selectedSerieIds)
                    serieId = selectedSerieIds(selSerieId);
                    if serieId~=numSeries
                        histogram(simNNDs(simNNDs(:,1)==serieId,3), 100, 'facealpha',0.25, 'normalization', norm, 'BinLimits',[0,500], 'FaceColor', colors(serieId,:));
                        hold on;
                    else
                        histogram(simNNDs(:,3), 100, 'facealpha',0.25, 'normalization', norm, 'BinLimits',[0,500], 'FaceColor', colors(serieId,:));
                        hold on;                        
                    end
                end                  
                xlabel('Nearest Neighbour Distance (Nm)','FontSize',config.fontSize+2);
                ylabel('Probability', 'FontSize',config.fontSize+2);
                legend(vertcat(selectedSerieNames, 'Simulated',selectedSerieNames));
                hold off;
            catch
                delete(HFig.axesPlot.Children)
                GPDQStatus.repError('Something went wrong while making the plot', true, dbstack());
                return
            end
        end

        % Title
        titleText = ['NND from ' num2str(fromRadius) ' Nm  to  ' num2str(toRadius) ' Nm'];
        title(titleText, 'FontSize',config.fontSize+3);        

    end 

%% Updates the table
    function updateTable(newTable)
        if newTable
            checkBoxes=num2cell(false(size(seriesData,1),1));
            tableData = [checkBoxes seriesData];
            set(HFig.table,'Data',tableData);
        else
            HFig.table.Data(:,2:end) =  seriesData;
        end
    end

%% Shows the series definition.
    function showSimulation(~, ~)
        infoText(simData.tag, 'Data description')
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
        axesPlotWidthPx = 940;
        panelWidthPx = axesPlotWidthPx;
        panelPlotHeightPx = axesPlotHeightPx+3*borderPx+buttonHeightPx;
        panelSeriesHeightPx = 12*buttonHeightPx+5*borderPx;
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
        HFig.panelExpSeries = uipanel(HFig.mainFigure,'Units','pixels','Title','Simulation');
        set(HFig.panelExpSeries,'Position',[borderPx,panelPlotHeightPx+2*borderPx+buttonHeightPx, panelWidthPx, panelSeriesHeightPx])
        
        % Open experimental series
        HFig.openButton = uicontrol('Parent', HFig.panelExpSeries, 'Style', 'pushbutton', 'String', 'Open');
        set(HFig.openButton, 'Position', [borderPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx, buttonWidthPx buttonHeightPx]);
        HFig.expSeriesTitleText = uicontrol('Parent', HFig.panelExpSeries,'Style', 'Edit', 'Enable', 'inactive', 'String', '','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [2*borderPx+buttonWidthPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx, panelWidthPx-4*borderPx-2*buttonWidthPx buttonHeightPx]);
        HFig.infoSeriesButton = uicontrol('Parent', HFig.panelExpSeries,'Style', 'pushbutton', 'String', 'Info',...
            'Position', [panelWidthPx-1*borderPx-buttonWidthPx, panelSeriesHeightPx-buttonHeightPx-2*borderPx,buttonWidthPx buttonHeightPx]);
        
        % Table
        columnformat = {'logical', 'char', 'numeric', 'numeric', 'numeric', 'numeric','numeric', 'numeric'};
        columneditable =  [true false false false false false false false];
        columnname =   {'Select', 'Series', 'Num Sections', 'Avg. NND (Real)', 'Avg. NND (Sim)', 'p-value', 'Num ASOC', 'Num DISOC'};
        HFig.table = uitable('Parent', HFig.panelExpSeries,'Units','Pixels', 'ColumnName', columnname, 'ColumnFormat', columnformat, 'ColumnEditable', columneditable,...
            'Position', [borderPx 1*buttonHeightPx+2*borderPx axesPlotWidthPx-2*borderPx 10*buttonHeightPx]);
        set (HFig.table,'ColumnWidth', {buttonWidthPx/2,4*buttonWidthPx,buttonWidthPx, 1.25*buttonWidthPx,1.25*buttonWidthPx,buttonWidthPx});% , 'RowName',[] ,'BackgroundColor',[.7 .9 .8],'ForegroundColor',[0 0 0]);
        
        %Radius selection
        HFig.frompLabel= uicontrol('Parent',HFig.panelExpSeries,'Style', 'text','FontWeight','bold','horizontalalignment','left',...
            'Position', [borderPx, 1*borderPx-5, 2.5*buttonWidthPx buttonHeightPx]);
        if ~isempty(simData)
            set(HFig.frompLabel,'String', ['From ' num2str(simData.simradius) 'Nm (Real / Simulated)']);
        end
      
        HFig.top2_5RadioButton = uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'To 2.5 Nm','Value',0,'horizontalalignment','right','FontWeight','bold',...
            'Position', [2*borderPx+2.5*buttonWidthPx,1*borderPx, 1.25*buttonWidthPx buttonHeightPx]);
        HFig.top5RadioButton = uicontrol('Parent',HFig.panelExpSeries,'Style', 'radiobutton', 'String', 'To 5 Nm', 'Value',1,'Enable','inactive','FontWeight','bold',...
            'Position', [3*borderPx+3.75*buttonWidthPx,1*borderPx, 1.25*buttonWidthPx buttonHeightPx]);
        %HFig.toradioButtons = [HFig.top2_5RadioButton, HFig.top5RadioButton]; % Ugly radio button grouup. Not available with guide (I think)
        
        
        % Export button
        HFig.buttonExportData = uicontrol('Parent',HFig.panelExpSeries,'Style', 'pushbutton', 'String', 'Export data');
        set(HFig.buttonExportData, 'Position', [panelWidthPx-1*borderPx-1.25*buttonWidthPx, 1*borderPx, 1.25*buttonWidthPx buttonHeightPx]);
        HFig.buttonExportTable = uicontrol('Parent',HFig.panelExpSeries,'Style', 'pushbutton', 'String', 'Export table');
        set(HFig.buttonExportTable, 'Position', [panelWidthPx-2*borderPx-2.5*buttonWidthPx, 1*borderPx, 1.25*buttonWidthPx buttonHeightPx]);
        
        % Panel Plot
        HFig.panelPlot = uipanel(HFig.mainFigure,'Units','pixels');
        set(HFig.panelPlot,'Position',[borderPx,2*borderPx+buttonHeightPx, panelWidthPx, panelPlotHeightPx])
        
        % Axes
        HFig.axesDims = [buttonWidthPx +3*buttonHeightPx+borderPx, axesPlotWidthPx-2*buttonWidthPx, axesPlotHeightPx-3*buttonHeightPx];
        HFig.axesPlot = axes('Parent',HFig.panelPlot,'units','pixels','visible','off','Position', HFig.axesDims);
        
        % Plot selection
        HFig.plotSelText = uicontrol('Parent', HFig.panelPlot,'Style', 'Text', 'String', 'Plot type ','HorizontalAlignment','left','backgroundcolor',figureColor,'Position', [borderPx borderPx buttonWidthPx buttonHeightPx]);
        HFig.plotSelPopUp = uicontrol('Parent', HFig.panelPlot,'Style', 'popup', 'Position', [2*borderPx+buttonWidthPx borderPx (axesPlotWidthPx/2)-buttonWidthPx buttonHeightPx]);
        set(HFig.plotSelPopUp,'String',{'Cumulative distribution function','Box plot', 'Histogram (densities)'});
        
        HFig.buttonExportFigure = uicontrol('Parent', HFig.panelPlot, 'Style', 'pushbutton', 'String', 'Figure', 'Position', [panelWidthPx-borderPx-buttonWidthPx, borderPx buttonWidthPx buttonHeightPx]);

        % Close button.
        HFig.closeButton = uicontrol('Parent', HFig.mainFigure, 'Style', 'pushbutton', 'String', 'Close');
        set(HFig.closeButton, 'Position', [figureWidthPx-borderPx-buttonWidthPx, borderPx, buttonWidthPx buttonHeightPx]);
    end % createFig

end

