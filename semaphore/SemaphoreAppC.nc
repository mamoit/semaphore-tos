/**
 * @author
 **/

configuration SemaphoreAppC
{
}
implementation
{
	components MainC, SemaphoreC, LedsC;
	components new TimerMilliC() as Timer0;

	SemaphoreC -> MainC.Boot;
	SemaphoreC.Timer0 -> Timer0;
	SemaphoreC.Leds -> LedsC;
	
	components CollectionC;
	SemaphoreC.CollectionControl -> CollectionC;
	SemaphoreC.RootControl -> CollectionC;
	SemaphoreC.CarsReceive -> CollectionC.Receive[54];
}

