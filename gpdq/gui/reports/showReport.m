%% showReport Displays a report as a spreadsheet. 
%
% Example
% -------
%
%   showReport(particleReport, 'gabab1.csv')
%
% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function showReport(report, file)
    
    if nargin<2
        file = '';
    end
    
    relativeSize = 0.65;
    
    % Gets the screen size.
    screenSize = get(0,'Screensize');

    % Initial size and position
    figureHeightPx = screenSize(4)*relativeSize;
    figurePosYPx = (screenSize(4)-figureHeightPx)/2;
    figureWidthPx = screenSize(3)*relativeSize;
    figurePosXPx = (screenSize(3)-figureWidthPx)/2;
    
    
    % Size of some components
    marginPx = 10;                                                                                 
    buttonWidthPx = 80;                                                                             
    buttonHeightPx = 25;   
    panelWidthPx = figureWidthPx-2*marginPx;
    panelHeightPx = figureHeightPx-2*marginPx;
   
    % Main figure
    HFig.mainFigure = figure('NumberTitle','off','Units', 'pixels', 'resize','off','menubar', 'none', 'DockControls','off','Visible','off');
    figureColor = get(HFig.mainFigure, 'color'); 
    set(HFig.mainFigure, 'Name', 'GPDQ v1.0: Report viewer (non editable)');
    set(HFig.mainFigure, 'Position', [figurePosXPx figurePosYPx figureWidthPx figureHeightPx]);
    
    HFig.panel = uipanel('Parent',HFig.mainFigure,'Units','pixels','Position',[marginPx, marginPx, figureWidthPx-2*marginPx, figureHeightPx-2*marginPx]); 
	HFig.reportLabel = uicontrol('Parent',HFig.panel, 'Style', 'Text', 'String', 'Report file','HorizontalAlignment','left', 'backgroundcolor',figureColor,'Position', [marginPx, marginPx, buttonWidthPx, buttonHeightPx]);
    HFig.reportButton = uicontrol('Parent',HFig.panel, 'Style', 'pushbutton', 'String', 'Save','Position',[panelWidthPx-marginPx-buttonWidthPx marginPx+5 buttonWidthPx, buttonHeightPx], 'Callback',@save);   
    HFig.reportText =  uicontrol('Parent',HFig.panel,'Style', 'Edit', 'Enable', 'on', 'String', file ,'HorizontalAlignment','left','backgroundcolor','white','Position', [2*marginPx+buttonWidthPx marginPx+5 panelWidthPx-4*marginPx-2*buttonWidthPx buttonHeightPx]); 

    
    % Table  
    % Adds a column for flag
    tableColumns = [cell(1,1) report.columns];
    numColumns = length(tableColumns);
    numRows = length(report.data);
    
    % Size
    tableWidthPx = figureWidthPx-4*marginPx;
    tableColumnWidthPx = cell(1,numColumns);
    tableColumnWidthPx{1} = 25;
    tableColumnWidthPx{2} = 50;
    columnWidthPx = (tableWidthPx-120) / (numColumns-2);
    for idColumn = 3:numColumns,
        tableColumnWidthPx{idColumn} = columnWidthPx;
    end
    
    % Generates the table.
    HFig.table = uitable('parent',HFig.panel, 'FontSize',10,'ColumnName',tableColumns, 'ColumnWidth', tableColumnWidthPx, 'RowName',[], ...
                    'Position', [marginPx, 3*marginPx+buttonHeightPx, panelWidthPx-2*marginPx, panelHeightPx-4*marginPx-buttonHeightPx]);                            
    tableData = cell(numRows,1);
    tableData = [tableData report.data];
        
    % Sets the colored flags.
    for idRow=1:numRows
        if report.data{idRow,1}<0
            tableData{idRow,1} = colorString('#FFBBBB', '&nbsp;');
            tableData{idRow,2} = -1*tableData{idRow,2};
        else
            tableData{idRow,1} = colorString('#BBFFFF', '&nbsp;');
        end
    end
    
    % Sets the data.
    set(HFig.table,'Data',tableData);
    
    % Sets the fonts
    setFonts(HFig);
    
    % Shows the figure.                                                
    set(HFig.mainFigure,'Visible','on');
    
   
    waitfor(HFig.mainFigure);
    
    %% Function save
    % Saves the record in the file.
    function save(~,~)
        fileName = get(HFig.reportText,'String');
        result = report.save(fileName);
        if GPDQStatus.isSuccess(result)
            GPDQStatus.repSuccess('Report sucessfully saved');
        else
            GPDQStatus.repError(['Error when saving the report in the file:' fileName], true, dbstack());                   
        end
    end

end

