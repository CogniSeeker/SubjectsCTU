/*
   Nastaveni:
    - Nastavte Port A jako vstupni
    - Nastavte Port D jako vystupni
    - Nastavte Port E jako vystupni
    - Nastavte konfiguracni registry AD prevodniku (ADCON0..2) ve funkci AD_Init
    - Prevedte vystupni hodnotu AD prevorniku na napeti (0..5V)
*/

#include <xc.h>
#include <pic18f4620.h>
#include "lcd_PIC18F4620.h"

#define _XTAL_FREQ 8000000

#define LCD_RS LATEbits.LATE2
#define LCD_EN LATEbits.LATE1

#pragma config OSC = INTIO67, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, PBADEN = OFF, MCLRE = ON, LVP = OFF, DEBUG = OFF, 

unsigned int adresult;
unsigned char txt[7];

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

unsigned int AD_Init()
{        
    ADCON0 = 0b00000001;    // Channel 0, AD enable
    ADCON1 = 0b00001110;    // Reference voltage Vdd and VSS, AN0-Analog input
    ADCON2 = 0b10001011;    // Right justify, ACQT>2.4us (str. 228), ADCS (str. 229, TAB 19-1): 0.7us<TAD<25us (str. 360, TAB 26-25)
}

unsigned int AD_Convert()
{    
   ADCON0bits.GO=1;
   while(ADCON0bits.GO == 1);

   return ((((unsigned int)ADRESH)<<8)|ADRESL);
}

void Int_to_String(unsigned int val, char* str) // Prevod Integer na String
{
   str[0]=(val/10000)+0x30;  
   str[1]=((val%10000)/1000)+0x30;  
   str[2]=((val%1000)/100)+0x30;  
   str[3]=((val%100)/10)+0x30;
   str[4]=(val%10)+0x30;
   str[5]=0;
}

void main(void) 
{
    OSCCONbits.IRCF = 0b111;    // 8MHz
    ADCON1bits.PCFG = 0b1111;   // All pins digital (str 224)
    CMCONbits.CM = 0b111;       // Comparator disconnect (str 234)

    
    TRISA = 0b11111111;
    TRISD = 0b00000000;
    TRISE = 0b00000000;
    LATA =  0b00000000;
    LATD =  0b00000000;
    LATE =  0b00000000;
 
    LCD_Init();
    AD_Init();
          
    adresult = AD_Convert();
    Int_to_String(adresult, txt);
    Send_String(txt);
  
    while(1)
    {
      __delay_ms(100);
      Send_Command (0b00000001);
      adresult = AD_Convert();
      Int_to_String(adresult, txt); // Prevede Integer na String
      Send_String(txt);             // Zobrazi text na LCD     
    }
    
    return;
}
