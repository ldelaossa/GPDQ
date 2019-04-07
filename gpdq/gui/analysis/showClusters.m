function results = showClusters(currentSection)
    global config;

    % Avoids multiple openings of the figure. If it is already open, shows it.
    windowClusters = findobj('type', 'figure', 'tag', 'showclusters');
    if ~isempty(windowClusters)
        figure(windowClusters);
        return;
    end   
    
    % Extracts the information of the section 
    maskedImage = currentSection.image;
    maskSection = currentSection.mask;
    maskedImage(~maskSection) = maskedImage(~maskSection)./2;   
    scale = currentSection.scale;
    particles = currentSection.particles;
    particlesPx = particles(:,1:2)/scale; 
    
    % Creates the figure
    HFig = createSectionFig(maskedImage);
    set(HFig.closeButton,'CallBack', @close);    
    set(HFig.toFigure,'Callback',@toFigure);  
    set(HFig.markButton,'Callback',@cluster);       
    
    % Marks existing particles (THIS IS PROVISIONAL)
    markPoints(particlesPx(particles(:,4)==5,:), 5.0/scale, '-', 1, 'red', false, HFig.hImageAxes);
    markPoints(particlesPx(particles(:,4)==2.5,:), 2.5/scale, '-', 1, 'blue', false, HFig.hImageAxes);
    hold(HFig.hImageAxes);
    
    % Objects
    numParticles = [];
    distParticles = [];  
    marksClusters = [];
    numParticles = [];
    distParticles = [];
    clusters = [];
    refParticles = [];

%% Closes the figure
    function close(~,~)
        delete(gcf);
    end

%% Calculates and marks clusters
    function cluster(~,~)
        numParticles = str2double(HFig.numEdit.String);
        distParticles = str2double(HFig.distEdit.String);
        % There can be problems when closing the figure and returning to
        % the main window.
        try
            delete(marksClusters);
        catch
            marksClusters = [];
        end

        
       % Selects the particles
        refParticles = false(size(particles,1),1);
        if get(HFig.refParticles5Nm,'Value')
            refParticles(particles(:,4)==5)=true;
        end
        if get(HFig.refParticles2_5Nm,'Value')
            refParticles(particles(:,4)==2.5)=true;
        end 
        % Calculates the clusters
        clusters =  hClustering(particles(refParticles,1:2), distParticles, numParticles);
        % Marks the clusters
        marksClusters = markClusters(particlesPx(refParticles,1:2), clusters, HFig.markPopup.String{HFig.markPopup.Value}, '--', 2, 'green',HFig.hImageAxes);
    end

%% Exports to figure
    function toFigure(~,~)
        figure;
        imshow(maskedImage);
        markPoints(particlesPx(particles(:,4)==5,1:2), 5.0/scale, '-', 0.5, 'red', false);
        markPoints(particlesPx(particles(:,4)==2.5,1:2), 2.5/scale, '-', 0.5, 'blue', false);
        hold on;
        markClusters(particlesPx(refParticles,1:2), clusters, HFig.markPopup.String{HFig.markPopup.Value}, '--', 2, 'green');
        hold off;
    end

