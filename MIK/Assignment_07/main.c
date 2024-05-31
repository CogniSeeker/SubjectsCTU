/*

    �kol: Generov�n� PWM sign�lu s kmitoctem 10 kHz 
    
    Postup:
        - Nastavte casovac Timer2 prostrednictv�m registru T2CON 
        - Nastavte modul CCP1 prostrednictv�m registru CCP1CON 

*/

#include <xc.h>
#include <pic18f4620.h>
#include "lcd_PIC18F4620.h"

#define _XTAL_FREQ 8000000

#define LCD_RS LATEbits.LATE2
#define LCD_EN LATEbits.LATE1

#pragma config OSC = INTIO67, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, PBADEN = OFF, MCLRE = ON, LVP = OFF, DEBUG = OFF, 
unsigned char txt[7];

void PWM1_Init()  //page 144
  {
   
    //PWM Period = [(PR2) + 1] * 4 * TOSC *(TMR2 Prescale Value)
    //PWM Duty Cycle = (CCPRXL:CCPXCON<5:4>) *TOSC * (TMR2 Prescale Value)

   
    T2CON = 0b00000101;         // Timer2 konfiguracn� registr  (str. 133)
    PR2 = 49;                  // Timer2 registr periody 
    CCP1CON = 0b00001100;               // CCP1 konfiguracn� registr  (str. 139)

    T2CONbits.TMR2ON=1;         // Start Timer2
 
} 

void Int_to_String(unsigned int val, char* str) // Converts Integer type into the string
{
   str[0]=(val/10000)+0x30;  
   str[1]=((val%10000)/1000)+0x30;  
   str[2]=((val%1000)/100)+0x30;  
   str[3]=((val%100)/10)+0x30;
   str[4]=(val%10)+0x30;
   str[5]=0;
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
    TRISC = 0b11111011;
    TRISD = 0b00000000;
    TRISE = 0b00000000;
    LATA =  0b00000000;
    LATD =  0b00000000;
    LATE =  0b00000000;
 
    LCD_Init();
    PWM1_Init();
    
    CCPR1L = 50;
   
    while(1)
    {
        if (!PORTBbits.RB1)     // Zv�s� hodnotu Duty cycle o 10
        {
            if(CCPR1L <= 240) CCPR1L += 10;
            while(!PORTBbits.RB1);
        }
        if (!PORTBbits.RB0)     // Sn�z� hodnotu Duty cycle o 10
        {
             if(CCPR1L >= 10)CCPR1L -= 10;
            while(!PORTBbits.RB0);
        }
        
        __delay_ms(100);
        Send_Command (0b00000001);
        Int_to_String(CCPR1L, txt);
        Send_String(txt);
    }
    
    return;
}
