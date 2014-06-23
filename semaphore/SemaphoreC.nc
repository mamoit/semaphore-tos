/**
 *
 **/

#include "Timer.h"

module SemaphoreC @safe()
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
}

implementation
{
  uint8_t  light      = 0;        // current light on state machine
  uint16_t timeGreen  = 5 * 1000; // timeout para verde
  uint16_t timeYellow = 1 * 1000; // timeout para yellow
  uint16_t timeRed    = 5 * 1000; // timeout para vermelho

  event void Boot.booted()
  {
    call Timer0.startOneShot( timeGreen );
    call Leds.led0On();
    call Leds.led1Off();
    call Leds.led2Off();
  }

  event void Timer0.fired()
  {
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
}

