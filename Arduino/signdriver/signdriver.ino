#include <TimerOne.h>
#include "LPD6803.h"

// Globals  

#include "signCoords.h"

// some signs have inverted RGB pixels
// so we define these here, and applyColor() wil use this data
//Green sign
// LPD 6803 - 14109 : Leds 101-200
// the 14119 have the Green and Blue Leds swapped

//------------------------------------------------
// SET swappixels = 1 to enable a lookup
// these are begin-end pairs, first value is the # of pairs
byte swapPixels = 1 ;
byte reversedLED[3] = {1,100,199};
//byte reversedLED[5] = {1,100,139,178,186};
//------------------------------------------------

// Number of RGB LEDs in strand:
int nLEDs = 208;

// Chose 2 pins for output; can be any valid output pins:

//For "classic" Arduinos (Uno, Duemilanove,
// etc.), data = pin 11, clock = pin 13.  For Arduino Mega, data = pin 51,
// clock = pin 52.  For 32u4 Breakout Board+ and Teensy, data = pin B2,
// clock = pin B1.  For Leonardo, this can ONLY be done on the ICSP pins.
//LPD8806 strip = LPD8806(nLEDs);

int dataPin  = 51;
int clockPin = 52;

// First parameter is the number of LEDs in the strand.  The LED strips
// are 32 LEDs per meter but you can extend or cut the strip.  Next two
// parameters are SPI data and clock pins:
LPD6803 strip = LPD6803(nLEDs, dataPin, clockPin);

// how to use LPD-6803
//   https://github.com/adafruit/LPD8806
//   https://learn.adafruit.com/20mm-led-pixels?view=all

/*
 * pixel IDs are '0' based
 * strip.setPixelColor(index, 0); // off.
 * 
 * the pixels use 5 bits per channel ( 1-31 )
 * so any angorithms need to re-do indexes to between those values
 * 
 * NOTE - these ranges are REALLY FINE, it is hard to tell the difference
 * between 50% and 100% brightness
 * 
 * uint16_t mycolor = Color(  0, 31, 31 );
 * 
 * strip.setPixelColor(i, mycolor);
 * 
 * strip.setPixelColor(i, Color(  0, 31, 31 ) );
 * 
 */

// for indexing, we use a quantised set of color intensities in the range 0 - 31
// see 'indexColor() for details
byte indexChannel[6] = { 0,8,14,19,24,31 };


void setup() {
  int i;
  
  // The Arduino needs to clock out the data to the pixels
  // this happens in interrupt timer 1, we can change how often
  // to call the interrupt. setting CPUmax to 100 will take nearly all all the
  // time to do the pixel updates and a nicer/faster display, 
  // especially with strands of over 100 dots.
  // (Note that the max is 'pessimistic', its probably 10% or 20% less in reality)

  // GDH - this is a percentage value, 0-100%
  // the fastest clock cycle is thus 20ms (100%)
  // for 200 leds the max redraw rate seems to be ~100ms
  
  strip.setCPUmax(80);  // start with 50% CPU usage. up this if the strand flickers or is slow

  // Start up the LED strip
  strip.begin();

  // Update the strip, to start they are all 'off'
  for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);

  strip.show();
}


void loop() {
  // put your main code here, to run repeatedly:
  int i;
  int cindex ;
  uint32_t color;

  // Start by turning all pixels off:
  for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);
  strip.show();

//  ----- TESTING -----

//  for(i=0; i<strip.numPixels(); i++) {
////    color = applyColor(31,0,0,i);
//    color = applyColor(0,31,0,i);
////    color = applyColor(0,0,31,i);
//    strip.setPixelColor(i, color);
//  }
////
//
//  
//  strip.show();
//  delay (10000);
//  return;  

//  ----- TESTING -----

//  E.g:
//  color = indexToColor(2,-1);
//  color = applyColor(3,29,3,-1);

/*
  // color index cycle test
  for(cindex=0; cindex<=214; cindex++) {
    color = indexToColor(cindex,-1);
    for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, color);
    strip.show();
    delay(200);
  }
*/

// index color, but doesn't produce nice colours
// a lot of them are ~= white/gray
// But useful for testing the index lookup
//  for(cindex=0; cindex<=214; cindex++) {
//      lookup an index color 
//    color = indexToColor(cindex,-1);

/*
 * This is where we would insert the sequencing code
 * and load an array of information that
 * can call different effects
 */


// use wheel colors to roll around the pallet
  for(cindex=50; cindex<=96; cindex++) {
    
    // run through some different sequences

    
    showLetters(cindex,500,0);
    delay(200);

    // [ ] blink all the letters

    // color letterchase
//    showLetters(color,200,100);
//    delay(200);

    wipeLeftRight(cindex,100);
    delay(200);
    
    wipeUpDown(cindex,100);
    delay(200);

  }

 
}

/*
 * Show each letter for a fixed period of time,
 * turn off the last letter before showing the new one
 * If perPixelDelay > 0, we will draw each letter one pixel at a time
 * 
 */
void showLetters(int cindex, int letterDelay, int perPixelDelay ) {
  // loop over ALL letters
  int letter;
  int i;
  uint32_t color;
  for(letter=0; letter<=2; letter++) {

    //turn it all off
    for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);

    int len = lSeq[letter][0];
  
    for(i=1; i<=len; i++) {
      // lookup the pixels in this letter
      int id = lSeq[letter][i]; 
      color = Wheel(cindex,id);
      strip.setPixelColor(id, color);

      if ( perPixelDelay ) {
        // one pixel at a time
        if ( perPixelDelay <= 100 ) { perPixelDelay = 100; }
        strip.show();
        delay(perPixelDelay);
      }
      

      // delay(1000);
    }

    // draw the letter
    strip.show();
    delay(letterDelay);
  }

}

