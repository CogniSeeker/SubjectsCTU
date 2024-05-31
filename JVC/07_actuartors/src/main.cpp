 /*
  Rotary Encoder with Servo Motor Demo
  rot-encode-servo-demo.ino
  Demonstrates operation of Rotary Encoder
  Positions Servo Motor
  Displays results on Serial Monitor
  DroneBot Workshop 2019
  https://dronebotworkshop.com
*/
 
 // Include the Servo Library
#include <Arduino.h>
#include <ESP32Servo.h>

 // Rotary Encoder Inputs
 #define inputCLK 32
 #define inputDT 35
 
 // Create a Servo object
 Servo myservo1;
 Servo myservo2;
 
 int counter = 0; 
 int currentStateCLK;
 int previousStateCLK; 

 void setup() { 
   pinMode (inputCLK, INPUT);
   pinMode (inputDT, INPUT);
   
   Serial.begin (9600);
   
   myservo1.attach(25);
   myservo2.attach(33);
   
   previousStateCLK = digitalRead(inputCLK);
 } 

 void loop() {
   currentStateCLK = digitalRead(inputCLK);

   if (currentStateCLK != previousStateCLK){ 

     // Encoder is rotating counterclockwise
     if (digitalRead(inputDT) != currentStateCLK) { 
       counter -= 2;
       if (counter <= 0){
        counter = 0;
       }
      
     } else {
       // Encoder is rotating clockwise
       counter += 2;
       if (counter >= 180){
        counter = 180;
       }
       
     }
     
     // Move the servo
     myservo1.write(counter);
     myservo2.write(counter);
      
     Serial.print("Position: ");
     Serial.println(counter);
   } 
   previousStateCLK = currentStateCLK; 
 }