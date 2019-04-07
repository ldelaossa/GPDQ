%% gpdqGUI Calls the main application.
%
% Parameters
% ----------
%
%   relativeSize: [0.5 1] Size of the window, relative to the screen.
%
%   projectFileName: Full name of a .csv file containing a project.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)


function gpdqGUI(relativeSize, projectFileName)
global config;

% Avoids multiple openings of the figure.
windowMeasureScale = findobj('type', 'figure', 'tag', 'gpdqGUI');
if ~isempty(windowMeasureScale)
    GPDQStatus.repError('Another instance of gpdqGUI is already open. It must be closed first', true, dbstack());
    figure(windowMeasureScale);
    return;
end

% Default size (height) is 85% of the screen.
if nargin<1
    relativeSize = 0.85;
end

if nargin<2
    projectFileName = [];
end


%% GUI Definition

HFig = [];
gpdqGUIFig();

%-- Window
set(HFig.mainFigure,'CloseRequestFcn',@quit);

%-- Menu
set(HFig.menuNew,'Callback',@createNewProject);
set(HFig.menuOpen,'Callback',@openProject);
set(HFig.menuSave,'Callback',@saveProject);
set(HFig.menuSaveAs,'Callback',@saveProjectAs);
set(HFig.menuQuit, 'Callback',@quit);
%-----
set(HFig.menuUpdateData, 'Callback', @updateProjectData);
set(HFig.menuLoadData, 'Callback', @loadProjectData);
set(HFig.menuSaveData, 'Callback', @saveProjectData);
set(HFig.menuReport, 'Callback',@projectReport);
set(HFig.menuReportParticles, 'Callback',@particleReport);
%-----
set(HFig.menuNNDs,'Callback',@exploreNNDsEvt);
set(HFig.menuClusters,'Callback',@exploreClustersEvt);
set(HFig.menuDensities,'Callback', @exploreDensitiesEvt);
%-----
set(HFig.mFigSim,'Callback',@showSimulationFig);
set(HFig.mClusteringSim,'Callback',@showClusteringFig);

%-----
set(HFig.mGroupRenaming,'Callback',@renameGroupsEvt);
set(HFig.menuScaleCal, 'CallBack', @scaleImage);
%-----
set(HFig.menuAbout, 'Callback',@showAbout);
set(HFig.menuHelp, 'Callback', @showHelp);

%----- Info data
set(HFig.projectInfoDataButton, 'Callback', @showInfoData);
set(HFig.projectUpdateDataButton, 'Callback', @updateProjectData);

%----- Left Table
set(HFig.sectionsTable, 'CellSelectionCallback', @selectSectionCallBack);
set(HFig.sectionsTable,'CellEditCallBack',@editSectionDefCallBack);

set(HFig.addSectionMenu, 'Callback', @addSectionCI);
set(HFig.remSectionMenu, 'Callback',@removeSection);
set(HFig.scaleSectionMenu, 'Callback', @scaleCurrentSection);

set(HFig.sortButton,'Callback',@sortProject);
set(HFig.addButton,'Callback',@addSection);
set(HFig.removeButton, 'Callback',@removeSection);

%----- Right Panel
set(HFig.showParticlesCheckBox,'Callback',@changeShowMarks);
set(HFig.editSectionButton,'Callback',@editSectionMask);
set(HFig.labelSectionButton,'Callback',@labelSection);


%% Application data

% Information on the current project.
currentProject = [];                              % GPDQProject containing the project definition.
currentData = [];                                 % GPDQData contanining the project data.
% Current section.

currentSectionId = [];                            % Index of the current section.
currentSection = [];                              % Information of the current section (the one currently shown)

%% Initialization

% If a project is passes as parameter, loads it.
if ~isempty(projectFileName)
    [projectDir, projectFile, projectExt] = fileparts(projectFileName);
    loadProject(projectDir, [projectFile, projectExt]);
end

% Returns then the figure is closed.
waitfor(HFig.mainFigure);

%% -----------------------------------------------------------
%  Callbacks and auxiliar functions (Alphabetic order)
% ------------------------------------------------------------

%% Adds a new section
    function addSection(~,~)
        % Returns if there is no project loaded
        if isempty(currentProject)
            GPDQStatus.repError('There is no active project.', false, dbstack());
            return
        end
        
        % Opens the files
        [selImageList, selImageDir, ] = uigetfile(fullfile(currentProject.workingDirectory, config.imageType), 'Select images to add', 'MultiSelect', 'on');

        % Determines the number of images.    
        if iscell(selImageList)
            numImages = numel(selImageList);
        % If the list is not a cell, and is not 0, it is an string
        elseif selImageList ~= 0
            numImages = 1;
            % Stores the name of the image in a cell (to use the same code).
            tmpCell = cell(1);
            tmpCell{1} = selImageList;
            selImageList = tmpCell;
        else
            % Otherwise (tmpImageList==0) it returns.
            return;
        end
        
        % For integrity, only allows adding files in the subfolder.         
        % Determines if the selected files are in currentProjectDir of
        % any subfolder
        isSubFolder = false;
        if strcmp(selImageDir,currentProject.workingDirectory)
            isSubFolder = true;
        else
            subFolders = getSubdirList(currentProject.workingDirectory);
            for subFoldId=1:numel(subFolders)
                if strcmp(selImageDir(1:end-1), subFolders(subFoldId))
                    isSubFolder = true;
                    break;
                end
            end
        end        
        
        % If the selected images are not in the current directory or any of its subfolders, returns.
        if ~isSubFolder
            GPDQStatus.repError('Only images in the working directory can be added.', true, dbstack());
            return;
        end 
        
        % Otherwise, includes the images.
        if isSubFolder
            errors = false;
            for imageId=1:numImages
                % Extracts the file name.
                file = fullfile(selImageDir, selImageList{imageId});            
                relativePathFile = strrep(file, [currentProject.workingDirectory filesep], '');
                result = currentProject.addSection(relativePathFile);
                % If there has been some error, return.
                if GPDQStatus.isError(result)
                    errors = true;
                end
                if errors
                    GPDQStatus.repError('It has not been possible to add some of the sections.', true, dbstack());
                end
            end
        end        
        % Updates the table.
        updateTable();
    end

