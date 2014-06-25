/**
 * @author 
 **/

#include "../sem.h"
#include "Timer.h"

module SemaphoreC @safe()
{
	uses {
		interface Timer<TMilli> as Timer0;
		interface Leds;
		interface Boot;
		
		interface SplitControl as SerialControl;
		interface SplitControl as RadioControl;
		interface LowPowerListening;
		
		interface StdControl as CollectionControl;
		interface RootControl;
		interface Receive as CarsReceive;
	}
}

implementation
{
	uint8_t  light      = 0;        // current light on state machine
	uint16_t timeGreen  = 5 * TICK_SEC_MSEC; // timeout to green
	uint16_t timeYellow = 1 * TICK_SEC_MSEC; // timeout to yellow
	uint16_t timeRed    = 5 * TICK_SEC_MSEC; // timeout to red

	uint16_t ncars      = 0;        // number of cars in queue

	event void Boot.booted() {
		call Timer0.startOneShot( timeGreen );
		call Leds.led0On();
		call Leds.led1Off();
		call Leds.led2Off();
	}

	event void Timer0.fired(){
		if (light == 0) {
			call Leds.led0Off();
			call Leds.led1On();
			call Timer0.startOneShot( timeYellow );
			light = 1;
			dbg("SemaphoreC", "RED -> YELLOW");
		} else if (light == 1) {
			call Leds.led1Off();
			call Leds.led2On();
			call Timer0.startOneShot( timeRed );
			light = 2;
			dbg("SemaphoreC", "YELLOW -> GREEN");
		} else if (light == 2) {
			call Leds.led2Off();
			call Leds.led1On();
			call Timer0.startOneShot( timeYellow );
			light = 3;
			dbg("SemaphoreC", "GREEN -> YELLOW");
		} else if (light == 3) {
			call Leds.led1Off();
			call Leds.led0On();
			call Timer0.startOneShot( timeGreen );
			light = 0;
			dbg("SemaphoreC", "YELLOW -> RED");
		}
	}

	// Serial Control
	event void SerialControl.startDone(error_t error) { }
	event void SerialControl.stopDone(error_t error) { }

	// Radio Control
	event void RadioControl.startDone(error_t error) {
	/* Once the radio has started, we can setup low-power listening, and
		start the collection and dissemination services. Additionally, we
		set ourselves as the (sole) root for the theft alert dissemination
		tree */
		if (error == SUCCESS) {
			call LowPowerListening.setLocalWakeupInterval(512);
			call CollectionControl.start();
			call RootControl.setRoot();
		}
	}
	event void RadioControl.stopDone(error_t error) { }

	// Recieve from collection
	event message_t *CarsReceive.receive(message_t* msg, void* payload, uint8_t len)
	{
		car_t *newCar = payload;

		if (len == sizeof(*newCar)) {
			ncars ++;
		}
		return msg;
	}
}

