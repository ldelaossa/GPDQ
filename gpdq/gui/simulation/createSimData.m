
function simData = createSimData(data)

global config;
% Avoids multiple openings of the figure. If it is already open, shows it.
windowsimdata = findobj('type', 'figure', 'tag', 'createsimdataunif');
if ~isempty(windowsimdata)
    figure(windowsimdata);
    return;
end

simName = [data.project(1:end-4),'_sim_x.mat'];
simData = [];
fit = 0;

% Creates the figure
HFig = [];
createFig();
set(HFig.simButton,'Callback', @simulate)
set(HFig.okButton,'Callback', @ok)
set(HFig.saveButton,'Callback', @save)
set(HFig.fitNNDCB,'Callback', @setfit)
set(HFig.randomCB,'Callback', @setfit)
% Returns when the figure is closed.
waitfor(HFig.mainFigure);
  
    
%% Simulates the data
    function simulate(~,~) 
        % Number of simulations
        numSimulations = str2double(HFig.numSimulationsText.String);
        % Tag
        tag = HFig.tagText.String;
        % Radii of the simulated particles
        simParticles = [];
        if get(HFig.simParticles2_5Nm,'Value')
            simParticles = [simParticles , 2.5];
        end          
        if get(HFig.simParticles5Nm,'Value')
            simParticles = [simParticles , 5];
        end
        if isempty(simParticles)
            simParticles = [2.5, 5];
        end
        % Radii of the reference particles
        refParticles = [];
        if get(HFig.refParticles2_5Nm,'Value')
            refParticles = [refParticles , 2.5];
        end          
        if get(HFig.refParticles5Nm,'Value')
            refParticles = [refParticles , 5];
        end  
        % Minimum distance among simulated particles
        minDistanceSim = str2double(get(HFig.minSimDistanceText,'String'));
        if isempty(minDistanceSim)
            minDistanceSim=0;
        end
        % Confidence interval
        ci = str2double(get(HFig.ciText,'String'));
        if isempty(ci)
            ci=[];
        end    
        
        meanDiff = str2double(get(HFig.meanText,'String'));
        if isempty(meanDiff)
            meanDiff=[];
        end   

        if ~fit
            simData = GPDQSimulation(data, tag, simParticles, numSimulations, @uniformRandomSim, 'MinDistance', minDistanceSim, 'RefParticlesR', refParticles);
        else
            simData = GPDQSimulation(data, tag, simParticles, numSimulations, @fitDDRandomSim, 'Confidence', ci, 'RefParticlesR', refParticles, 'MaxMeanDistDiff',meanDiff);
        end
 
    end

%% Saves the data simulation
    function setfit(~, ~)
        fit = ~fit;
        if fit
            set(HFig.fitNNDCB,'Value',1);
            set(HFig.randomCB,'Value',0);
            set(HFig.ciText,'Enable','on');
            set(HFig.ciLabel,'Enable','on');
            set(HFig.meanText,'Enable','on');
            set(HFig.meanLabel,'Enable','on')            
        else
            set(HFig.fitNNDCB,'Value',0);
            set(HFig.randomCB,'Value',1);   
            set(HFig.meanText,'Enable','off');
            set(HFig.meanLabel,'Enable','off');
        end
    end
%% Saves the data simulation
    function ok(~, ~)
        % Returns
        delete(HFig.mainFigure);
    end

%% Returns the data
    function save(~, ~)
        if isempty(simData)
            return
        end

        simName = get(HFig.projectTitleText,'String');
        fullSimDataName = get(HFig.projectTitleText,'String');

        [tmpSimDataName, tmpSaveDirectory] = uiputfile('*.mat', 'Save project data as', fullSimDataName);
         % If no file is selected, the function returns.
          if isempty(tmpSimDataName) || (numel(tmpSimDataName)==1 && tmpSimDataName==0)
              return
          end
         newFullSimDataName = fullfile(tmpSaveDirectory, tmpSimDataName);
         
         result = GPDQSimulation.save(simData, newFullSimDataName);
         if ~GPDQStatus.isError(result)
             GPDQStatus.repSuccess(['Simulation succesfully saved in ' newFullSimDataName]);
             set(HFig.projectTitleText,'String', newFullSimDataName)
         else
             GPDQStatus.repError(['Error when saving the data of simulation ' newFullSimDataName], true, dbstack());   
         end     
    end
    
