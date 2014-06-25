/**
 * @author 
 **/

#include "../sem.h"
 
configuration CarAppC
{
}
implementation
{
	components CarC, ActiveMessageC, MainC;

	CarC.Boot -> MainC.Boot;
	
	CarC.RadioControl -> ActiveMessageC;
	
	components CC2420ActiveMessageC as Radio;
	CarC.LowPowerListening -> Radio;

	components CollectionC, new CollectionSenderC(COL_CARS) as CarSender;

	CarC.SemRoot -> CarSender;
	CarC.CollectionControl -> CollectionC;
}