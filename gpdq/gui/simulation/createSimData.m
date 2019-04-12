
function simData = createSimData(data)

global config;
% Avoids multiple openings of the figure. If it is already open, shows it.
windowsimdata = findobj('type', 'figure', 'tag', 'createsimdataunif');
if ~isempty(windowsimdata)
    figure(windowsimdata);
    return;
end



% Creates the figure
HFig = [];
createFig();



% Returns when the figure is closed.
waitfor(HFig.mainFigure);
  
    
%% Simulates the data
    function simulate(~,~) 
%         numSimulations = str2num(HFig.
%         simData = GPDQSimulation(data, numSimulations, simParticles, simFunction, tag, varargin)
    end

%% Returns the data
    function ok(~, ~)
        % Returns
        delete(HFig.mainFigure);
    end
    
%% Creates the Fig.
    function createFig
        screenSize = get(0,'Screensize');
        figureWidthPx = 800;
        buttonHeightPx = 25;
        buttonWidthPx = 80;
        borderPx = 10;
        textHeightPx = 100;
        figureHeightPx = 4*buttonHeightPx+6*borderPx+textHeightPx;
        figurePosXPx = (screenSize(3)-figureHeightPx)/2;
        figurePosYPx = (screenSize(4)-figureWidthPx)/2;
        HFig.mainFigure = figure('tag','createsimdataunif','NumberTitle','off','Units', 'pixels', 'resize','on','menubar', 'none', 'Position',[figurePosXPx figurePosYPx figureWidthPx, figureHeightPx]);
        set(HFig.mainFigure, 'Name', ['GPDQ v' config.version ' -  Data simulation (Random Uniform)']);
        figureColor = get(HFig.mainFigure, 'color');
        
        
        HFig.projectTitle = uicontrol('Style', 'Text', 'String', 'Project','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx, figureHeightPx-buttonHeightPx-borderPx-3, 0.5*buttonWidthPx, buttonHeightPx]);
        HFig.projectTitleText = uicontrol('Style', 'Edit', 'Enable', 'inactive', 'String', '','HorizontalAlignment','left','backgroundcolor','white','Enable', 'inactive',...
            'Position', [2*borderPx+0.5*buttonWidthPx, figureHeightPx-buttonHeightPx-borderPx, figureWidthPx-0.5*buttonWidthPx-3*borderPx, buttonHeightPx]);
        set(HFig.projectTitleText, 'String', fullfile(data.workingDirectory, data.project));

        HFig.numSimulationsLabel = uicontrol('Style', 'Text', 'String', 'Number of simulations','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx, figureHeightPx-2*buttonHeightPx-2*borderPx-3, 2.5*buttonWidthPx, buttonHeightPx]);        

        HFig.numSimulationsText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', '100','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [3*borderPx+2.5*buttonWidthPx, figureHeightPx-2*buttonHeightPx-2*borderPx, 0.5*buttonWidthPx, buttonHeightPx]);        

        
        HFig.simParticlesLabel = uicontrol('Style', 'Text', 'String', 'Particles to simulate','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx, figureHeightPx-3*buttonHeightPx-3*borderPx-3, 1.5*buttonWidthPx, buttonHeightPx]);
       
        HFig.simParticles5Nm = uicontrol('Style', 'checkbox', 'String', '5Nm', ...
            'Position', [3*borderPx+2.5*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx, buttonWidthPx, buttonHeightPx]);
        HFig.simParticles2_5Nm = uicontrol('Style', 'checkbox', 'String', '2.5Nm', 'Horizontalalignment','right', ...
            'Position', [2*borderPx+1.5*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx, buttonWidthPx, buttonHeightPx]);

        
        HFig.refParticlesLabel = uicontrol('Style', 'Text', 'String', 'Reference particles','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [4*borderPx+3.5*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx-3, 1.5*buttonWidthPx, buttonHeightPx]);
       
        HFig.refParticles5Nm = uicontrol('Style', 'checkbox', 'String', '5Nm', ...
            'Position', [5*borderPx+6*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx, buttonWidthPx, buttonHeightPx]);
        HFig.refParticles2_5Nm = uicontrol('Style', 'checkbox', 'String', '2.5Nm', 'Horizontalalignment','right', ...
            'Position', [5*borderPx+5*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx, buttonWidthPx, buttonHeightPx]);
        
        HFig.minDistanceLabel = uicontrol('Style', 'Text', 'String', 'Minimum distance','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [4*borderPx+3.5*buttonWidthPx, figureHeightPx-2*buttonHeightPx-2*borderPx-3, 1.5*buttonWidthPx, buttonHeightPx]);        

        HFig.minDistanceText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', '10','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [5*borderPx+5*buttonWidthPx, figureHeightPx-2*buttonHeightPx-2*borderPx, 0.5*buttonWidthPx, buttonHeightPx]);        

        
        HFig.simButton = uicontrol('Style', 'pushbutton', 'String', 'Simulate', 'Callback',@simulate, ...
            'Position', [figureWidthPx-1*buttonWidthPx-1*borderPx figureHeightPx-3*buttonHeightPx-3*borderPx, buttonWidthPx, buttonHeightPx]);
        
        
         
     
        HFig.tagText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', 'TAG:','HorizontalAlignment','left','backgroundcolor','white','Max',5,...
            'Position', [borderPx, buttonHeightPx+2*borderPx, figureWidthPx-2*borderPx, textHeightPx]);
        
        HFig.okButton = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Callback',@ok, ...
            'Position', [figureWidthPx-1*buttonWidthPx-1*borderPx borderPx, buttonWidthPx, buttonHeightPx]);
        HFig.saveButton = uicontrol('Style', 'pushbutton', 'String', 'Save','Callback',@cancel, ...
            'Position', [figureWidthPx-2*buttonWidthPx-2*borderPx borderPx, buttonWidthPx, buttonHeightPx]);        

        setFonts(HFig);
        
    end

end