%% Creates the figure
    function HFig = createSectionFig(image)
      
        % Gets the size of the image.
        imageSize = size(image);
        
        % Should calculate measures and position.
        screenSize = get(0,'Screensize');
        
        % Calculates the optimal size.
        
        % Calculates ratios image/screen (1 height, 2 width).
        ratioImScreen = [imageSize(1)/screenSize(4)  imageSize(2)/screenSize(3)];
        % Takes 0.75 the size of the screen for the dimmension with the biggest ratio
        if ratioImScreen(1)>ratioImScreen(2)
            imageHeightPx = screenSize(4) * 0.7; % 0.7 is the proportion of the largest dimension.
            imageWidthPx = imageHeightPx/imageSize(1) * imageSize(2);
        else
            imageWidthPx = screenSize(3) * 0.7; % 0.7 is the proportion of the largest dimension.
            imageHeightPx = imageWidthPx/imageSize(2) * imageSize(1);
        end
        % Centers
        posXWindow = screenSize(3)/2 - imageWidthPx/2;
        posYWindow = screenSize(4)/2 - imageHeightPx/2;
        borderPx = 5;
        buttonHeightPx = 25;
        buttonWidthPx = 80;
        
        % Creates the figure.
        HFig.mainFigure = figure('tag','showclusters','NumberTitle','off', 'Units', 'pixels', ...
                                 'Position',[posXWindow posYWindow imageWidthPx+2*borderPx, imageHeightPx+3*buttonHeightPx+5*borderPx]);
        set(HFig.mainFigure, 'menubar', 'none'); % No menu bar.
        set(HFig.mainFigure,'resize','off'); % Prevents the figure for resizing (it is almost maximized).
        set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version ' - Cluster view']);
        
        HFig.clusterText = uicontrol('Style','text','Horizontalalignment','left','String','Clustering type','Units','pixels',...
                                        'Position', [borderPx imageHeightPx+2*buttonHeightPx+4*borderPx-3 buttonWidthPx buttonHeightPx]);
        HFig.clusterPopup = uicontrol('Style', 'popup','Horizontalalignment','left','Units','pixels',...
                                        'Position', [2*borderPx+buttonWidthPx imageHeightPx+2*buttonHeightPx+4*borderPx-2 2*buttonWidthPx buttonHeightPx]);
        set(HFig.clusterPopup,'String',{'Agglomerative clustering'});       
        
         % Number text
        HFig.numText = uicontrol('Style', 'Text', 'String', 'Minimum size','Units','pixels','Horizontalalignment','right',...
                                 'Position', [3*borderPx+3.25*buttonWidthPx imageHeightPx+2*buttonHeightPx+4*borderPx-3 buttonWidthPx buttonHeightPx]);
        HFig.numEdit = uicontrol('Style', 'Edit', 'String', '3','Units','pixels',...
                                 'Position', [4*borderPx+4.25*buttonWidthPx imageHeightPx+2*buttonHeightPx+4*borderPx 0.5*buttonWidthPx buttonHeightPx]);   
         
        %Distance
        HFig.distText= uicontrol('Style', 'Text', 'String', 'Minimum distance','Units','pixels','Horizontalalignment','right',...
                                 'Position', [3*borderPx+2.25*buttonWidthPx imageHeightPx+1*buttonHeightPx+3*borderPx-4 2*buttonWidthPx buttonHeightPx]);
        HFig.distEdit = uicontrol('Style', 'Edit', 'String', '40','Units','pixels',...
                                 'Position', [4*borderPx+4.25*buttonWidthPx imageHeightPx+1*buttonHeightPx+3*borderPx 0.5*buttonWidthPx buttonHeightPx]);   
        % Mark
        HFig.markText = uicontrol('Style','text','Horizontalalignment','right','String','Mark','Units','pixels',...
                                        'Position', [imageWidthPx-2.5*buttonWidthPx imageHeightPx+2*buttonHeightPx+4*borderPx-3 0.5*buttonWidthPx buttonHeightPx]);        
        HFig.markPopup = uicontrol('Style', 'popup','Horizontalalignment','left','Units','pixels',...
                                            'Position', [imageWidthPx-2*buttonWidthPx+2*borderPx, imageHeightPx+2*buttonHeightPx+4*borderPx-2, 2*buttonWidthPx, buttonHeightPx]);  
        set(HFig.markPopup,'String',{'rectangle', 'ellipse', 'convexhull'});        
        
        HFig.markButton = uicontrol('Style', 'pushbutton', 'String', 'Make clusters','Units','pixels',...
                                            'Position', [imageWidthPx-buttonWidthPx+borderPx, imageHeightPx+1*buttonHeightPx+3*borderPx, buttonWidthPx, buttonHeightPx]);          
        
        % Shows the image.
        HFig.hImageAxes = axes('parent', HFig.mainFigure, 'Units', 'pixels',...
                               'Position', [borderPx buttonHeightPx+2*borderPx imageWidthPx, imageHeightPx]);
                           
        HFig.imageHandle = imshow(image, 'Parent', HFig.hImageAxes);
        
        % Particles
        
        HFig.particlesText = uicontrol('Style','text','Horizontalalignment','left','String','Particles','Units','pixels',...
                                          'Position', [borderPx, imageHeightPx+1*buttonHeightPx+3*borderPx-4, buttonWidthPx, buttonHeightPx]);  
        HFig.refParticles5Nm = uicontrol('Style', 'checkbox', 'String', '5Nm', 'Value', true, ...
                                          'Position', [3*borderPx+buttonWidthPx, imageHeightPx+1*buttonHeightPx+3*borderPx, 0.75*buttonWidthPx, buttonHeightPx]); 
        HFig.refParticles2_5Nm = uicontrol('Style', 'checkbox', 'String', '2.5Nm','Value', true, ...
                                          'Position', [4*borderPx+2*buttonWidthPx, imageHeightPx+1*buttonHeightPx+3*borderPx, 0.75*buttonWidthPx, buttonHeightPx]);  
                                      


        % To Figure button
        HFig.toFigure = uicontrol('Style', 'pushbutton', 'String', 'Figure','Units','pixels',...
                                  'Position', [borderPx borderPx buttonWidthPx buttonHeightPx]);
        % Close button
        HFig.closeButton = uicontrol('Style', 'pushbutton', 'String', 'Close','Units','pixels',...
                                     'Position', [imageWidthPx-buttonWidthPx+borderPx borderPx buttonWidthPx buttonHeightPx]);        
    end
end
    
    





