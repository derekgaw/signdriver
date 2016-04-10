/**
 * LoadFile 1
 * 
 * Loads a text file that contains two numbers separated by a tab ('\t').
 * A new pair of numbers is loaded each frame and used to draw a point on the screen.
 */

// declare globals that all functions can see
JSONObject json ;
JSONObject lindex ;
JSONObject data ;
PImage[] images;

int radius = 10;
int rp = 10 ;

String[] lseq = { "A" , "E" , "Z" };

int lidx = 0 ;
int sidx = 0 ;
int lastFrame = 0 ;
  
// size() CANNOT use variables,
// so we have to live with the hardcoding...
// see the json input for suggested values
// assume 240/300 x 660/700

// setup() block runs once
void setup() {
  size(690, 322);
  background(0);
  //stroke(255);
  noStroke();
  fill(255);
  frameRate(6);
  
  //
  // test writing a 2 d array to disk
  //
  String[][] ma = {
    { "A" , "E" , "Z" },
    { "C" , "X" , "Y" }
  };
  
  println ( ma.length);
  String[] flat = new String[ma.length +3 ];
  flat[0] = "String[][] dat = {";
  int fidx = 1 ;
  for (String[] line : ma) {
    String joined = join(line, "\",\"");
    joined = "  {\""+joined+"\"},";
    flat[fidx] = joined ;
    fidx++;
    println ( joined );
  }
  // add a dead line to save trailing ',' problems
  flat[fidx] = "{\"end\"}";
  fidx++;
  flat[fidx] = "};";
  
  
  saveStrings("foo.txt", flat );
  // arduino format is : 
  //   int pinMatrix[3][3] = {   {2,  3,  4}, {5,  6,  7}, {8,  9, 10} };

  // load the entire compiled config
  json = loadJSONObject("led-coords.json");
  
  // now pull some of this into variables
  lindex = json.getJSONObject("index").getJSONObject("letter");
  data = json.getJSONObject("pixels");
  
  //// load an animation of images into an array:
  //int imageCount = 20 ;
  //// initialise the array...
  //images = new PImage[imageCount];
  //for (int i = 0; i < imageCount; i++) {
  //    // Use nf() to number format 'i' into four digits
  //    //String filename = imagePrefix + nf(i, 4) + ".gif";
  //    String filename = "acloud-" + i + ".gif"; 
  //    //println( "load image : " , filename );
  //    images[i] = loadImage(filename);
  //}
  
  //mapimage(); 
 
}

// draw() block runs repeatedly
// and you can track state with 'frameCount' and a few other internal variables
void draw() {
  
  //animateByImage();
  //mapimage();
  //wipeDown(); 
  //flashLetter();
  //sequenceLetters();
  
  noLoop();
  
  if ( frameCount >= 19 ) {
    noLoop();
  }
  
  //saveFrame("frames/####.tif");
  
}

// animate a sequence by setting the color of the pixel to match
// a background image. The BG image is also a sequence of frames (originally)
// from an animated gif.
//
// images[] contains the array of backgrounds

void animateByImage() {
  
  // grab an image from the array (based on the framecount)
  // and crop it, using get(), to fit the window.
  // set it as the background
  PImage bgimg = images[frameCount].get(0, 0, width, height);
  background(bgimg);
  
  // then save the pixel map, and clear the window
  loadPixels();
  background(0);
   
  // call drawletter with 'true', to set the color based on
  // the pixelmap
  drawLetter("orig",true);
  
}

// a static example of setting the colors of the leds to match a background image

void mapimage() {
  // images must be the same size as the viewport
  // so we crop using get();
  
  // load and image from disk
  // and crop it, using get(), to fit the window.
  // set it as the background

  PImage clouds = loadImage("clouds.jpg");
  PImage bgimg = clouds.get(0, 0, width, height);
  background(bgimg);
  
  //drawAllLetters(sq,data);
  
  // then save the pixel map, and clear the window
  // call drawletter with 'true', to set the color based on
  // the pixelmap
  loadPixels();
  background(0);
   
  drawLetter("orig",true);
}

