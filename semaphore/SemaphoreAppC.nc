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
	components MainC, SemaphoreC, LedsC;
	components new AMSenderC(AM_RADIO_COUNT_MSG);
	components new AMReceiverC(AM_RADIO_COUNT_MSG);
	components ActiveMessageC;
	
	components new TimerMilliC() as Timer0;

	SemaphoreC -> MainC.Boot;
	SemaphoreC.Timer0 -> Timer0;
	SemaphoreC.Leds -> LedsC;

	SemaphoreC.Receive -> AMReceiverC;
	SemaphoreC.AMSend -> AMSenderC;
	SemaphoreC.AMControl -> ActiveMessageC;
	SemaphoreC.Packet -> AMSenderC;

	components SounderC;
	SemaphoreC.Mts300Sounder -> SounderC;
}

