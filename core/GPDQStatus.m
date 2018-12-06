%% Status Logger that allows managing messages of status at several levels. 

% Author: Luis de la Ossa (luis.delaossa@uclm.es).

classdef GPDQStatus
    
    properties (Constant)
        ERROR = java.util.UUID.randomUUID;    % Code for error in operation
        SUCCESS = java.util.UUID.randomUUID;  % Code for success in operation
        CANCELED = java.util.UUID.randomUUID; % Code for operation canceled.
    end
    
    methods(Static)
        function repSuccess(message)
            %% Reports success in an operation. To be used only when success must be reported to the user. 
            %
            % Parameters:
            %   message: Message to be shown.
            global config;            
            uiwait(msgbox(message, ['GPDQ v' config.version], 'modal'));
        end
        
        function repError(message, showDialog, dataFunction)
            %% Reports an error. This is for user, but also for debugging and bug detection. 
            % The error is written in standard output depending on the value of variable config.showErrorLog
            % 
            % Parameters:
            %   message: Message to be shown. 
            %   show: Whether to show the message dialog
            %   dataFunction: Internal information about the error            
            global config;
            % By default, does not show any window.
            if nargin<2
                showDialog = false;
            end            
            % If showErrorLog, reports the error messages by error output. 
            if config.showErrorLog 
                if nargin==3
                    fprintf(2,'* %s: %s %s (%d)\n',  message, dataFunction.file, dataFunction.name, dataFunction.line);
                else
                    fprintf(2,'\t %s\n', message);
                end
            end 
            % Shows the message if required.
            if showDialog
                uiwait(msgbox(message,  ['GPDQ v' config.version], 'error', 'modal', 'FontSize', config.fontSize));
            end
        end
               
        function error = isError(value)
            %% Tests whether a value corresponds to an error
            if isscalar(value) && value == GPDQStatus.ERROR
                error = true;
            else
                error = false;
            end
        end        
        
        function success = isSuccess(value)
            %% Tests whether a value corresponds to success
            if isscalar(value) && value == GPDQStatus.SUCCESS
                success = true;
            else
                success = false;
            end
        end   
        
       function success = isCancelled(value)
            %% Tests whether a value corresponds to operation cancelled
            if isscalar(value) && value == GPDQStatus.CANCELLED
                success = true;
            else
                success = false;
            end
        end  
    end
end

