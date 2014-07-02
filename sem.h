#ifndef CAR_H
#define CAR_H

typedef nx_struct sem_sync_t {
	nxle_uint16_t state;
	nxle_uint8_t check;
} sem_sync_t;

enum {
	COL_CARS      = 11,
	TICK_SEC_MSEC = 1024,
	AM_RADIO_COUNT_MSG = 6,
	
	S_RR2Y = 0,
	S_RY2G = 1,
	S_RG2Y = 2,
	S_RY2R = 3,
	S_R2YR = 4,
	S_Y2GR = 5,
	S_G2YR = 6,
	S_Y2RR = 7,
	
	SYNCTIMEOUT = 10*TICK_SEC_MSEC,
	CHECK = 35,
};
#endif
