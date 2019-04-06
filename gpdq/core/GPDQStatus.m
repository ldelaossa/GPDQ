%% Basic logger that allows managing messages and status. 

% Author: Luis de la Ossa (luis.delaossa@uclm.es).

classdef GPDQStatus
    
    properties (Constant)
        ERROR = 'GPDQ: Error';        % Code for error in operation
        SUCCESS = 'GPDQ: Success';    % Code for success in operation
        CANCELED = 'GPDQ: Canceled';  % Code for operation canceled.
        WARNING = 'GPDQ: Warning';   % Code for operation canceled.
    end
    
    methods(Static)
        function repSuccess(message)
            %% Reports success in an operation. To be used only when success must be reported to the user. 
            %
            % Parameters:
            %   message: Message to be shown.
            global config;   
            message = ['SUCCESS: ' message];
            uiwait(msgbox(message, ['GPDQ ' config.version], 'none', 'modal', 'FontSize', config.fontSize));     
            % Adds the message to the log
            GPDQStatus.log(message)
        end
        
        function repError(message, show, dataFunction)
            %% Reports an error. 
            % 
            % Parameters:
            %   message: Message to be shown. 
            global config; 
            message = ['ERROR: ' message];
            if show
                uiwait(msgbox(message,  ['GPDQ ' config.version], 'error', 'modal', 'FontSize', config.fontSize));
            end
            % Adds the message to the log
            if nargin==3
                GPDQStatus.log(message, dataFunction)
            else
                GPDQStatus.log(message)
            end            
        end
        
        function repWarning(message, show, dataFunction)
            %% Reports warning in an operation. 
            %
            % Parameters:
            %   message: Message to be shown.  
            global config;    
            message = ['WARNING: ' message];
            if show
                uiwait(msgbox(message, ['GPDQ ' config.version], 'warn', 'modal', 'FontSize', config.fontSize));
            end
            % Adds the message to the log
            if nargin==3
                GPDQStatus.log(message, dataFunction)
            else
                GPDQStatus.log(message)
            end    
        end        
          
        function log(message, dataFunction)
            %% Logs the activity. This is for user, but also for debugging and bug detection. 
            % The message is written in standard error or derived to file config.log.
            % 
            % Parameters:
            %   message: Message to be shown. 
            %   dataFunction: Internal information about the error  
            global config;
            if isempty(config)
                config = GPDQConfig.load();
            end
            
            % Writes the line in log file if possible.
            if config.logFile~=-1
                if nargin==2
                    fprintf(config.logFile,'\n%s \t %s: %s %s (%d)', datestr(now,'HH:MM:SS'), message, dataFunction.file, dataFunction.name, dataFunction.line);
                else
                    fprintf(config.logFile, '\n%s \t %s', datestr(now,'HH:MM:SS'), message);
                end
            end
            % Shows the error if configured
            if config.showErrorLog  
                fprintf(2, '%s \t %s\n', datestr(now,'HH:MM:SS'), message);
            end
        end
        
        function result = isError(value)
            %% Tests whether a value corresponds to an error
            %if isscalar(value) && ~isobject(value) && strcmp(value, GPDQStatus.ERROR)
            if strcmp(value, GPDQStatus.ERROR)
                result = true;
            else
                result = false;
            end
        end        
        
        function result = isSuccess(value)
            %% Tests whether a value corresponds to success
            if strcmp(value, GPDQStatus.SUCCESS)
                result = true;
            else
                result = false;
            end
        end   
        
       function result = isCanceled(value)
            %% Tests whether a value corresponds to operation cancelled
            if strcmp(value, GPDQStatus.CANCELED)
                result = true;
            else
                result = false;
            end
        end  
    end
end

