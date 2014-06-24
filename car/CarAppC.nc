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
	components ActiveMessageC as Radio; // FIXME

	CarC.Boot -> MainC.Boot;
	CarC.RadioControl -> ActiveMessageC;
//	CarC.LowPowerListening -> Radio;

	/* Instantiate and wire our collection service for theft alerts */
	components CollectionC, new CollectionSenderC(COL_CARS) as CarSender;

	CarC.SemRoot -> CarSender;
	CarC.CollectionControl -> CollectionC;

	/* Instantiate and wire our local radio-broadcast theft alert and 
	reception services */
	//   components new AMSenderC(AM_THEFT) as SendTheft, 
	//     new AMReceiverC(AM_THEFT) as ReceiveTheft;

	//   CarC.TheftSend -> SendTheft;
	//   CarC.TheftReceive -> ReceiveTheft;
}