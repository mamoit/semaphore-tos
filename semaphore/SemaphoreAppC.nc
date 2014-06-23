/**
 * @author
 **/

configuration SemaphoreAppC
{
}
implementation
{
  components MainC, SemaphoreC, LedsC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;


  SemaphoreC -> MainC.Boot;

  SemaphoreC.Timer0 -> Timer0;
  SemaphoreC.Timer1 -> Timer1;
  SemaphoreC.Timer2 -> Timer2;
  SemaphoreC.Leds -> LedsC;
}

