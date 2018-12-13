====
GPDQ 
====


GPDQ  (Gold Particle Detection and Quantification) is a tool for the analysis of images obtained by inmunogold labeling. 

.. figure:: _images/gpdqGUI.png
    :width: 600px
    :align: center
    :alt: Main application.
    :figclass: align-center

    Main application for project management.


Provides functionalities for:

* Managing projects and experimental series
* Automatic and semiautomatic labeling of images
* Basic image procesing
* Analyzing data
* Generating and exporting reports.

The Matlab  APP covers the whole analysis process, and uses a transparent representation of the information (structures, images and csv files) so that it can be used as well as a set of objects and functions that complement the work with other tools or statistical packages. 

.. code-block:: matlab

    project = GPDQProject.readFromFile('DATA/GABAB1-6M-WT/', 'project.csv');
    report = reportNNDStats(project.getProjectData(),2);
    report.save('GABAB1-6M-WT.csv');


.. toctree::
	:maxdepth: 0
	:caption: Contents:

	sections/quickstart
	sections/projects
	sections/utils
	sections/modules
	sections/code
	sections/tmpsnippets    


Requirements
============

GPDQ v1.0.0 has been written on Matlab R2018b. It requires these toolboxes:

* Image Processing Toolbox    (Version 10.3)
* Parallel Computing Toolbox   (Version 6.13)

Credits
=======

Author
------
 * Luis de la Ossa (luis.delaossa@uclm.es)

Contributors
------------
 * Rafael Lujan
 * Carolina Aguado

License
=======

MIT License

Copyright (c) 2018 Luis de la Ossa. University of Castilla-La Mancha (Spain).

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





  








