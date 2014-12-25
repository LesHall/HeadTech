// by Les Hall
// started Sun Nov 9 2014
// from oscP5 examples
// 


import oscP5.*;
import netP5.*;
import java.awt.*;
import java.awt.event.InputEvent;
import processing.video.*;
import blobscanner.*;


OscP5 oscP5;
NetAddress myRemoteLocation;
java.awt.Robot robo;
Capture cam;
Detector bd;


float mouseRate = 3.0;
PVector blob = new PVector(0, 0, 0);
PVector blobAvg = new PVector(0, 0, 0);
PVector gyro = new PVector(0, 0, 0);
PVector accel = new PVector(0, 0, 0);
PVector vel = new PVector(0, 0, 0);
PVector dist = new PVector(0, 0, 0);
int numButtons = 9;
boolean[] button = new boolean[9];
PVector mousePos = new PVector(0, 0, 0);
PImage img;
int purpleClicks = 0;


void setup()
{
  size(640, 360);
  frameRate(5);
  
  /* start oscP5, listening for incoming messages */
  oscP5 = new OscP5(this, 11000);
  myRemoteLocation = new NetAddress("127.0.0.1", 11000);

  // Robot class
  try
  { 
    robo = new java.awt.Robot();
  } 
  catch (AWTException e)
  {
    e.printStackTrace();
  }
  
  String[] cameras = Capture.list();

  if (cameras == null)
  {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, width, height);
  }
  if (cameras.length == 0)
  {
    println("There are no cameras available for capture.");
    exit();
  }
  else
  {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++)
    {
      println(cameras[i]);
    }

    // The camera can be initialized directly using an element
    // from the array returned by list():
    cam = new Capture(this, cameras[4]);
    // Or, the settings can be defined based on the text in the list
    //cam = new Capture(this, 640, 480, "Built-in iSight", 30);
    
    // Start capturing the images from the camera
    cam.start();
  }
  
  img = new PImage(width, height);  

  bd = new Detector(this, 255);
}


void draw()
{
  background(0); 
 
  // get a camera image
  if (cam.available() == true)
  {
    img = cam;
    cam.read();
    cam.filter(GRAY);
    cam.filter(BLUR, 2);
    cam.filter(POSTERIZE, 8);
    cam.filter(BLUR, 2);
    cam.filter(POSTERIZE, 8);
    cam.filter(BLUR, 2);
    cam.filter(THRESHOLD, 0.5);

    pushMatrix();
      scale(-1.0, 1.0);
      image(cam, -cam.width, 0);
    popMatrix();
    
    loadPixels();
    
    // blob scan
    bd.findBlobs(pixels, width, height);
    //To be called before quering
    //the library.
    bd.loadBlobsFeatures();
    //Computes the blob center of mass. 
    //Replaces findCentroids(boolean,boolean)
    //since v. 0.1-alpha.Also no more need to call 
    //weigthBlobs before it;
    bd.findCentroids();
    //The parameter is used to print or not a message
    //when no blobs are found.
    bd.weightBlobs(true);    
    
    
    int numBlobs = bd.getBlobsNumber();
    int k = 8;
    float bx = 0;
    float by = 0;
    float weightMax = 0;
    int numWeightMax = -1;
    float distMin = displayWidth;
    int numDistMin = -1;
    for (int i=0; i<numBlobs; ++i)
    {
      float bdx = bd.getCentroidX(i);
      float bdy = bd.getCentroidY(i);
      float dx = bdx - width/2;
      float dy = bdy - height/2;
      float dist = sqrt(dx*dx + dy*dy);
      if (dist <= distMin)
      {
        numDistMin = i;
        distMin = dist;
      }
      
      float weight = bd.getBlobWeight(i);
      if (weight > weightMax)
      {
        numWeightMax = i;
        weightMax = weight;
      }
    }
    
    if (numDistMin >= 0)
    {
      fill(0, 255, 0);
      for (int i=0; i<numBlobs; ++i)
        ellipse(bd.getCentroidX(i), bd.getCentroidY(i), k, k);

      float tau  = 0.5;
      float tauAvg = 0.9;
      blob.x = tau*blob.x + (1-tau)*bd.getCentroidX(numDistMin);
      blob.y = tau*blob.y + (1-tau)*bd.getCentroidY(numDistMin);
      blobAvg.x = tauAvg*blobAvg.x + (1-tauAvg)*blob.x;
      blobAvg.y = tauAvg*blobAvg.y + (1-tauAvg)*blob.y;
  
      fill(0, 255, 255);
      ellipse(blob.x, blob.y, 2*k, 2*k);
  
      float wx = 0.9*float(width)/float(displayWidth);
      float wy = 0.9*float(height)/float(displayHeight);
      fill(255, 255, 0);
      ellipse(width*0.05 + wx*mousePos.x, height*0.05 + wy*mousePos.y, 2*k, 2*k);
  
      fill(255, 0, 255);
      rect(blobAvg.x - k, blobAvg.y - k, 2*k, 2*k);

      fill(255, 0, 255);
      textAlign(CENTER, BOTTOM);
      text("purpleClicks = " + str(purpleClicks), width/2, height);
    }
  }
  
  // adjust mouse position
  mousePos.x -= mouseRate * gyro.y - (blob.x - blobAvg.x) * 2;
  mousePos.y -= mouseRate * gyro.x - (blob.y - blobAvg.y) * 8;
  if (mousePos.x < 0) mousePos.x = 0;
  if (mousePos.x >= (displayWidth - 1) ) mousePos.x = displayWidth - 1;
  if (mousePos.y < 0) mousePos.y = 0;
  if (mousePos.y >= (displayHeight - 1) ) mousePos.y = displayHeight - 1;
  
  // send Robot class command to move the mouse!
  robo.mouseMove( int(mousePos.x), int(mousePos.y) );

  // mouse buttons
  if (button[0] == true)
  {
    button[0] = false;
    robo.mousePress(InputEvent.BUTTON1_MASK);
    robo.mouseRelease(InputEvent.BUTTON1_MASK);
  }
  if (button[6] == true)
  {
    button[6] = false;
    robo.mousePress(InputEvent.BUTTON2_MASK);
    robo.mouseRelease(InputEvent.BUTTON2_MASK);
  }
  if (button[3] == true)
  {
    button[3] = false;
    robo.mousePress(InputEvent.BUTTON3_MASK);
    robo.mouseRelease(InputEvent.BUTTON3_MASK);
  }
}




void mouseClicked()
{
  if (get(mouseX, mouseY) == color(255, 0, 255) )
    ++purpleClicks;
}




/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage)
{
  // grab the gyro data
  String g = "/gyrosc/gyro";
  String a = "/gyrosc/accel";
  String b = "/gyrosc/button";
  if(g.equals(theOscMessage.addrPattern() ) )
  {
    gyro.x = theOscMessage.get(0).floatValue();  // pitch
    gyro.z = theOscMessage.get(1).floatValue();  // roll
    gyro.y = theOscMessage.get(2).floatValue();  // yaw
  }
  else if(a.equals(theOscMessage.addrPattern() ) )
  {
    accel.x = theOscMessage.get(0).floatValue();  // x axis
    accel.y = theOscMessage.get(1).floatValue();  // y axis
    accel.z = theOscMessage.get(2).floatValue();  // z axis
  }
  else if(b.equals(theOscMessage.addrPattern() ) )
  {
    button[theOscMessage.get(0).intValue()-1] = true;
  }
}

