%% GPDQCONFIG Stores some configuration parameters of the application
%
% Allows saving and storing those parameters. 

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

classdef GPDQConfig < handle
    
    properties (Constant)
        version = '1.0.0'           % Software version.
    end
    
    properties       
        % Can be configured
        imageType                   % Type of the images.  
        particleTypes               % Type and color of the images. Struct array with fields: radius, color  
        showErrorLog                % If true, shows the error log. 
        
        % Configured at startup
        fontSize                    % Font size for the elements in the GUI.
        logFile                     % Log file
    end
    
    methods 
        function save(obj) 
            %% Saves the configuration as a struct  
            config.imageType = obj.imageType;
            config.particleTypes = obj.particleTypes;
            config.showErrorLog = obj.showErrorLog;
            save('core/config.mat', 'config');
        end
        
        function obj = showLog(obj, showErrorLog)
            %% Whether to show error log by standard error 
            obj.showErrorLog = showErrorLog;
        end
    end
    
    methods(Static)
        function currentcfg = load() 
            %% Loads the configuration from core/config.mat and sets some parameters
           
            % Loads
            load('core/config.mat');                  % Loads into struct named config.
            currentcfg = GPDQConfig;                  % Creates the object
            currentcfg.particleTypes = config.particleTypes;
            currentcfg.imageType = config.imageType;
            currentcfg.showErrorLog = config.showErrorLog;
            
            % Font size
            if ismac
                currentcfg.fontSize = 14;
            elseif isunix
                currentcfg.fontSize = 12;
            elseif ispc
                currentcfg.fontSize = 12;
            end
    
            % Log file
            currentcfg.logFile = fopen(fullfile('log',[datestr(now,'dd-mm-yyyy-HH:MM') '.log']),'wt+');
        end
    end
    
end

