#include <TimerOne.h>
#include "LPD6803.h"

// Globals  

#include "signCoords.h"

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

// quantised color values in the range 0 - 127
byte indexChannel[6] = { 10,32,54,76,98,120 };


void setup() {
  int i;
  
  // The Arduino needs to clock out the data to the pixels
  // this happens in interrupt timer 1, we can change how often
  // to call the interrupt. setting CPUmax to 100 will take nearly all all the
  // time to do the pixel updates and a nicer/faster display, 
  // especially with strands of over 100 dots.
  // (Note that the max is 'pessimistic', its probably 10% or 20% less in reality)
  
  strip.setCPUmax(80);  // start with 50% CPU usage. up this if the strand flickers or is slow

  
  // Start up the LED strip
  strip.begin();

  // Update the strip, to start they are all 'off'
  for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);

//   test a pixel
//  strip.setPixelColor(1, Color(31, 0, 0));
  
  strip.show();
}


void loop() {
  // put your main code here, to run repeatedly:
  int i;
  uint32_t color;

//  color = Color(31,  20,    0); // Blue
  color = applyColor(31,20,30,-1); // red
  
//  color = strip.Color(0,  127,    0); // Green
//  color = strip.Color(0,    0,  127); // Blue
//  color = strip.Color(127,  127,  127); // White
  
  // Start by turning all pixels off:
  for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);

  // write first 10 pixels
//  for(i=0; i<10; i++) strip.setPixelColor(i, color);


/*
  // try and draw a letter, use row 0
  
  // First letter
  int letter = 2;

  // loop over ALL letters
  for(letter=0; letter<=2; letter++) {

    //turn it all off
    for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);

    int len = lSeq[letter][0];
  
    for(i=1; i<=len; i++) {
      // lookup the pixels in this letter
      int id = lSeq[letter][i]; 
      strip.setPixelColor(id, color);

      // delay(1000);
    }

    // draw the letter
    strip.show();
    delay(500);
  }

*/


  // run a wipe sequence

 // First letter
  int s;
  int slices = wipex[0][1];

//  slices = 4;
  
  int ss = 25;
  for(s=1; s<=slices; s++) {
//  for(s=ss; s<=ss; s++) {
    // set black
//    for(i=0; i<strip.numPixels(); i++) strip.setPixelColor(i, 0);
    
    // get the next slice
    int len = wipex[s][0];
  
    for(i=1; i<=len; i++) {
      int id = wipex[s][i]; 
      strip.setPixelColor(id, color);
    }
    strip.show();
    delay(100);
  }


 /* 
 * 
 */
  
  strip.show();
  delay(1000);

 
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

uint16_t applyColor(byte b, byte g, byte r, uint16_t id ) {
     uint16_t color = Color(r,g,b);
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
uint32_t indexToColor(uint16_t id, byte index)
{
  byte r, g, b;
  byte mod;

  mod = index % 6;
  b = indexChannel[ mod ];
  index -= mod;

  mod = index % 36;
  g = indexChannel[ mod / 6 ];
  index -= mod;

  r = indexChannel[ mod / 36 ];
    
  return(applyColor(r,g,b, -1 ));
}


//Input a value 0 to 384 to get a color value.
//The colours are a transition r - g - b - back to r

uint32_t Wheel(uint16_t WheelPos)
{
  byte r, g, b;
  switch(WheelPos / 128)
  {
    case 0:
      r = 127 - WheelPos % 128;   //Red down
      g = WheelPos % 128;      // Green up
      b = 0;                  //blue off
      break; 
    case 1:
      g = 127 - WheelPos % 128;  //green down
      b = WheelPos % 128;      //blue up
      r = 0;                  //red off
      break; 
    case 2:
      b = 127 - WheelPos % 128;  //blue down 
      r = WheelPos % 128;      //red up
      g = 0;                  //green off
      break; 
  }
  return(Color(r,g,b));
}

// Create a 15 bit color value from R,G,B
unsigned int Color(byte r, byte g, byte b)
{
  //Take the lowest 5 bits of each value and append them end to end
  return( ((unsigned int)g & 0x1F )<<10 | ((unsigned int)b & 0x1F)<<5 | (unsigned int)r & 0x1F);
}

