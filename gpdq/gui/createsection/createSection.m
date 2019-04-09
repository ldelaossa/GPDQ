%% createSection Given an image, allows creating an image with a section, such that the rest of pixels are white. 
% The new image is both saved and returned. If no name has been passed
% in the second parameter, it can be edited, and allows generating multiple
% sections from the same image. Otherwise, only allows one section.
%
% For multiple sections, they are saved as:
% - imageSectionName_sec_1.tif, imageSectionName_sec_2.tif, etc.
%
% If there is an error in the process, returns GPDQStatus.ERROR or  GPDQStatus.CANCELED.
% 
% Usage
% -----
%
%       imageSection = createSection(imageName, imageSectionName)
%
% Example
% -------
%
%       imageSection = createSection('AXON/23.tif', 'AXON/23_sec_1.tif')
%
% Parameters
% ----------
%
%   imageName: File containing the image.
%
%   imageSectionName: Name of the file containing the section.
%
% Returns
% -------
% 
%   imageSection: Depending on whether imageSectionName has been passed as
%   argument returns:
%       - The image with the section 
%       - A cell array with the images with the sections. 
%       - GPDQStatus.ERROR/GPDQStatus.CANCELED.

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function imageSection = createSection(imageName, imageSectionName)
    global config;

    % Avoids multiple openings of the figure.
    windowCreateSection = findobj('type', 'figure', 'tag', 'createSection');
    if ~isempty(windowCreateSection)
        GPDQStatus.repError('Another instance of createSection is already open. It must be closed first', true, dbstack());
        figure(windowCreateSection);
        return;
    end
    
    % Inits output and mask
    imageSection = GPDQStatus.ERROR;
    mask = [];
    
    % Reads the image.
    try
        image = imread(imageName);
    catch
        GPDQStatus.repError(['It has been imposible to read the image ' imageName], true, dbstack());
        return;
    end
    
    %% Builds the figure 
    
    HFig = createSectionFig(image);
    % Window: HFig.mainFigure
    % Image: HFig.hImageAxes, HFig.imageHandle
    % Buttons left: HFig.clearButton, HFig.invertCB
    % Buttons down right: HFig.saveButton, HFig.closeButton
    % Section name: HFig.sectionText, HFig.fileEditText
    
    % Name of the figure
    set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version '. Create section: ' imageName]);
    
    % If the name of the resulting image has been passed as parameter, it can not be edited.
    % And it does not allow creating multiple sections. Also, if the mask
    % already exists, shows it. 
    if (nargin == 2)
        set(HFig.fileEditText,'String', imageSectionName);
        set(HFig.fileEditText,'Enable','off');
        set(HFig.uniqueSec,'Enable','off');
        try
            mask = getSectionMask(readImage(imageSectionName));
        catch
            GPDQStatus.repWarning(['The section ' imageSectionName 'does not exist.'], false, dbstack());
        end   
    else
        set(HFig.uniqueSec,'Enable','on');
    end
    
    % Callbacks
    set(HFig.mainFigure,'CloseRequestFcn',@close);
    set(HFig.clearButton, 'Callback', @clear);
    set(HFig.invertCB, 'Callback', @invert);
    set(HFig.saveButton,'Callback', @save);
    set(HFig.closeButton,'Callback', @close);
    set(HFig.imageHandle,'ButtonDownFcn',@imageClick);
    
    
    % Resulting image
    imageRes=[];
    
    % Creates a mask or shows the existing one. 
    if isempty(mask)
        mask= false(size(image));
    else
        showMaskedImage;
    end
    
    % This indicates whether the selected region must be included or discarded. 
    includeSelected=true;
    
    % Flag indicating if the mask has been updated since last saving.
    updated = true;
    
    %% Functions
        
    % Returns when the figure is closed.
    waitfor(HFig.mainFigure);
    
    % Function imageClick
    % Creates an imfreehand object.
    function imageClick ( ~ , ~ )
        try
            imFH = drawfreehand;
        catch
            imFH = imfreehand;
        end
        % The new mask is added.
        if includeSelected
            mask = or(mask,imFH.createMask());
        else
            mask(imFH.createMask())=false;
        end
        % The mask has changed and it is not updated in the file.
        updated = false;
        showMaskedImage;        
    end
      
    % Function invert
    function invert(~,~)
        includeSelected = ~includeSelected;
    end
    
    % Function clear
    % Clears the mask.
    function clear(~,~)
        mask= false(size(image));
        updated = true;
        showMaskedImage;
    end

    % Function showMaskedImage
    % Shows the masked image.
    function showMaskedImage
        imageRes = image;
        imageRes(mask)=imageRes(mask).*1.33;
        imageRes(~mask)=imageRes(~mask).*0.66;
        HFig.imageHandle = imshow(imageRes, 'Parent', HFig.hImageAxes);
        set(HFig.imageHandle,'ButtonDownFcn',@imageClick);
    end

    % Function save
    % Saves the current image.
    function result = save(~,~)
        fileName = get(HFig.fileEditText,'String');
        if isempty(fileName)
            GPDQStatus.repError('The name of the file is empty', true, dbstack());
            result = GPDQStatus.ERROR;
            return
        end
        
        % Whether to use a unique section
        uniqueSection=get(HFig.uniqueSec,'Value');
        
        % Builds a cell array of masks
        if uniqueSection
            % Creates the mask
            masks = cell(1,1);
            masks{1} = mask;
        else
            % Detects the objects.
            objects = bwconncomp(mask);
            % Creates each individual mask
            masks = cell(objects.NumObjects,1);
            for nMask=1:objects.NumObjects
                sectionMask = false(size(image));
                sectionMask(objects.PixelIdxList{nMask})=true;
                masks{nMask}=sectionMask;
            end
        end
        
        % Saves each mask. 
        for idMask=1:numel(masks)
            sectionMask = masks{idMask};
            % Creates the image with the section
            imageSection = image;
            imageSection(~sectionMask)=65535;
            % Name of the section
            if uniqueSection
                sectionFileName=fileName;
            else
                sectionFileName = secImageFile(fileName, idMask);
            end
            
            % So that extension is the same for image and sections. 
            [~, ~, extF] = fileparts(imageName);
            [pathS, fileS, ~] = fileparts(sectionFileName);
            sectionFileName = fullfile(pathS,[fileS extF]);
            try
                
                imwrite(imageSection, sectionFileName, extF(2:end));
                GPDQStatus.repSuccess(['Image saved as: ' sectionFileName]);
                updated = true;
                result = 1;
            catch
                imageSection = GPDQStatus.ERROR;
                GPDQStatus.repError(['There has been an error when attempting to save ' sectionFileName], true, dbstack());
                result = GPDQStatus.ERROR;
            end            
        end 
    end


    % Function cancel
    % Closes the window and returns []
    function close(~,~)
        % If the image with the section has not been saved but the mask exists.
        if ~updated
            % Construct a questdlg with three options
            choice = questdlg('Do you want to close the figure without saving?', ' Warning', 'Cancel', 'Close without saving','Save and close','Save and close');
            % Handle response
            switch choice
                case 'Cancel' % Do not close.
                    return;
                case 'Close without saving' % Closes without saving.
                    imageSection = GPDQStatus.CANCELED;               
                case 'Save and close' % Saves and closes.
                    if GPDQStatus.isError(save())
                        return;
                    end  
            end      
        end
       delete(HFig.mainFigure);
    end
end

