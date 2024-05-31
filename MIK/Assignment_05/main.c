/*
    Task:
    - use the functions from the i2c library to write a byte to the EEPROM connected via the I2C bus
    - use the functions from the i2c library to read a byte from the EEPROM connected via the I2C bus
    - it is necessary to wait 10 miliseconds between writing and reading from the same address in EEPROM    
*/

#include <xc.h>
#include <pic18f4620.h>
#include "lcd_PIC18F4620.h"
#include "i2c.h"
#define _XTAL_FREQ 8000000

#define EEPROM_ADDR_WRITE 0b10100000 // Example EEPROM address for write operations (in 8-bit format)
#define EEPROM_ADDR_READ  0b10100001  // Example EEPROM address for read operations (in 8-bit format)
#define EEPROM_MEM_ADDR   0x00  // Example EEPROM memory location



#pragma config OSC = INTIO67, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, PBADEN = OFF, MCLRE = ON, LVP = OFF, DEBUG = OFF


unsigned int LCD_Init()
{
    Send_Command (0b00110000);
    Send_Command (0b00110000);
    Send_Command (0b00110000);
    Send_Command (0b00111000);
    Send_Command (0b00001000);
    Send_Command (0b00000001);
    Send_Command (0b00000110);
    Send_Command (0b00001100);
}

void main(void) 
{
    char x;
    unsigned char ack_bit;
    OSCCONbits.IRCF = 0b111;    // 8MHz
    ADCON1bits.PCFG = 0b1111;   // All pins digital (page 224)
    CMCONbits.CM = 0b111;       // Comparator disconnect (page 234)

    
    TRISC = 0b11100111;
    TRISD = 0b00000000;
    TRISE = 0b00000000;
    
    LATC =  0b00000000;
    LATD =  0b00000000;
    LATE =  0b00000000;
 
    LCD_Init();
    i2c_init();  
           
    // Write data byte to EEPROM
    
    x = 'A';
    i2c_start();
    ack_bit=i2c_wb(EEPROM_ADDR_WRITE, ack_bit);
    ack_bit = i2c_wb(EEPROM_MEM_ADDR, ack_bit);
    if (ack_bit == 0) {
        ack_bit = i2c_wb(x, ack_bit); // Write the data byte
    }
    i2c_stop();
    
    __delay_ms(10);
    //Read data byte from EEPROM
    i2c_start();
    ack_bit = i2c_wb(EEPROM_ADDR_READ, ack_bit); // Send EEPROM address with Read command
    ack_bit = i2c_wb(EEPROM_MEM_ADDR, ack_bit); // Send memory address within EEPROM
    x = i2c_rb(0); // Read the data byte, send NACK for single byte read
    i2c_stop();
    
    
    
    

    //View data on LCD
    Send_Command (0b00000001);      // Clear LCD
    Send_Data (x);                  // Writes the character stored in the variable x

    while(1)
    {
      
    }
    
    return;
}
