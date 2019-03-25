%% colorString
%
% Uses an html cell table to write strings over background color.
%
% Usage
% -----
%
%       string = colorString(color,string)
%
% Example:
% --------
%
%       string = colorString('#AA1111','Test string')
%
%
% Parameters
% ----------
%
%   color: Background color
%
%   text: Text to be shown
%
%
% Returns
% -------
%
%   string: HTML colde of the string inside a coloured cell.
%

% Author: Luis de la Ossa (luis.delaossa@uclm.es)

function string = colorString(color, text)
    string = ['<html><table border=0 width=200 bgcolor=', color,' ><TR><TD> <font color="black"><b>',text ,'</b></font></TD></TR></table></html>'];
end
