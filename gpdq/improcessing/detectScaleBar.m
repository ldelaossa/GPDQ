%% detectScaleBar
%
% Detects the scale bar in an image. 
%
% Returns the length of the scale bar, and its position as a rectangle.
% Also returns the scale if the expected size is passed as argument. 
%
% IMPORTANT: Works when the scale bar is a black rectangle. 
%
% If the bar is not found (depends on the format of the bar) returns
% GPDQStatus.ERROR.
%
% Usage
% -----
%
%       [scaleBarLen, scaleBarLine, scaleBarRect, scale] = detectScaleBar(image, sizeBar)
%
% Example
% -------
%
%       [scaleBarLen, scaleBarLine, scaleBarRect, scale] = detectScaleBar(image, 500)
%
%
% Parameters
% ----------
%
%       image: Ubject (array) containing the matrix. 
%       scaleBarLenNm: Size of the bar in NANOMETERS. Can be passed as argument or specified later. 
%
% Returns
% -------
%
%       scaleBarLenPx: Length of the scale bar (in  pixels).
%       scaleBarLine: Line with the scale bar (x1,y1; x2,y2);
%       scaleBarRect: Points of the rectangle with the scale bar (x,y,w,h); (x,y) corresponds to the topleft corner. 
%       scale: Scale of the image (Nm/pixel).
%
% Errors
% -------
%
%   Returns GPDQStatus.ERROR if the actual size of the Bar is unknown.
%

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function[scaleBarLenPx, scaleBarLine, scaleBarRectPx, scale] = detectScaleBar(image, scaleBarLenNm)
        scaleBarLenPx = -1;
        scaleBarRectPx = -1;
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
            if lenObj>scaleBarLenPx
                scaleBarLenPx = lenObj;
                detectedDims = bbObj;
                detectedOrientation = objects(objId).Orientation;
            end
        end
        
        % Returns if fail
        if scaleBarLenPx==-1
            scaleBarLenPx = GPDQStatus.ERROR;
            GPDQStatus.repError("Scale bar not found.", false, dbstack());
            return;
        end
        
        % Returns the coordinates of a line. 
        scaleBarRectPx = [detectedDims(1), detectedDims(2) detectedDims(3), detectedDims(4)];
        
        % Returns the coordinates of a line. 
        if detectedOrientation==0
            scaleBarLine = [detectedDims(1),detectedDims(2); detectedDims(1)+detectedDims(3), detectedDims(2)];
        else
            scaleBarLine = [detectedDims(1),detectedDims(2); detectedDims(1), detectedDims(2)+detectedDims(4)];
        end
  
        % Calculates the scale
        if nargin==2
            scale = scaleBarLenNm/scaleBarLenPx;
        end
end

