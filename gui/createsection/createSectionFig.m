function HFig = createSectionFig(image)
    global config;
    
    % Gets the size of the image.
    imageSize = size(image);
    
    % Should calculate measures and position.
    screenSize = get(0,'Screensize');
    
    % Calculates the optimal size.
    
    % Calculates ratios image/screen (1 height, 2 width).
    ratioImScreen = [imageSize(1)/screenSize(4)  imageSize(2)/screenSize(3)];
    % Takes 0.75 the size of the screen for the dimmension with the biggest ratio
    if ratioImScreen(1)>ratioImScreen(2)
        imageHeight = screenSize(4) * 0.75; % 0.75 is the proportion of the largest dimension.
        imageWidth = imageHeight/imageSize(1) * imageSize(2);
    else
        imageWidth = screenSize(3) * 0.75; % 0.75 is the proportion of the largest dimension.
        imageHeight = imageWidth/imageSize(2) * imageSize(1);
    end
    imageEscSize = [imageHeight, imageWidth];
    % Centers
    posXWindow = screenSize(3)/2 - imageWidth/2;
    posYWindow = screenSize(4)/2 - imageHeight/2;
    
    % Creates the figure.
    HFig.mainFigure = figure('tag','createSection','NumberTitle','off', 'Units', 'pixels', 'Position',[posXWindow posYWindow imageEscSize(2)+10, imageEscSize(1)+70]);
    set(HFig.mainFigure, 'menubar', 'none'); % No menu bar.
    set(HFig.mainFigure,'resize','off'); % Prevents the figure for resizing (it is almost maximized).
   
    % Shows the image.
    HFig.hImageAxes = axes('parent', HFig.mainFigure, 'Units', 'pixels','Position', [5 35 imageEscSize(2), imageEscSize(1)]);
    HFig.imageHandle = imshow(image, 'Parent', HFig.hImageAxes);  
    
    % Adds the components.    
    HFig.clearButton = uicontrol('Style', 'pushbutton', 'String', 'Clear','Units','pixels','Position', [5 5 50 25]); 
    HFig.invertCB = uicontrol('Style', 'checkbox', 'String', 'Discard selection','Units','pixels','Position', [60 8 150 20]); 
    
    HFig.uniqueSec = uicontrol('Style', 'checkbox', 'String', 'Unique section','Units','pixels','Value',true, 'Position', [imageEscSize(2)-200 8 150 20]); 
    HFig.saveButton = uicontrol('Style', 'pushbutton', 'String', 'Save','Units','pixels','Position', [imageEscSize(2)-100 5 50 25]); 
    HFig.closeButton = uicontrol('Style', 'pushbutton', 'String', 'Close','Units','pixels','Position', [imageEscSize(2)-45 5 50 25]); 
    HFig.sectionText = uicontrol('Style','text','Horizontalalignment','left','String','Section file:','Units','pixels', 'Position', [5 imageEscSize(1)+35 95 25]);
    HFig.fileEditText = uicontrol('Style', 'edit','Horizontalalignment','left','Units','pixels','Position', [105 imageEscSize(1)+42 imageEscSize(2)-100 20]);

end

