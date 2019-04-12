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
%   section: Section information as returned by GPDQProject.getSectionData(idSection);

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
    particlesPx = particles(:,1:2)/scale; 
    
    % Creates the figure
    HFig = createSectionFig(maskedImage);
    set(HFig.closeButton,'CallBack', @close);    
    set(HFig.simButton,'Callback', @simulate)
    set(HFig.toFigure,'Callback',@toFigure);

    % Marks existing particles (THIS IS PROVISIONAL)
    markPoints(particlesPx(particles(:,4)==5,:), 5.0/scale, '-', 1, 'red', false, HFig.hImageAxes);
    markPoints(particlesPx(particles(:,4)==2.5,:), 2.5/scale, '-', 1, 'blue', false, HFig.hImageAxes);

    % Objects
    numParticles = [];
    distParticles = [];
    simParticlesPx = [];
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
        % For calculating the distances
        refParticles = [];
        if get(HFig.refParticles5Nm,'Value')
            refParticles = [refParticles , 5];
        end
        if get(HFig.refParticles2_5Nm,'Value')
            refParticles = [refParticles , 2.5];
        end        
        simParticles = uniformRandomSim(maskSection, particles, numParticles, 'Scale', scale, 'MinDistance', distParticles, 'RefParticles', refParticles);
        marksSimParticles = markPoints(simParticles/scale, 5.0/scale, '-', 1, 'Yellow', true, HFig.hImageAxes);
    end

%% toFigure
    function toFigure(~,~)
        %% Exports the figure to a new-resizable one
        figure;
        imshow(maskedImage);
        markPoints(particlesPx(particles(:,4)==5,1:2), 5.0/scale, '-', 0.5, 'red', false);
        markPoints(particlesPx(particles(:,4)==2.5,1:2), 2.5/scale, '-', 0.5, 'blue', false);
        markPoints(simParticlesPx, 5.0/scale, '-', 0.5, 'Yellow', true);
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
            imageHeightPx = screenSize(4) * 0.65; % 0.75 is the proportion of the largest dimension.
            imageWidthPx = imageHeightPx/imageSize(1) * imageSize(2);
        else
            imageWidthPx = screenSize(3) * 0.65; % 0.75 is the proportion of the largest dimension.
            imageHeightPx = imageWidthPx/imageSize(2) * imageSize(1);
        end
        % Centers
        posXWindow = screenSize(3)/2 - imageWidthPx/2;
        posYWindow = screenSize(4)/2 - imageHeightPx/2;
        borderPx = 5;
        buttonHeightPx = 25;
        buttonWidthPx = 80;
        
        % Creates the figure.
        HFig.mainFigure = figure('tag','showsimulation','NumberTitle','off', 'Units', 'pixels', ...
                                 'Position',[posXWindow posYWindow imageWidthPx+2*borderPx, imageHeightPx+3*buttonHeightPx+5*borderPx]);
        set(HFig.mainFigure, 'menubar', 'none'); % No menu bar.
        set(HFig.mainFigure,'resize','off'); % Prevents the figure for resizing (it is almost maximized).
        set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version ' - Simulation view.']);
        
        % Configuration
        
        HFig.simulationText = uicontrol('Style','text','Horizontalalignment','left','String','Simulation','Units','pixels', ...
                                        'Position', [borderPx imageHeightPx+2*buttonHeightPx+4*borderPx-3, 0.75*buttonWidthPx buttonHeightPx]);
                                    
        HFig.simulationPopup = uicontrol('Style', 'popup','Horizontalalignment','left','Units','pixels', ...
                                         'Position',[2*borderPx+0.75*buttonWidthPx imageHeightPx+2*buttonHeightPx+4*borderPx-2, 2*buttonWidthPx buttonHeightPx]);
        set(HFig.simulationPopup,'String',{'Uniform simulation'});                                    
                                    
        HFig.simButton = uicontrol('Style', 'pushbutton', 'String', 'Simulate','Units','pixels',...
                                            'Position', [imageWidthPx-buttonWidthPx+borderPx, imageHeightPx+1*buttonHeightPx+3*borderPx, buttonWidthPx, buttonHeightPx]);                                      



        HFig.numText = uicontrol('Style', 'Text', 'String', 'Number of particles','Units','pixels','Horizontalalignment','left',...
                                 'Position', [3*borderPx+0.75*buttonWidthPx  imageHeightPx+1*buttonHeightPx+3*borderPx-3, 1.5*buttonWidthPx buttonHeightPx]);
        HFig.numEdit = uicontrol('Style', 'Edit', 'String', '10','Units','pixels',...
                                 'Position',[borderPx+2.25*buttonWidthPx imageHeightPx+1*buttonHeightPx+3*borderPx, 0.5*buttonWidthPx buttonHeightPx]);
        
        HFig.distText= uicontrol('Style', 'Text', 'String', 'Min. distance','Units','pixels','Horizontalalignment','right',...
                                 'Position', [3*borderPx+2.75*buttonWidthPx imageHeightPx+2*buttonHeightPx+4*borderPx-3, 1*buttonWidthPx, buttonHeightPx]);
        HFig.distEdit = uicontrol('Style', 'Edit', 'String', '10','Units','pixels',...
                                  'Position', [4*borderPx+3.75*buttonWidthPx imageHeightPx+2*buttonHeightPx+4*borderPx+1, 0.5*buttonWidthPx, buttonHeightPx]);
         
        HFig.refParticles5Nm = uicontrol('Style', 'checkbox', 'String', 'To 5Nm', 'Horizontalalignment','right', ...
                                          'Position', [4*borderPx+4.5*buttonWidthPx, imageHeightPx+1*buttonHeightPx+3*borderPx+2, buttonWidthPx, buttonHeightPx]);                                        
        HFig.refParticles2_5Nm = uicontrol('Style', 'checkbox', 'String', 'To 2.5Nm', ...
                                          'Position', [4*borderPx+4.5*buttonWidthPx, imageHeightPx+2*buttonHeightPx+4*borderPx+2, buttonWidthPx, buttonHeightPx]);                                        
        
        % Shows the image.
        HFig.hImageAxes = axes('parent', HFig.mainFigure, 'Units', 'pixels',...
                               'Position', [borderPx buttonHeightPx+2*borderPx imageWidthPx, imageHeightPx]);
        HFig.imageHandle = imshow(image, 'Parent', HFig.hImageAxes);
        
        % To Figure button
        HFig.toFigure = uicontrol('Style', 'pushbutton', 'String', 'Figure','Units','pixels',...
                                  'Position', [borderPx borderPx buttonWidthPx buttonHeightPx]);
        % Close button
        HFig.closeButton = uicontrol('Style', 'pushbutton', 'String', 'Close','Units','pixels',...
                                     'Position', [imageWidthPx-buttonWidthPx+borderPx borderPx buttonWidthPx buttonHeightPx]);
    end
end


