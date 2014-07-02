/**
 * @author 
 **/

#include "../sem.h"
 
configuration CarAppC
{
}
implementation
{
	components CarC, MainC, LedsC;
	components new AMSenderC(AM_RADIO_COUNT_MSG);
	components new AMReceiverC(AM_RADIO_COUNT_MSG);
	components ActiveMessageC;
	
	components new TimerMilliC() as Timer0;
	
	CarC.Boot -> MainC.Boot;
	CarC.Leds -> LedsC;
	CarC.Receive -> AMReceiverC;
	CarC.AMSend -> AMSenderC;
	CarC.AMControl -> ActiveMessageC;
	CarC.Packet -> AMSenderC;
	
	CarC.Timer0 -> Timer0;
}