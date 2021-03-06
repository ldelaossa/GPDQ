# GPDQ v1.0

GPDQ  (Gold Particle Detection and Quantification) is a tool for the analysis of images obtained by inmunogold labeling. Provides functionalities for:

* Managing projects and experimental series
* Automatic and semiautomatic labeling of images
* Basic image procesing
* Analyzing data
* Generating and exporting reports.

<img src="docs/html/_images/gpdqGUI.png" alt="gpdqGUI" ALIGN=â€centerâ€ width="800"/>

        
  
The Matlab  APP covers the whole analysis process, and uses a transparent representation of the information (structures, images and csv files) so that it can be used as well as a set of objects and functions that complement the work with other tools or statistical packages. 

``` matlab
project = GPDQProject.readFromFile('DATA/GABAB1-6M-WT/project.csv');
reportDistances = NNDData(project.getData());
reportDistances.save('GABAB1-6M-APP.csv');

```

---

## Requirements

GPDQ v1.0 has been written on Matlab R2019b. It requires these toolboxes (version tested):

* Image Processing Toolbox    (Version 10.3)
* Parallel Computing Toolbox   (Version 6.13)
* Statistics and Machine Learning Toolbox  (Version 11.6) 
* Deep Learning Toolbox   (Version 13.0)
---

## Credits

Author:
 * Luis de la Ossa (luis.delaossa@uclm.es)
 * Computing Systems Department. University of Castilla-La Mancha (Spain).

Contributors: 
 * Rafael Luján and Carolina Aguado
 * Celular Neurobiology Lab - Faculty of Medicine. University of Castilla-La Mancha (Spain).

---

## License

MIT License

Copyright (c) 2020 Luis de la Ossa. University of Castilla-La Mancha (Spain).

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
