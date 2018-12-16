%% GPDQExpSeries Stores and organizes the data of a project as a set of series
%
% Creates experimental series from a project. Each serie corresponds to a 
% an experimental group and is defined by a set of groups, and the categories
% of particles considered in the images of each group. Each category
% corresponds to a set of radius. 
% 
% IMPORTANT: Although most times each series corresponds to a group, and
% each group of particles corresponds to a size. This class provides 
% versatility for special situations.
%
% For example:
%
% definition.names = {'AXON','DENDRITE','SPINE'}
% defnition.series = {{'AXON_A', [2.5 5], 10; 
%                      'AXON_B', [2.5 5], 10}, 
%                     {'DEDRITE_A', 2.5, 5; 
%                      'DENDRITE_B', 5, 2.5}, 
%                     {'SPINE_A', 5, 2.5; 
%                      'SPINE_B', 5, 2.5}}
%
%
% This serie definition forms three experimental groups. The first one
% includes the images in groups 'AXON_A' and 'AXON_B', and divides the
% particles into two groups. In one of them, includes the particles with
% radii 2.5Nm and 5Nm. In the other, particles of 10Nm.
% The second experimental group includes the images
% tagged as 'DENDRITE_A' and 'DENDRITE_B'. For the first group of
% particles, it would consider those with radius 2.5 in 'DENDRITE_A', and
% those with radius 5 in group 'DENDRITE_B'. For the second group of particles,
% it would consider radius '5', for 'DENDRITE_A', and 2.5 for 'DENDRITE_B'.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)
classdef GPDQExpSeries < handle
    
    properties
        definition      % Definition of the experimental series
        series          % Experimental series
        numSeries       % Number of series
        numCategories   % Number of categories of particles considered (generally 1 or 2)
        minParticles    % Minimum number of particles to consider sections
    end
    
    methods(Static)
        function result = save(expSeries, fileName)
            %% Saves a GPDQExpSeries object to a file.
            %
            % Parameters
            %   expSeries: GPDQExpSeries object
            %   fileName: Name of the file
            %
            % Returns:
            %   result: GPDQStatus.SUCCESS or GPDQStatus.ERROR
            
            % If the class is not GPDQExpSeries, returns the error.
            result = GPDQStatus.ERROR;
            if ~isa(expSeries,'GPDQExpSeries')
                GPDQStatus.repError('Failing to save the object. It is not a GPDQExpSeries', true, dbstack());
                return;
            end
            % Saves in the file the object with name 'expSeries';
            try
                S.('expSeries') = expSeries;
                save(fileName, '-struct', 'S')
            catch
                return;
            end
            result = GPDQStatus.SUCCESS;
        end % result = save(expSeries, fileName)
        
        function expSeries = load(fileName)
            %% Loads and returns a GPDQExpSeries object.
            %
            % Parameters
            %   fileName: Name of the file
            %
            % Returns:
            %   expSeries: a GPDQExpSeries object or GPDQStatus.ERROR
            
            % Load the file. It expects a field S.expSeries
            S = load(fileName);
            expSeries = S.expSeries;
            if ~isa(expSeries,'GPDQExpSeries')
                GPDQStatus.repError('Failing to load the object. It is not a GPDQExpSeries', true, dbstack());
                expSeries = GPDQStatus.ERROR;
                return;
            end
        end % expSeries = load(fileName)
    end %  methods(Static)
    
    methods
        function es = GPDQExpSeries(project, definition, minParticles)
            %% Creates a GPDQExpSeries object.
            %
            % Parameters
            %   project: GPDQProject
            %   definition: definition of the series (see example above)
            %   minParticles: Section with no more than this number of
            %   particles are ignored. 
            %
            % Returns:
            %   expSeries: a GPDQExpSeries object or GPDQStatus.ERROR
            
            % Load the file. It expects a field S.expSeries
            es.definition = definition;
            es.series = [];
            es.numSeries = numel(definition.series);
            es.numCategories = size(definition.series{1},2)-1;
            es.minParticles = minParticles;
            
            % Extracts the data for each serie. 
            for idSerie=1:es.numSeries
                % Determines the sections and series included on each serie.
                numGroupsSerie = size(definition.series{idSerie},1);
                sectionsSerie = false(project.numSections,1);
                partSizeSection =cell(size(project.numSections,1),es.numCategories);
                % Extracts the sections that belong to each group
                for idGroup=1:numGroupsSerie
                    group = definition.series{idSerie}{idGroup,1};
                    sectionsGroup = strcmp(project.data(:,3), group);
                    sectionsSerie(sectionsGroup)=true;
                    for idCategory=1:es.numCategories
                        partSizeSection(sectionsGroup,idCategory)={definition.series{idSerie}{idGroup,idCategory+1}};
                    end % for idPartCategory=1:numCategories
                end % idGroup=1:numGroupsSerie
                
                % First calculations. can be done now.
                es.series(idSerie).name = definition.names(idSerie);
                es.series(idSerie).idSections = find(sectionsSerie);
                es.series(idSerie).numSections = numel(es.series(idSerie).idSections);
                
                % Auxiliar, particle sizes considered for each section/category
                partSizeSection = partSizeSection(es.series(idSerie).idSections,:);
                
                % Creates the structures to store the information of each serie.
                es.series(idSerie).idSerie = zeros(es.series(idSerie).numSections,1);
                es.series(idSerie).image = cell(es.series(idSerie).numSections,1);
                es.series(idSerie).section = zeros(es.series(idSerie).numSections,1);
                es.series(idSerie).group = cell(es.series(idSerie).numSections,1);
                es.series(idSerie).scale = zeros(es.series(idSerie).numSections,1);
                es.series(idSerie).area = zeros(es.series(idSerie).numSections,1);
                es.series(idSerie).numParticles = zeros(es.series(idSerie).numSections,es.numCategories);
                es.series(idSerie).particles = cell(es.series(idSerie).numSections,es.numCategories);
                es.series(idSerie).density = zeros(es.series(idSerie).numSections,es.numCategories);
                % To indicate which sections must be discarded.
                validSections = true(es.series(idSerie).numSections,1);
                
                % serIdSec is the relative position of the section in the serie.
                % proIdSec is position of the section in the project.
                for serIdSec=1:es.series(idSerie).numSections
                    % Extracts the series of the corresponding section.
                    proIdSec = es.series(idSerie).idSections(serIdSec);
                    sectionseries = project.getFullSectionData(proIdSec);
                    % Stores relevant series
                    es.series(idSerie).idSerie(serIdSec)=idSerie;
                    es.series(idSerie).image{serIdSec} = sectionseries.imageFile;
                    es.series(idSerie).section(serIdSec) = sectionseries.section;
                    es.series(idSerie).scale(serIdSec) = sectionseries.scale;
                    es.series(idSerie).area(serIdSec) = sectionseries.area;
                    % Particles
                    for idCategory=1:es.numCategories
                        if ~isempty(sectionseries.particles)
                            es.series(idSerie).particles{serIdSec,idCategory} = sectionseries.particles(ismember(sectionseries.particles(:,4),partSizeSection{serIdSec,idCategory}),:);
                            es.series(idSerie).numParticles(serIdSec,idCategory) = size(es.series(idSerie).particles{serIdSec,idCategory},1);
                            es.series(idSerie).density(serIdSec,idCategory) = es.series(idSerie).numParticles(serIdSec,idCategory) / es.series(idSerie).area(serIdSec);
                        else
                            es.series(idSerie).particles{serIdSec,idCategory} = [];
                            es.series(idSerie).numParticles(serIdSec,idCategory) = 0;
                            es.series(idSerie).numParticles(serIdSec,idCategory) = 0;
                        end
                    end
                    % Tests if the section is valid. If not, it is discarded.
                    if sum(es.series(idSerie).numParticles(serIdSec,:))<minParticles
                        validSections(serIdSec)=false;
                        continue;
                    else
                        validSections(serIdSec)=true;
                    end
                end % serIdSec=1:es.series(idSerie).numSections
     
                % Removes non valid sections
                es.series(idSerie).idSerie = es.series(idSerie).idSerie(validSections);
                es.series(idSerie).idSections = es.series(idSerie).idSections(validSections);
                es.series(idSerie).numSections = numel(es.series(idSerie).idSections);
                es.series(idSerie).image = es.series(idSerie).image(validSections);
                es.series(idSerie).group = es.series(idSerie).group(validSections);
                es.series(idSerie).section = es.series(idSerie).section(validSections);
                es.series(idSerie).scale = es.series(idSerie).scale(validSections);
                es.series(idSerie).area = es.series(idSerie).area(validSections);
                % Particles
                es.series(idSerie).particles = es.series(idSerie).particles(validSections,:);
                es.series(idSerie).numParticles = es.series(idSerie).numParticles(validSections,:) ;
                es.series(idSerie).density = es.series(idSerie).density(validSections,:);
            end % idSerie=1:es.numSeries
        end % es = GPDQExpSeries(project, definition, minParticles)
    end % methods
end