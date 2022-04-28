%% uniformRandomSim
%
% Generates points uniformly distributed in a region. Distance is given in
% pixels. The first four parameters must be the same for all simulation methods.
%
%  Simulation methods will be implemented in a class.
% 
%       randomPoints = uniformRandomSim(section, scale, secParticles, nSimParticles, varargin)
%
% Example
% -------
%
%       points = uniformRandomSim(section, scale, secParticles, nSimParticles, 'MinDistance', 10, 'RefParticles', [2.5, 5]);
%
% Parameters
% ----------
%
%   section: Binary image. Only generates points in positions set to true.
%
%   secParticles: Current existing particles (nx4 array).
%
%   scale: Scale of the section in Nm/Pixel.
%
%   nSimParticles: Number of particles to simulate
%
% Optional parameters
% -------------------
%
%   'MinDistance': Minimum allowed distance between particles. 
%
%   'MaxDistance': Maximum allowed distance between particles. 
%
%   'RefPoints': Radii of the particles used as reference. If so, distances
%                to these particles is also considered.
%
% Returns
% -------
%
%   randomParticles: A (numParticles x 2) array with the positions of the generated particles.


function randomParticles = uniformRandomSim(section, scale, secParticles, nSimParticles, varargin)
    % The function considers a section and its scale. Can take as input the
    % reference particles expressed in scale 1/1 and returns the
    % particles also in scale 1/1. Internally, works with the image.
    % Variables with name __Px indicate that measure pixels. 
    
    %% Options
    % Parse function inputs
    parseInput = inputParser;
    parseInput.addOptional('MinDistance',0);
    parseInput.addOptional('MaxDistance',inf);
    parseInput.addOptional('RefParticles',[]); 
    % Extracts  the parameters
    parseInput.parse(varargin{:});
    minDistance = parseInput.Results.MinDistance;  
    maxDistance = parseInput.Results.MaxDistance; 
    refParticles = parseInput.Results.RefParticles;

    % If the scale is not provided, assumes it is one.
    if isempty(scale)
        scale=1;
    end
 
    % Does not test nnd with other set of points
    if isempty(refParticles)
        testRefPoints=false;
    % If considering reference points, translates their coordinates to pixels.    
    else
        refParticlesNm = secParticles(ismember(secParticles(:,4),refParticles),1:2);
        refParticlesPx = refParticlesNm/scale;
        testRefPoints=true;
    end
 
    % Minimun distance
    if minDistance<0            % Test valid range and converts to pixels
        minDistancePx = 0;      
    else
        minDistancePx = minDistance/scale;        
    end
    
    % Maximum distance
    if maxDistance<minDistance  % Test valid range and convert to pixels
        GPDQStatus.repWarning('Maximum distance should be greater than minimum distance. Using infinity.', true, dbstack());
        maxDistancePx = inf;
    elseif maxDistance<inf      % Converts 
        maxDistancePx = maxDistance/scale;        
    else
        maxDistancePx = inf;    % Default value      
    end
   
    % Stores the random points
    randomParticlesPx = zeros(nSimParticles,2);
    
    % Size of the mask.
    sizeX = size(section,2);
    sizeY = size(section,1);
    
    %% Simulates the points
    idPoint = 1;
    while idPoint<=nSimParticles
        % Generates the point
        x = random('unid',sizeX);
        y = random('unid',sizeY);
        
        % The point must be inside region.
        if ~section(y,x)
            continue 
        end
        
        % The NND of the new point must be within the limits for NND
        if (idPoint>1)
            if (nndPoint([x y], randomParticlesPx(1:idPoint,:))<minDistancePx) || (testRefPoints && (nndPoint([x,y],refParticlesPx)<minDistancePx))
                continue
            end
        end
        
        % If all the conditions hold, adds the point
        randomParticlesPx(idPoint,1)=x;
        randomParticlesPx(idPoint,2)=y;
        
        idPoint=idPoint+1;
    end
    
    %% If there is no limit for the max allowed distance, returns. Otherwise replaces the point with the maximum NND until it fits the restriction.
    if maxDistancePx==inf
        randomParticles = randomParticlesPx*scale;
        return
    end

    % Maximum NND of a random point with respect to other random or simulated point.
    if ~testRefPoints
        [maxDist, idPointMaxDist] = max(nnd1Set(randomParticlesPx));
    else
        [maxDist, idPointMaxDist] = max(max([nnd1Set(randomParticlesPx), nnd2Sets(randomParticlesPx,refParticlesPx)],[],2));    
    end
    
    % Iterates until the restriction is hold.
    while (maxDist>maxDistancePx)
        
        % Generates a new point
        x = random('unid',sizeX);
        y = random('unid',sizeY);
        
        % If the generated point is not in the region, continues.
        if ~section(y,x)
            continue;
        end
        
        % If it does not satiesfy min distance, continues.
        if (nndPoint([x y], randomParticlesPx)<minDistancePx) || (testRefPoints && (nndPoint([x,y],refParticlesPx)<minDistancePx))
            continue;
        end
        
        % Note: Removing one point forces to test the maximum nnd for each point
        % so all maximum distances must be tested after replacement.
    
        % Replaces the point if it fits  
        randomParticlesPx(idPointMaxDist,1)=x;
        randomParticlesPx(idPointMaxDist,2)=y;
        
        % Updates the maximum distance
        if ~testRefPoints
            [maxDist, idPointMaxDist] = max(nnd1Set(randomParticlesPx));
        else
            [maxDist, idPointMaxDist] = max(max([nnd1Set(randomParticlesPx), nnd2Sets(randomParticlesPx,refParticlesPx)],[],2));
        end
    end
    
    % Converts to nanometers
    randomParticles = randomParticlesPx*scale;
end

