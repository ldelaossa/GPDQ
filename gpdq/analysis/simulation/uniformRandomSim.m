%% uniformRandomSim

% Generates points uniformly distributed in a region. Distance is given in
% pixels. 
% 
%       randomPoints = uniformRandomSim(section, numPoints, varargin)
%
% Example
% -------
%
%       points = uniformRandomSim(section, 15, 'Scale', 1.4585, 'MinDistance', 10 );
%
% Parameters
% ----------
%
%   section: Binary image. Only generates points in positions set to true.
%
%   nPoints: Number of points
%
% Optional parameters
% -------------------
%   
% 'Scale': Scale of the section in Nm/Pixel
%
% 'MinDistance': Minimum allowed distance between particles. 
%
% 'MaxDistance': Maximum allowed distance between particles. 
%
% 'RefPoints': (nx2) matrix with reference points. They are also considered
%              when computing maximum and minimum distances. 
%
% Returns
% -------
%
% randomPoints: An (numPoints,2) array with the positions of the generated points.


function randomParticles = uniformRandomSim(section, numParticles, varargin)
    %% Options
    % Parse function inputs
    parseInput = inputParser;
    parseInput.addOptional('Scale', []);
    parseInput.addOptional('MinDistance',0);
    parseInput.addOptional('MaxDistance',inf);
    parseInput.addOptional('RefParticles',[]); 

    
    % Extracts  the parameters
    parseInput.parse(varargin{:});
    minDistance = parseInput.Results.MinDistance;  
    maxDistance = parseInput.Results.MaxDistance; 
    refParticles = parseInput.Results.RefParticles;
    scale = parseInput.Results.Scale;
 
    % Does not test nnd with other set of points
    if isempty(refParticles)
        testRefPoints=false;
    else
        testRefPoints=true;
    end
 
    % Minimun distance
    minDistancePx = minDistance/scale;
    
    % Maximum distance
    if maxDistance<inf
        maxDistancePx = maxDistance/scale;
    else
        maxDistancePx = inf;
    end
   
    % Stores the random points
    randomParticles = zeros(numParticles,2);
    
    % Size of the mask.
    sizeX = size(section,2);
    sizeY = size(section,1);
    
    %% Simulates the points
    idPoint = 1;
    while idPoint<=numParticles
        % Generates the point
        x = random('unid',sizeX);
        y = random('unid',sizeY);
        %% Test conditions
        % The point must be inside region.
        if ~section(y,x)
            continue 
        end
        
        % The NND of the new point must be within the limits for NND
        if (idPoint>1)
            if (nndPoint([x y], randomParticles(1:idPoint,:))<minDistancePx) || (testRefPoints && (nndPoint([x,y],refParticles)<minDistancePx))
                continue
            end
        end
        
        % If all the conditions hold, replaces the point
        randomParticles(idPoint,1)=x;
        randomParticles(idPoint,2)=y;
        
        idPoint=idPoint+1;
    end
    
    %% If there is no limit for the max allowed distance, returns.
    if maxDistancePx==inf
        return
    end
    
    %% Otherwise replaces the point with the maximum NND until it fits the restriction.
    
    % Maximum NND of a random point with respect to other random or simulated point.
    if ~testRefPoints
        [maxDist, idPointMaxDist] = max(distToNearestPoint(randomParticles));
    else
        [maxDist, idPointMaxDist] = max(max([distToNearestPoint(randomParticles), distToNearestPoint2Sets(randomParticles,refParticles)],[],2));    
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
        if (nndPoint([x y], randomParticles)<minDistancePx) || (testRefPoints && (nndPoint([x,y],refParticles)<minDistancePx))
            continue;
        end
        
        % Note: Removing one point forces to test the maximum nnd for each point
        % so all maximum distances must be tested after replacement.
    
        % Replaces the point if it fits  
        randomParticles(idPointMaxDist,1)=x;
        randomParticles(idPointMaxDist,2)=y;
        
        % Updates the maximum distance
        if ~testRefPoints
            [maxDist, idPointMaxDist] = max(distToNearestPoint(randomParticles));
        else
            [maxDist, idPointMaxDist] = max(max([distToNearestPoint(randomParticles), distToNearestPoint2Sets(randomParticles,refParticles)],[],2));
        end
    end
end

