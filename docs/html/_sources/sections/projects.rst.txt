.. _projects:

=============
Projects
=============

A  **project** contains the group of images and related data that is used for a same study. Initially, **all images must be stored in a folder**. Although GPDQ automatically organizes and prepares the data,  many of the steps in project preparation or even analysis can be carried out with other tools. Therefore, it is convenient to understand the project structure.

Sections
========
The basic unit of a project is a **section**, which is the region of an image that corresponds to a functional part. An image can contain several sections. Next figure shows an image (``spine1.tif``), and its two sections (``spine1_sec_1.tif`` and ``spine1_sec_2.tif``). 

+-----------------------------------------+-----------------------------------------+-----------------------------------------+
| .. figure:: ../_images/spine1.png       | .. figure:: ../_images/spine1_sec_1.png | .. figure:: ../_images/spine1_sec_2.png |
|   :alt: image                           |   :alt: section 1                       |   :alt: section 2                       |
|   :width: 220px                         |   :width: 220px                         |   :width: 220px                         |
|   :figclass: align-center               |   :figclass: align-center               |   :figclass: align-center               |
|                                         |                                         |                                         |
|   ``spine1.tif``                        |   ``spine1_sec_1.tif``                  |   ``spine1_sec_2.tif``                  |
+-----------------------------------------+-----------------------------------------+-----------------------------------------+

GPDQ provides the functionalities for creating and organizing sections. However, it is possible to create them with any other image processing software, such as GIMP or imageJ. In such a case, there are some rules:

* Sizes of the original image and its sections must be the same.
* If ``imageFileName.tif`` is the name of the original image, section ``#n`` must be stored in a file named ``imageFileName_sec_n.tif``.  
* Discarded pixels (those not being part of the section) must be white. 

For each one of the sections, GPDQ creates a data file, with extension ``.csv`` , as the one shown below: with the location, radius (actual), and  radius (expected) of each one of its particles. 


.. csv-table:: File 1: ``SPINES DIS/spine1_sec_1.csv``
   :header: "X", "Y", "Radius", "Expected radius"
   :widths: 5,5,5,5
   :align: center

   622.70, 644.65, 4.00, 5.0
   610.50, 656.45, 4.00, 5.0
   606.72, 673.82, 4.50, 5.0
   595.72, 689.52, 4.00, 5.0


The name of this file must be the same as the name of the image with the section. For instance, the table shows the file ``SPINES DIS/spine1_sec_1.csv``, that corresponds to the section in image ``SPINES DIS/spine1_sec_1.tif``.


Organization
=================

All project files (images, sections, and data files) must be stored in a folder that can be organized in subfolders. Each section (``_sec_``) and corresponding data file (``.csv``) obtain from an image, must be located in the same folder than the image. Next figure shows the organization of a project. 

.. figure:: ../_images/project.png
    :width: 600px
    :align: center
    :alt: Project file organization
    :figclass: align-center

    Figure 2: Organization of files for a project.


The definition of the project is another ``.csv`` file, **located in the root of the project folder**, that contains a row for each one of the sections considered. Contains four columns:

1. Name of the (full) image. The name includes the path from the root of the project folder. Example: ``SPINES Dis/1.tif``.
2. Number of section. If the number is ``#n``, the section corresponds to  the image ``SPINES Dis/1_sec_n.tif`` and the data file ``SPINES Dis/1_sec_n.csv``.
3. The **group** name. Sections must be grouped for experimental purposes. 
4. Scale of the image in Nanometers/pixel. 


Next file shows an example project definition.


.. csv-table:: File 2: ``project_definition.csv``
   :header: "Image", "#Section", "Group", "Scale"
   :widths: 30,5,10,10
   :align: center

   "SPINES Dis/1.tif", 1, "SPINES", 1.4525
   "SPINES Dis/1.tif", 2, "SPINES", 1.4525
   "SPINES Dis/1.tif", 3, "SPINES", 1.4525
   "SPINES Dis/2.tif", 1, "SPINES", 0.875



GPDQ provides a functionality to select images and create the project definition (see :ref:`newproject`). However, it is possible to create it with any word processor or spreadsheet. 

