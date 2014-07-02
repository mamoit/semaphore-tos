#ifndef CAR_H
#define CAR_H

typedef nx_struct car_t {
	nxle_uint8_t plate;
} car_t;

enum {
	COL_CARS      = 20,
	TICK_SEC_MSEC = 1024,
	AM_RADIO_COUNT_MSG = 6
};
#endif
