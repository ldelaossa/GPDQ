%% GPDQPData Stores, organizes and serializes the data of a project
%
% Data are organized in experimental series that can contain data from
% several (original) groups. For example:
%
% expSeries = {{'AXON'},     {'AXON_A', 'AXON_B'};
%             {'DENDRITE'}, {'DEDRITE_A','DENDRITE_B'};
%             {'SPINE'},    {'SPINE_A','SPINE_B'}};

% Author: Luis de la Ossa (luis.delaossa@uclm.es)
classdef GPDQData < handle
    
    properties
        project         % Name of the project
        tag             % Tag with the information describing the data.
        expSeries       % Experimental series
        sections        % Structs with the information corresponding to each section.
        
        minParticles    % Minimum number of particles for a section to be included.
        numSeries       % Number of experimental series
        numSections     % Number of sections considered
    end
    
    methods(Static)
 
% save
        function result = save(data, fileName)
            %% Saves a GPDQData object to a file.
            %
            % Parameters
            %   data: GPDQData object
            %   fileName: Name of the file
            %
            % Returns:
            %   result: GPDQStatus.SUCCESS or GPDQStatus.ERROR
            
            % If the class is not GPDQData, returns the error.
            result = GPDQStatus.ERROR;
            if ~isa(data,'GPDQData')
                GPDQStatus.repError('Failing to save the object. It is not a GPDQData', true, dbstack());
                return;
            end
            % Saves in the file the object with name 'data';
            try
                S.('data') = data;
                save(fileName, '-struct', 'S')
            catch
                return;
            end
            result = GPDQStatus.SUCCESS;
        end % result = save(data, fileName)
        
% load        
        function data = load(fileName)
            %% Loads and returns a GPDQData object.
            %
            % Parameters
            %   fileName: Name of the file
            %
            % Returns:
            %   expSeries: a GPDQData object or GPDQStatus.ERROR
            
            % Load the file. It expects a field S.data
            S = load(fileName);
            data = S.data;
            if ~isa(data,'GPDQData')
                GPDQStatus.repError('Failing to load the object. It is not a GPDQExpSeries', true, dbstack());
                data = GPDQStatus.ERROR;
                return;
            end
        end % data = load(fileName)
        
    end %  methods(Static)
    
    methods
% Constructor
        function projectData = GPDQData(project, expSeries, varargin)
            %% Creates a GPDQData object given a project and the definition of the experimental series.
            %
            % Parameters
            %   project: GPDQProject
            %   expSeries: definition of the series (see example above).
            %
            %   'minParticles': Section with no more than this number of particles are ignored.
            %   'onlyValid': Includes only valid sections
            %   'tag': Allows identifying the series.
            %   'verbose': Indicates progress. Can be 0, 1 or 2.
            %
            % Returns:
            %   projectData: a GPDQData object or GPDQStatus.ERROR
            
            %% Options
            % Parse function inputs
            parseInput = inputParser;
            parseInput.addOptional('Tag',[]);                                              % Tag with the information about the data
            parseInput.addOptional('OnlyValid', false, @islogical);                        % Whether to include non valid images or not
            validateRangeMinParticles = @(x) validateattributes(x, {'double'},{'>=',0});   % Minimum number of particles for a section to be considered
            parseInput.addOptional('MinParticles', 0, validateRangeMinParticles);
            parseInput.addOptional('Verbose', false, @islogical);                        % Whether to include non valid images or not
            
            
            % Extracts  the parameters
            parseInput.parse(varargin{:});
            onlyValid = parseInput.Results.OnlyValid;
            verbose = parseInput.Results.Verbose;
            projectData.tag = parseInput.Results.Tag;
            projectData.minParticles = parseInput.Results.MinParticles;
            
            % Extracts project fileName
            projectData.project = fullfile(project.workingDirectory,project.fileName);
            
            % Exp series. Uses groups as default.
            if ~isempty(expSeries)
                projectData.expSeries = expSeries;
            else
                numGroups = size(project.groups,2);
                projectData.expSeries = cell(numGroups,2);
                projectData.expSeries(:,1) = project.groups;
                projectData.expSeries(:,2) = project.groups;
            end
            
            
            % Maps the names of the groups to series.
            projectData.numSeries = size(projectData.expSeries,1);
            groupToSerieId = containers.Map;
            for idSerie=1:projectData.numSeries
                numGroupsSerie = numel(projectData.expSeries{idSerie,2});
                for idGroup=1:numGroupsSerie
                    groupName = projectData.expSeries{idSerie,2}{idGroup};
                    groupToSerieId(groupName) = idSerie;
                end
            end
            
            % To indicate which sections must be discarded. All a priori.
            validSections = false(project.numSections,1);
            
            % Processes each section
            fprintf("Reading information from project: %s\n", projectData.project);
            for idSection=1:project.numSections
                % If the section is not included in any series, continues.
                if ~isKey(groupToSerieId,project.data{idSection,3})
                    continue;
                end
                
                % Extracts the data of the section.
                sectionData = project.getSectionData(idSection);
                
                % Stores the data (discards some information as images or mask for saving space)
                projectData.sections(idSection).idSerie = groupToSerieId(project.data{idSection,3});
                projectData.sections(idSection).serie = projectData.expSeries(groupToSerieId(project.data{idSection,3}),1);
                projectData.sections(idSection).idSection = idSection;
                projectData.sections(idSection).image = sectionData.imageFile;
                projectData.sections(idSection).section = sectionData.section;
                projectData.sections(idSection).scale = sectionData.scale;
                projectData.sections(idSection).area = sectionData.area;
                
                % Particles
                if ~isempty(sectionData.particles)
                    projectData.sections(idSection).particles = sectionData.particles;
                else
                    projectData.sections(idSection).particles = [];
                end
                
                % Tests if the section is valid. If not, it is discarded.
                % OJO
                % if minParticles>0 && ~isempty(es.sections(idSection).particles) && size(es.sections(idSection).particles,1)<minParticles
                if projectData.minParticles>0 && ~isempty(projectData.sections(idSection).particles) && size(projectData.sections(idSection).particles,1)<projectData.minParticles
                    validSections(idSection)=false;
                else
                    validSections(idSection)=true;
                end
                
                % Shows progress
                if verbose
                    fprintf("\t %s ", secImageFile(projectData.sections(idSection).image,projectData.sections(idSection).section));
                    if validSections(idSection)
                        fprintf("\n");
                    else
                        fprintf(" (DISCARDED) \n");
                    end
                else
                    fprintf(". ");
                end
            end % for idSection=1:project.numSections
            
            % Removes non valid sections if necessary
            projectData.sections = projectData.sections(validSections);
            projectData.numSections = sum(validSections);
            
        end % projectData = GPDQData(project, expSeries, varargin)
        
