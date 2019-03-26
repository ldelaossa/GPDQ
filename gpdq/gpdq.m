%% GPDQ Calls the main application.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)


function gpdq(screenSize, projectFileName)
    
    if nargin<1
        screenSize=0.8;
    end
    if nargin<2
        projectFileName = [];
    end

    % Calls the main application (figure 8% of the screen). 
    gpdqGUI(screenSize, projectFileName)
end
