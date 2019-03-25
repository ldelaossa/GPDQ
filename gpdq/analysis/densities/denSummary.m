function [rawInfo, sumInfo] = denSummary(data, radius, asCell)

if nargin<3
    asCell=false;
end

%% Extracts the data
idSerieSection = [data.sections.idSerie]';
idSection = [data.sections.idSection]';
numParticlesSection = data.numParticlesSection(radius);
areaSection = data.areas();
densitySection =  numParticlesSection ./ areaSection;

%% Creates the tables. Initially in vectors

% Raw data
rawInfo=[];
rawInfo = [idSerieSection, idSection, numParticlesSection, areaSection, densitySection];

% Summary
sumInfo = zeros(data.numSeries+1,11);    % Summary by series
for serieId=1:data.numSeries
    sectionsSerie = (idSerieSection==serieId);
    sumInfo(serieId,1) = serieId;
    sumInfo(serieId,2) = sum(sectionsSerie);
    sumInfo(serieId,3) = sum(numParticlesSection(sectionsSerie));
    sumInfo(serieId,4) = mean(numParticlesSection(sectionsSerie));
    sumInfo(serieId,5) = std(numParticlesSection(sectionsSerie));
    sumInfo(serieId,6) = sum(areaSection(sectionsSerie));
    sumInfo(serieId,7) = mean(areaSection(sectionsSerie));
    sumInfo(serieId,8) = std(areaSection(sectionsSerie));
    sumInfo(serieId,9) = sumInfo(serieId,3) / sumInfo(serieId,6);
    sumInfo(serieId,10) = mean(densitySection(sectionsSerie));
    sumInfo(serieId,11) = std(densitySection(sectionsSerie));
end
% Includes total in summary
sumInfo(data.numSeries+1,1) = 0;
sumInfo(data.numSeries+1,2) = numel(idSection);
sumInfo(data.numSeries+1,3) = sum(numParticlesSection);
sumInfo(data.numSeries+1,4) = mean(numParticlesSection);
sumInfo(data.numSeries+1,5) = std(numParticlesSection);
sumInfo(data.numSeries+1,6) = sum(areaSection);
sumInfo(data.numSeries+1,7) = mean(areaSection);
sumInfo(data.numSeries+1,8) = std(areaSection);
sumInfo(data.numSeries+1,9) = sumInfo(data.numSeries+1,3) / sumInfo(data.numSeries+1,6);
sumInfo(data.numSeries+1,10) = mean(densitySection);
sumInfo(data.numSeries+1,11) = std(densitySection);


% Converts to cell arrays (to include names of series and sections)

% Summary
if asCell
    sumInfo = num2cell(sumInfo);
    sumInfo(1:end-1, 1) = data.expSeries(:,1);
    sumInfo{end,1}='ALL';
end

% Raw
% Returns if there is no raw information
if isempty(rawInfo)
    return
end
% Converts to cell arrays (to include names of series and sections)
if asCell
    rawInfo = num2cell(rawInfo);
    rawInfo(:,1) = cellfun(@(idSerie) data.expSeries{idSerie,1}, rawInfo(:,1), 'UniformOutput',false);
    rawInfo(:,2) = cellfun(@(idSection) secImageFile(data.sections(idSection).image,data.sections(idSection).section), rawInfo(:,2), 'UniformOutput',false);
end

end

