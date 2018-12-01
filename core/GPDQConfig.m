%% GPDQCONFIG Stores some configuration parameters of the application
%
% Allows saving and storing those parameters. 
%
classdef GPDQConfig
    
    properties (Constant)
        version = '1.0.0'           % Software version.
    end
    
    properties                               
        imageType                   % Type of the images.  
        showErrorLog                % Whether to show error logs.         
        particleTypes               % Type and color of the images. Struct array with fields: radius, color   
        fontSize                    % Font size for the elements in the GUI
    end
    
    methods 
        function save(obj) 
            %% Saves the configuration as a struct  
            config.imageType = obj.imageType;
            config.particleTypes = obj.particleTypes;
            config.showErrorLog = obj.showErrorLog;
            config.fontSize = obj.fontSize;
            save(fileName, 'config');
        end
    end
    
    methods(Static)
        function currentcfg = load() 
            %% Loads the configuration from config.mat
            load('core/config.mat');     % Loads into struct named config.
            currentcfg = GPDQConfig;                % Creates the object
            currentcfg.particleTypes = config.particleTypes;
            currentcfg.imageType = config.imageType;
            currentcfg.showErrorLog = config.showErrorLog;
            currentcfg.fontSize = config.fontSize;
        end
    end
    
end

