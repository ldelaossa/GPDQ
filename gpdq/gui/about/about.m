%% about
% Shows copyright

% Author: Luis de la Ossa (luis.delaossa@uclm.es)
function about()

fid = fopen('copyright.txt');
str = textscan(fid, '%s', 'Delimiter','\n');
text = str{1};
fclose(fid);

infoText(text);


end

