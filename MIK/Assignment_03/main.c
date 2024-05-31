/*
    C�lem pr�kladu je rozbikat LED na portu D s vyuzit�m casovace (1s interval) a prerusen�.
    
    Nastavte:
    - PortD jako v�stupn�
    - Timer 0 (TMR0) jako 16bit casovac, s prirazenou preddelickou 1:32 a zapnete TMR0
    - Vynulujte TMR0 interrupt flag bit
    - Povolte prerusen� od TMR0 (pri jeho pretecen�)
    - Povolte pouzit� vsech prerusen� (Global Interrupt Enable)
    
*/

#include <xc.h>			    // Z�kladn� hlavickov� soubor 
#include <pic18f4620.h>		// Z�kladn� hlavickov� soubor pro PIC18F4620

#define _XTAL_FREQ 8000000	// Nezbytn� definice pro pouzit� funkc� __delay

#pragma config OSC = INTIO67, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, PBADEN = OFF, MCLRE = ON, LVP = OFF, DEBUG = OFF // nastaven� z�kladn�ch konfiguracn�ch bitu



void __interrupt() tcInt(void) // Funkce obsluhy prerusen�
{
    if (INTCONbits.TMR0IF) // Prerusen� od casovace TMR0?
    {                           
        LATD=~LATD;
        INTCONbits.TMR0IF=0;    // Nulov�n� TMR0 interrupt flag bitu
    }

    return;
}

void main(void) 
{
    OSCCONbits.IRCF = 0b111;    // 8MHz
    ADCON1bits.PCFG = 0b1111;   // All pins digital (str. 224)
    CMCONbits.CM = 0b111;       // Comparator disconnect (str. 234)
    
    
    TRISD = 0b00000000;			    // NAstaven� vstupu/v�stupu Portu D 
    LATD =  0b00000000;		        // V�stupn� hodnota Portu D
    

    T0CON = 0b10001100;         // NAstaven� Timer0 (TMR0 enable, 16bit, Internal instruction cycle clock, 1/32 prescaler)
    INTCONbits.TMR0IF = 0;      // Clear TMR0 flag bit
    INTCONbits.TMR0IE = 1;      // Set TMR0 enable bit
    INTCONbits.GIE = 1;         // Set global interrupt enable bit

    while(1)
    {
    
    }
    
    return;
}