%% Creates the Fig.
    function createFig
        screenSize = get(0,'Screensize');
        figureWidthPx = 840;
        buttonHeightPx = 25;
        buttonWidthPx = 80;
        borderPx = 10;
        textHeightPx = 100;
        figureHeightPx = 5*buttonHeightPx+7*borderPx+textHeightPx;
        figurePosXPx = (screenSize(3)-figureHeightPx)/2;
        figurePosYPx = (screenSize(4)-figureWidthPx)/2;
        HFig.mainFigure = figure('tag','createsimdataunif','NumberTitle','off','Units', 'pixels', 'resize','on','menubar', 'none', 'Position',[figurePosXPx figurePosYPx figureWidthPx, figureHeightPx]);
        set(HFig.mainFigure, 'Name', ['GPDQ v' config.version ' -  Data simulation']);
        figureColor = get(HFig.mainFigure, 'color');
        
        HFig.projectTitle = uicontrol('Style', 'Text', 'String', 'Project','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx, figureHeightPx-buttonHeightPx-borderPx-3, 0.5*buttonWidthPx, buttonHeightPx]);
        HFig.projectTitleText = uicontrol('Style', 'Edit', 'Enable', 'inactive', 'String', '','HorizontalAlignment','left','backgroundcolor','white','Enable', 'on',...
            'Position', [2*borderPx+0.5*buttonWidthPx, figureHeightPx-buttonHeightPx-borderPx, figureWidthPx-0.5*buttonWidthPx-3*borderPx, buttonHeightPx]);
        set(HFig.projectTitleText, 'String', fullfile(data.workingDirectory, simName));

        HFig.kindSimulationsLabel = uicontrol('Style', 'Text', 'String', 'Type of simulation','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx, figureHeightPx-2*buttonHeightPx-2*borderPx-3, 2.5*buttonWidthPx, buttonHeightPx]);        
  
        HFig.randomCB = uicontrol('Style', 'checkbox', 'String', 'Random', 'Horizontalalignment','right','Enable','on', 'Value',1,...
            'Position', [2*borderPx+1.5*buttonWidthPx, figureHeightPx-2*buttonHeightPx-2*borderPx, buttonWidthPx, buttonHeightPx]);         
        HFig.fitNNDCB = uicontrol('Style', 'checkbox', 'String', 'Fit NND', 'Horizontalalignment','right','Enable','on',...
            'Position', [3*borderPx+2.5*buttonWidthPx, figureHeightPx-2*buttonHeightPx-2*borderPx, buttonWidthPx, buttonHeightPx]);   

        HFig.ciLabel = uicontrol('Style', 'Text', 'String', 'Confidence interval','HorizontalAlignment','left','backgroundcolor',figureColor,'Enable','off',...
            'Position', [4*borderPx+3.5*buttonWidthPx, figureHeightPx-2*buttonHeightPx-2*borderPx-3, 1.5*buttonWidthPx, buttonHeightPx]);        

        HFig.ciText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', '0.9','HorizontalAlignment','left','backgroundcolor','white','Enable','off',...
            'Position', [5*borderPx+5*buttonWidthPx, figureHeightPx-2*buttonHeightPx-2*borderPx, 0.5*buttonWidthPx, buttonHeightPx]);    

        HFig.meanLabel = uicontrol('Style', 'Text', 'String', 'Maximum mean difference','HorizontalAlignment','left','backgroundcolor',figureColor,'Enable','off',...
            'Position', [6*borderPx+6*buttonWidthPx, figureHeightPx-2*buttonHeightPx-2*borderPx-3, 2*buttonWidthPx, buttonHeightPx]);        
        HFig.meanText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', '1','HorizontalAlignment','left','backgroundcolor','white','Enable','off',...
            'Position', [figureWidthPx-1.5*buttonWidthPx-2*borderPx, figureHeightPx-2*buttonHeightPx-2*borderPx, 0.5*buttonWidthPx, buttonHeightPx]);
        
        HFig.simParticlesLabel = uicontrol('Style', 'Text', 'String', 'Particles to simulate','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx, figureHeightPx-3*buttonHeightPx-3*borderPx-3, 1.5*buttonWidthPx, buttonHeightPx]);
        HFig.simParticles5Nm = uicontrol('Style', 'checkbox', 'String', '5Nm', 'Value', 1,... 
            'Position', [3*borderPx+2.5*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx, buttonWidthPx, buttonHeightPx]);
        HFig.simParticles2_5Nm = uicontrol('Style', 'checkbox', 'String', '2.5Nm', 'Horizontalalignment','right', ...
            'Position', [2*borderPx+1.5*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx, buttonWidthPx, buttonHeightPx]);
        HFig.minSimDistanceLabel = uicontrol('Style', 'Text', 'String', 'Minimum distance','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [4*borderPx+3.5*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx-3, 1.5*buttonWidthPx, buttonHeightPx]);        
        HFig.minSimDistanceText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', '10','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [5*borderPx+5*buttonWidthPx, figureHeightPx-3*buttonHeightPx-3*borderPx, 0.5*buttonWidthPx, buttonHeightPx]);    


        HFig.refParticlesLabel = uicontrol('Style', 'Text', 'String', 'Reference particles','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx, figureHeightPx-4*buttonHeightPx-4*borderPx-3, 1.5*buttonWidthPx, buttonHeightPx]);
        HFig.refParticles5Nm = uicontrol('Style', 'checkbox', 'String', '5Nm', ...
            'Position', [3*borderPx+2.5*buttonWidthPx, figureHeightPx-4*buttonHeightPx-4*borderPx, buttonWidthPx, buttonHeightPx]);
        HFig.refParticles2_5Nm = uicontrol('Style', 'checkbox', 'String', '2.5Nm', 'Horizontalalignment','right', ...
            'Position', [2*borderPx+1.5*buttonWidthPx, figureHeightPx-4*buttonHeightPx-4*borderPx, buttonWidthPx, buttonHeightPx]);           

        HFig.numSimulationsLabel = uicontrol('Style', 'Text', 'String', 'Number of simulations','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [figureWidthPx-3*buttonWidthPx-4*borderPx, figureHeightPx-4*buttonHeightPx-4*borderPx-3, 2.5*buttonWidthPx, buttonHeightPx]);   
        HFig.numSimulationsText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', '100','HorizontalAlignment','left','backgroundcolor','white',...
            'Position', [figureWidthPx-1.5*buttonWidthPx-2*borderPx, figureHeightPx-4*buttonHeightPx-4*borderPx, 0.5*buttonWidthPx, buttonHeightPx]);        
        HFig.simButton = uicontrol('Style', 'pushbutton', 'String', 'Simulate', 'Callback',@simulate, ...
            'Position', [figureWidthPx-1*buttonWidthPx-1*borderPx, figureHeightPx-4*buttonHeightPx-4*borderPx, buttonWidthPx, buttonHeightPx]);
    
        HFig.tagText = uicontrol('Style', 'Edit', 'Enable', 'On', 'String', 'TAG:','HorizontalAlignment','left','backgroundcolor','white','Max',5,...
            'Position', [borderPx, buttonHeightPx+2*borderPx, figureWidthPx-2*borderPx, textHeightPx]);
        
        HFig.okButton = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Callback',@ok, ...
            'Position', [figureWidthPx-1*buttonWidthPx-1*borderPx borderPx, buttonWidthPx, buttonHeightPx]);
        HFig.saveButton = uicontrol('Style', 'pushbutton', 'String', 'Save','Callback',@cancel, ...
            'Position', [figureWidthPx-2*buttonWidthPx-2*borderPx borderPx, buttonWidthPx, buttonHeightPx]);        

        setFonts(HFig);
        
    end

end

