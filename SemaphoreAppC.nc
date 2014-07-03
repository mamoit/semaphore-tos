/**
 * @author Miguel Almeida
 * @author Gonçalo Silva
 * @date July 2014
 **/

#include "sem.h"

configuration SemaphoreAppC
{
}
implementation
{
	components SemaphoreC;
	components MainC;
	SemaphoreC -> MainC.Boot;
	
	// Timers
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	SemaphoreC.Timer0 -> Timer0;
	SemaphoreC.Timer1 -> Timer1;

	// Leds
	components LedsC;
	SemaphoreC.Leds -> LedsC;

	// Radio
	components new AMSenderC(AM_RADIO_COUNT_MSG);
	components new AMReceiverC(AM_RADIO_COUNT_MSG);
	components ActiveMessageC;

	SemaphoreC.AMReceive -> AMReceiverC;
	SemaphoreC.AMSend -> AMSenderC;
	SemaphoreC.RadioControl -> ActiveMessageC;
	SemaphoreC.Packet -> AMSenderC;

	// Beeper with the MTS300 sensorboard
	// If it gives trouble comment it and on the SemphoreC too
	components SounderC;
	SemaphoreC.Mts300Sounder -> SounderC;
	
 	components PlatformSerialC;
	SemaphoreC.PCSerial -> PlatformSerialC;
	SemaphoreC.SerialControl -> PlatformSerialC;
	
	
}
