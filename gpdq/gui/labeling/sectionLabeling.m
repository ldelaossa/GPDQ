%% sectionLabeling
% Allows interactive labeling of particles in an image. It also includes automatic detection.
%
% Usage
% -----
%    
%       sectionLabeling(image, maskSection, scale, detectionFcn, varargin)
%
% Example
% -------
%
%        [centersNm, actualRadiiNm, radiiNm] = sectionLabeling(image', mask, 1.4583, 'SectionName','Axon 1_sec_1','File','Axon 1_sec_1.csv','Overwrite',false,'SizeGUI',0.7)
%
% Parameters
% ----------
%
%   image: Object containing the image.
%
%   maskSection: Binary mask with the section of interest.
%
%   scale: Scale of the image (Nanometers/Pixel).
% 
%   SectionName: (Optional) String containing the name of the image with the section.
%
%   File: (Optional) String containig the name of the file where the results must be written in csv format.
%
%   Overwrite: (Optional) Logical value indicating if information in the file must be overwritten.
%
%   SizeGUI: (Optional) Double value (0,1) indicating the size of the main figure in relation with the maximum possible size in the screen.
%
% Returns
% -------
%
%   centersNm: Centers of the detected particles (Nanometers)
%
%   radiiNm: Radii (expected) of the detected particles (Nanometers)
%
%   actualRadiiNm: Radii (actual) of the detected particles (Nanometers)

% Author: Luis de la Ossa (luis.delaossa@uclm.es).

function [centersNm, actualRadiiNm, radiiNm] = sectionLabeling (image, maskSection, scale, varargin)
    % Reads the global settings.
    global config;
    % Disables warning for small circles.
    warning('off','images:imfindcircles:warnForSmallRadius');
    warning('off','images:imfindcircles:warnForLargeRadiusRange');
    % Disables warning for big images 
    warning('off','images:initSize:adjustingMag');
    
    if size(image)~=size(maskSection)
        GPDQStatus.repError('The sizes of the image and mask must be similar.', true, dbstack());
        centersNm = GPDQStatus.ERROR;
        return;
    end
   
    %% Options
    % Parse function inputs
    parseInput = inputParser;
    validateRange = @(x) validateattributes(x, {'double'},{'>',0,'<',1});
    validateRangeZoom = @(x) validateattributes(x, {'double'},{'>=',100});
    % Name of the image
    parseInput.addOptional('SectionName',[]);
    % Name of the file where the results must be written
    parseInput.addOptional('File',[]);
    % Whether to append or overwrite
    parseInput.addOptional('Overwrite', false, @islogical);
    % Relative size of the window
    parseInput.addOptional('SizeGUI',0.7,validateRange);
    % Size of the zoom in nanometers
    parseInput.addOptional('ZoomSize', 0, validateRangeZoom);
    % Extracts  the parameters
    parseInput.parse(varargin{:});
    sizeGUI = parseInput.Results.SizeGUI;
    sectionName = parseInput.Results.SectionName;
    resultsFile = parseInput.Results.File;
    zoomSize = parseInput.Results.ZoomSize;
    % Checks if it must write the results.
    if ~isempty(resultsFile)
        writeFile = true;
        overwrite = parseInput.Results.Overwrite;
    else
        writeFile = false;
    end


    %% Variables 
    % Gets the configuration
    particleTypes = config.particleTypes;    
    
    % Scale of the underlying image used for detection (Nm/Pixel) 
    ampScale = 0.5;     
    
    % Default parameters
    currentParticleType = 2; % The default category corresponds to 5 Nm
    particleColor = particleTypes(currentParticleType).color;
    radiusNm = particleTypes(currentParticleType).radius;
    sensitivity = 0.75; % Default sensitivity
    marginRadiusNm = 2; % Due to blurring, and focusing, we allow 2Nm
    
    % Other parameters used in particle detection. 
    radiusPx = 0; radiusScaledPx = 0; 
    maxRadiusPx = 0; minRadiusPx = 0;
    marginRadiusPx = 0; marginRadiusScaledPx = 0;
    minDistNm = 0; minDistPx = 0;
    
    % Calculates all measures.
    updateRadius();    
    
    % The images are scaled to 0.5 nm/pixel so that the dots can be detected. In order to select detect a particle, it is used an image of 20nm.
    particleImageSideNm = 20;
    particleImageSidePx = particleImageSideNm ./ ampScale;  
    
    % Main image
    [imageHeightPx imageWidthPx] = size(image);
    imageHeightNm = imageHeightPx .* scale;
    imageWidthNm = imageWidthPx .* scale;    
    
    % Zoom image 
    if zoomSize>0 && zoomSize<min(imageHeightNm, imageWidthNm)
        zoomImageSizeNm = zoomSize;
    else
        zoomImageSizeNm = round(min(imageHeightNm, imageWidthNm)/3,-2); % Rounds to multiples of 100
    end    
    
    zoomImageSizePx = zoomImageSizeNm ./ scale;
    zoomImageSizeScaledPx = zoomImageSizeNm ./ ampScale; 
    
    %  Structures containing the results
    centersPx = [];
    centersNm = [];
    actRadiiPx = [];
    actualRadiiNm = [];
    radiiNm = [];    

    % Structures containing the graphical marks
    particleMarks = [];
    zoomParticleMarks = [];
    zoomDiscardedMarks = []; 
    
    
    % Loads the main image and builds the mask.
    if isempty(maskSection)              % Sometimes the mask is empty. 
         maskSection=ones(size(image));
    end
    maskedImage = image;
    maskedImage(~maskSection) = maskedImage(~maskSection)./2;   
    
    
    %% GUI Definition
    % Creates the figure.
    HFig = createFig();
    
    % Assigns callbacks
    set(HFig.mainFigure, 'CloseRequestFcn', @closeCallBack);
    set(HFig.mainFigure, 'windowbuttonupfcn',@imageMouseReleased);
    set(HFig.handleImage,'ButtonDownFcn',@imageClickCallBack);
    set(HFig.toogleMarksCheckBox,'Callback',@toogleMarks); 
    set(HFig.autDetectionButton,'Callback',@automaticDet);   
    set(HFig.clearButton,'Callback',@clear);   
    set(HFig.closeButton,'Callback',@closeCallBack); 
    set(HFig.saveButton,'Callback',@save); 
    set(HFig.radPopup,'Callback',@editRadius);
    set(HFig.sensEdit, 'Callback', @editSensitivity);
    set(HFig.marginEdit, 'Callback', @editMargin);
    set(HFig.confCheckBox, 'Callback', @toogleAssistCallBack);    



    %% Creates the zoom 
    positionZoomPx = [imageWidthPx/2-zoomImageSizePx/2 imageHeightPx/2-zoomImageSizePx/2 zoomImageSizePx zoomImageSizePx];
    % Declares these elements so that they can be accesed in the whole function
    zoomRectangle = [];
    zoomRectangleMov = imrect(HFig.axesImage, positionZoomPx);
    fcn = makeConstrainToRectFcn('imrect',get(HFig.axesImage,'XLim'),get(HFig.axesImage,'YLim'));
    setPositionConstraintFcn(zoomRectangleMov,fcn);   
    setResizable(zoomRectangleMov,false);
    imageZoom = [];
    maskedImageZoom = [];
    handleZoom = [];
    

    % If there is a file and it is not overwritten, the dots must be shown.
    if writeFile && ~overwrite
        try
            datacsv = csvread(resultsFile);
            % Converts measures to pixels.
            datacsv(:,1:3) = datacsv(:,1:3)./scale;
            centersPx = datacsv(:,1:2);
            actRadiiPx = datacsv(:,3);
            radiiNm = datacsv(:,4);
            % Draws all particles
            addAllParticleMarks();
            centersNm = centersPx .* scale;
            actualRadiiNm = actRadiiPx .* scale;
         catch 
            GPDQStatus.repError([resultsFile ' does not exist or is not a valid .csv file. A new file will be created.'], false, dbstack());
         end     
    end

    % Whether the information in the file has been updated.
    updated = true;

    % Sets the zoom 
    setZoom();

    % Waits for the main figure to return results.
    waitfor(HFig.mainFigure);      
    
    
%% -----------------------------------------------------------
%  Callbacks and functions (alphabetical order)
% ------------------------------------------------------------


%% Adds all particle marks
    function addAllParticleMarks()
        particleMarks = gobjects(numel(radiiNm,1));
        for typeParticle=0:numel(particleTypes)
            if (typeParticle>0)
                radius = particleTypes(typeParticle).radius;
                color =  particleTypes(typeParticle).color;
                particlesRadius = find(radiiNm==radius);
            else %Undetermined particles (they are shown in yellow, with radius 5)
                radius = 5;
                color =  'yellow';
                particlesRadius = find(radiiNm==0);
            end
            
            for particle=1:numel(particlesRadius)
                particleId = particlesRadius(particle);
                mark =  drawCircle (centersPx(particleId,1), centersPx(particleId,2), radius, '-', 1, color, true, HFig.axesImage);
                set(mark,'HitTest','off');
                particleMarks(particleId)= mark;
            end
        end
    end


%% Adds all zoom particle marks
    function addAllZoomParticleMarks()
         % Draws those dots already detected in the zoom. Some where deleted and are not marked.
        if (numel(centersPx)>0)
             selected = centersPx(:,1)>positionZoomPx(1) & centersPx(:,1)<positionZoomPx(1) +zoomImageSizePx & ...
                        centersPx(:,2)>positionZoomPx(2) & centersPx(:,2)<positionZoomPx(2) +zoomImageSizePx;
             centersZoomPx = centersPx(selected,:);
             radiiZoomNm = radiiNm(selected);
             if numel(centersZoomPx)>0
                centersZoomPx(:,1) = centersZoomPx(:,1)-positionZoomPx(1);
                centersZoomPx(:,2) = centersZoomPx(:,2)-positionZoomPx(2);
                centersZoomPx = centersZoomPx .* scale ./ ampScale;    
                % Draws each kind of particles.
                numTypeParticles = numel(particleTypes);
                for typeParticle=0:numTypeParticles
                    if (typeParticle>0)
                        radius = particleTypes(typeParticle).radius;
                        color =  particleTypes(typeParticle).color;
                        centers = find(radiiZoomNm == radius); 
                    else %Undetermined particles (they are shown in yellow, with radius 5)
                        radius = 5;
                        color = 'yellow';
                        centers = find(radiiZoomNm == 0); 
                    end
                     
                    for i=1:size(centers)
                        addMarkToZoom(centersZoomPx(centers(i),1),centersZoomPx(centers(i),2), radius./ampScale, color);
                    end
                end  
             end % numel(centersZoomPx)>0
        end % (numel(centersPx)>0)   
    end


%% Adds a discarded mark in zoom
    function addDiscardedMarkToZoom(coordX, coordY)
        sizePx = max(10,radiusScaledPx);
        mark =  rectangle('Position',[coordX-sizePx, coordY-sizePx, 2*sizePx, 2*sizePx], 'LineWidth',1,'EdgeColor', 'white','FaceColor','white','Parent',HFig.axesZoom);
        set(mark,'ButtonDownFcn',@deleteDiscardedMark);  
        zoomDiscardedMarks = [zoomDiscardedMarks; mark];        
    end

%% Adds a particle to the zoom.
    function addMarkToZoom(coordX, coordY, radius, color)
        if radius==0
            mark =  drawCircle (coordX, coordY, 3./ampScale, '-', 2, color, false, HFig.axesZoom);
        else
            mark =  drawCircle (coordX, coordY, radius, '-', 2, color, false, HFig.axesZoom);
        end
        set(mark,'ButtonDownFcn',@deleteParticle);  
        zoomParticleMarks = [zoomParticleMarks; mark];
    end


%% Adds a particle to the main image and results.
    function result = addParticle(coordX, coordY, radiusNm, actRadiusPx,color)
        % Does not allow overlapped particles. 
        if numel(centersPx>0)
            distNearest = min(pdist2(centersPx,[coordX,coordY]));
            if distNearest < minDistPx
                result = false; % The particle has not been added.
                return 
            end
        end
        % Adds the particle.
        centersPx = [centersPx; [coordX coordY]];
        radiiNm = [radiiNm; radiusNm];
        actRadiiPx = [actRadiiPx; actRadiusPx]; 
        % Adds the mark
        if radiusNm==0   % For undetermined marks radius is 5.
            mark =  drawCircle (coordX, coordY, 5, '-', 2, color, true, HFig.axesImage);
        else
            mark =  drawCircle (coordX, coordY, radiusNm, '-', 2, color, true, HFig.axesImage);
        end
        set(mark,'HitTest','off');
        particleMarks = [particleMarks, mark];
        updated = false;   % Results have been modified.
        result = true;     % The particle has been added.
        return;
    end

%% Clears all particles
    function clear( ~, ~ )
        % Deletes all results
        centersPx = [];
        centersNm = [];
        actRadiiPx = [];
        actualRadiiNm = [];
        radiiNm = [];  
        % Structures containing the graphical dots
        clearParticleMarks();
        clearDiscardedMarks();
        clearZoomParticleMarks();
    end % clear

%% Clears all discarded marks from the zoom.
    function clearDiscardedMarks()
        numMarks = numel(zoomDiscardedMarks);
        % Deletes the graphical objects
        for numMark=1:numMarks
            mark = zoomDiscardedMarks(numMark);
            delete(mark);
        end
        % Deletes the references.
        zoomDiscardedMarks=[];
    end


%% Clears all particle marks
    function clearParticleMarks()
        numMarks = numel(particleMarks);
        % Deletes the graphical objects
        for numMark=1:numMarks
            mark = particleMarks(numMark);
            delete(mark);
        end
        % Deletes the references.
        particleMarks = [];    
    end


%% Clears all particles in zoom marks
    function clearZoomParticleMarks()
        numMarks = numel(zoomParticleMarks);
        % Deletes the graphical objects
        for numMark=1:numMarks,
            mark = zoomParticleMarks(numMark);
            delete(mark);
        end
        % Deletes the references.
        zoomParticleMarks=[];        
    end

%% Closes the figure.
    function closeCallBack ( ~ , ~)
        % Translates results to nanometers.
        centersNm = centersPx .* scale;
        actualRadiiNm = actRadiiPx .* scale;
        % If everything is updated does not show the dialog.
        if updated
            delete(gcf);
            return
        end
        % Construct a questdlg with three options
        choice = questdlg('Do you want to close the figure without saving?', ' Warning', 'Cancel', 'Close without saving','Save and close','Save and close');
        % Handle response
        switch choice
            case 'Cancel' % Do not close.
                return;
            case 'Close without saving' % Closes without saving.
                delete(gcf);
            case 'Save and close' % Saves and closes.
                save();
                delete(gcf);
        end
    end % closeCallback

%% Deletes a discarded mark.
    function deleteDiscardedMark(objectHandle , ~)
         delete(objectHandle)
    end

%% Deletes a particle.
    function deleteParticle(objectHandle , ~)
        % Gets the position
        position = get(objectHandle,'Position');
        centerZoomPx = [position(1)+position(3)/2, position(2)+position(4)/2];
        centerPx = positionZoomPx(1:2) + centerZoomPx.*ampScale./scale;
        % Removes the particle (only one can be found)
        % indMarkZoom (Maybe it is necessary to delete the particle from the zoomMarks)
        indPart= find(centersPx(:,1)<centerPx(1)+3 & centersPx(:,1)>centerPx(1)-3 & centersPx(:,2)<centerPx(2)+3 & centersPx(:,2)>centerPx(2)-3); 
        centersPx(indPart,:)=[];
        radiiNm(indPart,:) = [];
        actRadiiPx(indPart,:) = [];
        % Removes the mark from both images.
        delete(objectHandle)
        particleMark = particleMarks(indPart);
        particleMarks(indPart) = [];
        delete(particleMark);
        updated = false;
    end
%% Sets the margin   
    function editMargin(objectHandle , ~)
        strMargin = get(objectHandle, 'String');
        result = str2double(strMargin);
        if isnan(result)
            GPDQStatus.repError([strMargin ' is not a valid number.'], true, dbstack());
            set(objectHandle,'String',num2str(marginRadiusNm));
            return
        end
        if result<0
         GPDQStatus.repError('Margin must be greater than 0', true, dbstack());
         set(objectHandle,'String',num2str(marginRadiusNm));
         return
        end
        marginRadiusNm = result;
        updateRadius;
    end % editMargin  

%% Edits the radius
    function editRadius(objectHandle , ~)
        currentParticleType = objectHandle.Value;
        oldRadiusNm = radiusNm;
        % When the expeted radius is provided 
        if currentParticleType<=numel(particleTypes)
            particleColor =  particleTypes(currentParticleType).color;
            radiusNm = particleTypes(currentParticleType).radius;
        % Otherwise, when the radius is not used.
        else
            particleColor='yellow';
            set(HFig.confCheckBox,'Value',0);
            toogleAssist(false);
            clearDiscardedMarks();
            radiusNm=0;
        end
        
        % If changes, deletes discarded marks.
        if oldRadiusNm ~= radiusNm
            updateRadius();
        end       
        
        % Depending on whether there is a function available for
        % the detection of the particles, enables or not the button.
%         if ~isempty(detectionFuncion)
%             set(autDetectionButton,'Enable','on')
%         else
%             set(autDetectionButton,'Enable','off')
%         end             
    end

%%  Edits the sensitivity
    function editSensitivity(objectHandle , ~)
        strSensitivity = get(objectHandle, 'String');
        result = str2double(strSensitivity);
        if isnan(result)
            GPDQStatus.repError([strSensitivity ' is not a valid number.'], true, dbstack());
            set(objectHandle,'String',num2str(sensitivity));
            return
        end
        if (result<0.5 || result>0.99)
             GPDQStatus.repError('Sensitivity must be in [0.5,0.99]', true, dbstack());
             set(objectHandle,'String',num2str(sensitivity));
        end
        sensitivity = result;
    end % editSensitivity 

%% When mouse is clicked in the left figure, updates the zoom.
    function imageClickCallBack(~ , ~)
       coordinates = get(HFig.axesImage,'CurrentPoint');
       positionZoomPx(1) = coordinates(1,1)-zoomImageSizePx/2;
       positionZoomPx(2) = coordinates(1,2)-zoomImageSizePx/2;
       setZoom();    
    end



%%  When mouse is released in the left figure, updates the zoom.
    function imageMouseReleased(~ , ~)
        % If the current object is the main image.
        if (gca==HFig.axesImage)
            % If the coordinates of the rectangle have changed, changes the
            % zoom
            positionZoomMovPx = getPosition(zoomRectangleMov);
            if (positionZoomPx(1) ~= positionZoomMovPx(1) || positionZoomPx(2) ~= positionZoomMovPx(2))
                positionZoomPx(1) = positionZoomMovPx(1);
                positionZoomPx(2) = positionZoomMovPx(2);
                setZoom();  
            end
        end
    end

%%  Writes the information in the provided file
    function save(~, ~)
        % Translates results to nanometers.
        centersNm = centersPx .* scale;
        actualRadiiNm = actRadiiPx .* scale;        
        % Writes the data into a file. Although it uses 'wt' as mode, original points are considered.
        file = fopen(resultsFile, 'wt');     
        numParticles = numel(radiiNm);
        for i=1:numParticles
            fprintf(file,'%.4f, %.4f, %.4f, %.1f\n',centersNm(i,1), centersNm(i,2), actualRadiiNm(i),radiiNm(i));
        end
        fclose(file);  
        updated = true;
    end % save




%% Function setZoom
    % Sets the setZoom in the selection function of the image.
    function setZoom()   
        % No part of the rectangle can be outside the image.
        if positionZoomPx(1)<1, positionZoomPx(1) = 1; end
        if positionZoomPx(1)>imageWidthPx-zoomImageSizePx, positionZoomPx(1) = imageWidthPx-zoomImageSizePx; end
        if positionZoomPx(2)<1, positionZoomPx(2) = 1; end
        if positionZoomPx(2)>imageHeightPx-zoomImageSizePx, positionZoomPx(2) = imageHeightPx-zoomImageSizePx; end    
        % Deletes the old rectangle and creates the new one.
        delete(zoomRectangle);
        zoomRectangle = rectangle('Position', positionZoomPx,'EdgeColor','white','LineWidth',3,'Parent',HFig.axesImage,'LineStyle','--');
        positionZoomMovPx = getPosition(zoomRectangleMov);
        if (positionZoomPx(1) ~= positionZoomMovPx(1) || positionZoomPx(2) ~= positionZoomMovPx(2))
            setPosition(zoomRectangleMov,positionZoomPx);
        end
        % It is scaled to final scale so that dot can be detected.
        imageZoom = imcrop(image,positionZoomPx);  
        maskedImageZoom = imcrop(maskedImage,positionZoomPx);  
        imageZoom = imresize(imageZoom, [zoomImageSizeScaledPx zoomImageSizeScaledPx]); 
        maskedImageZoom = imresize(maskedImageZoom, [zoomImageSizeScaledPx zoomImageSizeScaledPx]); 
        axes(HFig.axesZoom);
        handleZoom = imshow(maskedImageZoom);
        %handleZoom = imshow(imageZoom, 'Parent', axesZoom);       
        set(handleZoom,'ButtonDownFcn',@zoomClickCallback);
        % Margin
        zoomMarginPx = particleImageSidePx/2;
        line([zoomMarginPx, zoomMarginPx], [0, zoomImageSizeScaledPx], 'LineStyle', '--', 'LineWidth',2,'Color', 'white');
        line([zoomImageSizeScaledPx - zoomMarginPx, zoomImageSizeScaledPx - zoomMarginPx], [0, zoomImageSizeScaledPx], 'LineStyle', '--', 'LineWidth',2,'Color', 'white');
        line([0, zoomImageSizeScaledPx],[zoomMarginPx, zoomMarginPx], 'LineStyle', '--', 'LineWidth',2,'Color', 'white');
        line([0, zoomImageSizeScaledPx],[zoomImageSizeScaledPx - zoomMarginPx, zoomImageSizeScaledPx - zoomMarginPx], 'LineStyle', '--', 'LineWidth',2,'Color', 'white');
        
        % Clears particle and discarded point marks.        
        clearZoomParticleMarks();
        clearDiscardedMarks();
        addAllZoomParticleMarks();
    end

%% Toogles assist checkbox
    function toogleAssistCallBack(objectHandle, ~)
        status = get(objectHandle, 'Value');
        toogleAssist(status);
    end
    function toogleAssist(status)
        if status
            set(HFig.marginEdit,'Enable','on');
            set(HFig.sensEdit,'Enable','on');
        else
            set(HFig.marginEdit,'Enable','off');
            set(HFig.sensEdit,'Enable','off');            
        end  
    end

%% Toogles the marks
    function toogleMarks(~,~)
        checked = get(HFig.toogleMarksCheckBox,'Value');
        % If not checked, removes the marks
        if ~checked
            clearParticleMarks()
            clearZoomParticleMarks()
        else
            addAllParticleMarks();
            addAllZoomParticleMarks();
        end
    end


%% Updates values affected by changing the value of radiusNm.
    function updateRadius()
        % Especial case por undetermined
        oldRadiusNm = radiusNm;
        if radiusNm==0
            radiusNm=5;
        end
        % Updates radius measures
        radiusPx = radiusNm ./ scale;        
        radiusScaledPx = radiusNm ./ ampScale;     
        % Updates margins.
        marginRadiusPx = marginRadiusNm ./ scale; 
        marginRadiusScaledPx = marginRadiusNm ./ ampScale; 
        % Updates the valid range of radius.
        minRadiusNm = radiusNm - marginRadiusNm;
        minRadiusPx = minRadiusNm ./scale;
        maxRadiusNm = radiusNm + marginRadiusNm;  
        maxRadiusPx = maxRadiusNm ./ scale;
        % Minimimum distance allowed
        minDistNm = radiusNm;
        minDistPx = radiusPx;       
        
        radiusNm = oldRadiusNm;
        
        % Gets the function for automatic detection. TO-DO
        % detectionFuncion = classifierForParticleType(diameterNm);       
    end % updateRadius 
       
%% Function zoomClickCallback
    %  CallBack. When mouse is clicked over the right image. Marks a dot.
    function zoomClickCallback(~ , ~)
        % If marks are deleted, shows them again.
        if ~get(HFig.toogleMarksCheckBox,'Value')
            set(HFig.toogleMarksCheckBox,'Value',1);
            toogleMarks;
        end        
        assistLabeling = get(HFig.confCheckBox, 'Value');
        
        %% Gets the coordinates
        coordinatesZoom = get(HFig.axesZoom,'CurrentPoint'); 
        coordinatesZoom = coordinatesZoom(1,1:2);
        coordinatesImage = positionZoomPx(1:2) + coordinatesZoom.*ampScale./scale;
        % Nothing happens when clicking over the discarded areas.
        if ~maskSection(uint16(coordinatesImage(2)), uint16(coordinatesImage(1)))
         	return
        end
        
        %% If there is no assistance the radius is not measured
        if ~assistLabeling
            % Obtains the actual position and radius in the original image.
            centerScaledPx = [coordinatesZoom(1), coordinatesZoom(2)];
            centerPx = positionZoomPx(1:2) + centerScaledPx.*ampScale./scale;  
            % Add particle returns true if the particle has been added  and false when there is already
            % a particle at a minimum distance.
            if addParticle(centerPx(1), centerPx(2) , radiusNm, 0, particleColor)
                % In this case, it does 
                set(HFig.detRadiusEdit,'String', '--');                         
                set(HFig.detRadiusEdit,'Foregroundcolor','red');   
                % Adds a mark
                if radiusNm>0
                    addMarkToZoom(centerScaledPx(1), centerScaledPx(2), radiusNm/ampScale, particleColor);
                else
                    addMarkToZoom(centerScaledPx(1), centerScaledPx(2), 5/ampScale, particleColor);
                end
            end            
            return;
        end           
        
        %% Otherwise, assists labeling.
        % Gets the image of the dot
        rectParticlePx = [coordinatesZoom(1)-particleImageSidePx/2 ,coordinatesZoom(2)-particleImageSidePx/2,  particleImageSidePx-1, particleImageSidePx-1];
        % Does not allow not complete rectangles (out of the margin)
        if (rectParticlePx(1)<1) || (rectParticlePx(2)<1)
            return
        end
        if ((rectParticlePx(1)+particleImageSidePx-1)>size(imageZoom,1) || (rectParticlePx(2)+particleImageSidePx-1)>size(imageZoom,2))
            return
        end      
        % Extracts the image of the dot and scales it so that circle can be properly detected.
        imageParticle = imcrop(imageZoom, rectParticlePx);                 
        % Gets the main circle in the image of the dot.
        [centerScaledPx, actRadiusScaledPx, ~] = getMainCircle(imageParticle, radiusScaledPx, sensitivity,marginRadiusScaledPx+2);    
        % If some circle has been detected
        if actRadiusScaledPx>0
            % Obtains the actual position and radius in the original image.
            actRadiusPx = actRadiusScaledPx .* ampScale ./ scale;
            centerScaledPx = centerScaledPx + rectParticlePx(1:2);
            centerPx = positionZoomPx(1:2) + centerScaledPx.*ampScale./scale;       
            % Determines if the radius is valid.
            isValidDotRadius = (actRadiusPx>=minRadiusPx && actRadiusPx<=maxRadiusPx);    
            % If it is valid, it is visualized and added.
            if isValidDotRadius
                % Add particle returns true if the particle has been added  and false when 
                % there is already a particle at a minimum distance.
                if addParticle(centerPx(1), centerPx(2) , radiusNm, actRadiusPx, particleColor)
                     % Resports the diameter of the detected point.
                    set(HFig.detRadiusEdit,'String',[num2str(actRadiusPx*scale) ' Nm']);                         
                    set(HFig.detRadiusEdit,'Foregroundcolor','black');   
                    addMarkToZoom(centerScaledPx(1),centerScaledPx(2),radiusScaledPx,particleColor);
                end     
            % Otherwise, they are marked as discarded.             
            else 
                set(HFig.detRadiusEdit,'String',[num2str(actRadiusPx*scale) ' Nm']);  
                set(HFig.detRadiusEdit,'Foregroundcolor','red');
                addDiscardedMarkToZoom(centerScaledPx(1),centerScaledPx(2));            
            end% isValidDotRadius
        end % actRadiusScaledPx
        
        
    end % zoomClickCallback       

%% -----------------------------------------------------------
%  GUI Creation
% ------------------------------------------------------------
    function HFig = createFig
        screenSize = get(0,'Screensize');
        % Calculates ratios image/screen
        ratioImScreen = [imageHeightPx/screenSize(4)  imageWidthPx/screenSize(3)];
        % Takes the size of the screen for the dimmension with the biggest ratio
        if ratioImScreen(1)>ratioImScreen(2)
            dispImageHeightPx = screenSize(4) * sizeGUI;
            dispImageWidthPx = dispImageHeightPx/imageHeightPx * imageWidthPx;
        else
            dispImageWidthPx = screenSize(3) * sizeGUI;
            dispImageHeightPx = dispImageWidthPx/imageWidthPx * imageHeightPx;
        end
        % Elements
        buttonWidthPx = 80;
        buttonHeightPx = 25;
        borderPx = 10;
        % The section amplified is a square whose size is the height of the image.
        zoomToolsHeightPx = 3*buttonHeightPx+4*borderPx;
        zoomImageSidePx = dispImageHeightPx-zoomToolsHeightPx;
        % Size of the main figure.
        figureWidthPx = dispImageWidthPx + zoomImageSidePx + 120;
        figureHeightPx = dispImageHeightPx + 120;
        % Position
        posXWindow = screenSize(3)/2 - figureWidthPx/2;
        posYWindow = screenSize(4)/2 - figureHeightPx/2;
        % Reference points used to place the components in the figure.
        gridXPx = [20, 20+dispImageWidthPx, 20+dispImageWidthPx+80, 20+dispImageWidthPx+80+zoomImageSidePx];
        gridYPx = [60, 60+dispImageHeightPx];
        
        %% GUI
        HFig.mainFigure = figure('NumberTitle','off','Units', 'pixels', 'menubar', 'none','resize','off',...
            'Position',[posXWindow posYWindow figureWidthPx, figureHeightPx]);
        % Title.
        %if ~isempty(sectionName)
        %    set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version ' -  Particle labeling: ' sectionName]);
        %else
            set(HFig.mainFigure, 'Name',  ['GPDQ v' config.version ' -  Particle labeling']);
        %end
        figureColor = get(HFig.mainFigure, 'color');
        
        % Image
        HFig.panelImage = uipanel('Units','pixels','Position',[gridXPx(1) gridYPx(1) dispImageWidthPx dispImageHeightPx]);
        HFig.axesImage = axes('parent', HFig.panelImage, 'Position', [0 0 1 1]);
        titleImageText = [sectionName ' - ' int2str(imageHeightNm) 'x' int2str(imageWidthNm) ' Nm.'];
        HFig.editImage = uicontrol('Style','edit','String', titleImageText,'FontSize',11, 'FontWeight','bold','Unit','pixels', ...
            'Position', [gridXPx(1) gridYPx(2)+15 dispImageWidthPx/2 20], 'HorizontalAlignment', 'Left');
        HFig.textImage = uicontrol('Style','text','String', 'Drag rectangle or click to move zoom','FontSize',11, 'FontWeight','bold','Unit','pixels', ...
            'Position', [gridXPx(1)+dispImageWidthPx/2 gridYPx(2)+15 dispImageWidthPx/2 20], 'HorizontalAlignment', 'Right');        
        
        % Zoom
        HFig.panelZoom = uipanel('Units','pixels',...
            'Position',[gridXPx(3) gridYPx(1) zoomImageSidePx dispImageHeightPx]);
        HFig.axesZoom = axes('parent', HFig.panelZoom,'Units','pixels',...
            'Position', [0 zoomToolsHeightPx zoomImageSidePx zoomImageSidePx]);
        titleZoomText = ['Ampliation: ' int2str(zoomImageSizeNm) 'x' int2str(zoomImageSizeNm) ' Nm.'];
        HFig.textZoom1 = uicontrol('Style','text','String', titleZoomText,'FontSize',11, 'FontWeight','bold','Unit','pixels', ...
            'Position', [gridXPx(3) gridYPx(2)+15 zoomImageSidePx/2 20], 'HorizontalAlignment', 'Left');
        HFig.textZoom2 = uicontrol('Style','text','String', 'Click to mark/delete particle','FontSize',11, 'FontWeight','bold','Unit','pixels', ...
            'Position', [gridXPx(4)-zoomImageSidePx/2 gridYPx(2)+15 zoomImageSidePx/2 20], 'HorizontalAlignment', 'Right');
        
        
        % Create buttons for clearing the image, saving the file, and closing the application.
        HFig.clearButton = uicontrol('parent',HFig.mainFigure,'Style', 'pushbutton', 'String', 'Clear','Units','pixels',...
            'Position', [gridXPx(2)-80 20 80 25],'Tooltipstring','Delete all marks and points');
        HFig.closeButton = uicontrol('parent',HFig.mainFigure,'Style', 'pushbutton', 'String', 'Close','Units','pixels',...
            'Position',[gridXPx(4)-80 20 80 25],'Tooltipstring','Closes the application');
        HFig.saveButton = uicontrol('parent',HFig.mainFigure,'Style', 'pushbutton', 'String', 'Save','Units','pixels',...
            'Position',[gridXPx(4)-170 20 80 25],'Tooltipstring','Save particle locations in a file');
        
        % Toogle marks
        HFig.toogleMarksCheckBox = uicontrol('parent',HFig.mainFigure,'Style', 'checkbox', 'String', 'Show marks','Units','pixels','Value',1,...
            'Tooltipstring','Shows/Hides the marks.',...
            'Position', [gridXPx(1) 20 150 25]);
        % The button is only enabled if a file name has been provided.
        if ~writeFile
            set(HFig.saveButton, 'Enable','off');
        end
        
        % For automatic detection.
        HFig.autDetectionButton = uicontrol('parent',HFig.mainFigure,'Style', 'pushbutton', 'String', 'Automatic detection','Units','pixels',...
            'Position', [gridXPx(2)-250 20 150 25],'Tooltipstring','Automatic detection');
        set(HFig.autDetectionButton,'Enable','off');
        
        % Detected radius
        HFig.detRadiusText = uicontrol('Parent', HFig.panelZoom, 'Style', 'Text', 'String', 'Last detected: ','HorizontalAlignment','right','backgroundcolor', figureColor,...
            'Position', [zoomImageSidePx-2*borderPx-3*buttonWidthPx, zoomToolsHeightPx-borderPx-buttonHeightPx-5, 2*buttonWidthPx, buttonHeightPx]);
        HFig.detRadiusEdit = uicontrol('Parent', HFig.panelZoom, 'Style', 'Edit', 'String','','Enable','inactive', 'backgroundcolor','white','FontWeight','bold','HorizontalAlignment','left',...
            'Tooltipstring','Shows the radius of the last detected particle.',...
            'Position', [zoomImageSidePx-borderPx-buttonWidthPx, zoomToolsHeightPx-borderPx-buttonHeightPx, buttonWidthPx, buttonHeightPx]);
        
        % Radius selection
        HFig.radSelText = uicontrol('Parent', HFig.panelZoom,'Style', 'Text', 'String', 'Radius: ','HorizontalAlignment','left','backgroundcolor',figureColor,...
            'Position', [borderPx zoomToolsHeightPx-1*borderPx-buttonHeightPx-4 buttonWidthPx 25]);
        HFig.radPopup = uicontrol('Parent', HFig.panelZoom,'Style', 'popup', ...
            'Position', [2*borderPx+buttonWidthPx zoomToolsHeightPx-1*borderPx-buttonHeightPx 1.5*buttonWidthPx buttonHeightPx]);
        set(HFig.radPopup,'String',createRadiusPopupOptions());
        set(HFig.radPopup,'Value',currentParticleType);
        
        % Assist
        HFig.confCheckBox = uicontrol('Parent', HFig.panelZoom, 'Style','Checkbox','string','Assist labeling', 'HorizontalAlignment','right',...
            'Position', [borderPx,  zoomToolsHeightPx-2*borderPx-2*buttonHeightPx,  2*buttonWidthPx, buttonHeightPx],'Value',1);
        % Margin
        HFig.marginText = uicontrol('Parent', HFig.panelZoom,'Style', 'Text', 'String', 'Margin ( > 0 Nm):',...
            'Position', [borderPx borderPx-5, 1.5*buttonWidthPx buttonHeightPx], 'backgroundcolor',figureColor,'HorizontalAlignment','left');
        HFig.marginEdit =uicontrol('Parent', HFig.panelZoom,'Style', 'Edit', 'backgroundcolor','white','String',num2str(marginRadiusNm),...
            'Tooltipstring','Particles which differ from the selected selected more than this margin are discarded.',...
            'Position', [2*borderPx+1.5*buttonWidthPx borderPx  buttonWidthPx buttonHeightPx]);
        % Sensitivity
        HFig.sensText = uicontrol('Parent', HFig.panelZoom, 'Style', 'Text', 'String', 'Sensitivity ( 0.5 - 0.99 ):',...
            'Position', [zoomImageSidePx-2*borderPx-3*buttonWidthPx borderPx-5 2*buttonWidthPx buttonHeightPx], 'backgroundcolor',figureColor,'HorizontalAlignment','right');
        HFig.sensEdit = uicontrol('Parent', HFig.panelZoom, 'Style', 'Edit','backgroundcolor','white','String',num2str(sensitivity), ...
            'Tooltipstring','Fixes the sensitivity of the Hough transform. Higher values allow detecting more circles.',...
            'Position', [zoomImageSidePx-borderPx-buttonWidthPx borderPx buttonWidthPx buttonHeightPx]);
        
        %HFig.sensSlider = uicontrol('Parent', HFig.panelZoom, 'Style', 'slider', 'Min', 0.5, 'Max', 0.99, 'Value', 0.75, ...
        %    'backgroundcolor',figureColor, 'Position', [zoomImageSidePx-borderPx-buttonWidthPx borderPx buttonWidthPx buttonHeightPx]);
        
        
        % Loads the image
        HFig.handleImage = imshow(maskedImage, 'Parent', HFig.axesImage);
        
        % Updates the font sizes
        setFonts(HFig);
        
        %% Function diameterPopupOptions
        %  Creates the popup options for different particle models.
        function radiusPopupOptions = createRadiusPopupOptions()
            numParticles = numel(particleTypes);
            radiusPopupOptions = {numParticles+1};
            % The other are taken from configuration.
            for nPart=1:numParticles
                partLabel = ['<HTML><FONT COLOR=' particleTypes(nPart).color '><b>' num2str(particleTypes(nPart).radius) ' Nm</b></HTML>'];
                radiusPopupOptions{nPart} = partLabel;
            end
            % The last position indicates that radii are not used.
            partLabel = '<HTML><FONT COLOR=black><b>Not used</b></HTML>';
            radiusPopupOptions{numParticles+1} = partLabel;
        end % radiusPopupOptions
    end % createFig

end