/*
 * run a wipe, but don't clear the last slice,
 * just slowly fill the sign
 */
 
void wipeLeftRight(int cindex, int sliceDelay) {
  // run a wipe X sequence
  // get the # of slices from the first row in the array
  int s ;
  int i ;
  uint32_t color ;
  int slices = wipex[0][1];

  // reset to black
  for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);


  // wipe from bottom to top 
  // (first row is the bottom)
  for(s=1; s<=slices; s++) {
    
    // get the next slice
    int len = wipex[s][0];
  
    for(i=1; i<=len; i++) {
      int id = wipex[s][i]; 
      color = Wheel(cindex,id);
      strip.setPixelColor(id, color);
    }
    strip.show();
    delay(sliceDelay);
  }
  
}


void wipeUpDown(int cindex, int sliceDelay) {
  // run a wipe Y sequence
  // get the # of slices from the first row in the array
  int s ;
  int i ;
  uint32_t color ;
  int slices = wipey[0][1];

  // reset to black
  for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);

  // wipe from bottom to top 
  // (first row is the bottom)
  for(s=1; s<=slices; s++) {
    
    // get the next slice
    int len = wipey[s][0];
  
    for(i=1; i<=len; i++) {
      int id = wipey[s][i]; 
      color = Wheel(cindex,id);
      strip.setPixelColor(id, color);
    }
    
    strip.show();

    /*
    // draw eack slice and then clear screen
    delay(150);
    for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);
    strip.show();
    */
    
    delay(sliceDelay);
  }
  
}

/*
 * Get a pixel color
 * This is a wrapper because we may need to rotate some RGB
 * values for some chipsets and chip IDs
 * and returning arrays is tricky in C++, so
 * we just return the packed int.
 * 
 * for 6803 chipsets, the color order is B,R,G !!
 * 
 * if the ID doesn't match a known rule, we
 * just calculate the color regardless
 * (This also lets you pass bogus/unknown IDs)
 */

uint16_t applyColor(byte r, byte g, byte b, int id ) {

     // we need to swap B & R for ALL normal strips
     // because Color() expects the order of B,G,R
     // so the default is to just roll the values
     uint16_t color = Color(b,g,r);

     // SO, for the alternate chipsets we need to swap G&B
     // which is actually the G&R inputs
     // so we want this:
     //      color = Color(g,b,r);
//
     if ( swapPixels ) {
        int numpairs = reversedLED[0];
        int idx;
        for(idx=0; idx<=numpairs; idx++) {
          // where in reversedLED[] do we find the next pair...
          int rangeIdx = (idx * 2) + 1;
          int rstart = reversedLED[ rangeIdx ] ;
          int rend = reversedLED[ rangeIdx + 1 ] ;

          if ( id >= rstart && id <= rend ) {
              color = Color(g,b,r);            
          }
          
        }
        
     }
//
     
     //reversedLED[1]
     // walk pairs 
     // numpairs = reversedLED[0]
     // idx = 0 .. numpairs
     // min = idx * 2 + 1, max = min+1
     
     return color;
}

/*  
 *  Get a color from an index 
 *  
 *  use an index value from 0-215 to calculate the RGB values
 *  for a color, where the values can be from 0-127
 *  We do this by using the lookup table indexChannel[]
 *  and packing 3 values from 1-6 into a single byte
 *  And adding them together
 *  ( ri*36 + gi*6 + bi )
 *  
 *  because we can't return an array, we pass the rgb values
 *  to applyColor(), BUT this also means we need to pass
 *  the LED ID, (but we can pass '-1' to bypass this)
 */
uint32_t indexToColor(int index, int id)
{
  byte r, g, b;
  int mod;
  int ii = index;

  mod = index % 6;
  b = indexChannel[ mod ];
  index -= mod;

  mod = index % 36;
  g = indexChannel[ mod / 6 ];
  index -= mod;

  r = indexChannel[ index / 36 ];

//  Serial.begin(9600);    
//  Serial.println("in index2c : rgb");
//  Serial.println(ii,DEC);
//  Serial.println(r,DEC);
//  Serial.println(g,DEC);
//  Serial.println(b,DEC);
//  Serial.println(mod,DEC);
//  Serial.println("---");

  return(applyColor(r,g,b,id));
  
}


//Input a value 0 to 384 to get a color value.
//The colours are a transition r - g - b - back to r

//Input a value 0 to 96 to get a color value.
//The colours are a transition r - g -b - back to r
uint32_t Wheel(byte WheelPos, byte id)
{
  byte r,g,b;
  switch(WheelPos >> 5)
  {
    case 0:
      r=31- WheelPos % 32;   //Red down
      g=WheelPos % 32;      // Green up
      b=0;                  //blue off
      break; 
    case 1:
      g=31- WheelPos % 32;  //green down
      b=WheelPos % 32;      //blue up
      r=0;                  //red off
      break; 
    case 2:
      b=31- WheelPos % 32;  //blue down 
      r=WheelPos % 32;      //red up
      g=0;                  //green off
      break; 
  }
  return(applyColor(r,g,b,id));
}

// Create a 15 bit color value from R,G,B
unsigned int Color(byte r, byte g, byte b)
{
  //Take the lowest 5 bits of each value and append them end to end
  return( ((unsigned int)g & 0x1F )<<10 | ((unsigned int)b & 0x1F)<<5 | (unsigned int)r & 0x1F);
}

