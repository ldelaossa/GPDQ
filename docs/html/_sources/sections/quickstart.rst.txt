.. _quickstart:

===================
Quickstart: GUI App
===================



The GPDQ APP covers the whole analysis process: from project definition to analysis. It can be directly executed (after being installed as a Matlab APP), or from command line as:

.. code-block:: matlab

   setconfig
   gpdq(0.85, project)


where ``0.85`` indicates the size of the window (as proportion of the screen) and ``project`` a file containing a project. Both parameters ar optional.

Next figure shows an screenshoot of the APP.


.. figure:: ../_images/gpdqGUI.png
    :width: 600px
    :align: center
    :alt: New project edition.
    :figclass: align-center

    Figure 1: Main application.


The analysis of a set of images takes several steps. 

.. note::
   As starting point, it is necessary to place all images in one folder (that can be organized in subfolders). In this example, the project is created from scratch. However, sections and data files could be previously created with any other program, but must fit the requirements described in section  :ref:`projects`.

Step 1: Project creation
==========================

First of all it is necessary to create a project. Menú ``File->New`` launches a window as the one shown below, that allows selecting which images (original, no sections) must be included in the project, whether to use or not the subfolders as group names, and to stablish the default scale Nm/pixel (see section :ref:`newproject` for further details). It also requires the name of the project.


.. figure:: ../_images/newProjectEdit.png
    :width: 400px
    :align: center
    :alt: New project edition.
    :figclass: align-center

    Figure 2: Project creation.

By default, it creates a section for each one of the images. It is possible to add, remove, and sort sections. Also, it is possible to add new images (button ``Add`` of the figure). 

.. figure:: ../_images/addSection.png
    :width: 400px
    :align: center
    :alt: Adding and removing sections.
    :figclass: align-center

    Figure 3: Functionalities for adding-removing-sorting sections.


Once added the sections, it could be necessary edit their group names. It can be done directly by editing the table, or through menu ítem ``Utilities->Rename groups`` (see :ref:`groupedition'), that opens an utlity to do that.

.. figure:: ../_images/groupEdition.png
    :width: 600px
    :align: center
    :alt: Group edition.
    :figclass: align-center

    Figure 4: Group edition.


Lastly, it is very frequent to work with sets of images with different scales. When scales (Nm/pixel) are not known, it is also possible to calculate the scale of a section by option ``Get scale current section`` of the context menú shown in Figure 3 (See :ref:`measurescale`). 

.. figure:: ../_images/measureScale.png
    :width: 600px
    :align: center
    :alt: Scale measurement.
    :figclass: align-center

    Figure 5: Scale measuring.


Step 2: Section edition
==========================

Part of the 

.. figure:: ../_images/createSection.png
    :width: 400px
    :align: center
    :alt: Section edition.
    :figclass: align-center

    Figure 6: Section edition.


Step 3: Section labeling
==========================

.. figure:: ../_images/sectionLabeling.png
    :width: 600px
    :align: center
    :alt: Section labeling.
    :figclass: align-center

    Figure 7: Section labeling.   

Step 4: Create project data object
==================================

.. figure:: ../_images/dataCreation.png
    :width: 600px
    :align: center
    :alt: Data creation.
    :figclass: align-center

    Data object creation.    



Step 5: Analysis
==================================


.. figure:: ../_images/projectReport.png
    :width: 600px
    :align: center
    :alt: Report showing.
    :figclass: align-center

    Project report. 

.. figure:: ../_images/exploreNND.png
    :width: 600px
    :align: center
    :alt: Report showing.
    :figclass: align-center

    Explore NND from project.     