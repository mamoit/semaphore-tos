/**
 * @author Miguel Almeida
 * @author Gonçalo Silva
 * @date July 2014
 **/

#include "sem.h"
#include "Timer.h"

module SemaphoreC @safe()
{
	uses {
		// Boot
		interface Boot;
		
		// Timmers
		interface Timer<TMilli> as Timer0;
		interface Timer<TMilli> as Timer1;
		
		// LEDs
		interface Leds;
		
		// Sounder
		interface Mts300Sounder;
		
		// Active Messages
		interface AMSend;
		interface SplitControl as RadioControl;
		interface Packet;
		interface Receive as AMReceive;
		
		// Serial
		interface StdControl as SerialControl;
		interface UartStream as PCSerial;
	}
}

implementation
{
	uint8_t  state;                                  // current light on state machine
	uint16_t timeGreen  = T_GREEN  * TICK_SEC_MSEC;  // time in green
	uint16_t timeYellow = T_YELLOW * TICK_SEC_MSEC;  // time in yellow
	uint16_t timeRed    = T_RED    * TICK_SEC_MSEC;  // common time in red
	
	uint16_t peerTimeGreen;  // Other node's time in green
	uint16_t peerTimeYellow; // Other node's time in yellow
	
	// Serial command buffer
	char cmdBuffer[MAXSTR] = "";
	uint8_t cmdBufferPos = 0;
	
	message_t packet;
	bool locked;
	
	bool accept_sync = TRUE;
	
	// Boot event
	event void Boot.booted() {
		// Default peer times assumed
		peerTimeGreen = timeGreen;
		peerTimeYellow = timeYellow;
		
		// Light control
		state = S_RR2Y;
		signal Timer0.fired();
		
		// Serial Control
		call SerialControl.start();
		
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
	
	// Sends the current times to the other node
	void sendTimes() {
		if (locked) {
			return;
		}
		else {
			time_sync_t* rcm = (time_sync_t*)call Packet.getPayload(&packet, sizeof(time_sync_t));
			if (rcm == NULL) {
				return;
			}
			rcm->yellow = timeYellow;
			rcm->green = timeGreen;
			rcm->check = CHECK;
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(time_sync_t)) == SUCCESS) {
				locked = TRUE;
			}
		}
	}
	
	// Sends a byte to the terminal.
	//beep shortly (5ms) if error occured.
	void serialSendByte(uint8_t num){
		if (call PCSerial.send(&num,1)!= SUCCESS)
			call Mts300Sounder.beep(5);
	}
	
	// Prints a number to the serial terminal
	void serialSendNum(uint16_t num){
		uint8_t temp;
		
		char buf[MAXSTR];
		uint8_t i = 0, j;
		
		do {
			temp = num % 10;
			num -= temp;
			num /= 10;
			buf[i] = temp + ASCII0;
			i++;
		} while (num != 0);
		
		for (j=0; j<i; j++) {
			serialSendByte(buf[i-1-j]);
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
	
	// Change the times of green and yellow
	//used when received a time update package
	void setTimes(uint16_t green, uint16_t yellow) {
		peerTimeGreen = green;
		peerTimeYellow = yellow;
	}
	
	// Print a string
	void serialPrint(char *str) {
		uint8_t i;
		for (i = 0; i<MAXSER; i ++) {
			if (str[i] == '\0')
				break;
			serialSendByte((uint8_t)str[i]);
		}
	}
	
	// Print a \n
	void serialSendEnter(){
		serialSendByte(ASCIILF);
		serialSendByte(ASCIICR);
	}
	
	// Print a string plus a \n
	void serialPrintln(char *str) {
		serialPrint(str);
		serialSendEnter();
	}
	
	// Sends an updated screen to the serial terminal
	task void printScreen() {
		// Clear the screen
		serialSendByte(ASCIIFF);
		
		// State machine state
		serialPrint("State: ");
		serialSendNum(state);
		serialSendEnter();
		
		// Light being displayed
		serialPrint("Light: ");
		if (state == S_G2YR) {
			serialPrintln("GREEN");
		} else if (state == S_Y2GR || state == S_Y2RR) {
			serialPrintln("YELLOW");
		} else {
			serialPrintln("RED");
		}
		
		serialPrintln("########");
		
		// Current times
 		serialPrintln("Times:");
 		serialPrint("Green:  ");
		serialSendNum(timeGreen);
 		serialSendEnter();
 		serialPrint("Yellow: ");
		serialSendNum(timeYellow);
 		serialSendEnter();
 		serialPrint("Red:    ");
		serialSendNum(peerTimeGreen + 2* peerTimeYellow);
 		serialSendEnter();
 		
 		serialSendEnter();
		
		// Prompt line
		serialPrint("> ");
		serialPrint(cmdBuffer);
	}
	
	// Beeps the sounder for 100ms.
	task void beep() {
		call Mts300Sounder.beep(100);
	}
	
	// Compares the cmdBuffer string with another given as argument
	bool strCompare(char *str, uint8_t pos) {
		uint8_t i;
		
		for (i = 0; i<MAXSTR; i ++) {
			if (str[i] == '\0') {
				return TRUE;
			} else if (str[i] != cmdBuffer[i+pos]){
				return FALSE;
			}
		}
		return FALSE;
	}
	
	// Translate cmdBuffer into an integer
	//starting in position pos of the cmdBuffer
	uint16_t strToi(uint8_t pos) {
		uint8_t i;
		uint16_t val = 0;
		
		for (i = 0; i<MAXSTR; i ++) {
			if (cmdBuffer[i+pos] == '\0' || cmdBuffer[i+pos] == ' ')
				return val;
			val *= 10;
			val += cmdBuffer[i+pos] - ASCII0;
		}
		return val;
	}
	
	// Command parser
	task void runCommand() {
		bool res;
		atomic {
			res = (cmdBufferPos > 7);
		}
		if (res) {
			atomic {
				res = strCompare("set t ", 0);
			}
			if (res){
				atomic {
					res = strCompare("g ", 6);
				}
				if (res){
					atomic {
						timeGreen = strToi(8);
					}
					sendTimes();
				} else {
					atomic {
						res = strCompare("y ", 6);
					}
					if (res) {
						atomic {
							timeYellow = strToi(8);
						}
						sendTimes();
					}
				}
			}
		}
		
		atomic {
			cmdBufferPos = 0;
			cmdBuffer[0] = '\0';
		}
		post printScreen();
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
			call Timer0.startOneShot( peerTimeYellow );
			lightRed();
			state = S_RY2G;
		} else if (state == S_RY2G) {
			call Timer0.startOneShot( peerTimeGreen );
			lightRed();
			state = S_RG2Y;
		} else if (state == S_RG2Y) {
			call Timer0.startOneShot( peerTimeYellow );
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
		post printScreen();
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
		if (len == sizeof(sem_sync_t)) {
			sem_sync_t* rcm = (sem_sync_t*)payload;
			if (rcm->check != CHECK) {
				call Mts300Sounder.beep(5);
				return bufPtr;
			} else {
				setState(rcm->state);
				return bufPtr;
			}
		} else if (len == sizeof(time_sync_t)) {
			time_sync_t* rcm = (time_sync_t*)payload;
			if (rcm->check != CHECK) {
				call Mts300Sounder.beep(5);
				return bufPtr;
			} else {
				setTimes(rcm->green, rcm->yellow);
				return bufPtr;
			}
		} else {
			call Mts300Sounder.beep(5);
			return bufPtr;
		}
	}
	
	// Beep if radio didn't turn on properly
	event void RadioControl.startDone(error_t ok) {
		if (ok != SUCCESS) {
			call Mts300Sounder.beep(1000);
		}
	}
	
	// Do nothing when radio is turned off
	event void RadioControl.stopDone(error_t ok) {}
	
	// Do nothing when finished sending something to the computer
	async event void PCSerial.sendDone( uint8_t* buf, uint16_t len, error_t error ) {}
	
	// Process a byte that was just received a byte on the serial line
	async event void PCSerial.receivedByte( uint8_t byte ){
		if(byte == ASCIIDEL) {
			if (cmdBufferPos <= 0) {
				post beep();
			} else {
				cmdBufferPos --;
				cmdBuffer[cmdBufferPos] = '\0';
			}
			post printScreen();
		} else if(byte == ASCIICR) {
			post runCommand();
		} else if(cmdBufferPos <= MAXSTR -1){
			cmdBuffer[cmdBufferPos] = byte;
			cmdBufferPos ++;
			cmdBuffer[cmdBufferPos] = '\0';
			post printScreen();
		} else {
			post beep();
		}
	}
	
	// Do nothing when finished receiving on the serial line
	async event void PCSerial.receiveDone( uint8_t* buf, uint16_t len, error_t error ){}
}
