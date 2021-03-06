function [rawInfo, sumInfo] = nndSummary(data, fromRadius, toRadius, asCell)

%% IMPORTANT TO UNDESTARND CODE
% idSection: id of the section in the project that generates the data: data.sections(posSection).idSection
% posSection: position of the serie in the struct array data.sections.

if nargin<4
    asCell=false;
end

%% Extracts particles involved
particlesFrom = data.particlesSection(fromRadius);
particlesTo = data.particlesSection(toRadius);

% Auxiliar function.
    function pPositions = getPositions(particles)
        if isempty(particles) || size(particles,1)<2 % Discards cells with less than 2 particles.
            pPositions = [];                         % As it is not possible to calculate NNDs
        else
            pPositions = particles(:,1:2);
        end
    end

% Gets and extracts the particles ([] when there are no particles
particleFromPos = cellfun(@(particlesSection) getPositions(particlesSection), particlesFrom, 'UniformOutput',false);
particleToPos = cellfun(@(particlesSection) getPositions(particlesSection), particlesTo, 'UniformOutput',false);

%%  Discards sections not containing particles
emptyPartFrom = cellfun('isempty',particleFromPos);
emptyPartTo = cellfun('isempty',particleToPos);
posValidSections = find(~(emptyPartFrom | emptyPartTo));
% Id of the serie for each valid section.
serieIDSection = data.idSeries;
serieIDSection = serieIDSection(posValidSections);
% Id of each valid section. 
sectionIDSection = data.idSections;
sectionIDSection = sectionIDSection(posValidSections);
% Filters valid sections
particleFromPos = particleFromPos(posValidSections);
particleToPos = particleToPos(posValidSections);

%% Calculates distances and number of particles (From) in section (only for non empty).
NNDs = cellfun(@(pf,pt) nnd2Sets(pf,pt), particleFromPos, particleToPos, 'UniformOutput',false);
numPartSection = cellfun(@(particlesSection) size(particlesSection,1), particleFromPos, 'UniformOutput',false);

% Only valid sections from now onwards

%% Creates the tables. Initially in vectors
rawInfo=[];                             % Raw data
sumInfo = zeros(data.numSeries+1,4);    % Summary by series


for serieId=1:data.numSeries
    % Raw data
    sectionsSerie = (serieIDSection==serieId);
    serieNNDs = cell2mat(NNDs(sectionsSerie)');
    rawInfo = [rawInfo; serieNNDs];
    % Summary
    sumInfo(serieId,1) = serieId;
    sumInfo(serieId,2) = sum(sectionsSerie);
    sumInfo(serieId,3) = mean(serieNNDs);
    sumInfo(serieId,4) = std(serieNNDs);
end

%% Completes information of summary
% Includes total in summary
sumInfo(data.numSeries+1,1) = 0;
sumInfo(data.numSeries+1,2) = numel(posValidSections);               % Number of sections
sumInfo(data.numSeries+1,3) = mean(rawInfo);
sumInfo(data.numSeries+1,4) = std(rawInfo);
% Converts to cell arrays (to include names of series and sections)
if asCell
    sumInfo = num2cell(sumInfo);
    sumInfo(1:end-1, 1) = data.expSeries(:,1);
    sumInfo{end,1}='ALL';    
end

%% Raw information
% Returns if there is no information
if isempty(rawInfo)
    return
end
% Creates a row with the ID of the serie (a value for each particle) and another one with the id of the section
serieIDParticle = cell2mat(arrayfun(@(v,r) repmat(v,1,r), serieIDSection', cell2mat(numPartSection), 'UniformOutput',false));
sectionIDParticle = cell2mat(arrayfun(@(v,r) repmat(v,1,r), sectionIDSection', cell2mat(numPartSection), 'UniformOutput',false));
sectionPosParticle = cell2mat(arrayfun(@(v,r) repmat(v,1,r), posValidSections, cell2mat(numPartSection), 'UniformOutput',false));

rawInfo = [serieIDParticle', sectionIDParticle', rawInfo];
% Converts to cell arrays (to include names of series and sections)
if asCell
    rawInfo = num2cell(rawInfo);
    rawInfo(:,1) = cellfun(@(idSerie) data.expSeries{idSerie,1}, rawInfo(:,1), 'UniformOutput',false);
    rawInfo(:,2) = arrayfun(@(posSection) secImageFile(data.sections(posSection).image,data.sections(posSection).section), sectionPosParticle, 'UniformOutput',false);
end

end

