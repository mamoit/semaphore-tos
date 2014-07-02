/**
 * @author
 **/

#include "sem.h"

configuration SemaphoreAppC
{
}
implementation
{
	components MainC, SemaphoreC, LedsC;
	components new AMSenderC(AM_RADIO_COUNT_MSG);
	components new AMReceiverC(AM_RADIO_COUNT_MSG);
	components ActiveMessageC;
	
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;

	SemaphoreC -> MainC.Boot;
	SemaphoreC.Timer0 -> Timer0;
	SemaphoreC.Timer1 -> Timer1;
	SemaphoreC.Leds -> LedsC;

	SemaphoreC.AMReceive -> AMReceiverC;
	SemaphoreC.AMSend -> AMSenderC;
	SemaphoreC.RadioControl -> ActiveMessageC;
	SemaphoreC.Packet -> AMSenderC;

	components SounderC;
	SemaphoreC.Mts300Sounder -> SounderC;
}

