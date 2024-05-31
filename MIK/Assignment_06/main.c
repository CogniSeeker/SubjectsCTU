/*
    �kol:
    - Doplnte nastaven� konfiguracn�ch registru ve funkci UART_Init pro nastaven� odes�l�n� a pr�jem dat
    - Vypoc�tejte hodnotu registru SPBRG pro nastaven� prenosov� rychlosti 9600 baudu
*/

#include <xc.h>
#include <pic18f4620.h>
#include "lcd_PIC18F4620.h"
#define _XTAL_FREQ 8000000

#pragma config OSC = INTIO67, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, PBADEN = OFF, MCLRE = ON, LVP = OFF, DEBUG = OFF


unsigned int UART_Init()
{
// Nastavte 8-bit transmission, Enable (Serial Port, Transmitter and Receiver), Asynchronous mode, Low speed, 8-bit Baud Rate Generator (str. 202, 203, 204)
  TXSTA =   0b00101010; 
  RCSTA =   0b10010000; 
  BAUDCON = 0b01010000; 
// Vypoc�tejte hodnotu pro 9600 baud a 8 MHz Fosc (str. 206 Example 18-1) 
  SPBRG =   12;
}

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
    OSCCONbits.IRCF = 0b111;    // 8MHz
    ADCON1bits.PCFG = 0b1111;   // All pins digital (str. 224)
    CMCONbits.CM = 0b111;       // Comparator disconnect (str. 234)

    
    TRISB = 0b11111111;
    TRISC = 0b11100111;
    TRISD = 0b00000000;
    TRISE = 0b00000000;
    
    LATB =  0b00000000;
    LATC =  0b00000000;
    LATD =  0b00000000;
    LATE =  0b00000000;
 
    LCD_Init();
    UART_Init();  
    
   
    while(1)
    {
      if(!(PORTB & 0b00000001))     // RB0 tlac�tko stisknuto?
      {
        while(!TXSTAbits.TRMT);
        TXREG = 'H';
        while(!TXSTAbits.TRMT);
        TXREG = 'e';
        while(!TXSTAbits.TRMT);
        TXREG = 'l';
        while(!TXSTAbits.TRMT);
        TXREG = 'l';
        while(!TXSTAbits.TRMT);
        TXREG = 'o';
        while(!TXSTAbits.TRMT);
        TXREG = ' ';
        __delay_ms(500);
      }
      
      if(PIR1bits.RCIF)             // Prijat� datov� byte?
      {
        PIR1bits.RCIF = 0;
         Send_Data (RCREG);
      }
    }
    
    return;
}
