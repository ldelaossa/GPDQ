%% GPDQSimulation Stores simulation data
%
%  Given a GPDQData object, stores a cell array with simulations for each
%  section. Each simulation is a cell array that contains a set of particles. 
%  It also provides functionalities for loading, saving, creating
%  and accesing the simulated data. 
 

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

% WILL BE CONVERTED IN A CHILD CLASS OF GPDQData

classdef GPDQSimulation < handle 
    
    properties
        project         % Name of the project associated to the simulation.
        sections        % Name of the sections.  
        created         % Timestamp 
        data            % Stores the original particles. 
        tag             % Descriptive tag
        
        numSections     % Number of sections considered
        numSimulations  % Number of simulation per serie
        simData         % Simulation data: cell(numSections,numSimulations)
    end
    
    
    methods(Static) 
        
%% save
        function result = save(simulation, fileName)
            %% Saves a GPDQSimulation object to a file.
            %
            % Parameters
            %   simulation: GPDQSimulation object
            %   fileName: Name of the file
            %
            % Returns:
            %   result: GPDQStatus.SUCCESS or GPDQStatus.ERROR
            
            % If the class is not GPDQSimulation, returns the error.
            result = GPDQStatus.ERROR;
            if ~isa(simulation,'GPDQSimulation')
                GPDQStatus.repError('Failing to save the object. It is not a GPDQSimulation', true, dbstack());
                return;
            end
            % Saves in the file the object with name 'simdata';
            try
                S.('simdata') = simulation;
                save(fileName, '-struct', 'S')
            catch
                return;
            end
            % Returns success
            result = GPDQStatus.SUCCESS;
        end % result = save(simulation, fileName)
        
%% load        
        function simulation = load(fileName)
            %% Loads and returns a GPDQData object.
            %
            % Parameters
            %   fileName: Name of the file
            %
            % Returns:
            %   simulation: a GPDQSimulation object or GPDQStatus.ERROR
            
            % Load the file. It expects a field S.simdata
            S = load(fileName);
            simulation = S.simdata;
            if ~isa(simulation,'GPDQSimulation')
                GPDQStatus.repError('Failing to load the object. It is not a GPDQSimulation', true, dbstack());
                simulation = GPDQStatus.ERROR;
                return;
            end
        end % simulation = load(fileName)
        
    end %  methods(Static)
    
    
    
    methods     
        
%% Constructor
        function sim = GPDQSimulation(data, numSimulations, simParticles, simFunction, tag, varargin)
            %% Makes simulation for the sections included in a data object.
            %
            % Parameters
            %   data: GPDQData object. 
            %   numSimulations: Number of simulations per section.
            %   simParticles: Radii of the simulated particle (determines the number of particles to simulate).
            %   simFunction: Reference to the function used for simulation
            %   varargin: Optional arguments passed to simFunction
            
            global config;
    
            % Static data
            sim.project = data.project;
            sim.created = datestr(now,'dd-mm-yyyy HH:MM PM');
            sim.numSections = data.numSections;
            sim.numSimulations = numSimulations;
            sim.sections = cell(data.numSections,1);
            sim.data = {data.sections.particles}';
            sim.tag = tag;
            
            % Simulations (parallel processing can not access to sim so the results must be added later. 
            simData = cell(sim.numSections, sim.numSimulations);
            % Wait bar
            tic
            fwaitbar = waitbar(0,['0' '/' num2str(data.numSections)],'Name','Simulating data');
            for idSection=1:data.numSections % Processes each section.
                
                % Section image name
                sim.sections{idSection} = secImageFile(data.sections(idSection).image, data.sections(idSection).section);
                % Reads the image section
                image = readImage(fullfile(data.workingDirectory, sim.sections{idSection}));
                % If the image section exists, gets the mask.
                if ~GPDQStatus.isError(image) 
                    mask = getSectionMask(image);
                % Otherwise, uses the whole image. 
                else
                    image = readImage(fullfile(data.workingDirectory, data.sections(idSection).image));
                    mask = true(size(image));
                end
                
                % Particles
                particles = data.sections(idSection).particles;
                numParticles = sum(ismember(particles(:,4), simParticles));
                % Makes the simulations. 
                parfor idSim=1:numSimulations
                    simData{idSection,idSim} = simFunction(mask, particles, numParticles, varargin{:});
                end
                waitbar(idSection/data.numSections,fwaitbar, [num2str(idSection) '/' num2str(data.numSections)]);
            end
            delete(fwaitbar)
            % Adds the simulations to the object. 
            sim.simData = simData;
            toc
        end % sim = GPDQSimulation(data, numSimulations, simParticles, simFunction, varargin)
    end % methods
    
end % classdef GPDQSimulation < handle















