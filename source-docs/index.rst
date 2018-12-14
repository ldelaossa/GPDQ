====
GPDQ 
====


GPDQ  (Gold Particle Detection and Quantification) is a tool for the analysis of images obtained by inmunogold labeling. It is written in Matlab, and provides a set of functionalities that allow:


* Managing projects and experimental series
* Automatic and semiautomatic labeling of images
* Basic image procesing
* Data analysis
* Generating and exporting reports.

.. figure:: _images/gpdqGUI.png
    :width: 600px
    :align: center
    :alt: Main application.
    :figclass: align-center

    Main application for project management.



The Matlab APP covers the whole analysis process, and the objects and functions use a transparent representation of the information (data structures, images and csv files) so that they can be used as a complement in the work with other tools or statistical packages. 

 .. code-block:: matlab

    % Reads the description of the project from a csv file
    project = GPDQProject.readFromFile('DATA/GABAB1-6M-WT/', 'project.csv'); 
    % Calculates Nearest Neighbour Distances between 5Nm particles
    report = reportNNDStats(project.getProjectData(),[5]);  
    % Exports a report to csv                   
    report.save('GABAB1-6M-WT.csv');

-----------

.. toctree::
	:maxdepth: 2
	:caption: Contents:

	sections/quickstart
	sections/projects
	sections/utils
	sections/code
	sections/modules


------------

Credits
=======

This project has been has been developed as...

**Author**
    Luis de la Ossa

    *Computing Systems Department. University of Castilla-La Mancha (Spain).*


**Contributors**
    Rafael Lujan and Carolina Aguado.

    *Celular Neurobiology Lab - Faculty of Medicine. University of Castilla-La Mancha (Spain).*


MIT License
-----------

Copyright (c) 2018 Luis de la Ossa.  *University of Castilla-La Mancha (Spain)*.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.









  








