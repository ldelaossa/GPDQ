% Sets the configuration and path

% Core
addpath('./core');


% Loads the configuration
global config;
config = GPDQConfig.load();

% Analysis
addpath('./analysis/basic');


% GUI
addpath('./gui');
addpath('./gui/about');
addpath('./gui/createsection');
addpath('./gui/labeling');
addpath('./gui/newproject');
addpath('./gui/scale');


% Image processing
addpath('./improcessing');

% Utils
addpath('./util');
addpath('./util/files');
addpath('./util/gui');
addpath('./util/plot');






