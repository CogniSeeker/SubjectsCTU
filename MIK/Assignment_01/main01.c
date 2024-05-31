/*
Priklad pro nastaveni PORTU B a D, kam jsou pripojeny LED na desce PICGenios.
Ukolem je provest nastaveni registru TRISx pro vyber vstupu/vystupu a nastaveni vystupnich hodnot prostrednictvim registru LATx.
Otestujte funkci blikani LED na portu D.
*/

#include <xc.h>			    // zakladni konfiguracni soubor 
#include <pic18f4620.h>		// zakladni konfiguracni soubor 
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define _XTAL_FREQ 8000000	//nutna definice frekvance pro pouziti funkci __delay

#pragma config OSC = INTIO67, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, PBADEN = OFF, MCLRE = ON, LVP = OFF, DEBUG = OFF //nastaveni konfiguracnich bitu

void main(void) 	    	// funkce Main
{
    OSCCONbits.IRCF = 0b111;    // nastaveni frekvence na 8MHz
    ADCON1bits.PCFG = 0b1111;   // nastaveni vsech vstupu jako digitalnich (str. 224)
    CMCONbits.CM = 0b111;       // odpojeni komparatoru (str. 234)
    
    TRISB = 0b11111111;			    // nastaveni vstupu/vystupu na portu B
    TRISD = 0b00000000;			    // nastaveni vstupu/vystupu na portu D
    
    LATB = 0b00000000;		// vystupni hodnota portu B
    LATD = 0b00000000;		// vystupni hodnota portu D
    
    while(1)			    // nekonecny cyklus
    {
	    __delay_ms(200);		// cekani
        LATD = 0b01010101;		// napr. vsechny liche LED
        __delay_ms(200);		// cekani
        LATD = 0b10101010;     // napr. vsechny sude LED
    }
    
    return;
}