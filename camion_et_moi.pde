import processing.video.*;

// film de la route
String roadmovie_path = "road.mp4"; // le fichier est dans le dossier data/
Movie road;
boolean finishing = false;
int finishingOffset  = 0;

//
// camion en route normale
String camion_normal_path = "camion/normal_";  // les fichiers sont dans le dossier data/camion/
int camion_normal_sequence_frames = 60;
PImage[] camion_normal_sequence = new PImage[camion_normal_sequence_frames]; // sequence normale
 
//
// chute du camion
String camion_falling_path = "camion/falling_"; // les fichiers sont dans le dossier data/camion/
int camion_falling_sequence_frames_real = 560; // nombre total reel disponible
int falling_c = 5; // ici, une image sur 5
int finishing_keypoint = 30; // seuil de declenchement de la chute du camion
int camion_falling_sequence_frames = camion_falling_sequence_frames_real/falling_c;
PImage[] camion_falling_sequence = new PImage[camion_falling_sequence_frames]; // sequence de chute

// librairie minim pour le son
import ddf.minim.analysis.*;
import ddf.minim.*;

Minim       minim;
AudioPlayer jingle;
FFT         fft;
AudioInput  in;
float m = 0;

void setup()
{
  
  road = new Movie(this,roadmovie_path);
  road.loop();
  
  //
  // chargements de la sequence normale
  for(int i=0; i<camion_normal_sequence_frames; i++){
    //
    camion_normal_sequence[i] = loadImage(camion_normal_path+(i+1)+".png");
  }
  
  //
  // chargement de la sequence de chute
  for(int i=0; i<camion_falling_sequence_frames; i++){
    camion_falling_sequence[i] = loadImage(camion_falling_path+(i*falling_c+1)+".png");
  }
  
   // taille de la fenetre processing
  size(512+960, 540, P3D);

  // demarage de minim pour la captation sonore
  minim = new Minim(this);
  
  // use the getLineIn method of the Minim object to get an AudioInput
  in = minim.getLineIn();
  
  // Fast Fourier Transform
  // Transformation de Fourier rapide
  // voir http://fr.wikipedia.org/wiki/Transformation_de_Fourier_rapide 
  fft = new FFT(in.bufferSize(),in.sampleRate());
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}

void draw()
{
  // on imprime du noir partout
  background(0);
  
  // on imprime la video de la route
  image(road, 512, 0);
  
  // on regarde un pixel sur la fenetre processing
  color pipette = get(512+480,450);
  // on l'utilise comme couleur de remplissage
  fill(pipette);
  
  // affichage de la couleur de la pipette
  ellipseMode(CENTER);
  ellipse(512+480,450,60,60);
  
  
  // couleur du trait
  stroke(255);
  // couleur de remplissage
  fill(255);
  
  //
  // gestion de l'entree son : du microphone
  //
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
  // m est une valeur moyenne
  if(fftMed==0){
    m = m*.9;
    m = m<0 ?0 : m;
  }else{
    m = m*.98 + (  fftMed-TRESHOLD)*.02;
  }
  noStroke();
  fill(255,0,0);
  rect(0,200,m*3,20);
  
  
  //
  // affichage du camion
  // 
  
  tint(pipette);
  PImage currentImage = null;
  
  
  if(!finishing){ // NOT finishing
    //
    // cas route ou debut de souffle
    //
    int mMax = (int) min(m,camion_falling_sequence_frames-1); // image maximum
    
    // selection de l'image
    currentImage = m<1 ? // si le souffle n'existe pas (inferieur a 1)
                    camion_normal_sequence[frameCount%camion_normal_sequence_frames] : // on utilise le frameCount processing
                     camion_falling_sequence[mMax]; // sinon on utilise le dbut de la sequence de chute
    // si on depasse le point de chute
    if(m>finishing_keypoint){
      //
      finishing = true; 
      finishingOffset = frameCount;
    }
  }else{ // finishing
    //
    // cas fin de chute
    //
    int finishingFrame = frameCount-finishingOffset+finishing_keypoint;
    finishingFrame = min(finishingFrame,camion_falling_sequence_frames-1);
    currentImage = camion_falling_sequence[finishingFrame];
    //
    // si on est a la fin de la chute on s'arrete
    if(finishingFrame == camion_falling_sequence_frames-1){
      road.pause();
    }
  }
  
  // on affiche l'image selectionnee
  image(currentImage,512,0);
  // on remet la teinte naturelle blanche (255);
  tint(color(255));

}
