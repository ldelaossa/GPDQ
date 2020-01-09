function HFig = detectParticlesFig(image, maskSection, radius)
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
    HFig.mainFigure = figure('tag','createSection','NumberTitle','off', 'Units', 'pixels', 'Position',[posXWindow posYWindow imageEscSize(2)+10, imageEscSize(1)+40]);
    set(HFig.mainFigure, 'menubar', 'none'); % No menu bar.
    set(HFig.mainFigure,'resize','off'); % Prevents the figure for resizing (it is almost maximized).
   
    % Shows the image.
    HFig.hImageAxes = axes('parent', HFig.mainFigure, 'Units', 'pixels','Position', [5 35 imageEscSize(2), imageEscSize(1)]);
    
    maskedImage = image;
    maskedImage(~maskSection) = maskedImage(~maskSection)./3;   
    HFig.imageHandle = imshow(maskedImage, 'Parent', HFig.hImageAxes);  
    
    
    
    % Adds the components (Left to right)
    % Radius
    HFig.radiusText = uicontrol('Style', 'Text', 'String', 'Radius', 'Position', [5 2 40 25], 'HorizontalAlignment','left');
    HFig.radiusEdit =uicontrol('Style', 'Edit', 'backgroundcolor','white','String', 5, 'Enable', 'off', 'Position', [50 5 25 25],...
                               'Tooltipstring','Radius to be detected.');    
    % Margin
    HFig.marginText = uicontrol('Style', 'Text', 'String', 'Margin ( > 0 Nm)', 'Position', [95 2 100 25], 'HorizontalAlignment','left');
    HFig.marginEdit = uicontrol('Style', 'Edit', 'backgroundcolor','white','String', 1, 'Position', [200 5 30 25], ... 
        'Tooltipstring','Particles which differ from the selected selected more than this margin are discarded.');      
    
    % Sensitivity
    HFig.sensText = uicontrol('Style', 'Text', 'String', 'Sensitivity ( 0.5 - 0.99 )','Position', [250 2 125 25],'HorizontalAlignment','left');
    HFig.sensEdit = uicontrol('Style', 'Edit','backgroundcolor','white','String', 0.75, ...
        'Tooltipstring','Fixes the sensitivity of the Hough transform. Higher values allow detecting more circles.',...
        'Position', [385 5 30 25],'HorizontalAlignment','right');

    % Detect button
    HFig.detectButton = uicontrol('Style', 'pushbutton', 'String', 'Detect','Units','pixels','FontWeight','bold','Position', [425 2 55 30]); 
    HFig.detectText = uicontrol('Style', 'Text', 'String', 'Takes several seconds','Position', [485 2 150 25],'HorizontalAlignment','left');

    % Exit
    HFig.cancelButton = uicontrol('Style', 'pushbutton', 'String', 'Cancel','Units','pixels','Position', [imageEscSize(2)-105 2 55 30]); 
    HFig.okButton = uicontrol('Style', 'pushbutton', 'String', 'Ok','Units','pixels','Position', [imageEscSize(2)-45 2 55 30]); 

    % Updates the font sizes
    setFonts(HFig);
end

