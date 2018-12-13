%% setFonts
%
% Establishes the font size provided in the configuration for the
% components in the figure HFig (allows working with different operating systems).

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function HFig  = setFonts(HFig)
    global config;
    fields = fieldnames(HFig);
    for idField=1:length(fields)
        if strcmp(class(HFig.(fields{idField})),'matlab.ui.control.UIControl')
            set(HFig.(fields{idField}),'FontSize',config.fontSize);
            continue;
        end
        if strcmp(class(HFig.(fields{idField})),'matlab.ui.container.Panel')
            set(HFig.(fields{idField}),'FontSize',config.fontSize);
            continue;            
        end
    end    
end

