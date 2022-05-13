
%% fitDDRandomSim
%
% Generates a set of random points such that the distribution of distances 
% is similar to the original one. It uses kstest2 with the confidence passed as
% parameter to test if there is statistical difference. 
% 
%       randomPoints = fitDDRandomSim(section, scale, particles, simParticlesR, varargin)
%
% Example
% -------
%
%       points = fitDDRandomSim(section, scale, particles, simParticlesR, 'MinDistance', 10, 'RefParticles', [2.5, 5]);
%
% Parameters
% ----------
%
%   section: Binary image. Only generates points in positions set to true.
%
%   scale: Scale of the section in Nm/Pixel.
%
%   particles: Current existing particles (nx4 array).
%
%   simParticlesR: Radii of the particles to be simulated 
%
%
% Optional parameters
% -------------------
%
%   'Confidence': Confidence threshold for the test
%
%   'MinDistance': Minimum allowed distance between particles. 
%
%   'MaxDistance': Maximum allowed distance between particles. 
%
%   'RefParticlesR': Radii of the particles used as reference. If so, distances
%                   to these particles are also considered.
%
%   'MaxMeanDistDiff': Maximum allowed difference between real and
%    simulated means of NNDs (expressed as a fraction the real mean). By
%    default, it allows the simulated mean to be double of the real one.
%    It is mainly used for special cases with an small number of particles.
%    If empty, it is set to infitity and only used when the number of
%    particles is 2 and no test can be performed.
%   
% Returns
% -------
%
%   randomParticles: A (numParticles x 2) array with the positions of the generated particles.


function randomParticles = fitDDRandomSim(section, scale, particles, simParticlesR, varargin) 
    % The function considers a section and its scale. Can take as input the
    % reference particles expressed in scale 1/1 and returns the
    % particles also in scale 1/1. Internally, works with the image.
    % Variables with name __Px indicate that measure pixels. 
    
    %% Options
    % Parse function inputs
    parseInput = inputParser;
    parseInput.addOptional('Confidence', 0.95);     
    parseInput.addOptional('MinDistance',10);
%     parseInput.addOptional('MaxDistance',inf);
    parseInput.addOptional('RefParticlesR',[]); 
    parseInput.addOptional('MaxMeanDistDiff', 1);    
    % Extracts  the parameters
    parseInput.parse(varargin{:});
    confidence = parseInput.Results.Confidence;
    minDistance = parseInput.Results.MinDistance;  
%     maxDistance = parseInput.Results.MaxDistance; 
    refParticlesR = parseInput.Results.RefParticlesR;
    maxMeanDistDiff = parseInput.Results.MaxMeanDistDiff;   


    %% Numerical parameters

    % If the scale is not provided, assumes it is one.
    if isempty(scale)
        scale=1;
    end

    % Minimun distance
    if minDistance<0            % Test valid range and converts to pixels
        minDistance=0;
    end
    
