#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
// #include <Adafruit_SSD1306.h>
#include <U8g2lib.h>
#include <LiquidCrystal_I2C.h>

#include <stdlib.h>
#include <time.h>

#define DTB_POT_PIN 0
#define DATA_ROT_POT_PIN 2
#define SDA_OLED_PIN 4
#define SCK_OLED_PIN 5

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

#define OLED_RESET -1
// Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/ U8X8_PIN_NONE, SCK_OLED_PIN, SDA_OLED_PIN);
LiquidCrystal_I2C lcd(0x27, 16, 2); 

void paddleDirection(uint8_t arr[]);

void resetValues();

void updateHistory(uint8_t history[], uint8_t newValue);

void drawBlocks();

void drawBlock(uint8_t row, uint8_t blockIndex);

bool checkCollision(uint8_t blockX, uint8_t blockY);

void displayGameState();

uint8_t countAllCharacters(const String& str);

void displayPageState(const String& str, uint16_t pageDelay);

uint16_t potValue = 0;
uint16_t potRotValue = 0;

uint8_t paddlePosition = 64;
uint8_t paddleLength = 20;
uint8_t paddleWidth = 3;

uint8_t paddlePreviousDirections[2] = {};
uint8_t numPrevPaddleStates = sizeof(paddlePreviousDirections) / sizeof(paddlePreviousDirections[0]);

bool firstCollision = true;

uint8_t numOfRows = 2;
uint8_t numBlocksRow = 15;
uint8_t w = 6;
uint8_t h = 6;
uint8_t offsetLR = 4;
uint8_t offsetBlocks = 2;

uint8_t blockMap[3][15] = {};

uint8_t score = 0;

enum GameState {
    GAME_START,
    GAME_PLAYING,
    GAME_OVER
};

enum BlockState {
    ACTIVE,
    HIT
};

enum PaddleState {
  LEFT,
  RIGHT,
  STILL
};

PaddleState paddleState;

GameState gameState = GAME_START;

class Ball {
  private:
    uint8_t size;
    uint8_t offset;
    int16_t x, y;
    int16_t startX, startY;
    int16_t addX, addY;
    uint8_t speed;

  public:
    Ball(uint8_t startSize, uint8_t startOffset, int16_t startX, int16_t startY, uint8_t startSpeed)
      : size(startSize), offset(startOffset), x(startX), y(startY), startX(startX), startY(startY), addX(0), addY(0), speed(startSpeed) {}
    
    enum MoveDirection {
      X_LEFT,
      X_RIGHT,
      X_STILL,
      Y_UP,
      Y_DOWN,
      Y_STILL
    };

    void updatePosition() {
        x += addX * speed;
        y += addY * speed;
    }

    void resetValues() {
        setMove(X_STILL);
        setMove(Y_STILL);
        setX(startX);
        setY(startY);
    }

    void invertDirectionX() { addX = -addX; }
    void invertDirectionY() { addY = -addY; }

    int16_t getX() const { return x; }
    int16_t getY() const { return y; }
    uint8_t getOffset() const { return offset; }
    uint8_t getSpeed() const { return speed; }
    int16_t getRightEdge() const { return x + offset; }
    int16_t getLeftEdge() const { return x - offset; }
    int16_t getTopEdge() const { return y - offset; }
    int16_t getBottomEdge() const { return y + offset; }
    MoveDirection getMovementDirectionX() {
      if (addX > 0) {
        return X_RIGHT;
        // WARNING REMOVED = from <=
      } else if (addX < 0) {
        return X_LEFT;
      } else {
        return X_STILL;
      }
    }
    MoveDirection getMovementDirectionY() {
      if (addY > 0) {
        return Y_DOWN;
        // WARNING REMOVED = from <=
      } else if (addY < 0) {
        return Y_UP;
      }  else {
        return Y_STILL;
      }
    } 
    void setSpeed(uint8_t newSpeed) { speed = newSpeed; }
    void setX(int16_t newX) { x = newX; }
    void setY(int16_t newY) { y = newY; }
    void setMove(MoveDirection direction) {
      switch (direction) {
      case X_LEFT:
        addX = -1;
        break;
      case X_RIGHT:
        addX = 1;
        break;
      case X_STILL:
        addX = 0;
        break;  
      case Y_UP:
        addY = -1;
        break;
      case Y_DOWN:
        addY = 1;
        break;
      case Y_STILL:
        addY = 0;
        break;
      }
    }

