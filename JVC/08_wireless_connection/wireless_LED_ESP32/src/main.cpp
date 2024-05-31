#include <Arduino.h>
#include <esp_now.h>
#include <WiFi.h>
#include <ESP32Servo.h>

// Must match the sender structure
typedef struct struct_message {
    char a[32];
    int currentStateCLK;
    int previousStateCLK;
    int currentStateDT;
    int counter;
} struct_message;

// Create a struct_message called myData
struct_message myData;

Servo myservo;

// callback function that will be executed when data is received
void OnDataRecv(const uint8_t * mac, const uint8_t *incomingData, int len) {
  memcpy(&myData, incomingData, sizeof(myData));
  // Serial.print("Bytes received: ");
  // Serial.println(len);
  // Serial.print("Char: ");
  // Serial.println(myData.a);
  Serial.print("currentStateCLK: ");
  Serial.println(myData.currentStateCLK);
  Serial.print("previousStateCLK: ");
  Serial.println(myData.previousStateCLK);
  Serial.print("currentStateDT: ");
  Serial.println(myData.currentStateDT);
  Serial.print("Counter: ");
  Serial.println(myData.counter);
  Serial.println();
}
 
void setup() {
  Serial.begin(115200);

  WiFi.mode(WIFI_STA);

  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  
  // Register for recv CB to get recv packer info
  esp_now_register_recv_cb(OnDataRecv);

  myservo.attach(25);
}
 
void loop() {
  myservo.write(myData.counter);
  delay(1);
}