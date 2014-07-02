/**
 * @author 
 **/

#include "../sem.h"
#include "Timer.h"

module CarC @safe()
{
  uses {
		interface Timer<TMilli> as Timer0;
		interface Boot;
		interface Leds;
		
		interface AMSend;
		interface SplitControl as AMControl;
		interface Packet;
		interface Receive;
  }
}
implementation
{
	message_t packet;
	bool locked;

	/* Report theft, based on current settings */
	void report() {
		if (locked) {
			return;
		}
		else {
			car_t* rcm = (car_t*)call Packet.getPayload(&packet, sizeof(car_t));
			if (rcm == NULL) {
				return;
			}
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(car_t)) == SUCCESS) {
				locked = TRUE;
			}
		}
	}

	/* We have nothing to do after messages are sent */
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if (&packet == bufPtr) {
			locked = FALSE;
		}
	}
	
	event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
		if (len != sizeof(car_t)) {return bufPtr;}
		return bufPtr;
	}
	
	/* At boot time, start the periodic timer and the radio */
	event void Boot.booted() {
		call AMControl.start();
	}

	/* Radio started. Now start the collection protocol and set the
		wakeup interval for low-power-listening wakeup to half a second. */
	event void AMControl.startDone(error_t ok) {
		if (ok == SUCCESS) {
			call Leds.led0On();
			call Timer0.startPeriodic(1000);
		}
	}

	event void AMControl.stopDone(error_t ok) { }
	
	event void Timer0.fired(){
		report();
	}

}
