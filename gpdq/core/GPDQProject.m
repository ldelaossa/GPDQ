%% GPDQProject Allows managing projects. 
%
% Projects are stored in folders and consist of:
%
%       - The .csv file with the data describing each section: file of the image, number of section, group, and scale. 
%       - The images and sections in some format ('tif','jpg', etc).
%       - The csv files with the informations about the particles of each section.
% 
% This class represents a project. Stores its definition and data, and allows 
% reading, writing, manipulating and accessing to its information. 

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

classdef GPDQProject %< handle
   
    properties
        workingDirectory                    % Directory where the project is located. 
        fileName                            % Name of the project   
        data                                % Cell array with the data of each section.
    end
    
    methods(Static)
        function pr = readFromFile(workingDirectory, fileName)
            %% Reads the project from a csv file and creates the object.
            %
            % Parameters
            %   workingDirectory: Directory containing the files.
            %   fileName: File containing the description of the project. 
            %
            % Returns:
            %   pr: The object containing the project, or GPDQStatus.ERROR in case
            %   of error. 
            try
                % Reads the project as a table.
                projectTable = readtable(fullfile(workingDirectory,fileName), 'Delimiter',';','ReadVariableNames',false,'Format','%s%u%s%f');
                % Converts to cell array
                data = table2cell(projectTable);
                % Removes spaces
                data(:,1)=strtrim(data(:,1));
                data(:,3)=strtrim(data(:,3));
                % Changes 0's or NaN By [];
                data(cellfun(@(c)(isequal(c,0)), data(:,2)),2)={[]};
                data(cellfun(@isnan, data(:,4)),4)={[]};
                % If it has been possible to read the data, creates the object
                pr = GPDQProject();
                pr.workingDirectory = workingDirectory;
                pr.fileName = fileName;
                pr.data = data;
            catch
                % If there has been an error, shows it and returns the code.
                GPDQStatus.repError(['There has been a problem when reading the project: '  fileName], false, dbstack());
                pr = GPDQStatus.ERROR;
            end             
        end
    end
    
    methods      
        
        function result = save(self)
        %% Saves the project into a csv file
        % 
        %  Returns:
        %   result: The result of the operation, that can be either
        %   GPDQStatus.ERROR or GPDQStatus.SUCESS.
        
            % The project must have a name.
            if isempty(self.fileName)
                GPDQStatus.repError('The name of the project is empty, and can not be saved.', false, dbstack());
                result = GPDQStatus.ERROR;
                return;
            end
            % Gets the full file name 
            fullFileName = fullfile (self.workingDirectory, self.fileName);
            try
                % Opens the file
                file = fopen(fullFileName,'w');
                % Number of rows.
                numRows = size(self.data,1);
                % Writes each row
                for row=1:numRows
                    fprintf(file,'%s ;', self.data{row,1});
                    if ~isempty(self.data{row,2})
                        fprintf(file,'%d',self.data{row,2});
                    end
                    fprintf(file,' ;');
                    fprintf(file, '%s ;', self.data{row,3});
                    if ~isempty(self.data{row,4})
                        fprintf(file, '%.4f', self.data{row,4});
                    end
                    fprintf(file,' \n');
                end
                % Closes the file
                fclose(file);
                result = GPDQStatus.SUCCESS;
            catch
                Staturs.repError(['There has been a problem when writing the project '  fullFileName], true, dbstack());
                result = GPDQStatus.ERROR;
            end
        end
    
        function result = removeSection(self, idSection)
            %% Removes a section on the current project given its id (position).
            %  Parameters:
            %   idSection: id (position) of the section to be removed. 
            %  
            %  Returns:
            %   result: The result of the operation, that can be either
            %   GPDQStatus.ERROR or GPDQStatus.SUCESS.
        
           % Test the valid range
            if ~self.checkIdSection(idSection)
                result = GPDQStatus.ERROR;
                return;
            end    
            self.data(idSection,:)=[];
            result = GPDQStatus.SUCCESS;
        end    
        
        function result = addSection(self, image, section, group, scale)
            %% Appends section
            %  Parameters:
            %   image: Name of the image containing the section.
            %   section: id of the section. 
            %   group: Name of the group the section belongs to. 
            %   scale: Scale of the image. 
            %  
            %  Returns:
            %   result: The result of the operation, that can be either
            %   GPDQStatus.ERROR or GPDQStatus.SUCESS.

            % At least the name of the image must be provided.
            if nargin<2
                GPDQStatus.repError('At least the name of the image must be provided.' ,false, dbstack());
                result = GPDQStatus.ERROR;
                return;
            end
            if nargin<3
                section = [];
            end
            if nargin<4
                group = [];
            end
            if nargin<5
                scale = [];
            end
            %  Both the image and the section must be provided. 
            %  First of all, test that image and section does not exist.
            for idSection=1:self.numSections
                if strcmp(image,self.data{idSection,1}) && (~isempty(section) && section==self.data{idSection,2})
                        GPDQStatus.repError(['Section ' image ' #' num2str(section) ' already exists.'] ,false, dbstack());
                        result = GPDQStatus.ERROR;
                        return;
                end
            end
            % Creates the entry.
            self.data{self.numSections+1,1} = image;
            self.data{self.numSections,2} = section;
            self.data{self.numSections,3} = group;
            self.data{self.numSections,4} = scale;
            result = GPDQStatus.SUCCESS;
        end        
        
        function image = imageSection(self, idSection)
            %% Returns the image in the section #idSection or GPDQStatus.ERROR in case of error. 
            %  Parameters:
            %       idSection: id (position) of the section to be removed. 
            %  
            %  Returns:
            %       image: The image corresponding to the section, or
            %       GPDQStatus.ERROR.
        
            % Test the valid range
            if ~self.checkIdSection(idSection)
                image = GPDQStatus.ERROR;
                return;
            end     
            % Full name of the image.
            fullImageName = fullfile(self.workingDirectory,self.data{idSection,1});  
            % Reads the image
            try
                image = readImage(fullImageName);
            catch
                image = GPDQStatus.ERROR;
            end
        end
        
        function particles = particlesSection(self, idSection)  
            %% Returns the data for the section #idSection or GPDQStatus.ERROR in case of error
            %  Parameters:
            %       idSection: id (position) of the section
            %  
            %  Returns:
            %       particles: An array with the data corresponding to the
            %       particles in the section, or GPDQStatus.ERROR.
        
            % Test the valid range
            if ~self.checkIdSection(idSection)
                particles = GPDQStatus.ERROR;
                return;
            end   
            % Full name of the file with the particles of the section
            secDataFileName = secDataFile(fullfile(self.workingDirectory,self.data{idSection,1}),self.data{idSection,2});              
            % Reads the particles
            try 
                particles = readCSV(secDataFileName);
            catch
                particles = GPDQStatus.ERROR;
            end
        end        
        
        function mask = maskSection(self, idSection)
            %% Returns the mask for the section #idSection or or GPDQStatus.ERROR in case of error
            %  Parameters:
            %       idSection: id (position) of the section
            %  
            %  Returns:
            %       mask: The image with the mask of the section, or GPDQStatus.ERROR.
        
            % Test the valid range
            if ~self.checkIdSection(idSection)
                mask = GPDQStatus.ERROR;
                return;
            end   
            % Full name of the image with the section
            maskImageName = secImageFile(fullfile(self.workingDirectory,self.data{idSection,1}),self.data{idSection,2});  
            % Reads the image
            maskImage = readImage(maskImageName);
            % Returns the mask.
            try
                mask = getSectionMask(maskImage);
            catch
                mask = GPDQStatus.ERROR;
            end
        end
        
        function num = numSections(self)
         %% Returns the number of sections in the project.

            num = size(self.data,1);
        end
        
        function imageSize = imageSize(self, idSection)
            %% Returns the size of the images
            % (In this state of develpment, all images in the project have the same size). 
            %  Parameters:
            %       idSection: id (position) of the section
            %  
            %  Returns:
            %       imageSize: The image with the mask of the section, or GPDQStatus.ERROR. 
            % Test the valid range
            if ~self.checkIdSection(idSection)
                imageSize = GPDQStatus.ERROR;
                return;
            end             
             imageSize = size(imageSection(self,idSection));
        end


        function sectionData = getFullSectionData(self, idSection)
            %% Returns all the information of a section as a struct that 
            % includes the image and mask. 
            %
            %  Parameters:
            %       idSection: id (position) of the section
            %  
            %  Returns:
            %     sectionData: An structure with all the data corresponding to
            %     a section. In case of error, returns GPDQStatus.ERROR.
            % 
            %     sectionData.valid                 Whether the data is valid (complete)
            %     sectionData.imageFile             Name of the file containing the image
            %     sectionData.section               Identifier of the section (and so the file containing it)   
            %     sectionData.group                 Identifier of the group
            %     sectionData.scale                 Scale of the image (Nm/pixels)
            %
            %     sectionImageFilePath              Path to the file containing the image    
            %     sectionMaskFilePath               Path to the file containing the section
            %     sectionDataFilePath               Path to the file containing the particles   
            %
            %     sectionData.image                 Image                        
            %     sectionData.mask                  Boolean mask with the section                           
            %     sectionData.particles             Matrix with the coordinates, radii and teorethical radii of each particle.  
            %
            %     sectionData.area                  Area of the section in (Sq. Micra)
        
            % Test that the image is in the valid range
            if ~self.checkIdSection(idSection)
                sectionData = GPDQStatus.ERROR;
                return;
            end                  
            % Stores the section and the names of the associated files.
            sectionData.imageFile = self.data{idSection,1};
            sectionData.section = self.data{idSection,2};       
            sectionData.group = self.data{idSection,3};
            sectionData.scale = self.data{idSection,4};     
            
            % If the name of the image is empty, the image is directly ignored. 
            if isempty(sectionData.imageFile)
                GPDQStatus.repError('The name of the image is empty.', false, dbstack());   
                sectionData = GPDQStatus.ERROR;
                return;
            end    
            
            % Gets the path to the image and checks if it exist. If not, the section is ignored.
            sectionImageFilePath = fullfile(self.workingDirectory, sectionData.imageFile);  
            if ~exist(sectionImageFilePath, 'file')
                GPDQStatus.repError(['The file with the image' sectionImageFilePath 'does not exist'], false, dbstack());   
                sectionData = GPDQStatus.ERROR;                
                return;       
            end       
            
            % Reads the image. If the image can not be read, it returns error.  
            sectionData.image = readImage(sectionImageFilePath);
            if GPDQStatus.isError(sectionData.image)
                GPDQStatus.repError(['Error opening the image ' sectionImageFilePath], false, dbstack());   
                sectionData = GPDQStatus.ERROR;
                return;    
            end       
            
            % Gets the path to the files with the mask of the section and the information of the particles.
            % If there is no section, it is reported, and the section and particle files remain empty.
            if ~isempty(sectionData.section)
                sectionMaskFilePath = secImageFile(sectionImageFilePath, sectionData.section);
                sectionDataFilePath = [sectionMaskFilePath(1:end-3) 'csv'];
            else
                GPDQStatus.repError(['The section id is empty for section' num2str(sectionData.section) ' of image ' sectionData.imageFile], false, dbstack());  
                sectionData = GPDQStatus.ERROR;
                return;
            end    
            
            % Gets the image of interest and the section. If the file for the section does not exist, uses the whole image.
            % Extracts the mask and returns the area.
            if exist(sectionMaskFilePath,'file') && (~isempty(sectionMaskFilePath))
                % Gets the mask and its area
                 sectionData.mask = getSectionMask(readImage(sectionMaskFilePath));  
                 sectionData.area = areaSection(sectionData.mask, sectionData.scale, true);
            else
                sectionData.mask = getSectionMask(readImage(sectionImageFilePath)); 
                sectionData.area = areaSection(sectionData.mask, sectionData.scale, false);
                % If the problem is a missing file, reports it. Any other problem is reported inside getSection.
                if ~isempty(sectionMaskFilePath)
                    GPDQStatus.repError(['The section file ' sectionMaskFilePath ' does not exist (using the whole image).'], false, dbstack());   
                end
            end     
            
            % Reads the information about particles.
            if exist(sectionDataFilePath,'file')
                try
                    sectionData.particles = readCSV(sectionDataFilePath);
                    % Validity is only asserted at this point.
                    if ~isempty(sectionData.scale)
                        sectionData.valid = true;
                    else
                        sectionData.valid = false;
                    end
                catch
                    GPDQStatus.repError(['The format of the file ' sectionDataFilePath ' is not valid.'], false, dbstack());
                    sectionData.particles = []; 
                end
            else
                if ~isempty(sectionDataFilePath)                    
                    GPDQStatus.repError([sectionDataFilePath ' does not exist.'], false, dbstack());
                    sectionData.particles = []; 
                end
            end                        
        end % getSectionData    
        
        function projectData = getProjectData(self, onlyValid)
            %% Returns a cell array with all the data of the project. It
            %  does NOT include images and masks. If the data of a section
            %  is not valid, it can be ignored. 
            %
            %  Parameters:
            %       onlyValid: if True, ignores sections marked as non valid.
            %  
            %  Returns:
            %     projectData: A cell array of structures with all the data
            %     corresponding to the project. For each section returns:
            % 
            %     projectData{idSection}.valid                 Whether the data is valid (complete)
            %     projectData{idSection}.imageFile             Name of the file containing the image
            %     projectData{idSection}.section               Identifier of the section~ (and so the file containing it)   
            %     projectData{idSection}.group                 Identifier of the group
            %     projectData{idSection}.scale                 Scale of the image (Nm/pixels)
            %     projectData{idSection}.area                  Area of the section in (Sq. Micra)                       
            %     projectData{idSection}.particles             Matrix with the coordinates, radii and teorethical radii of each particle.  
            %
            %  In case of error, returns GPDQStatus.ERROR.
            
            % By default, discards non valid data.
            if nargin<2
                onlyValid = true;
            end
            
            for idSection=1:size(self.data,1)
                % Reads data of the section
                sectionData = getFullSectionData(self,idSection);
                % Discards non valid
                projectData(idSection).valid = sectionData.valid;
                if onlyValid && ~projectData(idSection).valid
                    continue;
                end
                
                projectData(idSection).idSection = idSection;
                projectData(idSection).imageFile = sectionData.imageFile;
                projectData(idSection).section = sectionData.section;
                projectData(idSection).group = sectionData.group;
                projectData(idSection).scale = sectionData.scale;
                projectData(idSection).area = sectionData.area;
                projectData(idSection).particles = sectionData.particles;
            end
        end % projectData

        function report = getProjectReport(self)
            %% Returns a GPDQReport with fields:
            % Image, section, group, scale, area, radius, particles.
            
            % Lenght of the project
            projectData = getProjectData(self);
            numSections = length(projectData);
            % Types of particles    
            global config;
            numParticleTypes = numel(config.particleTypes);

            repData = cell(numSections*numParticleTypes, 8);
            for auxIdSection=1:numSections
                particles = projectData(auxIdSection).particles;
                for idParticleType=1:numParticleTypes
                    row = numParticleTypes*(auxIdSection-1)+idParticleType;
                    radius = config.particleTypes(idParticleType).radius;
                    repData{row, 1} = projectData(auxIdSection).idSection;
                    repData{row, 2} = projectData(auxIdSection).imageFile;
                    repData{row, 3} = projectData(auxIdSection).section;
                    repData{row, 4} = projectData(auxIdSection).group;
                    repData{row, 5} = projectData(auxIdSection).scale;
                    repData{row, 6} = projectData(auxIdSection).area;
                    repData{row, 7} = config.particleTypes(idParticleType).radius;
                    repData{row, 8} = size(particles(particles(:,4)==radius,:),1);
                end
            end
                        
            % Creates the report.               
            columns = {'ID SECTION', 'IMAGE', 'SECTION', 'GROUP', 'SCALE', 'AREA', 'RADIUS','#PARTICLES'};
            format = {'%d', '%s', '%d', '%s', '%.4f', '%.6f', '%.1f', '%d'};
            report = GPDQReport(columns, format, repData);
        end
        
        function report = getParticleReport(self, includeAllData)
            %% Returns a GPDQReport with information about particles.
            % Each row corresponds to a particle and includes:
            % ID, x, y, actual radius, radius
            % 
            % It is possible to include all information with argument includeAllData=True;
            %
            % ID, Image, section, group, scale, area, x, y, actual radius, radius
            
            if nargin<1
                includeAllData=false;
            end
            
            % Lenght of the project
            projectData = getProjectData(self);
            numSections = length(projectData);
            numParticles = size(cat(1, projectData.particles),1);

            % Allocates space
            if includeAllData
                repData = cell(numParticles, 10);
            else
                repData = cell(numParticles, 5);
            end
                
            row = 1;
            for auxIdSection=1:numSections
                particles = projectData(auxIdSection).particles;
                for idParticle=1:size(particles,1)
                    repData{row, 1} = projectData(auxIdSection).idSection;
                    if includeAllData
                        repData{row, 2} = projectData(auxIdSection).imageFile;
                        repData{row, 3} = projectData(auxIdSection).section;
                        repData{row, 4} = projectData(auxIdSection).group;
                        repData{row, 5} = projectData(auxIdSection).scale;
                        repData{row, 6} = projectData(auxIdSection).area;
                        repData{row, 7} = projectData(auxIdSection).particles(idParticle,1);
                        repData{row, 8} = projectData(auxIdSection).particles(idParticle,2);
                        repData{row, 9} = projectData(auxIdSection).particles(idParticle,3);
                        repData{row, 10} = projectData(auxIdSection).particles(idParticle,4);                                                
                    else
                        repData{row, 2} = projectData(auxIdSection).particles(idParticle,1);
                        repData{row, 3} = projectData(auxIdSection).particles(idParticle,2);
                        repData{row, 4} = projectData(auxIdSection).particles(idParticle,3);
                        repData{row, 5} = projectData(auxIdSection).particles(idParticle,4); 
                    end
                    row=row+1;
                end
            end
                        
            % Creates the report.  
            if includeAllData
                columns = {'ID SECTION', 'IMAGE', 'SECTION', 'GROUP', 'SCALE', 'AREA', 'X','Y','ACT. RADIUS','RADIUS'};
                format = {'%d', '%s', '%d', '%s', '%.4f', '%.6f', '%.3f', '%.3f', '%.1f', '%.1f'};
            else
                columns = {'ID SECTION', 'X','Y','ACT. RADIUS','RADIUS'};
                format = {'%d', '%.3f', '%.3f', '%.1f', '%.1f'}; 
            end
            
            report = GPDQReport(columns, format, repData);
        end
    end  % methods
    
    
    methods(Access=private)
    %% Checks if the id of the section is correc (is in range). 
        function ok = checkIdSection(self, idSection)
            if idSection<0 || idSection>size(self.data,1)
                GPDQStatus.repError(['Trying to access section #'  num2str(idSection) '. Use [1,' num2str(size(self.data,1)) '].'], false, dbstack());
                ok = false;
                return;
            else
                ok = true;
            end
        end
    end    
end