%     % Maximum distance
%     if maxDistance<minDistance  % Test valid range and convert to pixels
%         GPDQStatus.repWarning('Maximum distance should be greater than minimum distance. Using infinity.', true, dbstack());
%         maxDistance = inf;      
%     end

    % Maximum allowed difference for the mean
    if isempty(maxMeanDistDiff)
        maxMeanDistDiff = inf;
    end    

    %% Particles

    % These method require the original particles
    if isempty(particles)
        GPDQStatus.repError('This simulation requires real particles to be passed', true);
        randomParticles = GPDQStatus.ERROR;
        return
    end

    % If the scale is not provided, assumes it is one.
    if isempty(simParticlesR)
        GPDQStatus.repError('It is necessary to pass the radii of the particles to be simulated', true);
        randomParticles = GPDQStatus.ERROR;
        return   
    else
        simParticles = particles(ismember(particles(:,4),simParticlesR),1:2);
    end    


    % Does not test nnd with other set of points
    if isempty(refParticlesR)
        testRefPoints=false;
    % If considering reference points, translates their coordinates to pixels.    
    else
        refParticles = particles(ismember(particles(:,4),refParticlesR),1:2);
        testRefPoints=true;
    end    

    %% End options
    

    % Maximum number of iterations. Sometimes (not very often) the procedure
    % may get stuck in a local optima, and is not able to increase the p-value.
    maxIterations = 20000;  
    
    % Size of the mask.
    sizeX = size(section,2);
    sizeY = size(section,1);

    %% Simulation

    % The number of simulated particles is given by simParticlesR
    numSimParticles = sum(ismember(particles(:,4),simParticlesR));

    % Stores the random particles
    randomParticles = zeros(numSimParticles,2);
    
    % Pairwise distance between the real points.
    realDistances = distances1Set(simParticles);
   
    % Computes the maximum mean difference in nanometers
    maxMeanDistDiff = maxMeanDistDiff*mean(realDistances);


    %% Special case: One particle (reduntant code, but clearer)
    % If the number of particles to simulate is one, fit simulation
    % makes no sense, and returns the random particle
    if numSimParticles<=1
        if testRefPoints
            randomParticles = uniformRandomSim(section, scale, particles, simParticlesR, refParticlesR);
        else
            randomParticles = uniformRandomSim(section, scale, particles, simParticlesR); 
        end    
        return
    end


    %% Wraps the statistical test to deal with special cases    
    % This wraps the statistical test so that it is passed always when
    % there are only two particles. In future, it will allow passing the
    % the test as argument
    function p = testSimilarity(realD, simD)
        if numSimParticles==2
            p = 1;
        else
            [~ , p] = kstest2(realD, simD);
        end
    end


    %% General Case
    % Iterates until the simulation is valid.
    validSimulation = false;
    while ~validSimulation

        % Initializes the simulation with an initial set of random points
        if testRefPoints
            randomParticles = uniformRandomSim(section, scale, particles, simParticlesR, refParticlesR);
        else
            randomParticles = uniformRandomSim(section, scale, particles, simParticlesR); 
        end    
        

        % Calculates distances for the random points        
        randomDistances = distances1Set(randomParticles);
        
        % Test the distributions of distances
        p = testSimilarity(realDistances(~isnan(realDistances)), randomDistances(~isnan(randomDistances)));  

        % Calculates
        meanDistReal = nanmean(realDistances(:));
        meanDistRandom = nanmean(randomDistances(:));
        meanDistDiff = abs(meanDistRandom-meanDistReal);


        % Carries out an iterative improvement until the simulation is valid
        % or reaches the maximum number of iterations
        iteration = 0;
        while iteration<maxIterations && (p<confidence || (meanDistDiff>maxMeanDistDiff))

            % Generates the new point (at pixel scale)
            XPx = random('unid',sizeX);
            YPx = random('unid',sizeY);           
            
            % Test whether the new point is inside the region.
            % If not, it is discarded
            if ~section(YPx,XPx)
                continue;
            end 

            % Translates to nanometers to measure distances
            XNm = XPx*scale;
            YNm = YPx*scale;

            % Test for the minimum distance
            part_NND = nndPoint([XNm,YNm], randomParticles);
            if part_NND < minDistance
                continue;
            end        

            % If there are points to care about, also test for the distance constraint
            if testRefPoints
                part_NND = nndPoint([XNm,YNm], refParticles);
                if part_NND < minDistance 
                    continue
                end
            end  

            % Replaces the particle
            % Selects the particle to be replaced.
            id_particle = randi(numSimParticles);  
            % Saves the original particle and distances, as only changes
            % improving p value (and mean distances difference) are valid. 
            formerParticle = randomParticles(id_particle,:);   
            formerRandomDistances = randomDistances;
            formerMeanDistRandom = meanDistRandom;
            formerMeanDistDiff = meanDistDiff;

            % Replaces the particle
            randomParticles(id_particle,:)= [XNm,YNm];

            % Calculates the new distances for the random points (this step could be optimized) 
            randomDistances = distances1Set(randomParticles);  
            
            % Calculates the new difference
            meanDistRandom = nanmean(randomDistances(:));
            meanDistDiff = abs(meanDistRandom-meanDistReal);

            % Test whether there is improvement

            %  Test the distributions of distances 
            new_p = testSimilarity(realDistances(~isnan(realDistances)), randomDistances(~isnan(randomDistances)));            

            % The change is accepted if improves both the p-value an the mean difference (if they are not within the limits)
            if (new_p>confidence || new_p>=p) && (abs(meanDistDiff)<maxMeanDistDiff || meanDistDiff<=formerMeanDistDiff)
                p = new_p;
            % Otherwise the change is discarded
            else
                randomParticles(id_particle,:) = formerParticle;
                randomDistances = formerRandomDistances;  
                meanDistRandom = formerMeanDistRandom;
                meanDistDiff = formerMeanDistDiff;
  
            end
        end % iteration<maxIterations && p<confidence

        % Once the simulation has been made, tests if it is valid. 
        % If not, it is repeated.
        if p>=confidence  && (abs(meanDistDiff)<maxMeanDistDiff)
            validSimulation = true;
        end
    end % ~validSimulation
end


   


