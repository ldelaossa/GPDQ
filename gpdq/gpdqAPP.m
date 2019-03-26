%% GPDQAPP Calls the main application.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)


function gpdqAPP()
    
    global config;
    config = GPDQConfig.load();

    gpdqGUI(0.8, [])
end


