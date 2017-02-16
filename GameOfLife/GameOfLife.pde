import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myLocation;

OscMessage msg = new OscMessage("");

String ip = "127.0.0.1";

// Size of cells
int cellSize = 22;
int numCells = 0;
// How likely for a cell to be alive at start (in percentage)
float probabilityOfAliveAtStart = 20;

// Variables for timer
int interval = 2123;
int lastRecordedTime = 0;

// Color evolution
int r = int(random(255));
int g = int(random(255));
int b = int(random(255));
color Human = color(r,g,b);

color dead = color(0);

// Array of cells
int[][] cells; 
// Buffer to record the state of the cells and use this while changing the others in the interations
int[][] cellsBuffer; 
// Buffer to record the number of cycles a cell is alive
int[][] cellLifes;
// Pause
boolean pause = false;

void setup() {
  size (600, 600);
  oscP5 = new OscP5(this,7039);
  myLocation = new NetAddress(ip,7039);
  // Instantiate arrays 
  cells = new int[width/cellSize][height/cellSize];
  cellsBuffer = new int[width/cellSize][height/cellSize];
  cellLifes = new int[width/cellSize][height/cellSize];

  // This stroke will draw the background grid
  stroke(30);

  noSmooth();

  // Initialization of cells
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      float state = random (100);
      if (state > probabilityOfAliveAtStart) { 
        state = 0;
        cellLifes[x][y] = 0;
      }
      else {
        state = 1;
      }
      cells[x][y] = int(state); // Save state of each cell
      cellLifes[x][y] = int(state);
    }
  }
  background(0); // Fill in black in case cells don't cover all the windows
}


void draw() {

  //Draw grid
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      if (cells[x][y]==1) {
        Human = color(r,g,b,cellLifes[x][y]);
        fill(Human);
      }
      else {
        fill(dead); // If dead
      }
      rect (x*cellSize, y*cellSize, cellSize, cellSize);
    }
  }
  // Iterate if timer ticks
  if (millis()-lastRecordedTime>interval) {
    if (!pause) {
      iteration();
      lastRecordedTime = millis();
    }
  }

  // Create  new cells manually on pause
  if (pause && mousePressed) {
    // Map and avoid out of bound errors
    int xCellOver = int(map(mouseX, 0, width, 0, width/cellSize));
    xCellOver = constrain(xCellOver, 0, width/cellSize-1);
    int yCellOver = int(map(mouseY, 0, height, 0, height/cellSize));
    yCellOver = constrain(yCellOver, 0, height/cellSize-1);

    // Check against cells in buffer
    if (cellsBuffer[xCellOver][yCellOver]==1) { // Cell is alive
      cells[xCellOver][yCellOver]=0; // Kill
      cellLifes[xCellOver][yCellOver] = 0;
      fill(dead); // Fill with kill color
    }
    else { // Cell is dead
      cells[xCellOver][yCellOver]=1; // Make alive
      cellLifes[xCellOver][yCellOver]=1;
      //fill(Human);
    }
  } 
  else if (pause && !mousePressed) { // And then save to buffer once mouse goes up
    // Save cells to buffer (so we opeate with one array keeping the other intact)
    for (int x=0; x<width/cellSize; x++) {
      for (int y=0; y<height/cellSize; y++) {
        cellsBuffer[x][y] = cells[x][y];
      }
    }
  }
}



void iteration() { // When the clock ticks
  numCells = 0;
  // Save cells to buffer (so we operate with one array keeping the other intact)
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      cellsBuffer[x][y] = cells[x][y];
      if(cells[x][y] == 1){
        cellLifes[x][y]++;
        numCells++;
        msg = new OscMessage("/xylife");
        msg.add(x);
        msg.add(y);
        msg.add(cellLifes[x][y]);
        oscP5.send(msg, myLocation);
      }
      if(cells[x][y] == 0){
        cellLifes[x][y] = 0;
      }
    }
  }
  msg = new OscMessage("/numCells");
  msg.add(numCells);
  oscP5.send(msg, myLocation);
  //println(numCells);
  // Visit each cell:
  for (int x=0; x<width/cellSize; x++) {
    for (int y=0; y<height/cellSize; y++) {
      // And visit all the neighbours of each cell
      int neighbours = 0; // We'll count the neighbours
      for (int xx=x-1; xx<=x+1;xx++) {
        for (int yy=y-1; yy<=y+1;yy++) {  
          if (((xx>=0)&&(xx<width/cellSize))&&((yy>=0)&&(yy<height/cellSize))) { // Make sure you are not out of bounds
            if (!((xx==x)&&(yy==y))) { // Make sure to to check against self
              if (cellsBuffer[xx][yy]==1){
                neighbours ++; // Check alive neighbours and count them
              }
            } // End of if
          } // End of if
        } // End of yy loop
      } //End of xx loop
      // We've checked the neigbours: apply rules!
      if (cellsBuffer[x][y]==1) { // The cell is alive: kill it if necessary
        if (neighbours < 2 || neighbours > 3) {
          cells[x][y] = 0; // Die unless it has 2 or 3 neighbours
          cellLifes[x][y] = 0;
        }
      } 
      else { // The cell is dead: make it live if necessary      
        if (neighbours == 3 ) {
          cells[x][y] = 1; // Only if it has 3 neighbours
        }
      } // End of if
    } // End of y loop
  } // End of x loop
} // End of function

void keyPressed() {
  if (key=='r' || key == 'R') {
    // Restart: reinitialization of cells
    r = int(random(255));
    g = int(random(255));
    b = int(random(255));
    for (int x=0; x<width/cellSize; x++) {
      for (int y=0; y<height/cellSize; y++) {
        float state = random (100);
        if (state > probabilityOfAliveAtStart) {
          state = 0;
        }
        else {
          state = 1;
        }
        cells[x][y] = int(state); // Save state of each cell
        cellLifes[x][y] = int(state);
      }
    }
  }
  if (key==' ') { // On/off of pause
    pause = !pause;
  }
  if (key=='c' || key == 'C') { // Clear all
    for (int x=0; x<width/cellSize; x++) {
      for (int y=0; y<height/cellSize; y++) {
        cells[x][y] = 0; // Save all to zero
        cellLifes[x][y] = 0;
        numCells = 0;
      }
    }
  }
}