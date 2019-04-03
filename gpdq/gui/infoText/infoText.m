%% infoText
%
% Shows a window with a text field.
%
% Usage
% -----
%
%   infoText(text, title)
%
% Example
%
%   infoText(data.descriptionString, 'Data description')
%
% Parameters
% ----------
%
%   text: Text to be displayed
%   title: Title of the window

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function infoText(text, title)
global config;
% Avoids multiple openings of the figure. If it is already open, shows it.
windowAbout = findobj('type', 'figure', 'tag', 'infotext');
if ~isempty(windowAbout)
    figure(windowAbout);
    return;
end

% Default title
if nargin<2
    title=[];
else
    title = [': ' title];
end

screenSize = get(0,'Screensize');
figureHeightPx = 600; % Dimmension
figureWidthPx = 600;
figurePosXPx = (screenSize(3)-figureHeightPx)/2;
figurePosYPx = (screenSize(4)-figureWidthPx)/2;
mainFigure = figure('tag','infotext','NumberTitle','off','Units', 'pixels', 'resize','on','menubar', 'none', 'Position',[figurePosXPx figurePosYPx figureWidthPx, figureHeightPx]);
set(mainFigure, 'Name', ['GPDQ v' config.version title]);

closeButton = uicontrol('Style', 'pushbutton', 'String', 'Close', 'Position', [270 10, 60, 25],'Callback',@close);
set(closeButton,'fontSize', config.fontSize);

infoText=uicontrol('Style', 'Edit', 'String','','Enable','inactive', 'HorizontalAlignment','Left','backgroundcolor','white', 'Position', [10, 45, 580, 545]);
set(infoText,'fontSize', config.fontSize);
set(infoText,'Max', 20);

set(infoText,'String',text);

    function close(~,~)
        delete(gcf);
    end

end