%serieNames
        function names = serieNames(self, asCell)
            %% Returns the names of the series
            %
            % Parameters
            %   asCell: Wether to return them as cell array (string array otherwise)
            %
            % Returns:
            %   names: Names of the series
            if nargin<2
                asCell=false;
            end
            if asCell
                names = self.expSeries(:,1);
            else
                names = convertCharsToStrings(self.expSeries(:,1));
            end
        end
        
% groupsSerie
        function groups = groupsSerie(self, idSerie, asCell)
            %% Returns the groups for a serie
            %
            % Parameters
            %   idSerie: id (position) of the serie whose groups must bereturned
            %   asCell: Whether to return them as cell array (string array otherwise)
            %
            % Returns:
            %   names: Names of the series
            if idSerie>self.numSeries
                groups =  GPDQStatus.ERROR;
                return
            end
            if nargin<3
                asCell=false;
            end
            if asCell
                groups = self.expSeries{idSerie,2};
            else
                groups = convertCharsToStrings(self.expSeries{idSerie,2});
            end
        end  % groupsSerie(self, idSerie, asCell)
        
% seriesSection
        function series = seriesSection(self)
            %% Returns an array with name of the serie each valid section belongs to.
            series = convertCharsToStrings([self.sections.serie])';
        end % seriesSection(self)
        
% idSeries
        function idSeries = idSeries(self)
            %% Returns an array with the id of the serie each section belongs to.
            idSeries = [self.sections.idSerie]';
        end  % idSeries(self)
        
% idSections
        function idSections = idSections(self)
            %% Returns an array with the id of the serie each section belongs to.
            idSections = [self.sections.idSection]';
        end  % idSections(self)
        
% areas
        function areas = areas(self)
            %% Returns the area of each section.
            areas = [self.sections.area]';
        end  % areas(self)
        
% numParticlesSection
        function numParticles = numParticlesSection(self,radius)
            %% Returns the number of particles with the given radius for each section
            
            % Returns 0 if the set of particles is empty
            function np = auxNumParticles(particles)
                if isempty(particles), np = 0; else, np = sum(ismember(particles(:,4),radius)); end
            end
            
            %% Returns an array with the number of particles for each section given its radius
            numParticles = cellfun(@(particles) auxNumParticles(particles), {self.sections.particles})';
            %numParticles = cellfun(@(p) sum(ismember(p(:,4),radius)), {self.sections.particles})';
        end % numParticlesSection(self,radius)
        
% particlesSection
        function particles = particlesSection(self,radius)
            
            % Returns the particles of interest or an empty set
            function pr = auxParticles(particles)
                if isempty(particles), pr = []; else, pr = particles(ismember(particles(:,4),radius),:); end
            end
            %% Returns the set of particles for each section given is radius
            particles = cellfun(@(p) auxParticles(p), {self.sections.particles}, 'UniformOutput',false);
            %particles = cellfun(@(p) p(ismember(p(:,4),radius),:), {self.sections.particles}, 'UniformOutput',false);
        end  % particlesSection(self,radius)
    
    end % methods
    
end % classdef GPDQData < handle















