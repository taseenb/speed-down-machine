import processing.video.*;
import SimpleOpenNI.*;

// SETTINGS
int waitBeforeReady = 3; // seconds before starting to move particles


// -- webcam --
Capture cam;
boolean kinectMode = false;
int detail = 3;

// Globals
SimpleOpenNI kinect;
PImage irImage, generatedImage;
int[] depthMap;
boolean standby;
int standbyTime;
int activeTime;
boolean agentsCreated = false;
boolean goBack = false;


// ------ agents ------
Agent[] agents;
int agentsCount = 12000;
float noiseScale = 300, noiseStrength = 10; 
float overlayAlpha = 10, agentsAlpha = 90, strokeWidth = 4;
int drawMode = 1;
String[] updateType = {"linear", "decompose", "goBack"};
int currentUpdateType;


// ------ Point cloud -----
ArrayList<PVector> visiblePoints;


// depth
float        zoomF = 0.5f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
                                   // the data from openni comes upside down
float        rotY = radians(0);


void setup()
{
  size(1024, 768, P3D);
  frameRate(60);
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
//              10,
//              15000);
  
  // Create all the agents once
  agents = new Agent[agentsCount];
  
  background(255);
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
    kinect.setMirror(true);
    irImage = kinect.irImage();
    depthMap = kinect.depthMap();
    // 3d position
    translate(width/2, height/2, 0);
    rotateX(rotX);
    rotateY(rotY);
    scale(zoomF); // 0.5
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
  } else if (cam.available() == true) {
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
  
  
  if (standby) {
    standbyTime =  millis();
    agentsCreated = false;
  } else {
    activeTime = millis() - standbyTime;
    createAgents();
    updateAgents(); 
  }
  
}



void createAgents() {
  if (!agentsCreated) {
    for (int i=0; i<agentsCount; i++) {
      if (visiblePoints.size() > i) {
        agents[i] = new Agent(visiblePoints.get(i).x, visiblePoints.get(i).y, true); // VISIBLE AGENT/POINT
      } else {
        float xPos = random(-width, width*2);
        float yPos = random(-height, height*2);
        agents[i] = new Agent(xPos, yPos, false); // NOT VISIBLE AGENT/POINT
      }
    }
    agentsCreated = true;
  }
}



void updateAgents() {
  //int maxPoints = visiblePoints.size() > agentsCount ? agentsCount : visiblePoints.size();
  
  if (frameCount % 60 == 0 && updateType[currentUpdateType] == "decompose") {
    println("how many visible points? " + visiblePoints.size());
  }
  
  for(int i=0; i<agentsCount; i++) {
    
    if (updateType[currentUpdateType] == "goBack") {
      // GOBACK
      if (visiblePoints.size() > i) {
        agents[i].visible = true;
        agents[i].updateGoBack(visiblePoints.get(i).x, visiblePoints.get(i).y);
      }
      
    } else if (updateType[currentUpdateType] == "decompose") {
      // DECOMPOSE
     if (visiblePoints.size() > i) {
       agents[i].visible = true;
       agents[i].updateDecompose(visiblePoints.get(i).x, visiblePoints.get(i).y, i);
      }
      
    } else if (updateType[currentUpdateType] == "linear") {
      // LINEAR
      if (visiblePoints.size() > i) {
        agents[i].visible = true;
        agents[i].updateLinear(visiblePoints.get(i).x, visiblePoints.get(i).y);
      }
    }
  }
  
}



void mousePressed() {
  currentUpdateType++;
  if (currentUpdateType > updateType.length-1) {
    currentUpdateType = 0;
  }
}

void keyPressed() {
  if (key == 83 || key == 115) { // S or s
    save("fog_" + frameCount + ".jpg");
    println("saving frame " + frameCount);
  }
}


