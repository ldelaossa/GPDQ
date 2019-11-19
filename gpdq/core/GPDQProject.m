%% GPDQProject Allows managing projects.
%
% Projects are stored in folders and consist of:
%
%       - The .csv file with the data describing each section: file of the image, number of section, group, and scale.
%       - The images and sections in some format ('tif','jpg', etc).
%       - The csv files with the informations about the particles of each section.
%
% This class represents project. Stores its definition and data, and allows
% reading, writing, manipulating and accessing to its information. Row data
% are represented in GDDQData objects for efficiency.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

classdef GPDQProject < handle
    
    properties
        workingDirectory                    % Directory where the project is located.
        fileName                            % Name of the project
        data                                % Cell array with the data of each section.
    end

    methods(Static)
        
% readFromFile        
        function project = readFromFile(workingDirectory, fileName)
            %% Reads the project from a csv file and creates the object.
            %
            % Parameters
            %   workingDirectory: Directory containing the files.
            %   fileName: File containing the description of the project.
            %
            % Returns:
            %   pr: The object containing the project, or GPDQStatus.ERROR in case of error.
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
                project = GPDQProject();
                project.workingDirectory = workingDirectory;
                project.fileName = fileName;
                project.data = data;
            catch
                % If there has been an error, shows it and returns the code.
                GPDQStatus.repError(['There has been a problem when reading the project: '  fileName], false, dbstack());
                project = GPDQStatus.ERROR;
            end
        end %  pr = readFromFile(workingDirectory, fileName)
        
    end % methods(Static)
    
    
    methods
        
% addSection       
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
                GPDQStatus.repError('The name of the image is necessary to create a section.', true, dbstack());
                result = GPDQStatus.ERROR;
                return;
            end
            if nargin<3
                section = []; % uint32(0);
            end
            if nargin<4
                group = []; % 'default';
            end
            if nargin<5
                scale = [];
            end
            %  Both the image and the section must be provided.
            %  First of all, test that image and section does not exist.
            for idSection=1:self.numSections
                if strcmp(image,self.data{idSection,1}) && (~isempty(section) && section==self.data{idSection,2})
                    GPDQStatus.repError(['Section ' image ' #' num2str(section) ' already exists.'], true, dbstack());
                    result = GPDQStatus.ERROR;
                    return;
                end
            end
            % Creates the entry.
            self.data{self.numSections+1,1} = image; % Here, it updates the number of sections
            self.data{self.numSections,2} = section;
            self.data{self.numSections,3} = group;
            self.data{self.numSections,4} = scale;
            
            result = GPDQStatus.SUCCESS;
        end % addSection(self, image, section, group, scale)
        
% addSection       
        function result = addSectionPos(self, position, image, section, group, scale)
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
            if nargin<3
                GPDQStatus.repError('The name of the image is necessary to create a section.', true, dbstack());
                result = GPDQStatus.ERROR;
                return;
            end
            if nargin<4
                section = []; % uint32(0);
            end
            if nargin<5
                group = []; % 'default';
            end
            if nargin<6
                scale = [];
            end
            %  Both the image and the section must be provided.
            %  First of all, test that image and section does not exist.
            for idSection=1:self.numSections
                if strcmp(image,self.data{idSection,1}) && (~isempty(section) && section==self.data{idSection,2})
                    GPDQStatus.repError(['Section ' image ' #' num2str(section) ' already exists.'], true, dbstack());
                    result = GPDQStatus.ERROR;
                    return;
                end
            end
            
            % Creates the new section.
            newSection = {image, section, group, scale};
            % Adds it
            if position>self.numSections
                self.data(self.numSections+1,:) = newSection;
            else
                self.data = [self.data(1:position-1,:); newSection;  self.data(position:end,:)];
            end

            
            result = GPDQStatus.SUCCESS;
        end % addSectionPos(self, image, section, group, scale)
              
        
% existsSection
        function result = existsSection(self, image, section)
            % Only considers sections with image name and number
            valid = ~cellfun(@isempty,self.data(:,2));
            valid = valid & (~cellfun(@isempty,self.data(:,1)));
            % First detect those with the same image name. 
            withImage = strcmp(self.data(:,1), image);
            
            withImage = withImage & valid;
            % There is no image with this name
            if isempty(withImage)
                result = false;
                return;
            end
            % If the image is present, looks for the section
            
            withSection = sum(cell2mat(self.data(withImage,2))==section);
            if withSection==0
                result = false;
            else
                result = true;
            end            
        end
        
