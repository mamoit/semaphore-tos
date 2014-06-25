#ifndef CAR_H
#define CAR_H

typedef nx_struct car_t {
	nxle_uint8_t plate;
} car_t;

enum {
	COL_CARS      = 54,
	AM_THEFT      = 99,
	TICK_SEC_MSEC = 1024
};
#endif
