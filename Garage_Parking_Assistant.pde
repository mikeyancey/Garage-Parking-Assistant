// =========================================================================
//
//	Modified for Arduino - Mike Yancey / 3-29-2010
//
//	Original Header:
//   Purpose... Provide Visual Aid For Parking Car In Garage
//   Author.... Chris Savage -- Savage Circuits
//   E-mail.... info@savagecircuits.com
//   Started... 02-21-2007
//   Updated... 09-07-2008
//
// =========================================================================

// -----[ Program Description ]---------------------------------------------

// This parking assitant works like a traffic light in that it lets you know
// when to pull ahead (GREEN), slow down (YELLOW) and stop (RED) in your
// garage based on constants you set for four different zones.  See the
// grpahical chart for more information.  Only one LED will be on at any
// given time.

// Zone1 represents the minimum clearance from the wall the sensor is
// attached to.  When the car is in this Zone the Red LED will blink On/Off.

// Zone2 represents the area where you want the front of your car to stop.
// When the car is in this Zone the Red LED will remain on.  The range of
// this Zone will be anywhere in between Zone1 and Zone2.  So if you have
// Zone1 set to 36 and Zone2 set to 48 then the Red LED will remain on when
// the front of the car is between 36" and 48" from the Sensor/Wall.

// Zone3 represents the area where you want to slow and prepare to stop.
// When the car is in this Zone the Yellow LED will remain on.

// Zone4 represents the area from the maximum distance you want the car to
// be detected until you want it to slow down.  When the car is in this Zone
// the Green LED will remain on.  Maximum range of Zone4 is from Zone3 to
// the Maximum detection range of the PING))) sensor.

// -----[ Revision History ]------------------------------------------------

// 09-07-2008
// This new improved version of the Garage Parking Assistant allows you to
// set your zones using a push-button, rather than having to program the
// settings all in from a laptop.  Holding the button for approximately two
// seconds will put the unit into program mode where you can move you car
// into each zone and press the button to set that distance in the EEPROM.

// -----[ Library Includes ]-------------------------------------------------

#include <EEPROM.h>


// -----[ I/O Definitions ]-------------------------------------------------


// Sensor Pin for the PING))) Sensor
#define    PingPIN    8                // In/Out Pin for the PING)))
#define    GreenLED   9                // Green (GO) LED
#define    YellowLED 10                // Yellow (SLOW) LED
#define    RedLED    11                // Red (STOP) LED
#define    ProgramButton 12            // Program Button
#define    LightSensor 5               // Analog Pin 5 --> CDS voltage divider

// -----[ Constants ]-------------------------------------------------------

#define    RawToIn 889                  // 1 / 73.746 (with **)
#define    RawToCm 2257                 // 1 / 29.034 (with **)

// -----[ Variables ]-------------------------------------------------------

int              counter;               // LED Blink Counter
int              counter2;              // Button Counter

int              Zone1;                 // Zone 1 Value
int              Zone2;                 // Zone 2 Value
int              Zone3;                 // Zone 3 Value
int              Zone4;                 // Zone 4 Value

boolean          isBlinking = false;    // Blinking Red LED
boolean          isBlinkOn  = false;    // Blinking Red LED is OFF
boolean          isProgram  = false;    // Program Button is Pushed

void setup() {
  // initialize serial communication:
  Serial.begin(9600);

  // Initialize and do a Test Display of the Lamps
  pinMode(RedLED, OUTPUT );
  pinMode(YellowLED, OUTPUT);
  pinMode(GreenLED, OUTPUT); 

  // Program Button is a switch Tied high
  pinMode(ProgramButton, INPUT);
  digitalWrite(ProgramButton, HIGH );

  // Analog 0 Pin is the Light Sensor for 'sleep' mode

  // Play
  animateLeds();

  readSettings();
  Serial.println( "starting" );
}

