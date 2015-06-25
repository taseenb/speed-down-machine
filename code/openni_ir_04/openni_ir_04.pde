import processing.video.*;
import gab.opencv.*;
import controlP5.*;
import SimpleOpenNI.*;

// SETTINGS
int waitBeforeReady = 3; // seconds before starting to move particles


// -- webcam --
Capture cam;
boolean kinectMode = false;
int detail = 5;

// Globals
SimpleOpenNI kinect;
OpenCV opencv;
PImage irImage, generatedImage;
int[] depthMap;
//int brightnessThresold = 100;
boolean standby;
int standbyTime;
int activeTime;
boolean agentsCreated = false;
boolean goBack = false;
float goBackTransition;


// ------ agents ------
Agent[] agents;
//Agent[] agents = new Agent[10000]; // create more ... to fit max slider agentsCount
int agentsCount = 4000;
float noiseScale = 300, noiseStrength = 10; 
float overlayAlpha = 10, agentsAlpha = 90, strokeWidth = 4;
int drawMode = 1;

// ------ ControlP5 ------
ControlP5 controlP5;
boolean showGUI = false;
Slider[] sliders;


// ------ Point cloud -----
ArrayList<PVector> visiblePoints;


// depth
float        zoomF = 0.5f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
                                   // the data from openni comes upside down
float        rotY = radians(0);


void setup()
{
  //size(640*2, 480*2, P3D);
  size(1024, 768, P3D);
  smooth();
  
  
  // KINECT
  kinect = new SimpleOpenNI(this);
  if(kinect.isInit() == false) {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     kinectMode = false;
  } else {
     kinectMode = true;
     kinect.enableDepth();
     kinect.enableIR();
  }
  
  // CAMERA
  if (!kinectMode) {
    String[] cameras = Capture.list();
    if (cameras.length == 0) {
      println("There are no cameras available for capture.");
      exit();
    } else {
      println("Available cameras:");
      for (int i = 0; i < cameras.length; i++) {
        println(cameras[i]);
      }
      
      // The camera can be initialized directly using an 
      // element from the array returned by list():
      cam = new Capture(this, cameras[3]);
      cam.start();     
    } 
  }
  
//  perspective(radians(45),
//              float(width)/float(height),
//              10,150000);
  
  
  // Create all the agents once
  agents = new Agent[5000];
  
  fill(0);
  standbyTime =  millis();
}


void draw() {
  noStroke();
  fill(255, 20);
  rect(0,0, width, height);
  
  standby = true;
  visiblePoints = new ArrayList<PVector>();
  
  if (kinectMode) {
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
    for(int y=0;y < kinect.depthHeight();y+=detail) {
      for(int x=0;x < kinect.depthWidth();x+=detail) {
        index = x + y * kinect.depthWidth();
        if(depthMap[index] > 0) { 
          realWorldPoint = realWorldMap[index];
          if (realWorldPoint.z < 1000) {
            standby = false;
            visiblePoints.add(new PVector(realWorldPoint.x *2,realWorldPoint.y *2));
          }
        }
      }
    }
  } else {
    if (cam.available() == true) {
      cam.read();
      cam.loadPixels();
      //image(cam, 0, 0);
      for(int x=0;x < cam.width;x+=detail) {
        for(int y=0;y < cam.height;y+=detail) {
          int index = x + (y * cam.width);
          color c = cam.pixels[index];
//          fill(brightness(c));
//          ellipse(x*2, y*2, 4, 4);
          standby = false;
          if (brightness(c) < 150) {
            visiblePoints.add(new PVector(x * 2, y * 2));
          }
        }
      }
    }
  }
  
  
  if (standby) {
    standbyTime =  millis();
    //println("we are in waiting for you");
    agentsCreated = false;
    
  } else {
    
    activeTime = millis() - standbyTime;
    if (activeTime/1000 > waitBeforeReady) {
      if (!agentsCreated) {
        for (int i=0; i<agents.length; i++) { // 500 agents
          if (visiblePoints.size() > i) {
            agents[i] = new Agent(visiblePoints.get(i).x, visiblePoints.get(i).y); // VISIBLE AGENT/POINT
          } else {
            agents[i] = new Agent(0, 0); // NOT VISIBLE AGENT/POINT
          }
        }
        agentsCreated = true;
      } else {
        int agentsCount = agents.length;
        for(int i=0; i<agentsCount; i++) { 
          if (goBack) {
            if (visiblePoints.size() > i) {
              agents[i].goBack(visiblePoints.get(i).x, visiblePoints.get(i).y, goBackTransition);
            }
          } else {
            agents[i].update();
          }
        }
      }
      
    } else {
      
      for (int i=0; i<visiblePoints.size(); i++) {
        fill(0, 50);
        ellipse(visiblePoints.get(i).x, visiblePoints.get(i).y, 4, 4);
      }
      
    }
    
  }

}



void mousePressed() {
  
  if (!goBack) {
    if (goBackTransition < 1) {
      goBackTransition += 0.02;
    } else {
      goBackTransition = 1;
    }
    goBack = true;
  } else {
    goBackTransition = 0;
    goBack = false;
  }
//    println("reset!");
//    standby = true;
//    activeTime = 0;
//    standbyTime =  millis();
//    agentsCreated = false;
}


