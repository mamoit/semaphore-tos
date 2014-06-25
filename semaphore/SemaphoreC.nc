/**
 * @author 
 **/

#include "../sem.h"
#include "Timer.h"
#include "printf.h"

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
		
		interface Mts300Sounder;
	}
}

implementation
{
	uint8_t  light      = 0;					// current light on state machine
	uint16_t timeGreen  = 5 * TICK_SEC_MSEC;	// timeout to green
	uint16_t timeYellow = 1 * TICK_SEC_MSEC;	// timeout to yellow
	uint16_t timeRed    = 5 * TICK_SEC_MSEC;	// timeout to red

	uint16_t ncars      = 0;					// number of cars in queue

	event void Boot.booted() {
		// Light control
		call Timer0.startOneShot( timeRed );
		call Leds.led0On();
		call Leds.led1Off();
		call Leds.led2Off();

		// Radio Control
		call RadioControl.start();
		
		call Mts300Sounder.beep(100);
		printf("Boot\n");
		printfflush();
	}

	event void Timer0.fired(){
		if (light == 0) {
			call Leds.led0Off();
			call Leds.led1On();
			call Timer0.startOneShot( timeYellow );
			light = 1;
			printf("YELLOW\n");
			printfflush();
		} else if (light == 1) {
			call Leds.led1Off();
			call Leds.led2On();
			call Timer0.startOneShot( timeRed );
			light = 2;
			printf("GREEN\n");
			printfflush();
		} else if (light == 2) {
			call Leds.led2Off();
			call Leds.led1On();
			call Timer0.startOneShot( timeYellow );
			light = 3;
			printf("YELLOW\n");
			printfflush();
		} else if (light == 3) {
			call Leds.led1Off();
			call Leds.led0On();
			call Timer0.startOneShot( timeGreen );
			light = 0;
			printf("RED\n");
			printfflush();
		}
	}

	// Serial Control
	event void SerialControl.startDone(error_t error) { }
	event void SerialControl.stopDone(error_t error) { }

	// Radio Control
	event void RadioControl.startDone(error_t error) {
	/* Once the radio has started, we can setup low-power listening, and
		start the collection service. Additionally, we set ourselves as the
		(sole) root for the theft alert dissemination tree */
		if (error == SUCCESS) {
			call LowPowerListening.setLocalWakeupInterval(512);
			call CollectionControl.start();
			call RootControl.setRoot();
			call Leds.led0On();
			call Leds.led1On();
			call Leds.led2On();
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
		call Leds.led0On();
		call Leds.led1On();
		call Leds.led2On();
		return msg;
	}
}

