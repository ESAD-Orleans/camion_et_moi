import processing.video.*;

Movie road;
boolean finishing = false;
int finishingOffset  = 0;
float finishingIPS = 30;

int camion_normal_sequence_frames = 60;
PImage[] camion_normal_sequence = new PImage[camion_normal_sequence_frames];

int camion_falling_sequence_frames_real = 560;
int falling_c = 5;
int finishing_keypoint = 30;
int camion_falling_sequence_frames = camion_falling_sequence_frames_real/falling_c;
PImage[] camion_falling_sequence = new PImage[camion_falling_sequence_frames];

import ddf.minim.analysis.*;
import ddf.minim.*;

Minim       minim;
AudioPlayer jingle;
FFT         fft;
AudioInput  in;
float m = 0;

void setup()
{
  
  road = new Movie(this,"road.mp4");
  road.loop();
  
  for(int i=0; i<camion_normal_sequence_frames; i++){
    camion_normal_sequence[i] = loadImage("camion/normal_"+(i+1)+".png");
  }
  
  for(int i=0; i<camion_falling_sequence_frames; i++){
    camion_falling_sequence[i] = loadImage("camion/falling_"+(i*falling_c+1)+".png");
  }
  
  size(512+960, 540, P3D);

  minim = new Minim(this);
  
  // use the getLineIn method of the Minim object to get an AudioInput
  in = minim.getLineIn();
  
  fft = new FFT(in.bufferSize(),in.sampleRate());
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}

void draw()
{
  background(0);
  image(road, 512, 0);
  
  color pipette = get(512+480,450);
  fill(pipette);
  ellipseMode(CENTER);
  ellipse(512+480,450,60,60);
  
  
  
  stroke(255);
  fill(255);
  
  // draw the waveforms so we can see what we are monitoring
  
  float n = 0;
  for(int i = 0; i < in.bufferSize() - 1; i++)
  {
    float j = abs(in.left.get(i)) + abs(in.right.get(i));
    n += j;
    line( i/2, 100 + in.left.get(i)*50, (i+1f)/2, 100 + in.left.get(i+1)*50 );
    line( i/2, 300 + in.right.get(i)*50, (i+1f)/2, 300 + in.right.get(i+1)*50 );
  }
  
  fft.forward( in.mix );
  stroke(255);
  float s = 0;
  for(int i = 0; i < fft.specSize(); i++)
  {
    float l = fft.getBand(i);
    s+=pow(l*2,.3);
    // draw the line for frequency band i, scaling it up a bit so we can see it
    line( i, height, i, height - fft.getBand(i)*8 );
  }
  float fftMed = 100*s/fft.specSize();
  //fill(255,fftMed);
  noStroke();
  float TRESHOLD = 80;
  if(fftMed>TRESHOLD){
  rect(0,160,fftMed,20);
  }else{
    fftMed = 0;
  }
  
  fill(0,0,255);
  noStroke();
  rect(0,180,n,20);
  if(fftMed==0){
m = m*.9;
  m = m<0 ?0 : m;
  }else{
  m = m*.98 + (  fftMed-TRESHOLD)*.02;
  }
  noStroke();
  fill(255,0,0);
  rect(0,200,m*3,20);
  
  String monitoringState = in.isMonitoring() ? "enabled" : "disabled";
  text( "Input monitoring is currently " + monitoringState + ".", 5, 15 );
  
  noFill();
  //stroke(255,0,0);
  //translate(width/2,height/2);
  //rotate(radians(-m/2));
  //rect(0,-100,80,100);
  
  tint(pipette);
  PImage currentImage = null;
  
  
  if(!finishing){
    int mMax = (int)min(m,camion_falling_sequence_frames-1);
    currentImage = m<1 ? camion_normal_sequence[frameCount%camion_normal_sequence_frames] :
                             camion_falling_sequence[mMax];                           
    if(m>finishing_keypoint){
      finishing = true;
      finishingOffset = frameCount;
      finishingIPS = 30;
    }
  }else{
    //road.frameRate(20);
    //frameRate(finishingIPS);
    int finishingFrame = frameCount-finishingOffset+finishing_keypoint;
    finishingFrame = min(finishingFrame,camion_falling_sequence_frames-1);
    currentImage = camion_falling_sequence[finishingFrame];
    finishingIPS = round(max(finishingIPS,4));
    if(finishingFrame == camion_falling_sequence_frames-1){
      road.pause();
    }
  }
  
  
  image(currentImage,512,0);
  tint(color(255));

}

void keyPressed()
{
  if ( key == 'm' || key == 'M' )
  {
    if ( in.isMonitoring() )
    {
      in.disableMonitoring();
    }
    else
    {
      in.enableMonitoring();
    }
  }
}
