The AEZ sign driver.

# What's here

There are 3 main folders:

* Arduino :
    Contains the arduino driver code
* led-positions :
    contains data sets and code for calculating the X,Y led positions.
    This also produced the original signCoords.h file
    (which has since been re-written by hand)
* processing :
    Contains code for testing and generating color sequences
    for the creation of a 'sequence.h' input file

## Arduino:

The microcode loader and simple sequencer

This uses the LPD6803 library to control the strip

Loads a signCoords.h file containing LED position data
Loads a sequence.h file (TBD) that can define the effects

The signCoords.h file has now been hardcoded based on testing in the lab.
So don't run any of the perl scripts unless you want to clobber your data.

NEVER call Color() directly! some of the LED strands have their RGB reversed (as BGR),
so you need to call the Wrapper function applyColor(R,G,B, ID) that will do the right thing based
on the pixel ID for that sign.

This also means that each sign is running a slightly different version of the code

### Build environment

* Clone the libraries into the Arduino libraries folder

    git clone https://github.com/adafruit/LPD6803-RGB-Pixels.git

    git clone https://github.com/PaulStoffregen/TimerOne.git

* Load the signdriver/signdriver.ino file into Arduino

* Most of the arduino code should be documented


## led-positions:

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

## Processing:

  This generates the arrays of color data for the arduino to load

  Input data is a json file which also includes a schema and config variables

  Output is a #include file that defines a 2D array of sequence data

        [ duration , #led1color , #led2color ... ],
        [ duration , #led1color , #led2color ... ],
        ...
