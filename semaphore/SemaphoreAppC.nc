/**
 * @author
 **/

#define NEW_PRINTF_SEMANTICS
#include "printf.h"

#include "../sem.h"

configuration SemaphoreAppC
{
}
implementation
{
	components MainC, SemaphoreC, LedsC, ActiveMessageC, SerialActiveMessageC;
	components new TimerMilliC() as Timer0;
	components PrintfC;
	components SerialStartC;

	SemaphoreC -> MainC.Boot;
	SemaphoreC.Timer0 -> Timer0;
	SemaphoreC.Leds -> LedsC;

	components CollectionC;
	SemaphoreC.CollectionControl -> CollectionC;
	SemaphoreC.RootControl -> CollectionC;
	SemaphoreC.SerialControl -> SerialActiveMessageC;
	SemaphoreC.CarsReceive -> CollectionC.Receive[COL_CARS];


	components CC2420ActiveMessageC as Radio;
	SemaphoreC.LowPowerListening -> Radio;
	SemaphoreC.RadioControl -> ActiveMessageC;
}

