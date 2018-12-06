%% measureScale Allows measuring the scale of an image. Returns it in Nm/pixel.
%
% Requires that user enters the expected size of the bar (in nanometers).
%
% Usage
% -----
%
%      currentScale = measureScale(fileName)
%
% Example
% -------
%
%      currentScale = measureScale(../AXON/1_sec_1.tif')
%
% Parameters
% ----------
%
%   fileName : Name of the file contanining the image. 
%
% Returns
% -------
%
%   currentScale: Scale of the image, or GPDQStatus.ERROR
%
% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function currentScale = measureScale(fileName)
    global config;

    % Initialized with the error. Only changes when a valid value
    % is calculated. 
    currentScale = GPDQStatus.ERROR;

    % Avoids multiple openings of the figure.
    windowMeasureScale = findobj('type', 'figure', 'tag', 'measureScale');
    if ~isempty(windowMeasureScale)
        GPDQStatus.repError('Another instance of measureScale is already open. It must be closed first', true, dbstack());
        figure(windowMeasureScale);
        return;
    end

    % If fileName does not exist, or is a directory, opens a dialog to pick
    if nargin<1 || exist(fileName,'dir')
        if nargin<1
            [tmpImageName, tmpImageDir] = uigetfile('*.*');
        else
            [tmpImageName, tmpImageDir] = uigetfile(fullfile(fileName,'*.*'));
        end
        % If no file has been selected, returns.
        if tmpImageName==0
            GPDQStatus.repError('Aborted scaling of image', false, dbstack());
            currentScale = GPDQStatus.CANCELED;
        else
            fileName = fullfile(tmpImageDir, tmpImageName);
        end
    end
    
    % Reads the image
    image = readImage(fileName);

    % Creates the figure.
    HFig = createFig();

    % Set callbacks
    set(HFig.mainFigure,'CloseRequestFcn',@close);
    set(HFig.expectedMeasText,'Callback', @editExpectedMeas);
    set(HFig.okButton, 'Callback', @closeOK);
    set(HFig.zoomButton, 'Callback', @zoom);
    set(HFig.autoButton, 'Callback', @auto_reset);

    % Scale and distances
    [imHeight, imWidth] = size(image);
    currentSizePx = 0;
    currentSizeNm = 0;

    % Zoom of the image.
    imageZoom = [];
    showingZoom = false; % Flag
    posZoomX=0;
    posZoomY=0;

    % Auto detection
    showingDetected = false; % Flag
    
    % Creates the containers for the scaling object.
    imDL = [];
    apiDL =[];
    
    % Draws the scaling object.
    drawScale();

    % Returns then the figure is closed.
    waitfor(HFig.mainFigure);

%% Callbacks and auxiliar functions

 %% Draws the scale line
    function drawScale()
        imDL = imdistline(HFig.axesImage);
        apiDL = iptgetapi(imDL);
        apiDL.setLabelVisible(true)
        apiDL.setColor('red');
        currentSizePx = apiDL.getDistance();
        apiDL.addNewPositionCallback(@getDistance);
        fcn = makeConstrainToRectFcn('imline',get(HFig.axesImage,'XLim'),get(HFig.axesImage,'YLim'));
        apiDL.setPositionConstraintFcn(fcn);
        update();
    end

%% Updates the data when editing the expected measure.
    function editExpectedMeas(~ , ~)
        strExpectedMeasure = get(HFig.expectedMeasText,'String');
        expectedMeasure = str2double(strExpectedMeasure);
        % If the scale is not valid, does not close (to prevent from losing information)
        if isempty(expectedMeasure) || numel(expectedMeasure)>1 || isnan(expectedMeasure)
            GPDQStatus.repError([strExpectedMeasure ' is not a valid number format. You must correct the value or leave it empty.'], true, dbstack());
        else
            currentSizeNm = expectedMeasure;
        end
        set(HFig.expectedMeasText,'String', num2str(currentSizeNm));
        % If the measure has not been introduced, uses color red for warning.
        if currentSizeNm==0
            set(HFig.expectedMeasText,'Foregroundcolor','red');
        else
            set(HFig.expectedMeasText,'Foregroundcolor','black');
        end
        update();
    end

%% Returns the distance measured by the component.
    function getDistance(~ , ~)
        currentSizePx = apiDL.getDistance();
        update();
    end

%% Updates the scale.
    function update()
        if currentSizeNm~=0
            currentScale = currentSizeNm/currentSizePx;
            set(HFig.scaleText, 'String', num2str(currentScale));
            set(HFig.scaleText,'Foregroundcolor','black');
        else
            currentScale = GPDQStatus.ERROR;
            set(HFig.scaleText, 'String', '--');
            set(HFig.scaleText,'Foregroundcolor','red');

        end
    end

%% Shows a zoom that includes the measurement line for adjusting.
    function zoom(~,~)
        posLine = apiDL.getPosition();
        if ~showingZoom
            showingZoom = true;
            % Calculates the position
            set(HFig.zoomButton,'String', 'Original');            
            posZoomX = max(min(posLine(1,1),posLine(2,1))-50,0);
            sizeZoomX = min(max(posLine(1,1),posLine(2,1))+50,imWidth);
            posZoomY = max(min(posLine(1,2),posLine(2,2))-50,0);
            sizeZoomY = min(max(posLine(1,2),posLine(2,2))+50, imHeight);      
            % Shows the part of interest of the image.
            imageZoom = imcrop(image, [posZoomX posZoomY abs(sizeZoomX-posZoomX) abs(sizeZoomY-posZoomY)]);
            HFig.imageHandle = imshow(imageZoom, 'Parent',HFig.axesImage);
            posLine = [posLine(1,1)-posZoomX, posLine(1,2)-posZoomY; posLine(2,1)-posZoomX, posLine(2,2)-posZoomY];
        else
            % Shows the image. 
            showingZoom = false;
            set(HFig.zoomButton,'String', 'Zoom');            
            HFig.imageHandle = imshow(image, 'Parent',HFig.axesImage);            
            posLine = [posLine(1,1)+posZoomX, posLine(1,2)+posZoomY; posLine(2,1)+posZoomX, posLine(2,2)+posZoomY];
        end
        drawScale();
        apiDL.setPosition(posLine);
        update();
    end

%% Calls auto detect.
    function auto_reset(~,~)
        if ~showingDetected
            if showingZoom
                zoom()
            end
            % If it has not been detected, returns the error.
            if GPDQStatus.isError(detect())
                GPDQStatus.repError('The scale bar has not been detected (only works with black bars). ', true, dbstack());
                return
            end
            showingDetected = true;
            set(HFig.autoButton,'String', 'Reset');  
        else
            showingDetected = false;
            set(HFig.autoButton,'String', 'Auto');           
            if showingZoom
                zoom();
            end
            delete(imDL);
            drawScale();
             
        end        
    end

%% Detects the scale.
    function detectedBarRect = detect()
        % Detects the scale bar. 
        [detectedSizePx, detectedBarLine, detectedBarRect, ~] = detectScaleBar(image);        
        % Returns if fail
        if detectedSizePx==GPDQStatus.ERROR || detectedBarRect(2,1)<10 || detectedBarRect(2,2)<10
            GPDQStatus.repError('Scale bar not detected.', true);
            set(HFig.autoButton,'String', 'Auto'); 
            return
        end
        %Otherwise, calculates the data.
        currentSizePx = detectedSizePx;       
        % Fixes the rectangle. 
        apiDL.setPosition(detectedBarLine);
        update();
    end

%% Closes the figure and returns the current scale
    function closeOK(~,~)
        delete(gcf);
    end

    %% Closes the figure with non valid scale
    function close(~,~)
        currentScale = GPDQStatus.ERROR;
        delete(gcf);
    end


    %% Creates the figure.
    % Figure, panel, axes and handle of the image
    % HFig.mainFigure, HFig.panelImage, HFig.axesImage, HFig.imageHandle

    % Labels and texts
    % HFig.expectedMeasLabel, HFig.expectedMeasText, HFig.scaleLabel, HFig.scaleText

    % Buttons
    % HFig.okButton, HFig.zoomButton, HFig.autoButton

    function HFig = createFig
        % Actual size of the image
        imageSizePx = size(image);
        screenSize = get(0,'Screensize');
        relativeSize = 0.85;
        axesHeightPx = screenSize(4)*relativeSize;
        axesWidthPx = (axesHeightPx/imageSizePx(1)) * imageSizePx(2);
        
        % Size and position of the figure.
        borderPx = 10;
        buttonHeightPx = 25;
        buttonWidthPx = 80;
        figureHeightPx = axesHeightPx+3*borderPx+buttonHeightPx;
        figureWidthPx = axesWidthPx+2*borderPx;
        figurePosYPx = (screenSize(4)-figureHeightPx)/2;
        figurePosXPx = (screenSize(3)-figureWidthPx)/2;
        
        % Figure
        HFig.mainFigure = figure('NumberTitle','off','Units', 'pixels', 'resize','off','menubar', 'none', 'DockControls','off','Visible','off');
        set(HFig.mainFigure,'Position', [figurePosXPx figurePosYPx figureWidthPx figureHeightPx]);
        set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version '. Measure scale: ' fileName]);
        
        % The tag is necessary to avoid opening more than one instance
        set(HFig.mainFigure,'tag','measureScale');
        
        figureColor = get(HFig.mainFigure, 'color');
        
        % Image
        HFig.panelImage= uipanel('Parent', HFig.mainFigure, 'Units','pixels', 'Position', [borderPx, 2*borderPx+buttonHeightPx, axesWidthPx, axesHeightPx]);
        HFig.axesImage = axes('Parent',HFig.panelImage,'Units','pixels','visible','off','Position',[0, 0, axesWidthPx, axesHeightPx]);
        
        set(HFig.mainFigure,'Visible','on');
        HFig.imageHandle = imshow(image, 'Parent',HFig.axesImage);
        
        % Info
        HFig.expectedMeasLabel = uicontrol('Style', 'Text', 'String', 'Expected distance (Nm)','HorizontalAlignment','left','backgroundcolor',figureColor,'Position', [borderPx borderPx-5 2*buttonWidthPx buttonHeightPx]);
        HFig.expectedMeasText = uicontrol('Style', 'Edit', 'String', 'EMPTY','HorizontalAlignment','left','backgroundcolor','white','Position', [2*buttonWidthPx+2*borderPx borderPx buttonWidthPx buttonHeightPx] , 'FontWeight', 'bold', 'Foregroundcolor','red');
        
        HFig.scaleLabel = uicontrol('Style', 'Text', 'String', 'Scale (Nm/Pixel)','HorizontalAlignment','right','backgroundcolor',figureColor,'Position', [3*buttonWidthPx+3*borderPx borderPx-5 1.5*buttonWidthPx buttonHeightPx]);
        HFig.scaleText = uicontrol('Style', 'Edit', 'Enable','inactive','String', '--','HorizontalAlignment','left','backgroundcolor','white','Position', [4.5*buttonWidthPx+4*borderPx borderPx buttonWidthPx buttonHeightPx]);
        
        % Buttons
        HFig.okButton = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Position', [figureWidthPx-borderPx-buttonWidthPx  borderPx buttonWidthPx buttonHeightPx]);
        HFig.zoomButton = uicontrol('Style', 'pushbutton', 'String', 'Zoom', 'Position', [figureWidthPx-2*borderPx-2*buttonWidthPx  borderPx buttonWidthPx buttonHeightPx]);
        HFig.autoButton = uicontrol('Style', 'pushbutton', 'String', 'Auto', 'Position', [figureWidthPx-3*borderPx-3*buttonWidthPx  borderPx buttonWidthPx buttonHeightPx]);
        
        % Adjusts the size of the font.
        HFig = setFonts(HFig);
    end

end

