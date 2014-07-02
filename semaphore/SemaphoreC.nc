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
		
		interface AMSend;
		interface SplitControl as AMControl;
		interface Packet;
		interface Receive;
		
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
	
	message_t packet;
	bool locked;
	
	event void Boot.booted() {
		// Light control
		call Timer0.startOneShot( timeRed );
		call Leds.led0On();
		call Leds.led1Off();
		call Leds.led2Off();

		// Radio Control
		call AMControl.start();
		
		call Mts300Sounder.beep(250);
	}

	event void Timer0.fired(){
		if (light == 0) {
			call Leds.led0Off();
			call Leds.led1On();
			call Timer0.startOneShot( timeYellow );
			light = 1;
		} else if (light == 1) {
			call Leds.led1Off();
			call Leds.led2On();
			call Timer0.startOneShot( timeRed );
			light = 2;
		} else if (light == 2) {
			call Leds.led2Off();
			call Leds.led1On();
			call Timer0.startOneShot( timeYellow );
			light = 3;
		} else if (light == 3) {
			call Leds.led1Off();
			call Leds.led0On();
			call Timer0.startOneShot( timeGreen );
			light = 0;
		}
	}
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if (&packet == bufPtr) {
			locked = FALSE;
		}
	}
	
	event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
		if (len != sizeof(car_t)) {return bufPtr;}
		call Mts300Sounder.beep(100);
		return bufPtr;
	}
	
	event void AMControl.startDone(error_t ok) {
		if (ok == SUCCESS) {
			// NADA
		}
	}
	
	event void AMControl.stopDone(error_t ok) {}

}
