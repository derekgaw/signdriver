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
  
  // load the entire compiled config
  json = loadJSONObject("led-coords.json");
  
  // now pull some of this into variables
  lindex = json.getJSONObject("index").getJSONObject("letter");
  data = json.getJSONObject("pixels");
  
  // load an animation of images into an array:
  int imageCount = 20 ;
  // initialise the array...
  images = new PImage[imageCount];
  for (int i = 0; i < imageCount; i++) {
      // Use nf() to number format 'i' into four digits
      //String filename = imagePrefix + nf(i, 4) + ".gif";
      String filename = "acloud-" + i + ".gif"; 
      println( "load image : " , filename );
      images[i] = loadImage(filename);
  }
  
  //mapimage(); 
 
}

// draw() block runs repeatedly
// draw block is the only function with access to vars defined in setup()
// and you can track state with 'frameCount'
void draw() {
 
  //background(clouds);
  
  //PImage clouds = loadImage("clouds.jpg");
  PImage bgimg = images[frameCount].get(0, 0, width, height);
  
  background(bgimg);
  // then save the pixel map, draw the image
  loadPixels();
  background(0);
   
  drawLetter("orig",true);

  
  //wipeDown(); 
  //flashLetter();
  //sequenceLetters();
  //noLoop();
  
  //saveFrame("frames/####.tif");
  if ( frameCount >= 19 ) {
    noLoop();
  }
  
  saveFrame("frames/####.tif");
  
}

void mapimage() {
  // images must be the same size as the viewport
  // so we crop using get();
  PImage clouds = loadImage("clouds.jpg");
  PImage bgimg = clouds.get(0, 0, width, height);
  
  background(bgimg);
  //drawAllLetters(sq,data);
  
  // then save the pixel map, draw the image
  loadPixels();
  background(0);
   
  drawLetter("orig",true);
}

void wipeDown() {  
  // clear the screen
  background(0);
   
  // draw a rectangle
  fill(209,209,55);
  rect(10,rp,width-20,150);
  
  // now try and grab a pixel from the pixel array.
  // this also lets us keep this data after a wipe
  // this is a flat array, so to convert to x,y we do some math
  // pixel[0] is top left,
  //  for x,y use pixels[y*width+x]
  loadPixels();
  background(0);
   
  drawLetter("orig",true);
  
  // move down
  rp+=10;
}

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

void sequenceLetters() {
  
  // start drawing a letter, work from the lindex
  String thisLetter = lseq[lidx];
  
  // get the list of pixels in this letter, this is an array of STRINGS!
  String[] seq = lindex.getJSONArray( thisLetter ).getStringArray();
  
  // work out where to stop, re-initialise for each letter
  if ( sidx == 0 ) {
    lastFrame += seq.length;
  }
  
  // Get the next pixel in the sequence
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

void drawPixel(String id) {
    JSONObject pixel = data.getJSONObject(id);
    int x = pixel.getInt("xpo");
    int y = pixel.getInt("ypo");
  
    ellipseMode(CENTER);
    ellipse(x,y,radius,radius);
  
}

void drawLetter(String letter, boolean usePixels ) {
  
  // get the list of pixels in this letter, this is an array of STRINGS!
  String[] seq = lindex.getJSONArray( letter ).getStringArray();
  
  for (String id : seq) {
    JSONObject pixel = data.getJSONObject(id);
    int x = pixel.getInt("xpo");
    int y = pixel.getInt("ypo");
    
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