    void draw() {
      updateHistory(paddlePreviousDirections, paddlePosition);

      // ball hits screen sides
      // TODO rewrite firstCollision condition
      if(firstCollision == true) {
        setMove(Y_UP);
        firstCollision = false;
      }
      if (getTopEdge() < 0) {
        invertDirectionY();
        // ensure that ball is within screen area
        setY(offset);
      }
      else if (getLeftEdge() < 0) {
        invertDirectionX();
        setX(offset);
      }
      else if (getRightEdge() > SCREEN_WIDTH) {
        invertDirectionX();
        setX(SCREEN_WIDTH - offset);
      }
      else if (getBottomEdge() > SCREEN_HEIGHT - paddleWidth) {
        // ball hits paddle 
        if (getRightEdge() >= paddlePosition && getLeftEdge() <= paddlePosition + paddleLength) {
          paddleDirection(paddlePreviousDirections); 
          invertDirectionY();
          setY(SCREEN_HEIGHT - paddleWidth - offset);
          switch (paddleState) {
          case LEFT:
            if (getMovementDirectionX() == X_RIGHT) {
              invertDirectionX();
            } else if (getMovementDirectionX() == X_STILL) {
              setMove(X_RIGHT);
            }
            break;
          case RIGHT:
            if (getMovementDirectionX() == X_LEFT) {
              invertDirectionX();
            } else if (getMovementDirectionX() == X_STILL) {
              setMove(X_LEFT);
            }
            break;
          case STILL:
            break;
          }
        } else {
          gameState = GAME_OVER;
        }
      }
      updatePosition();
      u8g2.drawDisc(x, y, size);
    }
};

Ball ball(1, 3, SCREEN_WIDTH / 2, 2 * SCREEN_HEIGHT / 3, 1);

void setup() {
  // Serial.begin(9600);

  pinMode(DTB_POT_PIN, INPUT);
  pinMode(DATA_ROT_POT_PIN, INPUT);

  u8g2.begin();

  lcd.begin(16, 2);

  lcd.backlight();

  lcd.setCursor(0, 0);
  lcd.print("Score: ");
  lcd.setCursor(0, 1);
  lcd.print("Speed: ");
  lcd.setCursor(9, 1);
  lcd.print("pix/fr");

  int sensorValue = analogRead(A3); // A3 is assumed to be unconnected
  srand(sensorValue);

  // for (uint8_t row = 0; row < numOfRows; row++) {
  // for (uint8_t col = 0; col < numBlocksRow; col++) {
  //   // Print each element followed by a space
  //   Serial.print(blockMap[row][col]);
  //   Serial.print(" ");
  // }
  // // After each row, print a newline character
  // Serial.println();
  // }
  
}

void loop() {
  // Serial.println(firstCollision);
  switch (gameState) {
  case GAME_START:
    displayGameState();
    gameState = GAME_PLAYING;

    lcd.setCursor(7, 0);
    lcd.print("  ");
    lcd.setCursor(7, 0);
    lcd.print(score);
    lcd.setCursor(7, 1);
    lcd.print("  ");
    lcd.setCursor(7, 1);
    lcd.print(ball.getSpeed());

    break;

  case GAME_PLAYING:
    potValue = analogRead(DTB_POT_PIN);
    potRotValue = analogRead(DATA_ROT_POT_PIN);
    ball.setSpeed(map(potRotValue, 0, 1023, 1, 6));
    paddlePosition = map(potValue, 0, 1023, 0, 128 - paddleLength);

    lcd.setCursor(7, 0);
    lcd.print("  ");
    lcd.setCursor(7, 0);
    lcd.print(score);
    lcd.setCursor(7, 1);
    lcd.print("  ");
    lcd.setCursor(7, 1);
    lcd.print(ball.getSpeed());

    u8g2.firstPage();
    do {
    u8g2.drawBox(paddlePosition, SCREEN_HEIGHT - paddleWidth, paddleLength, SCREEN_HEIGHT);
    ball.draw();
    drawBlocks();
    } while (u8g2.nextPage());
    break;
  
  case GAME_OVER:
    displayGameState();
    resetValues();
    gameState = GAME_START;
    break;
  }
  delay(1);
}

void updateHistory(uint8_t history[], uint8_t newValue) {
    history[2] = history[1];
    history[1] = history[0];
    history[0] = newValue;
}

void paddleDirection(uint8_t arr[]) {
  if (arr[0] < arr[1]) {
    paddleState = LEFT;
  } else if (arr[0] > arr[1]) {
    paddleState = RIGHT;
  } else {
    paddleState = STILL;
  }
}

void resetValues() {
  numPrevPaddleStates = sizeof(paddlePreviousDirections) / sizeof(paddlePreviousDirections[0]);
  for (uint8_t i = 0; i < numPrevPaddleStates; i++) {
    paddlePreviousDirections[i] = 0;
  }
  for (uint8_t r = 0; r < numOfRows; r++) {
    for (uint8_t bl = 0; bl < numBlocksRow; bl++) {
      blockMap[r][bl] = 0;
    }
  }
  ball.resetValues();
  paddleState = STILL;
  firstCollision = true;
  score = 0;
}

void drawBlocks() {
  for (uint8_t r = 0; r < numOfRows; r++) {
    for (uint8_t bl = 0; bl < numBlocksRow; bl++) {
        drawBlock(r, bl);
    }
  }
}

