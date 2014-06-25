/**
 * @author
 **/

#include "../sem.h"

configuration SemaphoreAppC
{
}
implementation
{
	components MainC, SemaphoreC, LedsC, ActiveMessageC;
	components new TimerMilliC() as Timer0;

	SemaphoreC -> MainC.Boot;
	SemaphoreC.Timer0 -> Timer0;
	SemaphoreC.Leds -> LedsC;

	components CollectionC;
	SemaphoreC.CollectionControl -> CollectionC;
	SemaphoreC.RootControl -> CollectionC;
	SemaphoreC.CarsReceive -> CollectionC.Receive[COL_CARS];

	components CC2420ActiveMessageC as Radio;
	SemaphoreC.LowPowerListening -> Radio;
	SemaphoreC.RadioControl -> ActiveMessageC;
	
	components SounderC;
	SemaphoreC.Mts300Sounder -> SounderC;
}

