/**
 * @author 
 **/

#include "sem.h"
#include "Timer.h"

module SemaphoreC @safe()
{
	uses {
		interface Timer<TMilli> as Timer0;
		interface Timer<TMilli> as Timer1;
		interface Leds;
		interface Boot;
		
		interface AMSend;
		interface SplitControl as RadioControl;
		interface Packet;
		interface Receive as AMReceive;
		
		interface Mts300Sounder;
	}
}

implementation
{
	uint8_t  state;					// current light on state machine
	uint16_t timeGreen  = 5 * TICK_SEC_MSEC;	// timeout to green
	uint16_t timeYellow = 1 * TICK_SEC_MSEC;	// timeout to yellow
	uint16_t timeRed    = (2*1 + 5) * TICK_SEC_MSEC;	// timeout to red

	message_t packet;
	bool locked;
	
	bool accept_sync = TRUE;
	
	event void Boot.booted() {
		// Light control
		state = S_RR2Y;
		signal Timer0.fired();

		// Radio Control
		call RadioControl.start();
	}

	// Send the current state to the other node
	void sendState() {
		if (locked) {
			return;
		}
		else {
			sem_sync_t* rcm = (sem_sync_t*)call Packet.getPayload(&packet, sizeof(sem_sync_t));
			if (rcm == NULL) {
				return;
			}
			rcm->state = state;
			rcm->check = CHECK;
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(sem_sync_t)) == SUCCESS) {
				locked = TRUE;
			}
		}
	}
	
	// Set the state to the opposite one of the received
	void setState(uint8_t peerState) {
		if (accept_sync) {
			state = (peerState+3)%8;
			signal Timer0.fired();
			
			accept_sync = FALSE;
			call Timer1.startOneShot( SYNCTIMEOUT );
		}
	}
	
	// Turn on green light and all the others off
	void lightGreen() {
		call Leds.led0On();
		call Leds.led1Off();
		call Leds.led2Off();
	}

	// Turn on yellow light and all the others off
	void lightYellow() {
		call Leds.led0Off();
		call Leds.led1On();
		call Leds.led2Off();
	}

	// Turn on red light and all the others off
	void lightRed() {
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2On();
	}
	
	// Main state machine
	event void Timer0.fired(){
		if (state == S_RR2Y) {
			call Timer0.startOneShot( timeYellow );
			lightRed();
			state = S_RY2G;
		} else if (state == S_RY2G) {
			call Timer0.startOneShot( timeGreen );
			lightRed();
			state = S_RG2Y;
		} else if (state == S_RG2Y) {
			call Timer0.startOneShot( timeYellow );
			lightRed();
			state = S_RY2R;
		} else if (state == S_RY2R) {
			call Timer0.startOneShot( timeRed );
			lightRed();
			state = S_R2YR;
		} else if (state == S_R2YR) {
			call Timer0.startOneShot( timeYellow );
			lightYellow();
			state = S_Y2GR;
		} else if (state == S_Y2GR) {
			call Timer0.startOneShot( timeGreen );
			lightGreen();
			state = S_G2YR;
		} else if (state == S_G2YR) {
			call Timer0.startOneShot( timeYellow );
			lightYellow();
			state = S_Y2RR;
		} else if (state == S_Y2RR) {
			call Timer0.startOneShot( timeRed );
			lightRed();
			state = S_RR2Y;
		}
		sendState();
	}
	
	// Time without sync is over, so lets sniff a pkg again
	event void Timer1.fired(){
		accept_sync = TRUE;
	}
	
	// Done sending a package
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if (&packet == bufPtr) {
			locked = FALSE;
		}
	}
	
	// Receive a generic package and act accordingly
	event message_t* AMReceive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
		if (len != sizeof(sem_sync_t)) {
			call Mts300Sounder.beep(5);
			return bufPtr;
		} else {
			sem_sync_t* rcm = (sem_sync_t*)payload;
			if (rcm->check != CHECK) {
				call Mts300Sounder.beep(5);
				return bufPtr;
			} else {
				setState(rcm->state);
				return bufPtr;
			}
		}
	}
	
	// Beep if radio didn't turn on properly
	event void RadioControl.startDone(error_t ok) {
		if (ok != SUCCESS) {
			call Mts300Sounder.beep(250);
		}
	}
	
	// Do nothing when radio is turned off
	event void RadioControl.stopDone(error_t ok) {}

}
