.. _quickstart:

===================
Quickstart: GUI App
===================


GPDQ  (Gold Particle Detection and Quantification) is a tool for the analysis of images obtained by inmunogold labeling. It is written in Matlab, and provides a set of functionalities that allow:

* Managing projects and experimental series
* Automatic and semiautomatic labeling of images
* Basic image procesing
* Analyzing data
* Generating and exporting reports.


.. figure:: ../_images/gpdqGUI.png
    :width: 600px
    :align: center
    :alt: Main application.
    :figclass: align-center

    Main application for project management.


The Matlab APP covers the whole analysis process, and uses a transparent representation of the information (structures, images and csv files) so that it can be used as well as a set of objects and functions that complement the work with other tools or statistical packages. 

.. code-block:: matlab

    project = GPDQProject.readFromFile('DATA/GABAB1-6M-WT/', 'project.csv');
    report = reportNNDStats(project.getProjectData(),2);
    report.save('GABAB1-6M-WT.csv');

    