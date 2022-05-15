function [rawNNDs, sumSection, sumSeries, rawSimNNDs, sumSimSection, sumSimSeries, serieNames, sectionNames] = nndSummarySim(simulation, fromRadius, toRadius, asCell)

%% IMPORTANT TO UNDESTARND CODE
%
% idSection: id of the section in the project that generates the data: data.sections(posSection).idSection
% posSection: position of the serie in the struct array data.sections.
%
% if fromRadius~=toRadius, then simulation.simradius must be either fromRadius or toRadius
% if fromRadius==toRadius then simulation.simradius  must be fromRadius/toRadius
% 
% In the summaries considers a special series, namely 'ALL', that represents the whole data. 

%% Returns

% rawNNDs (for each section/particle)
    % idSerie, idSection, NNDs

% sumSection (for each section)
    % idSerie, idSection, numParticlesFrom, numParticlesTo, mean(NND), std(NND)   

% sumSeries (for each serie)
%   % idSerie, numSections, mean(NND) std(NND)

% rawSimNNDs: (for each section/particle) 
%   % idSerie, idSection NNDsFrom 

% sumSimSection: (for each section)
%   % idSerie, idSection, numParticlesFrom, numParticlesTo, mean(NND), std(NND), mean(simNND), ci(simNND), asoc, disoc];

% sumSimSeries (for each serie)
%   idSerie, numSections, mean(NND), std(NND), mean(simNND), pvalor(meanNNDs), numAsoc, numDisoc



    if all(fromRadius==toRadius)
        if all(simulation.simradius~=fromRadius)
            GPDQStatus.repError('The radius of the simulated particles does not correspond to the radius of the real particles', true)
            return 
        end
    else
        if (simulation.simradius~=fromRadius) && (simulation.simradius~=toRadius)
            GPDQStatus.repError('The radius of the simulated particles does not correspond to any of the radii of the real particles', true)
            return 
        end
    end
    
    if nargin<4
        asCell=false;
    end
    
    % When calculating NND among the same kind of particles, there must be at
    % least two. Otherwise, there must be at least one of each.
    if all(fromRadius==toRadius)
        minParticles = 2;
    else
        minParticles = 1;
    end



%% Gets and extracts the particles ([] when there are no particles enough)
    % Auxiliar function. Returns an empty set of particles when there is
    % no particles enough to calculate distances
    function pParticles = getParticles(particles)
        if isempty(particles) || size(particles,1)<minParticles 
            pParticles = [];                                    
        else
            pParticles = particles(:,1:2);
        end
    end
    % Gets the positions of the particles corresponding to From and To
    particlesFrom = simulation.data.particlesSection(fromRadius);
    particlesTo = simulation.data.particlesSection(toRadius);
    particleFromPos = cellfun(@(particlesSection) getParticles(particlesSection), particlesFrom, 'UniformOutput',false);
    particleToPos = cellfun(@(particlesSection) getParticles(particlesSection), particlesTo, 'UniformOutput',false);


%% Discards sections not containing particles
    % Filters sections where some of the particles set are empty
    emptyPartFrom = cellfun('isempty',particleFromPos);
    emptyPartTo = cellfun('isempty',particleToPos);
    % Positions of the valid sections
    posValidSections = find(~(emptyPartFrom | emptyPartTo));
    % Number of valid sections
    numValidSections = numel(posValidSections);
    % Id of the serie for each valid section.
    serieIDSection = simulation.data.idSeries;
    serieIDSection = serieIDSection(posValidSections);
    % Id of each valid section. 
    sectionIDSection = simulation.data.idSections;
    sectionIDSection = sectionIDSection(posValidSections);

%% Get particles from valid sections
    particleFromPos = particleFromPos(sectionIDSection);
    particleToPos = particleToPos(sectionIDSection);
    particleSimPos = simulation.simdata(sectionIDSection,:);
    % Numper of particles of each section
    numParticlesFromSection = cellfun(@(particlesSection) size(particlesSection,1), particleFromPos, 'UniformOutput',false);
    numParticlesToSection = cellfun(@(particlesSection) size(particlesSection,1), particleToPos, 'UniformOutput',false);
    numParticlesSimSection = cellfun(@(particlesSection) size(particlesSection,1), particleSimPos(:,1), 'UniformOutput',false);

