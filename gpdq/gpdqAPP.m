%% GPDQAPP Calls the main application.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)


function gpdqAPP()
    warning('off','all');
    global config;
    config = GPDQConfig.load();
    
    % Loads prediction models
    global model10Nm
    load('model10Nm.mat');

    gpdqGUI(0.8, [])
    
    
end


