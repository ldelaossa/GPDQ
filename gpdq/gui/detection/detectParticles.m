%%
%
% Usage
% -----
%
%       
%
% Example
% -------
%
%       
%
% Parameters
% ----------
%
%   
%
%
% Returns
% -------
% 
%
% To do
% -------
%
% Test parameter values (edits) and accept section names as parameters.
% documentation.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function [pCenters, pActRadii, pRadii] = detectParticles(image, mask, scale, margin, sensitivity)
    global config;
    % Avoids multiple openings of the figure.
    windowDetectParticles = findobj('type', 'figure', 'tag', 'detectParticles');
    if ~isempty(windowDetectParticles)
        GPDQStatus.repError('Another instance of createSection is already open. It must be closed first', true, dbstack());
        figure(windowDetectParticles);
        return;
    end
    
    %% Builds the figure 
    HFig = detectParticlesFig(image, mask);
    
    % Name of the figure
    set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version '. Detect particles']);
    set(HFig.marginEdit,'String',num2str(margin));
    set(HFig.sensEdit,'String',num2str(sensitivity));
   
    % Callbacks
    set(HFig.cancelButton,'Callback', @cancel);
    set(HFig.mainFigure,'CloseRequestFcn',@cancel);
    set(HFig.detectButton,'Callback',@detect);
    set(HFig.okButton,'Callback', @save);    
    
    % Results
    pCenters = [];
    pActRadii = [];
    pRadii = [];
    marks = [];

    % Returns when the figure is closed.
    waitfor(HFig.mainFigure);  
    
    
    %% Functions    
  
% Function cancel
    % Closes the window and returns []
    function cancel(~,~)
        pCenters = GPDQStatus.CANCELED;
        pActRadii = [];    
        pRadii = [];
        delete(HFig.mainFigure);
    end    

% Function detect
    % Closes the window and returns []
    function detect(~,~)
        for m=1:numel(marks)
            delete(marks(m));
        end
        marks = [];
        pause(0.5);
        margin = str2double(get(HFig.marginEdit,'String'));
        sensitivity = str2double(get(HFig.sensEdit,'String'));
        maskedImage = image;
        maskedImage(~mask) = 2^16-1;
        [pCenters, pActRadii] = detectParticles10Nm(maskedImage, scale, margin, sensitivity, 0.5);
        pRadii = 5*ones(size(pActRadii));
        marks = markPoints(pCenters/scale, 5/scale, '-', 1, 'red', false);
    end    

% Closes the window and returns []
    function save(~,~)     
        delete(HFig.mainFigure);
    end    

end

