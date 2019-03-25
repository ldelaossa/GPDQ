%% showSimulation
%
% Simulates random points and shows them in an image. 
%
% Usage
% -----
%
%   showSimulation(section)
%
%
% Parameters
% ----------
%
%   section: Section information as returned by GPDQProject.getSectionData(1);

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function showSimulation(currentSection)
    global config;
    % Avoids multiple openings of the figure. If it is already open, shows it.
    windowSimulation = findobj('type', 'figure', 'tag', 'showsimulation');
    if ~isempty(windowSimulation)
        figure(windowSimulation);
        return;
    end    

    % Extracts the information of the section 
    maskedImage = currentSection.image;
    maskSection = currentSection.mask;
    maskedImage(~maskSection) = maskedImage(~maskSection)./2;   
    scale = currentSection.scale;
    particles = currentSection.particles;
    
    % Creates the figure
    HFig = createSectionFig(maskedImage);
    set(HFig.simButton,'Callback', @simulate)
    set(HFig.toFigure,'Callback',@toFigure);
    set(HFig.closeButton,'CallBack', @close);

    % Marks existing particles
    particlesScaled = particles(:,1:2)/scale; 
    markPoints(particlesScaled(particles(:,4)==5,:), 5.0/scale, '-', 0.5, 'red', false, HFig.hImageAxes);
    markPoints(particlesScaled(particles(:,4)==2.5,:), 2.5/scale, '-', 0.5, 'blue', false, HFig.hImageAxes);

    numParticles = [];
    distParticles = [];
    simParticlesScaled = [];
    marksSimParticles = [];
    
%% Closes the figure
    function close(~,~)
        delete(gcf);
    end

%% Simulates 
    function simulate(~,~)
        %% Simulates the particles
        numParticles = str2double(HFig.numEdit.String);
        distParticles = str2double(HFig.distEdit.String);
        delete(marksSimParticles);
        %newParticles = genUniformRandomPoints(numParticles, maskSection, distParticles, particles(:,1:2));
        simParticlesScaled = genUniformRandomPoints(numParticles, maskSection, distParticles/scale);
        marksSimParticles = markPoints(simParticlesScaled, 5.0/scale, '-', 1, 'Yellow', true, HFig.hImageAxes);
    end

%% toFigure
    function toFigure(~,~)
        %% Exports the figure to a new-resizable one
        figure;
        imshow(maskedImage);
        markPoints(particlesScaled(particles(:,4)==5,1:2), 5.0/scale, '-', 0.5, 'red', false);
        markPoints(particlesScaled(particles(:,4)==2.5,1:2), 2.5/scale, '-', 0.5, 'blue', false);
        markPoints(simParticlesScaled, 5.0/scale, '-', 0.5, 'Yellow', true);
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
            imageHeight = screenSize(4) * 0.65; % 0.75 is the proportion of the largest dimension.
            imageWidth = imageHeight/imageSize(1) * imageSize(2);
        else
            imageWidth = screenSize(3) * 0.65; % 0.75 is the proportion of the largest dimension.
            imageHeight = imageWidth/imageSize(2) * imageSize(1);
        end
        imageEscSize = [imageHeight, imageWidth];
        % Centers
        posXWindow = screenSize(3)/2 - imageWidth/2;
        posYWindow = screenSize(4)/2 - imageHeight/2;
        
        % Creates the figure.
        HFig.mainFigure = figure('tag','showsimulation','NumberTitle','off', 'Units', 'pixels', 'Position',[posXWindow posYWindow imageEscSize(2)+10, imageEscSize(1)+70]);
        set(HFig.mainFigure, 'menubar', 'none'); % No menu bar.
        set(HFig.mainFigure,'resize','off'); % Prevents the figure for resizing (it is almost maximized).
        set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version '. Simulation.']);

        % Configuration

        HFig.simulationText = uicontrol('Style','text','Horizontalalignment','left','String','Simulation type','Units','pixels', 'Position', [5 imageEscSize(1)+38 80 25]);
        HFig.simulationPopup = uicontrol('Style', 'popup','Horizontalalignment','left','Units','pixels','Position', [90 imageEscSize(1)+40 160 25]);
        set(HFig.simulationPopup,'String',{'Uniform simulation'});
        
        HFig.numText = uicontrol('Style', 'Text', 'String', 'Number of particles','Units','pixels','Position', [255 imageEscSize(1)+38 100 25]);
        HFig.numEdit = uicontrol('Style', 'Edit', 'String', '10','Units','pixels','Position', [360 imageEscSize(1)+41 50 25]);
                
        HFig.distText= uicontrol('Style', 'Text', 'String', 'Minimun allowed distance','Units','pixels','Position', [415 imageEscSize(1)+38 150 25]);        
        HFig.distEdit = uicontrol('Style', 'Edit', 'String', '10','Units','pixels','Position', [570 imageEscSize(1)+40 50 25]);
         
        HFig.simButton = uicontrol('Style', 'pushbutton', 'String', 'Simulate','Units','pixels','Position', [imageEscSize(2)+10-80-5 imageEscSize(1)+40 80 25]);
        
        % Shows the image.
        HFig.hImageAxes = axes('parent', HFig.mainFigure, 'Units', 'pixels','Position', [5 35 imageEscSize(2), imageEscSize(1)]);
        HFig.imageHandle = imshow(image, 'Parent', HFig.hImageAxes);
        
        % To Figure button
        HFig.toFigure = uicontrol('Style', 'pushbutton', 'String', 'Figure','Units','pixels','Position', [5 5 50 25]);
        % Close button
        HFig.closeButton = uicontrol('Style', 'pushbutton', 'String', 'Close','Units','pixels','Position', [imageEscSize(2)-45 5 50 25]);
    end
end


