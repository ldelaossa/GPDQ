%% detectScaleBar
% Detects the scale bar in an image. 
%
% Returns the scaleBarPosition. Also returns the scale if the expected size
% is passed as argument. 
%
% Works when the scale bar is a black rectangle. 
%
% If the bar is not found (depends on the format of the bar) returns
% GPDQStatus.ERROR.
%
% Usage
% -----
%
%       [scaleBarPosition, scale] = detectScaleBar(image, sizeBar)
%
% Example
% -------
%
%       [scaleBarPosition, scale] = detectScaleBar(image, 500)
%
%
% Parameters
% ----------
%
%       image: Ubject (array) containing the matrix. 
%       sizeBar: Size of the bar. Can be passed as argument or specified
%       later. 
%
% Returns
% -------
%
%       scaleBarPosition: Points of the rectangle with the scale bar. 
%       scale: Scale of the image (Nm/pixel).
%
% Errors
% -------
%
%   Returns GPDQStatus.ERROR if the actual size of the Bar is unknown.
%

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function[scaleBarPosition, scale] = detectScaleBar(image, sizeBar)
        scaleBarLen = -1;
        scaleBarPosition = -1;
        scale = -1;
        
        % Black regions
        maskBlack = (image==0);
        
        % Gets the objects
        maskBlack = bwareaopen(maskBlack,20);
        objectsBlack =  bwconncomp(maskBlack);
        objectsBlack = regionprops(objectsBlack,'BoundingBox', 'Solidity','Area','Orientation'); % Orientation could be useful.
        
        % White region
        maskWhite = (image==max(image));
        
        % Gets the objects
        maskWhite = bwareaopen(maskWhite,20);
        objectsWhite =  bwconncomp(maskWhite);
        objectsWhite = regionprops(objectsWhite,'BoundingBox', 'Solidity','Area','Orientation'); % Orientation could be useful.        
        
        % Detects the scale bar.
        objects = [objectsWhite; objectsBlack];
        for objId = 1:length(objects)
            % The scale bar must be solid
            if objects(objId).Solidity~=1
                continue;
            end
            % The area must corresponde with the size of the bounding box.
            bbObj = objects(objId).BoundingBox;
            if objects(objId).Area~=bbObj(3)*bbObj(4)
                continue;
            end
            
            % Selects the one with the maximum lenght.
            lenObj = max(bbObj(3),bbObj(4));
            if lenObj>scaleBarLen
                scaleBarLen = lenObj;
                detectedDims = bbObj;
                detectedOrientation = objects(objId).Orientation;
            end
        end
        
        % Returns if fail
        if scaleBarLen==-1
            scaleBarPosition = GPDQStatus.ERROR;
            GPDQStatus.repError("Scale bar not found.", false, dbstack());
            return;
        end
        
        % Returns the coordinates of a line. 
        if detectedOrientation==0
            scaleBarPosition = [detectedDims(1),detectedDims(2); detectedDims(1)+detectedDims(3), detectedDims(2)];
        else
            scaleBarPosition = [detectedDims(1),detectedDims(2); detectedDims(1), detectedDims(2)+detectedDims(4)];
        end
        
        if nargin==2
            scale = sizeBar/scaleBarLen;
        end
end

