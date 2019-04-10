%% genUniformRandomPoints
% Generates points uniformly distributed in a region. Distance is given in
% pixels. 
% 
%       randomPoints = genUniformRandomPoints(nPoints, region, rangeDistancesPx, otherPoints)
%
% Example
%
%       points = genUniformRandomPoints(30, mask, 15, otherPoints);
%
%% Parameters
%
% *nPoints*: Number of points
%
% *region*: Binary image. Only generates points in positions set to true.
%
% *rangeDistancesPx*: 2 element vector with the minimum and maximum NND
% allowed. It is given in pixels. If only one value is provided, then it
% only considers minimum distance.
%
% *refPoints*: (nx2) matrix with reference points. They are used to
% compute maximum and minimum distances. 
%
%% Returns
%
% *randomPoints*: An (nPoints,2) array with the positions of the generated points.
%
%% Errors
%
% * Invalid values for the parameters.


function randomPoints = genUniformRandomPoints(section, numPoints, scale, varargin)
    %% Options
    % Parse function inputs
    parseInput = inputParser;
    parseInput.addOptional('MinDistance',0);
    parseInput.addOptional('MaxDistance',inf);
    parseInput.addOptional('RefPoints',[]); 
    
%     % Extracts  the parameters
%     parseInput.parse(varargin{:});
%     minDistance = parseInput.Results.MinDistance;    
% 
%     % Does not test nnd with other set of points
%     if nargin<4
%         testOtherPoints=false;
%     elseif isempty(otherPoints) || size(otherPoints,1)==0
%         testOtherPoints=false;
%     else
%         testOtherPoints=true;
%     end
% 
%     % Minimun distance
%     if nargin<3 || numel(rangeDistancesPx)==0
%         minAllowedDistPx = 0;
%     else
%         minAllowedDistPx = rangeDistancesPx(1);
%     end
%     
%     % Maximum distance
%     if  nargin<3 || numel(rangeDistancesPx)<2
%         maxAllowedDistPx = inf;
%     else
%         maxAllowedDistPx = rangeDistancesPx(2);
%     end   
%     
%     % Stores the random points
%     randomPoints = zeros(numPoints,2);
%     
%     % Size of the mask.
%     sizeX = size(section,2);
%     sizeY = size(section,1);
%     
%     %% Simulates the points
%     idPoint = 1;
%     while idPoint<=numPoints
%         % Generates the point
%         x = random('unid',sizeX);
%         y = random('unid',sizeY);
%         %% Test conditions
%         % The point must be inside region.
%         if ~section(y,x)
%             continue 
%         end
%         
%         % The NND of the new point must be within the limits for NND
%         if (idPoint>1)
%             if (nndPoint([x y], randomPoints(1:idPoint,:))<minAllowedDistPx) || (testOtherPoints && (nndPoint([x,y],otherPoints)<minAllowedDistPx))
%                 continue
%             end
%         end
%         
%         % If all the conditions hold, replaces the point
%         randomPoints(idPoint,1)=x;
%         randomPoints(idPoint,2)=y;
%         
%         idPoint=idPoint+1;
%     end
%     
%     %% If there is no limit for the max allowed distance, returns.
%     if maxAllowedDistPx==inf
%         return
%     end
%     
%     %% Otherwise replaces the point with the maximum NND until it fits the restriction.
%     
%     % Maximum NND of a random point with respect to other random or simulated point.
%     if ~testOtherPoints
%         [maxDist, idPointMaxDist] = max(distToNearestPoint(randomPoints));
%     else
%         [maxDist, idPointMaxDist] = max(max([distToNearestPoint(randomPoints), distToNearestPoint2Sets(randomPoints,otherPoints)],[],2));    
%     end
%     
%     % Iterates until the restriction is hold.
%     while (maxDist>maxAllowedDistPx)
%         
%         % Generates a new point
%         x = random('unid',sizeX);
%         y = random('unid',sizeY);
%         
%         % If the generated point is not in the region, continues.
%         if ~section(y,x)
%             continue;
%         end
%         
%         % If it does not satiesfy min distance, continues.
%         if (nndPoint([x y], randomPoints)<minAllowedDistPx) || (testOtherPoints && (nndPoint([x,y],otherPoints)<minAllowedDistPx))
%             continue;
%         end
%         
%         % Note: Removing one point forces to test the maximum nnd for each point
%         % so all maximum distances must be tested after replacement.
%     
%         % Replaces the point if it fits  
%         randomPoints(idPointMaxDist,1)=x;
%         randomPoints(idPointMaxDist,2)=y;
%         
%         % Updates the maximum distance
%         if ~testOtherPoints
%             [maxDist, idPointMaxDist] = max(distToNearestPoint(randomPoints));
%         else
%             [maxDist, idPointMaxDist] = max(max([distToNearestPoint(randomPoints), distToNearestPoint2Sets(randomPoints,otherPoints)],[],2));
%         end
%     end
end

