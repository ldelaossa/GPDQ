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
          
            try
                % Loads
                load('core/config.mat');                  % Loads into struct named config.
                currentcfg = GPDQConfig;                  % Creates the object
                currentcfg.particleTypes = config.particleTypes;
                currentcfg.imageType = config.imageType;
                currentcfg.showErrorLog = config.showErrorLog;
            catch
                %Default values
                currentcfg = GPDQConfig;
                currentcfg.imageType = '*.tif';
                currentcfg.showErrorLog = true;               
                currentcfg.particleTypes(1).diameter=5;
                currentcfg.particleTypes(1).radius=2.5;
                currentcfg.particleTypes(1).color='blue';
                currentcfg.particleTypes(2).diameter=10;
                currentcfg.particleTypes(2).radius=5;
                currentcfg.particleTypes(2).color='red';       
                currentcfg.particleTypes(3).diameter=0;
                currentcfg.particleTypes(3).radius=0;
                currentcfg.particleTypes(3).color='yellow'; 
                GPDQStatus.repWarning('Unable to read config file. Using default settintgs.', true, dbstack());
            end
            
            % Font size
            if ismac
                currentcfg.fontSize = 12;
            elseif isunix
                currentcfg.fontSize = 12;
            elseif ispc
                currentcfg.fontSize = 8;
            end
    
            % Log file
            try
                if ~exist('log_gpdq','dir')
                    mkdir('log_gpdq');
                end
            catch
                % Does nothing here
            end
            logFileName = fullfile('log_gpdq',[datestr(now,'HH MM dd mm yyyy') '.log']);
            currentcfg.logFile = fopen(logFileName,'wt+');
            if currentcfg.logFile==-1
                fprintf(2, 'Unable to create log file: (%s).\nSet config.showErrorLog=True to show errors.\n', logFileName);
            end
        end
    end
    
end

