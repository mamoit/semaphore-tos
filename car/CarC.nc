/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/

#include "../sem.h"
#include "Timer.h"

module CarC
{
  uses {
		interface Boot;
//		interface Mts300Sounder;
		interface Send as SemRoot;
		interface StdControl as CollectionControl;
		interface SplitControl as RadioControl;
//		interface LowPowerListening;
  }
}
implementation
{
	message_t carMsg;

	/* Report theft, based on current settings */
	void theft() {
		/* Get the payload part of alertMsg and fill in our data */
		car_t *newCar = call SemRoot.getPayload(&carMsg, sizeof(car_t));
		if (newCar != NULL) {
			newCar->plate = TOS_NODE_ID;
			/* and send it... */
			call SemRoot.send(&carMsg, sizeof *newCar);
		}
	}

	/* We have nothing to do after messages are sent */
	event void SemRoot.sendDone(message_t *msg, error_t ok) { }

	/* At boot time, start the periodic timer and the radio */
	event void Boot.booted() {
		call RadioControl.start();
	}

	/* Radio started. Now start the collection protocol and set the
		wakeup interval for low-power-listening wakeup to half a second. */
	event void RadioControl.startDone(error_t ok) {
		if (ok == SUCCESS) {
			call CollectionControl.start();
	//		call LowPowerListening.setLocalWakeupInterval(512);
		}
	}

	event void RadioControl.stopDone(error_t ok) { }

}
