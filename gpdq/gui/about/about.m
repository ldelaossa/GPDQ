%% about
% Shows copyright

% Author: Luis de la Ossa (luis.delaossa@uclm.es)
function about()
global config;
% Avoids multiple openings of the figure. If it is already open, shows it.
windowAbout = findobj('type', 'figure', 'tag', 'about');
if ~isempty(windowAbout)
    figure(windowAbout);
    return;
end

screenSize = get(0,'Screensize');
figureHeightPx = 600; % Dimmension
figureWidthPx = 600;
figurePosXPx = (screenSize(3)-figureHeightPx)/2;
figurePosYPx = (screenSize(4)-figureWidthPx)/2;
mainFigure = figure('tag','about','NumberTitle','off','Units', 'pixels', 'resize','on','menubar', 'none', 'Position',[figurePosXPx figurePosYPx figureWidthPx, figureHeightPx]);
set(mainFigure, 'Name', ['GPDQ v' config.version]);

closeButton = uicontrol('Style', 'pushbutton', 'String', 'Close', 'Position', [270 10, 60, 25],'Callback',@close);
set(closeButton,'fontSize', config.fontSize);

infoText=uicontrol('Style', 'Edit', 'String','','Enable','inactive', 'HorizontalAlignment','Left','backgroundcolor','white', 'Position', [10, 45, 580, 545]);
set(infoText,'fontSize', config.fontSize);
set(infoText,'Max', 20);


%text = fileread('copyright.txt'); infoText adds empty lines!!

fid = fopen('copyright.txt');
str = textscan(fid, '%s', 'Delimiter','\n');
text = str{1};
fclose(fid);

set(infoText,'String',text);

    function close(~,~)
        delete(gcf);
    end

end

