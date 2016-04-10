

The LED strips are laid out in a physical space, so there are 3 components to this system:

- led-positions:

  This is the compiler that identifies the X,Y positions of each

  light and it's position in the original LED strip

  Input data is for a grid 12 x 33.

  This is scaled up to a grid : 690 x 322 (and inverted)

  Output data is a JSON file for processing

         Sign Co-ords are bottom,left -> top,right.
         Procesing Co-ords are Top,Left -> Bottom,right.

- Processing
  This generates the arrays of color data for the arduino to load
  Inout data is a json file which also includes a schema and config variables

- Arduino
  The microcode loader and simple sequencer

Use 'compile-data.pl' to generate the lists of leds per letter and their
position in the strip