void loop()
{


  // Test for Setup pushbutton; Normal is HIGH / Pressed is LOW
  if ( digitalRead(ProgramButton) == LOW ) {
    // If *already* pressed, then go into SETUP Program
    if ( isProgram ) {
      SetupMode();
      isProgram = false;          // Return to normal operation
    }
    else {
      isProgram = true;
    }
  }
  else {
    isProgram = false;
  }

  // TODO: Test for Light is On (or daylight)
  if ( analogRead(LightSensor) > 600 ) {

    // Lights are on, or door is open and it's daylight.. Start to Work...

    // establish variables for duration of the ping, 
    // and the distance result in inches and centimeters:
    long duration, inches, cm;

    duration = ping( PingPIN );

    // convert the time into a distance
    inches = microsecondsToInches(duration);
    cm = microsecondsToCentimeters(duration);

    // Set the LED Display based on the return...
    if ( inches < Zone1 ) {
      Serial.println("InZone1! Blink!");

      isBlinking = true;
      // Red is ON; Next half-second, blink it...
      if ( isBlinkOn ) {
        isBlinkOn = false;
        digitalWrite(RedLED, LOW);
      }
      else {
        isBlinkOn = true;
        digitalWrite(RedLED, HIGH);
      }
      digitalWrite(YellowLED, LOW);
      digitalWrite(GreenLED, LOW);
    } 
    else if ( inches < Zone2 ) {
      isBlinking = false;
      digitalWrite(RedLED, HIGH);     // Red is ON
      digitalWrite(YellowLED, LOW);
      digitalWrite(GreenLED, LOW);
    }
    else if ( inches < Zone3 ) {
      isBlinking = false;
      digitalWrite(RedLED, LOW);
      digitalWrite(YellowLED, HIGH);  // Yellow is ON
      digitalWrite(GreenLED, LOW);
    } 
    else if ( inches < Zone4 ) {
      isBlinking = false;
      digitalWrite(RedLED, LOW);
      digitalWrite(YellowLED, LOW);
      digitalWrite(GreenLED, HIGH);    // Green is ON
    }
    else {
      // At our theoretical PING))) Limit - just turn 'em off
      isBlinking = false;
      digitalWrite(RedLED, LOW);
      digitalWrite(YellowLED, LOW);
      digitalWrite(GreenLED, LOW);
    }

    Serial.print( inches );
    Serial.print( "in, " );
    Serial.print( cm );
    Serial.print( "cm" );
    Serial.println();
  }
  else { 
    // DARK! Sleep Now...
    digitalWrite(RedLED, LOW);
    digitalWrite(YellowLED, LOW);
    digitalWrite(GreenLED, LOW);
    delay(1000);
  }

  delay(500);                    // Wait a half-second between readings...
}

long ping( int PingPin )
{
  long duration;

  // The PING))) is triggered by a HIGH pulse of 2 or more microseconds.
  // Give a short LOW pulse beforehand to ensure a clean HIGH pulse:
  pinMode(PingPin, OUTPUT);
  digitalWrite(PingPin, LOW);
  delayMicroseconds(2);
  digitalWrite(PingPin, HIGH);
  delayMicroseconds(5);
  digitalWrite(PingPin, LOW);

  // The same pin is used to read the signal from the PING))): a HIGH
  // pulse whose duration is the time (in microseconds) from the sending
  // of the ping to the reception of its echo off of an object.
  pinMode(PingPin, INPUT);
  duration = pulseIn(PingPin, HIGH ); // Default timeout: 1 second

  return( duration );
}

long microsecondsToInches(long microseconds)
{
  // According to Parallax's datasheet for the PING))), there are
  // 73.746 microseconds per inch (i.e. sound travels at 1130 feet per
  // second).  This gives the distance travelled by the ping, outbound
  // and return, so we divide by 2 to get the distance of the obstacle.
  // See: http://www.parallax.com/dl/docs/prod/acc/28015-PING-v1.3.pdf
  return microseconds / 74 / 2;
}

