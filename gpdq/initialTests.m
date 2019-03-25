setConfig
project = GPDQProject.readFromFile('/Volumes/TRABAJO/DATOS/GABAB180928/GABAB1-1M-APP/', 'project1MAPP.csv');
definition  = {'DENDRITE', { '1 - SO OBLIQUE DENDRITE' ;
'4 - SR APICAL DENDRITE Prox' ;
'5 - SR OBLIQUE DENDRITE Prox' ;
'7 - SR APICAL DENDRITE Dis' ;
'8 - SR OBLIQUE DENDRITE Dis' ;
'10 - SLM OBLIQUE DENDRITE'  };
'SPINES',  { '2 - SO SPINES' ;
'6 - SR SPINES Prox' ;
'9 - SR SPINES Dis';
'11 - SLM SPINES'};
'SOMA',    { '3 - SP SOMA'}}

data1M = GPDQData(project, definition, 'Tag','Proyecto de prueba 1M');
GPDQData.save(data1M, 'data1M.mat');


project12 = GPDQProject.readFromFile('/Volumes/TRABAJO/DATOS/GABAB180928/GABAB1-12M-APP/', 'project12MAPP.csv');
data12M = GPDQData(project12, [], 'Tag','Proyecto de prueba 12M');
GPDQData.save(data12M, 'data12M.mat');


data1M = GPDQData.load('data1M.mat');
data12M = GPDQData.load('data12M.mat');