%% Adds a section from the current image
    function addSectionCI(~,~)
        % Returns if there is no project loaded
        if isempty(currentProject)
            GPDQStatus.repError('There is no active project.', false, dbstack());
            return
        end        
        % Adds it.
        result = currentProject.addSectionPos(currentSectionId+1, currentSection.imageFile,[], currentSection.group, currentSection.scale);
        % If there has been some error, return.
        if GPDQStatus.isError(result)
            GPDQStatus.repError('It has not been possible to add the section.', true, dbstack());
            return
        end
        
        % Updates the table.
        updateTable();     
        
    end


%%  Shows the section (and shows the marks depending on the state of the checkbox.
    function changeShowMarks(~,~)
        showCurrentSection();
    end

%% Creates a new project and stores it in the work space.
    function createNewProject(~,~)
        % Asks for name an directory.
        newProjectDir = uigetdir('.', 'Select project directory (where the images are)');
        if newProjectDir==0
            GPDQStatus.repError('Definition of new project aborted.' ,false, dbstack());
            return
        end
        
        % Loads the project definition
        try
            newProject = newProjectEdit(newProjectDir, config.imageType, '_sec_');
        catch % Returns if there is some problem
            GPDQStatus.repError('There has been a problem while creating the new project.', true, dbstack());
            return
        end
        
        % If the project creation has been aborted, returns.
        if isempty(newProject) || isempty(newProject.data) || GPDQStatus.isError(newProject) ||  GPDQStatus.isCanceled(newProject)
            GPDQStatus.repError('Creation of project aborted. The list of images is empty.', true, dbstack());
            return
        end
        
        % Saves the project in a file. As the path to the images are relative
        % to the directory where the project is located it can not be saved anywhere else.
        savedSuccess = newProject.save();
        % If there has been a problem while saving, tries again.
        if GPDQStatus.isError(savedSuccess)
            while true
                [newProjectName, newProjectFilePath] = uiputfile('*.csv','Save the new project',fullfile(newProjectDir,'New Project.csv'));
                % If the operation has been cancelled, return.
                if isempty(newProjectName) || (numel(newProjectName)==1 && newProjectName==0)
                    GPDQStatus.repError('Definition of new project aborted.',false, dbstack());
                    return
                end
                % If the project directory and path to the file matches, is ok.
                if strcmp(newProjectFilePath, [newProjectDir filesep])
                    newProject.fileName = newProjectName;
                    savedSuccess = newProject.save();
                    if savedSuccess
                        break
                    end
                else
                    GPDQStatus.repError('The project file must be saved in the same folder it was created.', true, dbstack());
                    continue;
                end
            end
        end
        
        % At this point, creation is considered as successful
        currentProject = newProject;
        
        % Updates the inteface.
        gpdqGUIFigScale(currentProject.imageSize(1));
        set(HFig.projectTitleText, 'String', fullfile(currentProject.workingDirectory, currentProject.fileName));
        updateTable();
        
        % Sets the first section as current
        setCurrentSection(1);
    end

%% Edit a section. The name of the image can not be edited.
     function editSectionDefCallBack(objectHandle,eventData) 
         % Gets the indexes of the edited cell.
         sectionId = eventData.Indices(1);
         field = eventData.Indices(2);
         
         % If the field is section, the new value must be an integer.
         if field==3
             sectionNumber = uint32(str2num(eventData.EditData));
             % If it is not a positive integer, returns to the previous data.
             if isempty(sectionNumber) || floor(sectionNumber)~=sectionNumber || sectionNumber<1
                 GPDQStatus.repError('Sections must be identified by positive integers',true, dbstack())
                 objectHandle.Data{sectionId, field} = eventData.PreviousData;
                 return
                 
             elseif currentProject.existsSection(currentProject.data{sectionId,1}, sectionNumber)
                 GPDQStatus.repError('The image/section already exists.',true, dbstack())
                 objectHandle.Data{sectionId, field} = eventData.PreviousData;
                 return
             else
                 % If it is a positive integer, updates the table and the application data.
                 objectHandle.Data{sectionId, field} = sectionNumber;
                 currentProject.data{sectionId,2} = sectionNumber;
             end
         end
         
        % If the field is scale, it must be an double.
        if field==5    
            scale = double(str2num(eventData.EditData));
            % If it is not a positive double, returns to the previous data.
            if ~isscalar(scale) || isempty(scale) || scale<=0
                GPDQStatus.repError('Scale must be given as a real number.',true, dbstack())
                objectHandle.Data{sectionId, field} = eventData.PreviousData;
                return
            % If it is a positive, updates the table and the application data.
            else     
                % Updates the table and the application data.
                objectHandle.Data{sectionId, field} = scale;             
                currentProject.data{sectionId,4} = scale;
            end
        end       
        
        % Otherwise, the updated value corresponds to the group
        % Updates the current section and project
        if field==4  
            group = eventData.EditData;
            % Updates the table and the application data.
            objectHandle.Data{sectionId, field} = group;
            currentProject.data{sectionId,3} = group; 
        end
         % Flags de section
         flagSection(sectionId);
         % Updates the current section
         setCurrentSection(sectionId);         
     end
 
%% Modifies the current section.
    function editSectionMask(~,~)
        % If there is no name for the section, the operation is aborted.
        if ~isempty(currentSection.section)
            createSection(currentSection.imageFilePath, currentSection.maskFilePath);
        else
            GPDQStatus.repError('Assign an identifier to the section before its creation', true, dbstack());
            return;
        end
        
        % Shows the section. Notice that only changes the section if the file has been saved.
        if exist(currentSection.maskFilePath, 'file')
            [currentSection.mask] = getSectionMask(readImage(currentSection.maskFilePath));
        end
        
        % Shows the current section.
        showCurrentSection();
    end

%% Enables data functions
    function enableDataFunctions(flag)
        set(HFig.menuSaveData,'Enable', flag);
        set(HFig.projectInfoDataButton,'Enable', flag);
        set(HFig.menuNNDs,'Enable',flag);
        set(HFig.menuDensities,'Enable',flag);
        set(HFig.menuClusters,'Enable',flag);     
        set(HFig.menuReport,'Enable',flag);
        set(HFig.menuReportParticles,'Enable',flag);        
    end

%% Explores the clusters
    function exploreClustersEvt(~,~)
        if isempty(currentProject)
            exploreClusters;
        else
            exploreClusters(currentData, currentProject.workingDirectory, 50);
        end
    end

%% Explores the clusteres
    function exploreDensitiesEvt(~,~)
        if isempty(currentProject)
            exploreDensities;
        else
            exploreDensities(currentData, currentProject.workingDirectory);
        end
    end

%% Explores NNDs
    function exploreNNDsEvt(~,~)
        if isempty(currentData)
            exploreNNDs;
        else
            exploreNNDs(currentData, currentProject.workingDirectory);
        end
    end

%% Assigns a color to a section depending on whether it is complete or not.
    function flagSection(idSection)
        if currentProject.isComplete(idSection)
            HFig.sectionsTable.Data{idSection, 1} = colorString('#BBFFFF','&nbsp;');
        else
            HFig.sectionsTable.Data{idSection, 1} = colorString('#FFBBBB','&nbsp;');
        end
    end

%% Assigns a color to each  section depending on whether it is complete or not.
    function flagSections()
        for idSection=1:currentProject.numSections
            flagSection(idSection);
        end
    end


%% Allows labeling a section
    function labelSection(~ , ~)
        % It is not possible to label a section if it does not exist.
        if isempty(currentSection.section)
            GPDQStatus.repError('Assign an identifier to the section before labeling.', true, dbstack());
            return
        end
        
        % If the scale does not exist, returns.
        if isempty(currentSection.scale)
            GPDQStatus.repError('You must introce the scale before labeling.', true, dbstack());
            return
        end
        
        % Launches section labeling.
        [centers, radii, actualRadii] = sectionLabeling(currentSection.image, currentSection.mask, currentSection.scale, 'SectionName',currentSection.maskFilePath,'File',[currentSection.dataFilePath],'Overwrite',false,'SizeGUI',0.6);
        
        % Updates the data.
        if ~isempty(radii)
            currentSection.particles = zeros(numel(radii),4);
            currentSection.particles(:,1:2) = centers;
            currentSection.particles(:,3) = radii;
            currentSection.particles(:,4) = actualRadii;
        end
        
        % Shows the section
        showCurrentSection();
    end


%% Loads a project.
    function loadProject(tmpProjectDirectory, tmpProjectFile)
        % Tries to open the configuration file, shows error if it does not
        % exist of the format is not correct.
        tmpProject = GPDQProject.readFromFile(tmpProjectDirectory, tmpProjectFile);
        
        % Reports and returns in case there is an error.
        if GPDQStatus.isError(tmpProject)
            GPDQStatus.repError(['Error when opening the project ' fullfile(tmpProjectDirectory, tmpProjectFile) '. Check the format of the file.'], true, dbstack());
            return
        end
        
        %% At this point, creation is considered as successful
        currentProject = tmpProject;
        
        % Updates the inteface.
        set(HFig.projectTitleText, 'String', fullfile(currentProject.workingDirectory, currentProject.fileName));
        enableDataFunctions('Off');
        
        updateTable();
        
        % Sets the first section as current
        setCurrentSection(1);
        
        
    end

%% Loads a project.
    function loadProjectData(~,~)
        % Opens the file
        if isempty(currentProject)
            [tmpDataFile, tmpDataDirectory] = uigetfile('*.mat');
        else
            [tmpDataFile, tmpDataDirectory] = uigetfile(fullfile(currentProject.workingDirectory,'*.mat'));
        end    
        
        % If no file has been selected, returns.
        if tmpDataFile==0
            GPDQStatus.repWarning('Aborted data loading', false, dbstack());
            return;
        end
        
        % Only allows data in the same folder.
        if ~strcmp(tmpDataDirectory(1:end-1), currentProject.workingDirectory)
            GPDQStatus.repError('Project and data file must be located in the same folder', true, dbstack());
            return
        end
        
        % Loads the data
        try
            currentData = GPDQData.load(fullfile(tmpDataDirectory, tmpDataFile));
            GPDQStatus.repSuccess('Data sucessfully loaded');
        catch
            GPDQStatus.repError('Error when loading data', true, dbstack());
        end
        
        % Enables data function if necessary
        if ~GPDQStatus.isError(currentData)
            enableDataFunctions('On');
        end
        
    end

%% Opens a project.
    function openProject(~,~)
        % Opens the file
        if isempty(currentProject)
            [tmpProjectFile, tmpProjectDirectory] = uigetfile('*.csv');
        else
            [tmpProjectFile, tmpProjectDirectory] = uigetfile(fullfile(currentProject.workingDirectory,'*.csv'));
        end
        
        % If no file has been selected, returns.
        if tmpProjectFile==0
            GPDQStatus.repWarning('Aborted project opening', false, dbstack());
            return;
        end
        
        loadProject(tmpProjectDirectory, tmpProjectFile);
        
    end

%% Shows particle report.
    function particleReport(~,~)
        if isempty(currentData)
            GPDQStatus.repError('Project data is currently empty', true, dbstack());
            return;
        end
        report = currentData.particleReport(true);
        showReport(report, fullfile(currentProject.workingDirectory, 'REP_PARTICLES_PR.csv'));
    end

%% Shows project report.
    function projectReport(~,~)
        if isempty(currentData)
            GPDQStatus.repError('Project data is currently empty', true, dbstack());
            return;
        end        
        report = currentData.projectReport();
        showReport(report, fullfile(currentProject.workingDirectory, 'REP_SECTIONS_PR.csv'));
    end

%% Closes the application.
    function quit(~,~)
        if  ~isempty(currentProject)
            choice = questdlg({'Save before exit'}, ' Warning', 'Yes', 'Exit without saving', 'Cancel', 'Yes');
            % Handle response
            if strcmp(choice, 'Cancel')
                return
            end
            if strcmp(choice, 'Yes')
                result = currentProject.save();
                if GPDQStatus.isError(result)
                    GPDQStatus.repError(['Error when saving the project ' fullfile(currentProject.workingDirectory, currentProject.fileName)], true, dbstack());
                    return;
                end
            end
        end
        delete(gcf);
    end


%% Rename groups
    function renameGroupsEvt(~,~)
        tmpProject = renameGroups(currentProject);
        % Return if it is cancelled.
        if GPDQStatus.isCanceled(tmpProject)
            return;
        end
        
        % Otherwise, updates the project
        currentProject = tmpProject;
        
        % Updates the inteface.
        set(HFig.projectTitleText, 'String', fullfile(currentProject.workingDirectory, currentProject.fileName));
        updateTable();
        
        % Sets the first section as current
        setCurrentSection(1);
    end


%% Removes a section
    function removeSection(~,~)
         % Returns if there is no project loaded
        if isempty(currentProject)
            GPDQStatus.repError('There is no active project.', false, dbstack());
            return
        end
        % If there is no section, return.
        if isempty(currentProject.data)
            GPDQStatus.repError('There is no sections left to be removed.', false, dbstack());
            return;
        end
          
        % Removes.
        result = currentProject.removeSection(currentSectionId);
        if GPDQStatus.isError(result)
            GPDQStatus.repError('There has been a problem when trying to remove the section', true, dbstack());
            return;
        end
        
        % If the section has been removed, updates the table   
        updateTable();
        
        % Moves to the next section if it exists. Otherwise, to the previous.
        nextSectionId = currentSectionId;
        if currentSectionId>currentProject.numSections
            nextSectionId = nextSectionId-1;
        end        
        % If there is no sections, disables the button.
        if nextSectionId==0
            set(HFig.removeButton,'Enable','off');
            imshow([], 'Parent', HFig.axesSection);
            set(HFig.sectionText,'String', []);                    
        else
            % Shows the corresponding section.
            setCurrentSection(nextSectionId);
            pause(0.25);
            HFig.sectionsTableCtrl.changeSelection(nextSectionId-1,1, false, false);
        end
    end


%% Saves a project. 
    function saveProject(~,~)
        if isempty(currentProject)
            return
        end        
        result = currentProject.save();
        fullProjectName = fullfile(currentProject.workingDirectory, currentProject.fileName);
        if ~GPDQStatus.isError(result)
            GPDQStatus.repSuccess(['Project ' fullProjectName  ' sucessfully saved']);
        else
            GPDQStatus.repError(['Error when saving the project ' fullProjectName], true, dbstack());            
        end
    end

%% Saves a project and changes its name 
    function saveProjectAs(~,~)
        if isempty(currentProject)
            return
        end
        fullProjectName = fullfile(currentProject.workingDirectory, currentProject.fileName);
        [tmpProjectName, tmpWorkDirectory] = uiputfile('*.csv', 'Save project as', fullProjectName);
         % If no file is selected, the function returns.
          if isempty(tmpProjectName) || (numel(tmpProjectName)==1 && tmpProjectName==0)
              return
          end

        % If the directory changes, there can be a problem because the
        % paths of the images are relative to the location of the file.
        if ~strcmp(tmpWorkDirectory, currentProject.workingDirectory)
            % Construct a questdlg with three options
            choice = questdlg({'Attempting to change the location of the project configuration file.' ...
                               'The paths to the images are RELATIVE to the location of the file' ...
                               'and might become not valid' 'Proceed anyway?'}, ' Warning', 'Cancel', 'Proceed anyway', 'Cancel');
            % If cancel, return.
            if strcmp(choice, 'Cancel')
                return
            end
        end

        % Stores the old references
        oldWorkDirectory = currentProject.workingDirectory;
        oldProjectName = currentProject.fileName;
        % Updates the references
        currentProject.workingDirectory=tmpWorkDirectory;
        currentProject.fileName = tmpProjectName;
        newFullProjectName = fullfile(currentProject.workingDirectory, currentProject.fileName);
        % Tries to save the project
        result = currentProject.save();
        if ~GPDQStatus.isError(result)
            GPDQStatus.repSuccess(['Project ' newFullProjectName  ' sucessfully saved']);
            set(HFig.projectTitleText, 'String', newFullProjectName); 
        else
            GPDQStatus.repError(['Error when saving the project ' fullProjectName], true, dbstack());   
            currentProject.workingDir=oldWorkDirectory;
            currentProject.fileName = oldProjectName;
        end            
    end


%% Saves a project and changes its name 
    function saveProjectData(~,~)
        if isempty(currentProject)
            return
        end
        fullProjectDataName = fullfile(currentProject.workingDirectory, currentProject.fileName);
        fullProjectDataName(end-3:end)=".mat";
        [tmpProjectDataName, tmpSaveDirectory] = uiputfile('*.mat', 'Save project data as', fullProjectDataName);
         % If no file is selected, the function returns.
          if isempty(tmpProjectDataName) || (numel(tmpProjectDataName)==1 && tmpProjectDataName==0)
              return
          end
        newFullProjectDataName = fullfile(tmpSaveDirectory, tmpProjectDataName);
        
        result = GPDQData.save(currentData, newFullProjectDataName);
        if ~GPDQStatus.isError(result)
            GPDQStatus.repSuccess(['Data succesfully saved in ' newFullProjectDataName]);
        else
            GPDQStatus.repError(['Error when saving the data of project ' fullProjectDataName], true, dbstack());   
        end            
    end

%% Calculates the scale for the current section
    function scaleCurrentSection(~,~)
        measureScale(currentSection.imageFilePath);
    end

%% Allows calculating the scale of some image.
    function scaleImage(~,~)
        measureScale();
    end



%% Selects a section
    function selectSectionCallBack(~ ,eventData)
        % Avoids some errors (when loading a project, it calls the selection... wrongly?).
        if isempty(eventData.Indices)
            return;
        end
        % Sets the current section
        setCurrentSection(eventData.Indices(1));
    end

%% Establishes the current section (the one which is shown.
    function setCurrentSection(idSection)
        % Updates current section.
        currentSectionId = idSection;
        % Gets the information.
        currentSection = currentProject.getSectionData(currentSectionId);
        % Updates the section which is shown.
        showCurrentSection();
    end


%% Shows window with the autorship and copyright information.
    function showAbout(~,~)
        about()
    end

%% Shows simulation figures
    function showClusteringFig(~,~)
        showClusters(currentSection);
    end

%% Shows the image with the current (selected) section.
    function showCurrentSection()
        % If the image is empty, shows an error and returns.
        if GPDQStatus.isError(currentSection) || isempty(currentSection.image) 
            % Shows the empty object.
            imshow([], 'Parent', HFig.axesSection);
            % Shows a message.
            warningMsg = 'The section does not exist or its name/number is not valid (remove section).';
            set(HFig.sectionText,'String', warningMsg);
            GPDQStatus.repWarning(warningMsg, false, dbstack());  % The information is already shown.
            
            % Disables the button to label and edit the section.
            set(HFig.editSectionButton,'Enable','off');
            set(HFig.labelSectionButton,'Enable','off');
            return
        end
        
        % Updates the size.
        gpdqGUIFigScale(currentProject.imageSize(currentSectionId));
        % If there is an image, enables the buttons
        set(HFig.editSectionButton,'Enable','on');
        set(HFig.labelSectionButton,'Enable','on');
        
        % Creates a new image where the section can be distinguised
        imageShown = currentSection.image;
        if ~isempty(currentSection.mask)
            imageShown(~currentSection.mask) = imageShown(~currentSection.mask)./3;
        end
        % Shows it
        imshow(imageShown, 'Parent', HFig.axesSection);
        % Draws the marks if necessary.
        if get(HFig.showParticlesCheckBox,'Value')
            showMarks();
        end
        % Shows the textual information.
        showInfoSection();
    end 

%% Shows window with help.
    function showHelp(~,~)
        web('https://ldelaossa.github.io/GPDQ','-browser')
    end

%% Shows info of current data
    function showInfoData(~,~)
        if isempty(currentData)
            GPDQStatus.repWarning('Data are not calculated/loaded', true, dbstack());
        else
            infoText(currentData.descriptionString, 'Current data');
        end
    end

%% Shows the information related to the section.
    function showInfoSection()
        % This function is called from showCurrentSection only if the image is
        % not empty. But this test is done just in case future modifications change this.
        if isempty(currentSection.image)
            GPDQStatus.repError('The object containing the image should not be empty', false, dbstack());
            return
        end
        
        % Builds the message
        infoSection = sprintf('IMAGE\t %s.', currentSection.imageFile);
        
        % Information about section.
        % If both the index and the mask exist shows the ordinary message
        if ~isempty(currentSection.section) && ~isempty(currentSection.mask)
            infoSection = strvcat(infoSection,sprintf('SECTION:\t %d', currentSection.section));
            % If only the name of the section exist, reports it.
        elseif ~isempty(currentSection.section)
            infoSection = strvcat(infoSection,sprintf('SECTION:\t %d (does not exist)', currentSection.section));
            % If not even the section name exist
        else
            infoSection = strvcat(infoSection,sprintf('SECTION:\t not specified'));
        end
        
        % Group
        if ~isempty(currentSection.group)
            infoSection = strvcat(infoSection,sprintf('GROUP:\t %s', currentSection.group));
        else
            infoSection = strvcat(infoSection,sprintf('GROUP:\t not specified'));
        end
        
        % Scale and area
        if ~isempty(currentSection.scale)
            infoSection = strvcat(infoSection,sprintf('SCALE:\t %.4f Nm/pixel',currentSection.scale));
            if ~isempty(currentSection.mask)
                area = areaSection(currentSection.mask,currentSection.scale);
            else
                area = areaSection(currentSection.image,currentSection.scale, false);
            end
            infoSection = strvcat(infoSection,sprintf('AREA:\t %.4f Sq. micra', area));
        else
            infoSection = strvcat(infoSection,sprintf('SCALE:\t Not specified'));
            infoSection = strvcat(infoSection,sprintf('AREA:\t Not available without scale'));
        end
        
        % Particles
        infoSection = strvcat(infoSection,sprintf('PARTICLES:\t\t %3d',size(currentSection.particles,1)));
        if ~isempty(currentSection.particles)
            for particleTypeId=1:numel(config.particleTypes)
                radius = config.particleTypes(particleTypeId).radius;
                tmpParticles = find(currentSection.particles(:,4)==radius);
                %if tmpParticles>0
                if particleTypeId<numel(config.particleTypes)
                    infoSection = strvcat(infoSection,sprintf(' * %3.1f Nm     %3d',config.particleTypes(particleTypeId).radius,size(tmpParticles,1)));
                else
                    infoSection = strvcat(infoSection,sprintf(' * Other      %3d',size(tmpParticles,1)));
                end
            end
        end
        % Updates the component.
        set(HFig.sectionText,'String', infoSection);
    end

%% Shows the marks corresponding to the section.
    function showMarks()
        % Marks are only shown if they exist and the scale has been fixed.
        if ~isempty(currentSection.particles) && ~isempty(currentSection.scale)
            centersPx =  currentSection.particles(:,1:2)./currentSection.scale;
            % Shows each kind of particle.
            for particleTypeId=1:numel(config.particleTypes)
                radius = config.particleTypes(particleTypeId).radius;
                color = config.particleTypes(particleTypeId).color;
                tmpParticles = currentSection.particles(:,4)==radius;
                markPoints(centersPx(tmpParticles,1:2), radius, '-', 1, color, false, HFig.axesSection);
            end
            % Special particles, with radius = 0
            radius = 0;
            color = 'yellow';
            tmpParticles = currentSection.particles(:,4)==radius;
            markPoints(centersPx(tmpParticles,1:2), 5, '-', 1, color, false, HFig.axesSection);
        end
    end

%% Shows simulation figures
    function showSimulationFig(~,~)
        showSimulation(currentSection);
    end

%% Sorts the project
    function sortProject(~,~)
        % Sorts
        currentProject.sort();
        % Updates the table.
        updateTable();
    end
%% Updates project data (for analysis)
    function updateProjectData(~, ~)
        currentData = createData(currentProject);
        if GPDQStatus.isError(currentData)
            GPDQStatus.repError('Error loading project data', true, dbstack());
            return;
        elseif GPDQStatus.isCanceled(currentData)
            GPDQStatus.repWarning('Cancelled project data loading', true, dbstack());
            return;
        end
        % Everything is ok
        enableDataFunctions('On');
        GPDQStatus.repSuccess('Project data sucessfully updated');
        return;
    end

%% Updates the table from the data in the project.
    function updateTable()
        % Stores some space for the marks.
        tableData = currentProject.data;
        tableData = [cell(currentProject.numSections,1) tableData];
        % Updates the data in the table.
        set(HFig.sectionsTable,'data',tableData);
        % Updates the flags
        flagSections();
    end

%% -----------------------------------------------------------
%  GUI Creation
% ------------------------------------------------------------

    function gpdqGUIFig
        % Main Figure
        HFig.mainFigure = figure('NumberTitle','off','Units', 'pixels', 'resize','off','menubar', 'none', 'DockControls','off','Visible','off');
        set(HFig.mainFigure,'Name', 'GPDQ v1.0');
        set(HFig.mainFigure,'Name',  ['GPDQ v' config.version]);
        set(HFig.mainFigure,'tag','gpdqGUI');                     % The tag is necessary to avoid opening more than one instance.
        figureColor = get(HFig.mainFigure, 'color');
        
        % Menu -> File
        HFig.menuFile = uimenu(HFig.mainFigure,'Label','File');
        HFig.menuNew = uimenu(HFig.menuFile,'Label','New','Accelerator','N','Enable','on');
        HFig.menuOpen = uimenu(HFig.menuFile,'Label','Open','Accelerator','O');
        HFig.menuOpenRecent = uimenu(HFig.menuFile,'Label','Open recent','Accelerator','R', 'Enable','Off');
        HFig.menuClose = uimenu(HFig.menuFile,'Label','Close','Accelerator','C','Enable','off');
        HFig.menuSave = uimenu(HFig.menuFile,'Label','Save', 'Separator','on','Accelerator','S');
        HFig.menuSaveAs = uimenu(HFig.menuFile,'Label','Save As','Accelerator','A');
        HFig.menuPref = uimenu(HFig.menuFile,'Label','Preferences','Accelerator','F','Separator','on','Enable','off');
        HFig.menuQuit = uimenu(HFig.menuFile,'Label','Quit','Separator','on','Accelerator','Q');
        % Menu -> Project
        HFig.mProject = uimenu(HFig.mainFigure,'Label','Project data','Enable','on');
        HFig.menuUpdateData = uimenu(HFig.mProject,'Label','Update project data','Enable','on');
        HFig.menuLoadData = uimenu(HFig.mProject,'Label','Load project data','Enable','on');
        HFig.menuSaveData = uimenu(HFig.mProject,'Label','Save project data','Enable','off');
        % Menu -> Report
        HFig.mReport = uimenu(HFig.mainFigure,'Label','Reports','Enable','on');
        HFig.menuReport = uimenu(HFig.mReport,'Label','Project report','Enable','off');
        HFig.menuReportParticles = uimenu(HFig.mReport,'Label','Particle report','Enable','off');
        % Menu -> Exploration
        HFig.menuExplore = uimenu(HFig.mainFigure,'Label','Exploration','Enable','on');
        HFig.menuNNDs = uimenu(HFig.menuExplore,'Label','NNDs','Enable','off');
        HFig.menuDensities = uimenu(HFig.menuExplore,'Label','Densities','Enable','off');
        HFig.menuClusters = uimenu(HFig.menuExplore,'Label','Clusters','Enable','off');
        % Menu -> Analysis
        HFig.mAnalysis = uimenu(HFig.mainFigure,'Label','Analysis','Enable','off');        
        % Menu -> Simulation
        HFig.mSim = uimenu(HFig.mainFigure,'Label','Simulation','Enable','on');
        % Menu -> Figures
        HFig.mFig = uimenu(HFig.mainFigure,'Label','Figures','Enable','on');
        HFig.mFigSim = uimenu(HFig.mFig,'Label','Simulation','Enable','on');
        HFig.mClusteringSim = uimenu(HFig.mFig,'Label','Clusters','Enable','on');
        % Menu -> Utils
        HFig.mUtils = uimenu(HFig.mainFigure, 'Label', 'Utilities');
        HFig.mGroupRenaming = uimenu(HFig.mUtils, 'Label', 'Rename groups', 'Enable','on');
        HFig.menuScaleCal = uimenu(HFig.mUtils,'Separator','on','Label','Scale calculation');
        % Menu -> Preferences
        HFig.mPref = uimenu(HFig.mainFigure,'Label','Preferences','Enable','off');
        % Menu -> About
        HFig.mHelp = uimenu(HFig.mainFigure,'Label','Help');
        HFig.menuHelp = uimenu(HFig.mHelp,'Label','Help','Accelerator','H','Enable','on');
        HFig.menuAbout = uimenu(HFig.mHelp,'Label','About','Separator','on');
        
        % Project title
        HFig.projectTitle = uicontrol('Style', 'Text', 'String', 'Project','HorizontalAlignment','left','backgroundcolor',figureColor);
        HFig.projectTitleText = uicontrol('Style', 'Edit', 'Enable', 'inactive', 'String', '','HorizontalAlignment','left','backgroundcolor','white');
        HFig.projectInfoDataButton = uicontrol('Style', 'pushbutton', 'String', 'Info data', 'Enable','Off');
        HFig.projectUpdateDataButton = uicontrol('Style', 'pushbutton', 'String', 'Update data', 'Enable','On');
        
        % Left panel (Sections)
        HFig.panelProject = uipanel(HFig.mainFigure,'Units','pixels','Title','Sections list ');
        HFig.sortButton = uicontrol('Parent', HFig.panelProject, 'Style', 'pushbutton', 'String', 'Sort');
        set(HFig.sortButton,'Tooltipstring', 'Sorts the sections by group/image/number');
        HFig.removeButton = uicontrol('Parent', HFig.panelProject, 'Style', 'pushbutton', 'String', 'Remove');
        set(HFig.removeButton,'Tooltipstring', 'Remove the current section');
        HFig.addButton = uicontrol('Parent',HFig.panelProject, 'Style', 'pushbutton', 'String', 'Add');
        set(HFig.addButton, 'Tooltipstring', 'Adds a new section');
        
        % Sections table
        colNames = {'','IMAGE','SECTION','GROUP','SCALE'};
        colFormat = {'char','char','numeric','char','numeric'};
        colEditable = [false, false, true, true, true]; % It is not allowed to change the name of the images.
        HFig.sectionsTable = uitable('parent', HFig.panelProject,'ColumnName',colNames,'ColumnEditable',colEditable,'RowName',[]);
        HFig.sectionListMenu = uicontextmenu();
        HFig.addSectionMenu = uimenu(HFig.sectionListMenu,'Label','Add section to current image');
        HFig.remSectionMenu = uimenu(HFig.sectionListMenu,'Label','Remove current section');
        HFig.scaleSectionMenu = uimenu(HFig.sectionListMenu,'Label','Get scale current section');
        set(HFig.sectionsTable,'UIContextMenu',HFig.sectionListMenu);
        
        % Right panel (Current section)
        HFig.panelSection= uipanel('Parent', HFig.mainFigure, 'Units','pixels','Title','Current Section');
        HFig.editSectionButton = uicontrol('Parent',HFig.panelSection,'Style', 'pushbutton','Enable','off', 'String', 'Edit');
        HFig.labelSectionButton= uicontrol('Parent',HFig.panelSection,'Style', 'pushbutton', 'Enable','off','String', 'Labeling');
        HFig.showParticlesCheckBox = uicontrol('Parent',HFig.panelSection,'Style', 'checkbox', 'String', 'Show marks');
        HFig.sectionText=uicontrol('Parent',HFig.panelSection,'Style', 'Edit', 'HorizontalAlignment','left','FontSize',9,'String','Section data','Enable','inactive', 'backgroundcolor','white');
        set(HFig.sectionText,'Max', 15);
        set(HFig.sectionText,'fontname','FixedWidth');
        HFig.axesSection = axes('Parent',HFig.panelSection,'Units','pixels','visible','off');
        % Scales the figure
        gpdqGUIFigScale()
        % Adjusts the size of the font.
        HFig = setFonts(HFig);
        % Shows the figure
        set(HFig.mainFigure,'Visible','on');
    end


%% -----------------------------------------------------------
%  GUI resizing
% ------------------------------------------------------------

    function gpdqGUIFigScale(imageSizePx)
        % Default image frame.
        if nargin<1
            imageSizePx = [1224 1204];
        end
        
        % Get the screen size
        screenSize = get(0,'Screensize');
        
        % Initial height and position. Centers vertically
        figureHeightPx = screenSize(4)*relativeSize;
        figurePosYPx = (screenSize(4)-figureHeightPx)/2;
        
        % Variables storing the sizes of the elements (FIX SIZE)
        marginPx = 10;                                                                                  % Minimum margin between components.
        buttonWidthPx = 80;                                                                             % Width of the buttons.
        buttonHeightPx = 25;                                                                            % Height of the buttons, labels and texts
        infoTextSectionPx = 150;                                                                        % Height of text for the section
        panelProjectWithPx = 550;                                                                       % Width of the left panel.                                         % Size of the image which is shown
        
        % Variables storing the sizes of the elements (VARIABLE SIZE)
        panelHeightsPx = figureHeightPx-2*marginPx-2*buttonHeightPx;                                    % Height of the pannels.
        tableWidthPx =panelProjectWithPx-2*marginPx;                                                    % Width of the table showing the project.
        axesImageSectionHeightPx =panelHeightsPx-3*marginPx-3*buttonHeightPx-infoTextSectionPx;         % Height of the axes where images are shown.
        axesImageSectionWidthPx = imageSizePx(2)*axesImageSectionHeightPx/imageSizePx(1);               % Width of the axes where images are shown.
        panelSectionWithPx = axesImageSectionWidthPx+2*marginPx;                                        % Width of the panel where the sections are shown.
        
        % Width of the figure (Vary according to the images and the height of the figure)
        figureWidthPx = 4*marginPx+panelProjectWithPx+panelSectionWithPx;
        figurePosXPx = (screenSize(3)-figureWidthPx)/2;
        
        % Main figure
        set(HFig.mainFigure,'Position',[figurePosXPx figurePosYPx figureWidthPx figureHeightPx]);
        
        % Project title
        set(HFig.projectTitle, 'Position', [2*marginPx figureHeightPx-2*marginPx-buttonHeightPx 60 buttonHeightPx]);
        set(HFig.projectTitleText, 'Position', [3*marginPx+60 figureHeightPx-2*marginPx-buttonHeightPx+5 figureWidthPx-6*marginPx-60-2*buttonWidthPx buttonHeightPx]);
        set(HFig.projectInfoDataButton, 'Position', [figureWidthPx-2*buttonWidthPx-2*marginPx figureHeightPx-2*marginPx-buttonHeightPx+5 buttonWidthPx buttonHeightPx]);
        set(HFig.projectUpdateDataButton, 'Position', [figureWidthPx-buttonWidthPx-marginPx figureHeightPx-2*marginPx-buttonHeightPx+5 buttonWidthPx buttonHeightPx]);

        % Left panel (Sections)
        set(HFig.panelProject,'Position',[marginPx, marginPx, panelProjectWithPx, panelHeightsPx]);
        set(HFig.sortButton,'Position', [marginPx, marginPx, buttonWidthPx, buttonHeightPx]);
        set(HFig.removeButton,'Position', [panelProjectWithPx-marginPx-buttonWidthPx, marginPx, buttonWidthPx, buttonHeightPx]);
        set(HFig.addButton,'Position',[panelProjectWithPx-2*marginPx-2*buttonWidthPx, marginPx, buttonWidthPx, buttonHeightPx]);
        
        % Sections table
        colWidthPx = {tableWidthPx*0.05,tableWidthPx*0.45,tableWidthPx*0.1,tableWidthPx*0.25,tableWidthPx*0.1};
        set(HFig.sectionsTable,'ColumnWidth',colWidthPx)
        set(HFig.sectionsTable,'Position', [marginPx, buttonHeightPx+2*marginPx, panelProjectWithPx-2*marginPx, panelHeightsPx-buttonHeightPx-4*marginPx]);
        jUIScrollPane = findjobj(HFig.sectionsTable);
        HFig.sectionsTableCtrl = jUIScrollPane.getViewport.getView; 
        
        % Right panel (Current section)
        set(HFig.panelSection,'Position',[panelProjectWithPx+3*marginPx, marginPx, panelSectionWithPx, panelHeightsPx]);
        set(HFig.editSectionButton,'Position', [panelSectionWithPx-buttonWidthPx-marginPx, marginPx, buttonWidthPx, buttonHeightPx]);
        set(HFig.labelSectionButton,'Position', [panelSectionWithPx-2*buttonWidthPx-2*marginPx, marginPx, buttonWidthPx, buttonHeightPx]);
        set(HFig.showParticlesCheckBox,'Position', [marginPx, marginPx, 100, buttonHeightPx]);
        set(HFig.sectionText,'Position', [marginPx, 2*marginPx+buttonHeightPx, panelSectionWithPx-2*marginPx, infoTextSectionPx]);
        set(HFig.axesSection,'Position',[marginPx, infoTextSectionPx+2*buttonHeightPx+2*marginPx, panelSectionWithPx-2*marginPx, axesImageSectionHeightPx]);
    end

end
