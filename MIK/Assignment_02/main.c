/*
    Cilem projektu je zobrazit text na alfanumerickem LCD.
    Postup:
    - provedte inicializace radice LCD podle str.45 v manualu lcd_hitachi44780.pdf
    - provedte nastaveni parametru radice LCD podle str.43 v manualu lcd_hitachi44780.pdf
*/

#include <xc.h>
#include <pic18f4620.h>
#include "lcd_PIC18F4620.h"

#define _XTAL_FREQ 8000000
#define CUSTOM_CHAR_ADDR 0x40

#pragma config OSC = INTIO67, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, PBADEN = OFF, MCLRE = ON, LVP = OFF, DEBUG = OFF, 

void createCustomChar(unsigned char location, unsigned char charmap[]);

void main(void) 
{
    OSCCONbits.IRCF = 0b111;    // 8MHz
    ADCON1bits.PCFG = 0b1111;   // Vsechny vstupy digitalni (str. 224)
    CMCONbits.CM = 0b111;       // Odpojeni komparatoru (str. 234)
    
    
    TRISA = 0;
    TRISB = 0;
    TRISC = 0;
    TRISD = 0;
    TRISE = 0;
    LATA = 0b00000000;
    LATB = 0b00000000;
    LATC = 0b00000000;
    LATD = 0b00000000;
    LATE = 0b00000000;

    unsigned char i = 0;
    unsigned char shift_time = 17;
    unsigned char eye[8] = {
	0b00000,
	0b00100,
	0b01110,
	0b11011,
	0b11011,
	0b01010,
	0b00100,
	0b00000
    };
    unsigned char mouth[8] = {
	0b00000,
	0b00000,
	0b00000,
	0b11111,
	0b00000,
	0b00000,
	0b00000,
	0b00000
    };
 // Inicializace radice LCD - str. 45 v lcd_hitachi44780.pdf
    Send_Command (0b00110000);
    Send_Command (0b00110000);
    Send_Command (0b00110000);
    Send_Command (0b00111000);
    Send_Command (0b00001000);
    Send_Command (0b00000001);
    Send_Command (0b00000110);
 // Nastaven� parametru a zobrazen� znaku - str. 43 v lcd_hitachi44780.pdf
    Send_Command (0b00111000);          //krok 2
    Send_Command (0b00001111);          //krok 3
    Send_Command (0b00000110);          //krok 4

    __delay_ms(300);

    Send_Data ('H');
    __delay_ms(30);
    Send_Data ('e');
    __delay_ms(30);
    Send_Data ('l');
    __delay_ms(30);
    Send_Data ('l');
    __delay_ms(30);
    Send_Data ('o');

    Send_Data (' ');
    __delay_ms(30);

    Send_Data ('C');
    __delay_ms(30);
    Send_Data ('V');
    __delay_ms(30);
    Send_Data ('U');
    __delay_ms(30);
    Send_Data ('T');
    __delay_ms(30);
    Send_Data ('!');

    __delay_ms(1000);

    while(i < shift_time)
    {
        Send_Command(0b00011100); // Display shift to the right
        __delay_ms(50);
        i++;
    }
    Send_Command(0b00000001); // Clear Display
    Send_Command(0b00000010); // Return cursor home
    
    __delay_ms(500);

    Send_Data ('L');
    Send_Data ('e');
    Send_Data ('t');
    Send_Data ('s');

    Send_Data (' ');

    Send_Data ('w');
    Send_Data ('r');
    Send_Data ('i');
    Send_Data ('t');
    Send_Data ('e');

    Send_Data (' ');

    Send_Data ('o');
    Send_Data ('n');

    Send_Data (' ');

    __delay_ms(300);
    Send_Command(0b11000000); // place cursor at the head of the second line

    Send_Data ('t');
    Send_Data ('h');
    Send_Data ('e');

    Send_Data (' ');

    Send_Data ('s');
    Send_Data ('e');
    Send_Data ('c');
    Send_Data ('o');
    Send_Data ('n');
    Send_Data ('d');

    Send_Data (' ');

    Send_Data ('l');
    Send_Data ('i');
    Send_Data ('n');
    Send_Data ('e');
    
    __delay_ms(1000);
    Send_Command(0b00000010); // Return cursor home
    i = 0;
    while(i < shift_time)
    {
        Send_Command(0b00011000); // Display shift to the left
        __delay_ms(100);
        i++;
    }
    
    Send_Command(0b00000001); // Clear Display
    Send_Command(0b00000010); // Return cursor home
    __delay_ms(200);

    createCustomChar(0, eye);
    createCustomChar(1, mouth);

    Send_Command(0x80);
    Send_Data(0);
    __delay_ms(100);
    Send_Data(0);
    __delay_ms(500);

    Send_Command(0xC0); // move to the second line
    Send_Data(1);
    Send_Data(1);
    __delay_ms(500);

    Send_Command(0b00010100);
    Send_Data ('P');
    __delay_ms(30);
    Send_Data ('E');
    __delay_ms(30);
    Send_Data ('P');
    __delay_ms(30);
    Send_Data ('E');

    __delay_ms(2000);

    return;
}
void createCustomChar(unsigned char location, unsigned char charmap[]) {
    // Set CGRAM address
    Send_Command(CUSTOM_CHAR_ADDR + (location * 8));
    for (int i = 0; i < 8; i++) {
        Send_Data(charmap[i]);  // Write character pattern to CGRAM
    }
}