void drawBlock(uint8_t row, uint8_t blockIndex) {
  uint8_t blockX = offsetLR + blockIndex * (w + offsetBlocks);
  uint8_t blockY = offsetLR + row * (offsetBlocks + h);
  if (blockMap[row][blockIndex] == ACTIVE) {
    blockMap[row][blockIndex] = checkCollision(blockX, blockY);
    if (blockMap[row][blockIndex] == ACTIVE) {
      u8g2.drawBox(blockX, blockY, w, h);
    } else if (blockMap[row][blockIndex] == HIT) {
      score += 1;
    }
  }
}

bool checkCollision(uint8_t blockX, uint8_t blockY) {
  // hit block from left side
  if (ball.getRightEdge() > blockX &&
   ball.getTopEdge() < (blockY + h) &&
   ball.getBottomEdge() > blockY &&
   ball.getLeftEdge() < (blockX + w) 
    ) {
      // Serial.println("Came to block from the left");
      // ball.setX(blockX - ball.getOffset());
      ball.setY(blockY + h/2);
      ball.invertDirectionX();
      if (ball.getMovementDirectionY() == Ball::Y_UP) {
        ball.invertDirectionY();
      }
      return true;
  // hit block from the bottom
  } else if (ball.getRightEdge() > blockX &&
   ball.getLeftEdge() < (blockX + w) &&
   ball.getTopEdge() < (blockY + h) &&
   // WARNING originaly was ball.getTopEdge()
   ball.getBottomEdge() > (blockY) 
   ) {
      // ball.invertDirectionY();
      // ball.setY(blockY + h + ball.getOffset());
      ball.setX(blockX + w/2);
      // TODO rewrite firstCollision condition 
      // Serial.println("Came to block from the bottom");
      // if(firstCollision == true) {
      // int rnd = rand();
      // Ball::MoveDirection xRandDirection = (rnd % 11) > 5 ? Ball::X_LEFT : Ball::X_RIGHT;
      // randomly choose ball X direction
      // ball.setMove(xRandDirection);
      if (ball.getMovementDirectionY() == Ball::Y_UP) {
        ball.invertDirectionY();
      }
      firstCollision = false;
        // Serial.print("First collision happened: ");
      // }
      return true;
  // hit block from the right
  } else if (ball.getLeftEdge() < (blockX + w) &&
   ball.getTopEdge() < (blockY + h) &&
   ball.getBottomEdge() > (blockY) && 
   ball.getLeftEdge() > (blockX)
   ) {
    // Serial.println("Came to block from the right");
    // ball.setX(blockX + w + ball.getOffset());
    ball.setY(blockY + h/2);
    ball.invertDirectionX();
    if (ball.getMovementDirectionY() == Ball::Y_UP) {
      ball.invertDirectionY();
    }
    return true;
  // hit block from the top
  } else if (ball.getRightEdge() > (blockX) &&
   ball.getLeftEdge() < (blockX + w) &&
   ball.getBottomEdge() > blockY &&
   // WARNING origilany was getBottomEdge()
   ball.getTopEdge() < (blockY + h)
  ) {
    // Serial.println("Came to block from the top");
    // ball.setY(blockY - ball.getOffset());
    ball.setX(blockY + w/2);
    if (ball.getMovementDirectionY() == Ball::Y_DOWN) {
      ball.invertDirectionY();
    }
    return true;
  }
  return false;
}

uint8_t countAllCharacters(const String& str) {
  return str.length();
}

void displayPageState(const String& str, uint16_t pageDelay) {
  const uint8_t characterWidth = 10; 
  uint8_t textLeftOffset = 0;
  u8g2.firstPage(); 
  do {
  u8g2.setFont(u8g_font_courB12);
  u8g2.setColorIndex(0); 
  u8g2.drawBox(20, 12, 88, 40); 
  u8g2.setColorIndex(1); 
  // set the right Left Offset for text
  if (countAllCharacters(str) != 0) {
    textLeftOffset = (uint8_t)((SCREEN_WIDTH - (countAllCharacters(str) * characterWidth)) / 2);
  } else {
    textLeftOffset = (uint8_t)((SCREEN_WIDTH - (characterWidth)) / 2);
  }
  u8g2.setCursor(textLeftOffset, 30); 
  u8g2.print(str);
  } while ( u8g2.nextPage() ); 
  delay(pageDelay);
}

void displayGameState() {
  String str1;
  String str2;
  String str3;
  String emptyString;
  if (gameState == GAME_START) {
    str1 = "Let's start";
    str2 = "Ready?";
    str3 = "Go!";
    emptyString = "";
  } else {
    str1 = "Game Over";
    str2 = "";
    str3 = "";
    emptyString = "";
  }
  for(uint8_t i=0;i<2;i++) { 
    displayPageState(str1, (uint16_t)250);
    displayPageState(emptyString, (uint16_t)250);
  }
    displayPageState(str2, (uint16_t)800);
  if (gameState == GAME_START) {
    displayPageState(str3, (uint16_t)500);
  }
}