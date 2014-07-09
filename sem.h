/**
 * @author Miguel Almeida
 * @author Gonçalo Silva
 * @date July 2014
 **/

#ifndef SEM_H
#define SEM_H

// State sync package
typedef nx_struct sem_sync_t {
	// self state
	nxle_uint16_t state;

	// check number
	nxle_uint8_t check;
} sem_sync_t;

// Time sync package
typedef nx_struct time_sync_t {
	// self times
	nxle_uint16_t yellow;
	nxle_uint16_t green;

	// check number
	nxle_uint8_t check;
} time_sync_t;

enum {
	// Timer multiplier to get seconds
	TICK_SEC_MSEC = 1024,
	
	// Default times
	T_GREEN  = 3,
	T_YELLOW = 1,
	T_RED    = 1,

	// ActiveMessage config
	AM_RADIO_COUNT_MSG = 6,

	// State machine states
	S_RR2Y = 0,
	S_RY2G = 1,
	S_RG2Y = 2,
	S_RY2R = 3,
	S_R2YR = 4,
	S_Y2GR = 5,
	S_G2YR = 6,
	S_Y2RR = 7,
	
	// Min time in seconds between accepting sync package.
	SYNCTIMEOUT = 10*TICK_SEC_MSEC,

	// Check to include in package to avoid interference
	// it is 35 just because... Anything goes.
	CHECK = 35,
	
	// ASCII definitions
	ASCII0 = 48,  // Character 0
	
	ASCIIBS = 8,  // Backspace
	ASCIILF = 10, // Next line
	ASCIIFF = 12, // Clear the screen
	ASCIICR = 13, // Clear line
	ASCIIDEL = 127, // Delete

	// Maximum size of serial command
	MAXSTR = 32,

	// Maximum size of string to be printed through serial
	MAXSER = 100,
};
#endif
