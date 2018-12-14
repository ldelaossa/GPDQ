%% GPDQ Calls the main application.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)


function gpdq()
    % Sets the path.
    setConfig;

    % Activates the log (in case it is not activated).
    %config.showErrorLog = true;

    % Calls the main application (figure 8% of the screen). 
    gpdqGUI(0.8)
end