long microsecondsToCentimeters(long microseconds)
{
  // The speed of sound is 340 m/s or 29 microseconds per centimeter.
  // The ping travels out and back, so to find the distance of the
  // object we take half of the distance travelled.
  return microseconds / 29 / 2;
}


// EEProm addresses for our settings.
#define Zone1addr 0
#define Zone2addr 2
#define Zone3addr 4
#define Zone4addr 6

void readSettings() 
{
  // Zone1 - Red Blinking - Minimum Distance to Wall!
  // Zone2 - Red Zone - Car Stop Region - Value is where Red Starts
  // Zone3 - Yellow Zone - Car Slowing Area - Value is where Yellow Starts
  // Zone4 - Green Zone - Car Approach Area - Value is the physical limit of the sensor
  //if ( EEPROM.read(Zone1addr) == 0 ) {
  // Probably not intitialized; set to reasonable defaults for first go-round
  Zone1 = 36;
  Zone2 = 46;
  Zone3 = 80;
  Zone4 = 140;
  //}
  //else {
  // If 'Blink-Red' is non-zero, then we're probably getting good values
  //   Zone1 = EEPROM.read(Zone1addr);
  //  Zone2 = EEPROM.read(Zone2addr);
  //  Zone3 = EEPROM.read(Zone3addr);
  //  Zone4 = EEPROM.read(Zone4addr);    
  //}  
}

void writeSettings()
{
  EEPROM.write(Zone1addr, Zone1);
  EEPROM.write(Zone2addr, Zone2);
  EEPROM.write(Zone3addr, Zone3);
  EEPROM.write(Zone4addr, Zone4);
}

void SetupMode()
{
  int counter = 0;
  int inches = 0;

  // Now in Setup Mode...
  Serial.println("In Setup..." );

  // Set Zone 4
  while( digitalRead(ProgramButton) == HIGH ) {

    if ( counter == 0 ) {
      inches = microsecondsToInches( ping( PingPIN ) );

      digitalWrite(GreenLED, HIGH); 
      counter = 1;
    }
    else {
      digitalWrite(GreenLED, LOW); 
      counter = 0;
    }
    delay( 500 );
  }

  animateLeds();
  counter = 0;
  EEPROM.write(Zone4addr, inches);

  // Set Zone 3
  while( digitalRead(ProgramButton) == HIGH ) {

    if ( counter == 0 ) {
      inches = microsecondsToInches( ping( PingPIN ) );

      digitalWrite(YellowLED, HIGH); 
      counter = 1;
    }
    else {
      digitalWrite(YellowLED, LOW); 
      counter = 0;
    }
    delay( 500 );
  }

  animateLeds();
  counter = 0;
  EEPROM.write(Zone3addr, inches);

  // Set Zone 2
  while( digitalRead(ProgramButton) == HIGH ) {

    if ( counter == 0 ) {
      inches = microsecondsToInches( ping( PingPIN ) );

      digitalWrite(RedLED, HIGH); 
      counter = 1;
    }
    else {
      digitalWrite(RedLED, LOW); 
      counter = 0;
    }
    delay( 500 );
  }

  animateLeds();
  counter = 0;
  EEPROM.write(Zone2addr, inches);

  // Set Zone 1
  // Zone 1 is calculated from Zone2 - basically a 6-inch range.
  inches = min( inches-6, 6);
  EEPROM.write(Zone1addr, inches);

  readSettings();
}

void animateLeds()
{
  for (int i = 0; i <= 5; i++) {
    if ( (i % 2) == 0 ) {
      digitalWrite(RedLED, HIGH);
      digitalWrite(YellowLED, HIGH);
      digitalWrite(GreenLED, HIGH);
    }
    else {
      digitalWrite(RedLED, LOW);
      digitalWrite(YellowLED, LOW);
      digitalWrite(GreenLED, LOW);
    }
    delay(250);
  } 
}




