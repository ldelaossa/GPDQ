% Loads the configuration and sets path

%% Loads the configuration
addpath('./core');
global config;
config = GPDQConfig.load();

%% Functions and classes

% Analysis
addpath('./analysis');
addpath('./analysis/basic');
addpath('./analysis/distances');
addpath('./analysis/clustering');
addpath('./analysis/densities');
addpath('./analysis/simulation');

% GUI
addpath('./gui');
addpath('./gui/about');
addpath('./gui/analysis');
addpath('./gui/createdata');
addpath('./gui/createsection');
addpath('./gui/gpdq');
addpath('./gui/grouprm');
addpath('./gui/infoText');
addpath('./gui/labeling');
addpath('./gui/newproject');
addpath('./gui/scale');
addpath('./gui/reports');

% Image processing
addpath('./improcessing');
% 
% Utils
addpath('./util');
addpath('./util/files');
addpath('./util/gui');
addpath('./util/plot');

%% Libraries
addpath('./lib/violin');