% getProjectData        
        function projectData = getProjectData(self)
            %% Returns a GPDQData object or GPDQStatus.ERROR in case of error
            %
            %  Returns:
            %       projectData: GPDQData object or GPDQStatus.ERROR.    
            
            projectData = GPDQData(self, [], 'tag', 'Full project data');
        end % projectData = getData(self)
        
% getSectionData        
        function sectionData = getSectionData(self, idSection)
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
            %     sectionData.imageFilePath              Path to the file containing the image
            %     sectionData.maskFilePath               Path to the file containing the section
            %     sectionData.dataFilePath               Path to the file containing the particles
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
            sectionData.imageFilePath = fullfile(self.workingDirectory, sectionData.imageFile);
            if ~exist(sectionData.imageFilePath, 'file')
                GPDQStatus.repError(['The file with the image' sectionData.imageFilePath 'does not exist'], false, dbstack());
                sectionData = GPDQStatus.ERROR;
                return;
            end
            
            % Reads the image. If the image can not be read, it returns error.
            sectionData.image = readImage(sectionData.imageFilePath);
            if GPDQStatus.isError(sectionData.image)
                GPDQStatus.repError(['Error opening the image ' sectionData.imageFilePath], false, dbstack());
                sectionData = GPDQStatus.ERROR;
                return;
            end
            
            % Gets the path to the files with the mask of the section and the information of the particles.
            % If there is no section, it is reported, and the section and particle files remain empty.
            if ~isempty(sectionData.section)
                sectionData.maskFilePath = secImageFile(sectionData.imageFilePath, sectionData.section);
                sectionData.dataFilePath = [sectionData.maskFilePath(1:end-3) 'csv'];
            else
                GPDQStatus.repError(['The section id is empty for section' num2str(sectionData.section) ' of image ' sectionData.imageFile], false, dbstack());
                sectionData = GPDQStatus.ERROR;
                return;
            end
            
            % Gets the image of interest and the section. If the file for the section does not exist, uses the whole image.
            % Extracts the mask and returns the area.
            if exist(sectionData.maskFilePath,'file') && (~isempty(sectionData.maskFilePath))
                % Gets the mask and its area
                sectionData.mask = getSectionMask(readImage(sectionData.maskFilePath));
                sectionData.area = areaSection(sectionData.mask, sectionData.scale);
            else
                sectionData.mask = getSectionMask(readImage(sectionData.imageFilePath));
                sectionData.area = areaSection(sectionData.mask, sectionData.scale);
                % If the problem is a missing file, reports it. Any other problem is reported inside getSection.
                if ~isempty(sectionData.maskFilePath)
                    GPDQStatus.repWarning(['The section file ' sectionData.maskFilePath ' does not exist (using the whole image).'], false, dbstack());
                end
            end
            
            % Reads the information about particles.
            if exist(sectionData.dataFilePath,'file')
                sectionData.particles = readCSV(sectionData.dataFilePath);
                % If there is a mistake, reports.
                if GPDQStatus.isError(sectionData.particles)
                    GPDQStatus.repError(['The format of the file ' sectionData.dataFilePath ' is not valid or it is empty.'], false, dbstack());
                    sectionData.particles = [];
                end
            else
                if ~isempty(sectionData.dataFilePath)
                    GPDQStatus.repWarning([sectionData.dataFilePath ' does not exist.'], false, dbstack());
                    sectionData.particles = [];
                end
            end
            
            % Validity is only asserted at this point.
            if ~isempty(sectionData.scale)
                sectionData.valid = true;
            else
                sectionData.valid = false;
            end
        end % getSectionData(self, idSection)
        
