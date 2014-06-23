/**
 * @author 
 **/

configuration CarAppC
{
}
implementation
{
  components MainC, CarC, LedsC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;


  CarC -> MainC.Boot;

  CarC.Timer0 -> Timer0;
  CarC.Timer1 -> Timer1;
  CarC.Timer2 -> Timer2;
  CarC.Leds -> LedsC;
}

