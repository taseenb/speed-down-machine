import gab.opencv.*;
import controlP5.*;
import SimpleOpenNI.*;

// Globals
SimpleOpenNI  kinect;
OpenCV opencv;
PImage irImage, generatedImage;
int[] depthMap;
int detail = 3;
int brightnessThresold = 100;
ControlP5 cp5;


// depth
float        zoomF = 0.5f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
                                   // the data from openni comes upside down
float        rotY = radians(0);



void setup()
{
  size(640*2, 480*2, P3D);
  
  smooth();
  
  kinect = new SimpleOpenNI(this);
  
//  cp5 = new ControlP5(this);
//  cp5.addSlider("brightnessThresold")
//     .setRange(0,255)
//     .setValue(100)
//     .setPosition(20,20);
  
  //opencv = new OpenCV( this );
  
  if(kinect.isInit() == false) {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }
  
  // enable depthMap generation 
  kinect.enableDepth();
  
  // enable skeleton generation for all joints
  //kinect.enableUser();
  
  // enable ir generation
  kinect.enableIR();
  
  // turn on depth/color alignment
  //kinect.alternativeViewPointDepthToImage();
  
//  perspective(radians(45),
//              float(width)/float(height),
//              10,150000);
  
  noStroke();
  fill(0);
}

void draw()
{
  //background(255);
  
  fill(255, 20);
  rect(0,0, width, height);
  
  // update the cam with IR data
  kinect.update();
  
  irImage = kinect.irImage();
  depthMap = kinect.depthMap();
  
  // 3d position
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  PVector realWorldPoint;
  PVector[] realWorldMap = kinect.depthMapRealWorld();
  int     index;
  
  //translate(0,0,-1000);
  
  beginShape(POINTS);
  for(int y=0;y < kinect.depthHeight();y+=detail) {
    for(int x=0;x < kinect.depthWidth();x+=detail) {
      index = x + y * kinect.depthWidth();
      if(depthMap[index] > 0) { 
        realWorldPoint = realWorldMap[index];
        if (realWorldPoint.z < 1000) {
          color c = irImage.pixels[index];
          fill(c, 50);
          float b = brightness(c);
          float radius = map(b, 0, 255, 10, 1);
          ellipse(realWorldPoint.x *2,realWorldPoint.y *2, radius, radius);
        }
        
        // vertex(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);
        // vertex(realWorldPoint.x,realWorldPoint.y,0);
      }
    }
  } 
  endShape();
  
  //kinect.drawCamFrustum();
  
//  Dots from IR image
//  for (int gridX = 0; gridX < irImage.width; gridX+=detail) {
//    for (int gridY = 0; gridY < irImage.height; gridY+=detail) {
//        // Get color
//        color c = irImage.pixels[gridY*irImage.width+gridX];
//        
//        float b = brightness(c);
//        
//        if (brightness(c) > brightnessThresold) {
//          fill(c);
//          float radius = map(b, brightnessThresold, 255, 10, 1);
//          ellipse(gridX*2, gridY*2, radius, radius);
//        }
//    }
//  }
  
 
}


