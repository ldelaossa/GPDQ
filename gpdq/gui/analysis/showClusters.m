function results = showClusters(currentSection)
global config;

    maskedImage = currentSection.image;
    maskSection = currentSection.mask;
    maskedImage(~maskSection) = maskedImage(~maskSection)./2;   
    
    scale = currentSection.scale;
    particles = currentSection.particles;
    particles(:,1:2) = particles(:,1:2)/scale;
    
    HFig = createSectionFig(maskedImage);
    set(HFig.simButton,'Callback', @cluster)
    set(HFig.toFigure,'Callback',@tofigure);

    markPoints(particles(particles(:,4)==5,1:2), 5.0/scale, '-', 0.5, 'red', 'false', HFig.hImageAxes);
    markPoints(particles(particles(:,4)==2.5,1:2), 2.5/scale, '-', 0.5, 'blue', 'false', HFig.hImageAxes);
    hold(HFig.hImageAxes);
    marksClusters = [];
    numParticles = [];
    distParticles = [];
    clusters = [];
    
    function cluster(~,~)
        numParticles = str2double(HFig.numEdit.String);
        distParticles = str2double(HFig.distEdit.String);
        delete(marksClusters);
        clusters =  hClustering(particles(:,1:2), distParticles, numParticles);
        
        marksClusters = markClusters(particles(:,1:2), clusters, HFig.markPopup.String{HFig.markPopup.Value}, '--', 2, 'green',HFig.hImageAxes);
        
    end
    function tofigure(~,~)
        figure;
        imshow(maskedImage);
        markPoints(particles(particles(:,4)==5,1:2), 5.0/scale, '-', 0.5, 'red', 'false');
        markPoints(particles(particles(:,4)==2.5,1:2), 2.5/scale, '-', 0.5, 'blue', 'false');
        hold on;
        marksClusters = markClusters(particles(:,1:2), clusters, HFig.markPopup.String{HFig.markPopup.Value}, '--', 2, 'green');
        hold off;

    end

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
        HFig.mainFigure = figure('tag','showSimulation','NumberTitle','off', 'Units', 'pixels', 'Position',[posXWindow posYWindow imageEscSize(2)+10, imageEscSize(1)+70]);
        set(HFig.mainFigure, 'menubar', 'none'); % No menu bar.
        set(HFig.mainFigure,'resize','off'); % Prevents the figure for resizing (it is almost maximized).
        
        HFig.simulationText = uicontrol('Style','text','Horizontalalignment','left','String','Clustering type','Units','pixels', 'Position', [5 imageEscSize(1)+35 80 25]);
        HFig.simulationPopup = uicontrol('Style', 'popup','Horizontalalignment','left','Units','pixels','Position', [115 imageEscSize(1)+42 160 20]);
        set(HFig.simulationPopup,'String',{'Agglomerative clustering'});
        
        HFig.markPopup = uicontrol('Style', 'popup','Horizontalalignment','left','Units','pixels','Position', [imageEscSize(2)-250 imageEscSize(1)+42 160 20]);
        set(HFig.markPopup,'String',{'rectangle', 'ellipse', 'convexhull'});
        
        % Number text
        HFig.numText = uicontrol('Style', 'Text', 'String', 'Minimum size','Units','pixels','Position', [280 imageEscSize(1)+35 100 25]);
        HFig.numEdit = uicontrol('Style', 'Edit', 'String', '3','Units','pixels','Position', [380 imageEscSize(1)+42 50 25]);
                
        HFig.distText= uicontrol('Style', 'Text', 'String', 'Minimum distance (inter)','Units','pixels','Position', [435 imageEscSize(1)+35 150 25]);        
        HFig.distEdit = uicontrol('Style', 'Edit', 'String', '40','Units','pixels','Position', [590 imageEscSize(1)+42 50 25]);
        
        HFig.simButton = uicontrol('Style', 'pushbutton', 'String', 'Mark','Units','pixels','Position', [imageEscSize(2)-45 imageEscSize(1)+40 50 25]);
        
        % Shows the image.
        HFig.hImageAxes = axes('parent', HFig.mainFigure, 'Units', 'pixels','Position', [5 35 imageEscSize(2), imageEscSize(1)]);
        HFig.imageHandle = imshow(image, 'Parent', HFig.hImageAxes);
        
        % Adds the components.
        HFig.toFigure = uicontrol('Style', 'pushbutton', 'String', 'Figure','Units','pixels','Position', [5 5 50 25]);
        
        HFig.closeButton = uicontrol('Style', 'pushbutton', 'String', 'Close','Units','pixels','Position', [imageEscSize(2)-45 5 50 25]);

        
    end



end

