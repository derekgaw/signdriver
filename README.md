

The LED strips are laid out in a physical space, so there are 3 components to this system:

- led-positions:

  This is the compiler that identifies the X,Y positions of each
  light and it's position in the original LED strip

  Input data is for a grid with x,y dims of 12 x 33.

  This is scaled up to a grid : 690 x 322 (and inverted)

         Sign Co-ords are bottom,left -> top,right.
         Procesing Co-ords are Top,Left -> Bottom,right.

  Output data is a JSON file for processing, and a header file
  'signCoords.h' for use by arduino, that has 4 arrays
 
    - lseq : which is a list of LEDs for something a letter
        The first int is the length of each array
    - wipex : a list of led arrays for a Left-Right wipe
        The first int is the length of the array
        The first array has len=2 and it the # of arrays
    - wipey : a list of led arrays for a top-bottom wipe
        The first int is the length of the array
        The first array has len=2 and it the # of arrays
    - seq : a set of sequencing instructions

- Processing:

  This generates the arrays of color data for the arduino to load

  Input data is a json file which also includes a schema and config variables
  
  Output is a #include file that defines a 2D array of sequence data

        [ duration , #led1color , #led2color ... ],
        [ duration , #led1color , #led2color ... ],
        ...

- Arduino:

  The microcode loader and simple sequencer

Use 'compile-data.pl' to generate the lists of leds per letter and their
position in the strip
