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
    set(HFig.mainFigure, 'Name', ['GPDQ v1.0. ', report.title]);
    set(HFig.mainFigure, 'Position', [figurePosXPx figurePosYPx figureWidthPx figureHeightPx]);
    
    HFig.panel = uipanel('Parent',HFig.mainFigure,'Units','pixels','Position',[marginPx, marginPx, figureWidthPx-2*marginPx, figureHeightPx-2*marginPx]); 
	HFig.reportLabel = uicontrol('Parent',HFig.panel, 'Style', 'Text', 'String', 'Report file','HorizontalAlignment','left', 'backgroundcolor',figureColor,'Position', [marginPx, marginPx, buttonWidthPx, buttonHeightPx]);
    HFig.reportButton = uicontrol('Parent',HFig.panel, 'Style', 'pushbutton', 'String', 'Save','Position',[panelWidthPx-marginPx-buttonWidthPx marginPx+5 buttonWidthPx, buttonHeightPx], 'Callback',@save);   
    HFig.reportText =  uicontrol('Parent',HFig.panel,'Style', 'Edit', 'Enable', 'on', 'String', file ,'HorizontalAlignment','left','backgroundcolor','white','Position', [2*marginPx+buttonWidthPx marginPx+5 panelWidthPx-4*marginPx-2*buttonWidthPx buttonHeightPx]); 

    
    % Table  
    % Adds a column for flag
    tableColumns = [cell(1,1) report.columns];
    numColumns = length(tableColumns);
    numRows = size(report.data,1);
    
    % Size
    
    % Number of strings and numbers
    numStrings = sum(not(cellfun('isempty',strfind(report.format,'%s'))));
    numNumbers = numColumns-numStrings-1;
    stringWidthPx = 150;
    numberWidthPx = 80;
    % This is the lenth required
    requiredWidthPx = 30 + 25 + numStrings*stringWidthPx+numNumbers*numberWidthPx;
    % The available space
    idealWidthPx = figureWidthPx-4*marginPx;
    
    %The table grows if possible.
    if requiredWidthPx<idealWidthPx
        stringWidthPx = stringWidthPx+(idealWidthPx-requiredWidthPx)/numStrings;
        tableWidthPx = idealWidthPx;
    else
        tableWidthPx = requiredWidthPx;
    end

    % Creates the table 
    tableColumnWidthPx = cell(1,numColumns);
    tableColumnWidthPx{1} = 25;
    for idColumn = 2:numColumns
        if strcmp(report.format{idColumn-1},'%s')
            tableColumnWidthPx{idColumn} = stringWidthPx;
        else
            tableColumnWidthPx{idColumn} = numberWidthPx;
        end
    end
    
    HFig.table = uitable('parent',HFig.panel, 'FontSize',10,'ColumnName',tableColumns, 'ColumnWidth', tableColumnWidthPx, 'RowName',[], ...
                    'Position', [marginPx, 3*marginPx+buttonHeightPx, tableWidthPx, panelHeightPx-4*marginPx-buttonHeightPx]);                            
    tableData = cell(numRows,1);
    tableData = [tableData report.data];
    if isempty(report.flags)
        tableFlags = ones(numRows,1);
    else
        tableFlags = report.flags;
    end
        
    % Sets the colored flags.
    for idRow=1:numRows
        if tableFlags(idRow)
            tableData{idRow,1} = colorString('#BBFFFF', '&nbsp;');
        else
            tableData{idRow,1} = colorString('#FFBBBB', '&nbsp;');
        end
    end
    
    % Sets the data.
    set(HFig.table,'Data',tableData);
    
    % Sets the fonts
    setFonts(HFig);
    
    % Shows the figure.                                                
    set(HFig.mainFigure,'Visible','on');
    
    % Waits for the figure to close
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

