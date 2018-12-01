%% GPDQReport allows creating a report from a bidimensional cell array. 
%
% The report can be either shown in a window, or exported to csv. Allows 
% naming the report, as well as specifying name and format of the columns.

classdef GPDQReport
  
    properties(GetAccess = public, SetAccess=protected)
        columns                         % Name of the columns. Ej. {'ID', 'IMAGE', 'SECTION', 'GROUP', 'SCALE', 'AREA', '#PARTICLES'}
        format                          % Format that must be used to print each column. Ej. {'%d', '%s', '%d', '%s', '%.4f', '%.6f', '%d'}
        data                            % Cell array with the data to be reported. 
    end
        
    properties
    end
    
    methods
         function obj = GPDQReport(columns, format, data)
            %% Creates a report object
            %
            % Parameters
            %   columns: Name of each columns. 
            %   format: Format of each column.
            %   data: Cell array with the data. 
            obj.columns = columns;
            obj.format = format;
            obj.data = data;
         end
         
         function result = save(self, file)
             %% Saves the data in a csv file with the format specified.
             %
             % Parameters
             %   file: Name of the file
             %
             % Returns
             %   result: Result of the operation
             
             % Number of columns.
             numColumns = length(self.columns);
             numEntries = length(self.data);
             
             % Writes the file.
             try
                 file = fopen(file,'w');
                 
                 % Writes the column names in the 
                 for column=1:numColumns-1
                     fprintf(file,' %s ;', self.columns{column});
                 end
                 fprintf(file,' %s\n', self.columns{numColumns});
                 
                 % Writes the entries.
                 for entry=1:numEntries
                     for column=1:numColumns-1
                         fprintf(file, [' ' self.format{column} ' ;'], self.data{entry,column});
                     end
                     fprintf(file, [' ' self.format{numColumns} ' \n'], self.data{entry,numColumns});
                 end
                 % Closes and returns sucess
                 fclose(file);
                 result = GPDQStatus.SUCCESS;
                 
             catch
                 % Closes and returns failure(
                 Status.repError(['printReport: There has been a problem when saving the file '  file], true, dbstack());
                 result = GPDQStatus.ERROR;
             end
         end
    end    
end

