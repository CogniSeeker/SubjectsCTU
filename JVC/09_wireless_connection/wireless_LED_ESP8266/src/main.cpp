#include <ESP8266WiFi.h>
#include <espnow.h>

// Rotary Encoder Inputs
#define inputCLK 5 // D1
#define inputDT 4 // D2

// RECEIVER MAC address
uint8_t broadcastAddress[] = {0xB8, 0xD6, 0x1A, 0x5B, 0xCC, 0xC8};

// Must match the receiver structure
typedef struct struct_message {
    char a[32];
    int currentStateCLK;
    int previousStateCLK;
    int currentStateDT;
    int counter;
} struct_message;

struct_message myData;

// Callback when data is sent
void OnDataSent(uint8_t *mac_addr, uint8_t sendStatus) {
  Serial.print("\r\nLast Packet Send Status:\t");
  Serial.println(sendStatus == 0 ? "Delivery Success" : "Delivery Fail");
}

void setup() {
  // Init Serial Monitor
  Serial.begin(115200);

  // Set device as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // Init ESP-NOW
  if (esp_now_init() != 0) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  // Register for Send Callback to get the status of Transmitted packet
  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(OnDataSent);

  // Register peer
  esp_now_add_peer(broadcastAddress, ESP_NOW_ROLE_SLAVE, 1, NULL, 0);

  pinMode(inputCLK, INPUT);
  pinMode(inputDT, INPUT);

  myData.previousStateCLK = digitalRead(inputCLK);
  myData.counter = 0;
}

void loop() {
  strcpy(myData.a, "THIS IS A CHAR");

  myData.currentStateCLK = digitalRead(inputCLK);

  if (myData.currentStateCLK != myData.previousStateCLK){ 

    // Encoder is rotating counterclockwise
    if (digitalRead(inputDT) != myData.currentStateCLK) { 
      myData.counter -= 2;
      if (myData.counter <= 0){
      myData.counter = 0;
      }
    
    } else {
      // Encoder is rotating clockwise
      myData.counter += 2;
      if (myData.counter >= 180){
      myData.counter = 180;
      }
      
    }

    // Serial.print("Current State CLK: ");
    // Serial.println(myData.currentStateCLK);
    // Serial.print("Current State prevoious CLK: ");
    // Serial.println(myData.previousStateCLK);
    // Serial.print("Current State DT: ");
    // Serial.println(myData.currentStateDT);
    Serial.print("Counter: ");
    Serial.println(myData.counter);

    // Send message via ESP-NOW
    uint8_t result = esp_now_send(broadcastAddress, (uint8_t *)&myData, sizeof(myData));
    
    if (result == 0) {
      Serial.println("Sent with success");
    }
    else {
      Serial.println("Error sending the data");
    }

  } 
  myData.previousStateCLK = myData.currentStateCLK; 
  delay(1);
}
