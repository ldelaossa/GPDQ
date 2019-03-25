function [rawInfo, sumInfo] = clusterSummary(data, radius, maxDistance, minParticles, asCell)

if nargin<5
    asCell=false;
end

%% Extracts particles involved
particles = data.particlesSection(radius);
% Auxiliar function.
    function pPositions = getPositions(particles)
        if isempty(particles) || size(particles,1)<2 % Discards cells with less than 2 particles.
            pPositions = [];                         % As it is not poss~ible to calculate NNDs
        else
            pPositions = particles(:,1:2);
        end
    end
% Gets and extracts the particle positions ([] when there are no particles)
particlesPos = cellfun(@(p) getPositions(p), particles, 'UniformOutput',false);

%% Gets cluster data
clusters = cellfun(@(p) hClustering(p, maxDistance, minParticles), particlesPos, 'UniformOutput',false);
areas = cellfun(@(p,c) areaClusters(p,c), particles, clusters, 'UniformOutput',false);
numParticles = cellfun(@(p,c) sizeClusters(p,c), particles, clusters, 'UniformOutput',false);
numClusters= cellfun(@(p) size(p,1), areas, 'UniformOutput',false);

%% Valid sections
sectionIDs = find(~cellfun('isempty',areas));
serieIDs = data.idSeries;
serieIDs = serieIDs(sectionIDs);
% Filters valid sections
clusters = clusters(sectionIDs);
areas = areas(sectionIDs);
numParticles =  numParticles(sectionIDs);
numClusters = numClusters(sectionIDs);
        
%% Creates the tables. Initially in vectors

% Summary 
sumInfo = zeros(data.numSeries+1,9);   
for serieId=1:data.numSeries
    secSerie = find(serieIDs==serieId);
    sumInfo(serieId,1) = serieId;                                     % serieID,
    sumInfo(serieId,2) = numel(secSerie);                             % number of sections
    sumInfo(serieId,3) = sum(cell2mat(numClusters(secSerie)));        % number of clusters
    sumInfo(serieId,4) = mean(cell2mat(numClusters(secSerie)));       % mean number of clusters
    sumInfo(serieId,5) = std(cell2mat(numClusters(secSerie)));        % std number of clusters   
    sumInfo(serieId,6) = mean(cell2mat(areas(secSerie)'));            % mean area 
    sumInfo(serieId,7) = std(cell2mat(areas(secSerie)'));             % std area     
    sumInfo(serieId,8) = mean(cell2mat(numParticles(secSerie)'));     % mean number of particles 
    sumInfo(serieId,9) = std(cell2mat(numParticles(secSerie)'));      % std number of particles     
end
% Completes information of summary
sumInfo(data.numSeries+1,1) = 0;
sumInfo(data.numSeries+1,2) = numel(sectionIDs);               
sumInfo(data.numSeries+1,3) = sum(cell2mat(numClusters));        
sumInfo(data.numSeries+1,4) = mean(cell2mat(numClusters));       
sumInfo(data.numSeries+1,5) = std(cell2mat(numClusters));          
sumInfo(data.numSeries+1,6) = mean(cell2mat(areas'));            
sumInfo(data.numSeries+1,7) = std(cell2mat(areas'));               
sumInfo(data.numSeries+1,8) = mean(cell2mat(numParticles'));      
sumInfo(data.numSeries+1,9) = std(cell2mat(numParticles'));  

% Transforms to cells if required
if asCell
    % Summary
    sumInfo = num2cell(sumInfo);
    sumInfo(1:end-1, 1) = data.expSeries(:,1);
    sumInfo{end,1}='ALL';
end


% Raw data
if isempty(sectionIDs) 
    rawInfo = [];
    return % Returns if there is no information
end
    
% Expands the serie and section id so that there is one value per cluster
serieIDs = cell2mat(arrayfun(@(v,r)repmat(v,1,r), serieIDs', cell2mat(numClusters), 'UniformOutput',false));
sectionIDs = cell2mat(arrayfun(@(v,r)repmat(v,1,r), sectionIDs, cell2mat(numClusters), 'UniformOutput',false));
% Creates the matrix
rawInfo=[serieIDs', sectionIDs', cell2mat(numParticles'), cell2mat(areas')];


%% Converts to cell arrays (to include names of series and sections)
if asCell

    rawInfo = num2cell(rawInfo);
    rawInfo(:,1) = cellfun(@(idSerie) data.expSeries{idSerie,1}, rawInfo(:,1), 'UniformOutput',false);
    rawInfo(:,2) = cellfun(@(idSection) secImageFile(data.sections(idSection).image,data.sections(idSection).section), rawInfo(:,2), 'UniformOutput',false);
end

end

