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
        parallelCompute             % Whether there is parallel computation or nog. 
        
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
        function currentConfig = load() 
            %% Loads the configuration from core/config.mat and sets some parameters
          
            try
                % Loads
                load('core/config.mat');                  % Loads into struct named config.
                currentConfig = GPDQConfig;                  % Creates the object
                currentConfig.particleTypes = config.particleTypes;
                currentConfig.imageType = config.imageType;
                currentConfig.showErrorLog = config.showErrorLog;
            catch
                %Default values
                currentConfig = GPDQConfig;
                currentConfig.imageType = '*.tif';
                currentConfig.showErrorLog = true;               
                currentConfig.particleTypes(1).diameter=5;
                currentConfig.particleTypes(1).radius=2.5;
                currentConfig.particleTypes(1).color='blue';
                currentConfig.particleTypes(2).diameter=10;
                currentConfig.particleTypes(2).radius=5;
                currentConfig.particleTypes(2).color='red';       
                currentConfig.particleTypes(3).diameter=0;
                currentConfig.particleTypes(3).radius=0;
                currentConfig.particleTypes(3).color='yellow'; 
                GPDQStatus.repWarning('Unable to read config file. Using default settintgs.', true, dbstack());
            end
            
            % Font size
            if ismac
                currentConfig.fontSize = 12;
            elseif isunix
                currentConfig.fontSize = 12;
            elseif ispc
                currentConfig.fontSize = 8;
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
            currentConfig.logFile = fopen(logFileName,'wt+');
            if currentConfig.logFile==-1
                fprintf(2, 'Unable to create log file: (%s).\nSet config.showErrorLog=True to show errors.\n', logFileName);
            end
            
            % Whether there is parallel computation available or not
            verML = ver;
            if any(strcmp('Parallel Computing Toolbox', {verML.Name}))
                currentConfig.parallelCompute = true;
            else
                currentConfig.parallelCompute = false;
            end
        end % config = load()  
        
    end % methods(Static)
end
    