//
// animate the pixels based in a simple yellow bar that wipes down the screen
//
void wipeDown() {  
  // clear the screen
  background(0);
   
  // draw a rectangle, use the variable 'rp' to set the position
  // of the rectangle
  fill(209,209,55);
  rect(10,rp,width-20,150);
  
  // now try and grab a pixel from the pixel array.
  // this also lets us keep this data after a wipe
  // this is a flat array, so to convert to x,y we do some math
  // pixel[0] is top left,
  //  for x,y use pixels[y*width+x]
  loadPixels();
  
  // clear the screen and re-draw JUST the leds
  background(0);
  drawLetter("orig",true);
  
  // move the wipe bar down
  rp+=10;
  
  if ( frameCount >= 30 ) {
    noLoop();
  }

}

//
// make each letter flash in sequence,
// use use math on the frameCount to select each letter
// also set the letter to a different color
//
void flashLetter() {  
  switch(frameCount % 3) {
    case 1: 
      background(0);
      fill(209,39,48);
      drawLetter("A",false);
      break;
    case 2: 
      background(0);
      fill(39,209,48);
      drawLetter("E",false);
      break;
    default:
      background(0);
      fill(48,39,209);
      drawLetter("Z",false);
      break;
  }
  
  
  if ( frameCount >= 30 ) {
    noLoop();
  }
}

//
// draw a letter one pixel at a time, 
// for each frame, add another pixel
//
// we are indexing through some arrays : 
//   lidx : which letter we are drawing
//   sidx : which pixel in that letter we are drawing
//   lastFrame : so we know when to stop
//
//
void sequenceLetters() {
  
  // start drawing a letter, work from the lseq array (A,E,Z)
  String thisLetter = lseq[lidx];
  
  // get the list of pixels in this letter, this is an array of STRINGS!
  String[] seq = lindex.getJSONArray( thisLetter ).getStringArray();
  
  // work out where to wind on, re-initialise for each letter
  if ( sidx == 0 ) {
    lastFrame += seq.length;
  }
  
  // Get the next pixel ID in the sequence
  String id = seq[sidx]; 
  
  //println( "fc" , frameCount , thisLetter , id );
  drawPixel( id );
  sidx++;
  
  // check when to switch to a new letter
  if ( frameCount >= lastFrame ) {
    // wind on the the next letter
    sidx = 0;
    lidx ++ ;
    
    //println ( "new letter" , lidx );
    
  }
  
  // stop when we run out of letters
  if ( lidx >= lseq.length ) {
    noLoop();
  }

  //saveFrame("frames/####.tif");
  
}

//
// draw an LED pixel based on it's ID.
// we can then lookup a record to get XY position and other fun things
//
void drawPixel(String id) {
    JSONObject pixel = data.getJSONObject(id);
    int x = pixel.getInt("xpo");
    int y = pixel.getInt("ypo");
  
    ellipseMode(CENTER);
    ellipse(x,y,radius,radius);
  
}

//
// Draw all the LEDs in a single letter,
// do this by using the letter index to get the list of IDs for
// this letter.
//
// if we pass 'true' as the second argument, we will set the color
// of the LED to the value in the pixels[] array that matches the
// XY position of the pixel.
// This lets composite colors based on a packground image

void drawLetter(String letter, boolean usePixels ) {
  
  // get the list of pixel IDs in this letter, this is an array of STRINGS!
  String[] seq = lindex.getJSONArray( letter ).getStringArray();
  
  for (String id : seq) {
    JSONObject pixel = data.getJSONObject(id);
    int x = pixel.getInt("xpo");
    int y = pixel.getInt("ypo");
 
    // now try and grab a pixel from the pixel array.
    // this also lets us keep this data after a wipe
    // this is a flat array, so to convert to x,y we do some math
    // pixel[0] is top left,
    //    for x,y use pixels[y*width+x]
      
    // map the color to the pixels array
    if ( usePixels ) {
       color c = pixels[y*width+x];
       fill(c);
    }
  
    ellipseMode(CENTER);
    ellipse(x,y,radius,radius);
  
    //println(id,x,y);
    //println(pixel , x);
  }
  
   
}

//
// GN:DN
// 
// this was old experimental code.
// use drawLetter(,) instead
//

void drawAllLetters(String[] sq, JSONObject data) {
  for (String id : sq) {
    JSONObject pixel = data.getJSONObject(id);
    int x = pixel.getInt("xpo");
    int y = pixel.getInt("ypo");
  
    ellipseMode(CENTER);
    ellipse(x,y,radius,radius);
  
    println(id);
    println(pixel , x);
  }
}