% groups        
        function groups = groups(self)
            %% Returns a list with the groups.
            groups = unique(self.data(:,3)');
            % Discards empty
            groups = groups(~cellfun('isempty',groups));
        end % groups = groups(self)

%% Returns whether a section is complete or not
    function complete = isComplete(self,idSection)
        if ~self.checkIdSection(idSection)
            complete = GPDQStatus.ERROR;
            return;
        end
        for field=1:4
            if isempty(self.data{idSection,field})
                complete = false;
                return;
            end
        end
        complete = true;
    end
    
% imageSize        
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
            imageSize = size(sectionImage(self,idSection));
        end % imageSize = imageSize(self, idSection)
                
% numSections        
        function num = numSections(self)
            %% Returns the number of sections in the project.
            num = size(self.data,1);
        end % num = numSections(self)
                
% removeSection        
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
                GPDQStatus.repError(['Section #' num2str(idSection) ' does not exist.'], false, dbstack());
                result = GPDQStatus.ERROR;
                return;
            end
            % Deletes the section
            self.data(idSection,:)=[];
            result = GPDQStatus.SUCCESS;
        end % result = removeSection(self, idSection)
        
% save        
        function result = save(self)
            %% Saves the project into a csv file
            %
            %  Returns:
            %   result: The result of the operation, that can be either
            %   GPDQStatus.ERROR or GPDQStatus.SUCESS.
            
            % The project must have a name.
            if isempty(self.fileName)
                GPDQStatus.repError('The name of the project is empty, and the project can not be saved.', false, dbstack());
                result = GPDQStatus.ERROR;
                return;
            end
            % Gets the full file name
            fullFileName = fullfile (self.workingDirectory, self.fileName);
            try
                % Opens the file
                file = fopen(fullFileName,'w');
                % Number of rows.
                numSections = self.numSections;
                % Writes each row
                for idSection=1:numSections
                    fprintf(file,'%s ;', self.data{idSection,1});
                    if ~isempty(self.data{idSection,2})
                        fprintf(file,'%d',self.data{idSection,2});
                    end
                    fprintf(file,' ;');
                    fprintf(file, '%s ;', self.data{idSection,3});
                    if ~isempty(self.data{idSection,4})
                        fprintf(file, '%.4f', self.data{idSection,4});
                    end
                    fprintf(file,' \n');
                end
                % Closes the file
                fclose(file);
                result = GPDQStatus.SUCCESS;
            catch
                GPDQStatus.repError(['There has been a problem when writing the project '  fullFileName], false, dbstack());
                result = GPDQStatus.ERROR;
            end
        end % result = save(self)
                
        
      
                
% sectionFilePath      
        function filePath = sectionFilePath(self, idSection)
            %% Returns the image in the section #idSection or GPDQStatus.ERROR in case of error.
            %  Parameters:
            %       idSection: id (position) of the section to be removed.
            %
            %  Returns:
            %       image: The image corresponding to the section, or GPDQStatus.ERROR.
            
            % Test the valid range
            if ~self.checkIdSection(idSection)
                image = GPDQStatus.ERROR;
                return;
            end
            % Full name of the image.
            filePath =secImageFile(self.data{idSection,1}, self.data{idSection,2});
        end % sectionImage(self, idSection)

        
% sectionImage        
        function image = sectionImage(self, idSection)
            %% Returns the image in the section #idSection or GPDQStatus.ERROR in case of error.
            %  Parameters:
            %       idSection: id (position) of the section to be removed.
            %
            %  Returns:
            %       image: The image corresponding to the section, or GPDQStatus.ERROR.
            
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
        end % sectionImage(self, idSection)
        
% sectionImageMask        
        function maskImage = sectionImageMask(self, idSection)
            %% Returns the image with the mask for the section #idSection or or GPDQStatus.ERROR in case of error
            %  Parameters:
            %       idSection: id (position) of the section
            %
            %  Returns:
            %       mask: The image with the mask of the section, or GPDQStatus.ERROR.
            
            % Test the valid range
            if ~self.checkIdSection(idSection)
                maskImage = GPDQStatus.ERROR;
                return;
            end
            % Full name of the image with the section
            maskImageName = secImageFile(fullfile(self.workingDirectory,self.data{idSection,1}),self.data{idSection,2});
            % Reads the image
            try
                maskImage = readImage(maskImageName);
            catch
                maskImage = GPDQStatus.ERROR;
            end
        end % maskImage = sectionImageMask(self, idSection)
        
% sectionMask        
        function mask = sectionMask(self, idSection)
            %% Returns the mask for the section #idSection or or GPDQStatus.ERROR in case of error
            %  Parameters:
            %       idSection: id (position) of the section
            %
            %  Returns:
            %       mask: The mask of the section, or GPDQStatus.ERROR.
            
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
        end % mask = sectionMask(self, idSection)
        
        
        
        
% sectionParticles        
        function particles = sectionParticles(self, idSection)
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
        end % sectionParticles(self, idSection)
        
% sort
        function sort(self)
            %% Sorts the rows by group/image/section
            isComplete = false(1,self.numSections);
            for idSection=1:self.numSections
                isComplete(idSection)=self.isComplete(idSection);
            end
            completeData = self.data(isComplete,:);
            incompleteData = self.data(~isComplete,:);
            completeData = sortrows(completeData,[3,1,2]);
            self.data = [completeData; incompleteData];
        end
        
    end % methods


    
    methods(Access=private)        
% checkIdSection       
        function validID = checkIdSection(self, idSection)
            %% Checks if the id of the section is correct (is in range).
            if idSection<0 || idSection>size(self.data,1)
                GPDQStatus.repError(['Trying to access section #'  num2str(idSection) '. Use [1,' num2str(size(self.data,1)) '].'], false, dbstack());
                validID = false;
            else
                validID = true;
            end
        end
    end % methods(Access=private)
end


