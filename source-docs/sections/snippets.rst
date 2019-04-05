.. _tmpsnippets:

=================
Snippets
=================

Packages

.. note::

   This is a note box (blue)

And so on

.. code-block:: matlab

    project = GPDQProject.readFromFile('DATA/GABAB1-6M-WT/', 'project.csv');
    report = reportNNDStats(project.getProjectData(),2);
    report.save('GABAB1-6M-WT.csv');