%% Calculates NNDs
    % Calculates distances between from and to particles (only for non empty). One for each section
    realNNDs = cellfun(@(pf,pt) nnd2Sets(pf,pt), particleFromPos, particleToPos, 'UniformOutput', false);

    % Calculates distances involving simulated particles. One for each section/simulation

    % Case I: Sim-Sim
    if all(fromRadius==toRadius)
        simNNDs = cellfun(@(pf,pt) nnd2Sets(pf,pt), particleSimPos, particleSimPos, 'UniformOutput', false);
    % Case II: Sim-To
    elseif all(simulation.simradius==fromRadius)
        simNNDs = cellfun(@(pf,pt) nnd2Sets(pf,pt), particleSimPos, repmat(particleToPos, simulation.numSimulations,1)', 'UniformOutput',false);
    % Case III: From-Sim
    else
        simNNDs = cellfun(@(pf,pt) nnd2Sets(pf,pt), repmat(particleFromPos, simulation.numSimulations,1)', particleSimPos, 'UniformOutput',false);
    end

    % All simulated particles per section One for each section (with size numParticles x numSimulations)
    allSimNNDs = arrayfun(@(ROWIDX) horzcat(simNNDs{ROWIDX,:}), 1:size(simNNDs,1), 'Uniform', 0); 
    allSimNNDs = cellfun(@(nnds) nnds(:), allSimNNDs, 'UniformOutput',false);                   
    
    % Mean and standard deviation of real NNDs for each section
    meanRealNNDs = cell2mat(cellfun(@(nndSec) mean(nndSec), realNNDs, 'UniformOutput',false))';     % Mean NND per section      
    stdRealNNDs = cell2mat(cellfun(@(nndSec) std(nndSec), realNNDs, 'UniformOutput',false))';       % Std. Dev NND per section      
    % Mean and standard deviation of simulated for NNDs each section/simulation
    meanSimNNDs = cell2mat(cellfun(@(nndSec) mean(nndSec), simNNDs, 'UniformOutput',false));            % Mean Sim NND per section/simulation 
    stdSimNNDs = cell2mat(cellfun(@(nndSec) std(nndSec), simNNDs, 'UniformOutput',false));              % Std. dev. Sim NND per section/simulation 
    % Mean and standard deviation of all simulated NNDs for each section
    allMeanSimNNDs = cell2mat(cellfun(@(nndSec) mean(nndSec), allSimNNDs, 'UniformOutput',false))';     % Mean Sim NND per section
    allStdSimNNDs = cell2mat(cellfun(@(nndSec) std(nndSec), allSimNNDs, 'UniformOutput',false))';       % Std. dev. Sim NND per section

%% rawNNDs 
    % idSerie, idSection, NND(From)
    serieIDParticle = cell2mat(arrayfun(@(v,r) repmat(v,1,r), serieIDSection', cell2mat(numParticlesFromSection), 'UniformOutput',false));
    sectionIDParticle = cell2mat(arrayfun(@(v,r) repmat(v,1,r), sectionIDSection', cell2mat(numParticlesFromSection), 'UniformOutput',false));
    rawNNDs = [serieIDParticle', sectionIDParticle', vertcat(realNNDs{:})];

    % Returns if there is no information
    if isempty(rawNNDs)
        return
    end    

%% sumSection 
    % idSerie, idSection, numParticlesFrom, numParticlesTo, mean(NND), std(NND) 
    sumSection = [serieIDSection, sectionIDSection, cell2mat(numParticlesFromSection)', cell2mat(numParticlesToSection)', meanRealNNDs, stdRealNNDs];

%% sumSeries (for each serie and for the whole set)
    % idSerie, numSections, mean(NND) std(NND)
    sumSeries = zeros(simulation.data.numSeries+1,4);    
    for serieId=1:simulation.data.numSeries
        sectionsSerie = (serieIDSection==serieId);
        serieNNDs = cell2mat(realNNDs(sectionsSerie)');
        sumSeries(serieId,1) = serieId;
        sumSeries(serieId,2) = sum(sectionsSerie);
        sumSeries(serieId,3) = mean(serieNNDs);
        sumSeries(serieId,4) = std(serieNNDs);
    end
    % Includes total in summary
    allNDDs = cell2mat(realNNDs');
    sumSeries(simulation.data.numSeries+1,1) = simulation.data.numSeries+1;
    sumSeries(simulation.data.numSeries+1,2) = numValidSections;              
    sumSeries(simulation.data.numSeries+1,3) = mean(allNDDs);
    sumSeries(simulation.data.numSeries+1,4) = std(allNDDs);


%% rawSimNNDs: (for each section/particle)
%   % idSerie, idSection NNDsFrom {numParticlesFrom x numSimulations}
    rawSimNNDs = [num2cell(serieIDSection), num2cell(sectionIDSection), allSimNNDs'];
    %% IMPORTANT
    % For efficiency, it should be returned like this. But in order to
    % preserve the structure of rawNNDs and make it easy to compute, this
    % data will be returned in long form.
    
    try
        colNNDs = vertcat(rawSimNNDs{:,3});
        colSeries = cell2mat(arrayfun(@(v,r) repmat(v,1,r), cell2mat(rawSimNNDs(:,1)),cellfun(@(c) size(c,1), rawSimNNDs(:,3)),'UniformOutput',false)');
        colSections = cell2mat(arrayfun(@(v,r) repmat(v,1,r), cell2mat(rawSimNNDs(:,2)),cellfun(@(c) size(c,1), rawSimNNDs(:,3)),'UniformOutput',false)');
        rawSimNNDs = [colSeries',colSections', colNNDs];
    catch
        GPDQStatus.repError('Data can not be returned in long form', true, dbstack());
    end

%% sumSimSection: For each section
%   % idSerie, idSection, numParticlesFrom, numParticlesTo, mean(realNND), std(realNND), mean(simNND), ci(simNND), asoc, disoc];
    sumSimSection = sumSection;

    % For each section, calculates the mean and CI from the simulated means
    meanPopSimNNDs = mean(meanSimNNDs,2);  
    ciPopSimNNDs =  quantile(meanSimNNDs', [0.025;0.9775])';
    sumSimSection = [sumSimSection, meanPopSimNNDs, ciPopSimNNDs];

    % Computes association of dissociation
    asoc =  meanRealNNDs<ciPopSimNNDs(:,1);
    disoc =  meanRealNNDs>ciPopSimNNDs(:,2);
    sumSimSection = [sumSimSection, asoc, disoc];

    % Alternative
    % idSerie, idSection, numParticlesFrom, numParticlesTo, mean(realNND), std(realNND), mean(allSimNND), std(allSimNND), ci(simNND), asoc, disoc];
%     ciPopSimNNDs =  cell2mat(cellfun(@(nnds) quantile(nnds, [0.025;0.9775]), allSimNNDs, 'UniformOutput',false))';
%     asoc =  meanRealNNDs<ciPopSimNNDs(:,1);
%     disoc =  meanRealNNDs>ciPopSimNNDs(:,2);
%     sumSimSection = [sumSimSection, allMeanSimNNDs, allStdSimNNDs, ciPopSimNNDs, asoc, disoc]; 


%% sumSimSeries (for each serie)
%   idSerie, numSections, mean(NND), std(NND), mean(simNND), pvalor(meanNNDs), numAsoc, numDisoc

    sumSimSeries = zeros(simulation.data.numSeries+1,8); 
    sumSimSeries(:,1:4) = sumSeries;

    for serieId=1:simulation.data.numSeries
        sectionsSerie = (serieIDSection==serieId);
        sumSimSeries(serieId, 5) = mean(sumSimSection(sectionsSerie, 7));
        [h,p,ci,stats] = ttest(sumSimSection(sectionsSerie, 5),sumSimSection(sectionsSerie, 7),'Tail','both');
        sumSimSeries(serieId,6) = p;
        sumSimSeries(serieId,7) = sum(sumSimSection(sumSimSection(:,1)==serieId,10));
        sumSimSeries(serieId,8) = sum(sumSimSection(sumSimSection(:,1)==serieId,11));
    end

    sumSimSeries(serieId+1, 5) = mean(sumSimSection(:,7));
    [h,p,ci,stats] = ttest(sumSimSection(:, 5),sumSimSection(:, 7),'Tail','both');
    sumSimSeries(serieId+1,6) = p;
    sumSimSeries(serieId+1,7) = sum(sumSimSection(:,10));
    sumSimSeries(serieId+1,8) = sum(sumSimSection(:,11));    

    %% Converts to series if necessary
    if asCell
        rawNNDs = num2cell(rawNNDs);
        sumSection = num2cell(sumSection);
        sumSeries = num2cell(sumSeries);
        rawSimNNDs = num2cell(rawSimNNDs);
        sumSimSection = num2cell(sumSimSection);
        sumSimSeries = num2cell(sumSimSeries);
    end

%% serieNames (for each serie)    
    serieNames = vertcat(simulation.data.expSeries(:,1),'ALL');

%% sectionNames (for each section)   
    sectionNames = cell(numValidSections, 2);
    sectionNames(:,1) = arrayfun(@(posSection) serieNames{posSection}, serieIDSection, 'UniformOutput',false);
    sectionNames (:,2) = arrayfun(@(posSection) secImageFile(simulation.data.sections(posSection).image, simulation.data.sections(posSection).section), sectionIDSection, 'UniformOutput',false);
end

