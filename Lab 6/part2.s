
	/* globals */
#define BUF_SIZE 6100 // about 10 seconds of buffer (@ 8K samples/sec)
#define BUF_THRESHOLD 96 // 75% of 128 word buffer
/* function prototypes */
void buttons_check(int *, int *, int *); // wait for button 0 or 1
void waithalfsecs(int factor); // wait factor x 1/2 secs
void led_set(unsigned int v); // set the LED DR to v

struct audio_t {
	volatile unsigned int control;
	volatile unsigned char rarc;
	volatile unsigned char ralc;
	volatile unsigned char warc;
	volatile unsigned char walc;
    volatile unsigned int ldata;
	volatile unsigned int rdata;
};

struct audio_t *const audiop = ((struct audio_t *)0xff203040);


/*******************************************************************************
* This program performs the following:
* 1. records audio for 10 seconds when KEY[0] is pressed. LEDR[0] is lit
* while recording.
* 2. plays the recorded audio when KEY[1] is pressed. LEDR[1] is lit while
* playing.
******************************************************************************/
int left_buffer[BUF_SIZE];
int right_buffer[BUF_SIZE];

void 
audio_record(void) {        
            int buffer_index;

            audiop->control = 0x4; // clear the input FIFOs
            audiop->control = 0x0; // resume input conversion
            buffer_index = 0;
            while (buffer_index < BUF_SIZE) { 
                // read samples if there are any in the input FIFOs
                if (audiop->rarc) {
                      left_buffer[buffer_index] = audiop->ldata;
                      right_buffer[buffer_index] = audiop->rdata;
                      ++buffer_index;
		}
            }
}

void 
audio_playback(void) {
            int buffer_index = 0;

            audiop->control = 0x8; // clear the output FIFOs
            audiop->control = 0x0; // resume output conversion
            while (buffer_index < BUF_SIZE) {
              // output data if there is space in the output FIFOs
              if (audiop->warc) {
                  audiop->ldata = left_buffer[buffer_index];
                  audiop->rdata = right_buffer[buffer_index];
                  ++buffer_index;
              }
             }
}	

int 
main(void) {
     /* used for audio record/playback */
     int record = 0, play = 0, buffer_index = 0;

     /* read and echo audio data */
     record = 0;
     play = 0;

	 buffer_index = 0;
	 led_set(0);

       while (1) {
            buttons_check(&record, &play, &buffer_index);
            if (record) {
              led_set(0x1); // turn on LEDR[0]
			  audio_record();
              // done recording
              record = 0;
              led_set(0x10); // turn off LEDR
	        } else if (play) {
               led_set(0x2); // turn on LEDR_1
	           audio_playback();
               // done playback
               play = 0;
               led_set(0x10); // turn off LEDR
            } // else if
      } // while (1)
}

//======================================================

struct PIT_t {
volatile unsigned int DR;
volatile unsigned int DIR;
volatile unsigned int MASK;
volatile unsigned int EDGE;
};
// The LED pit is at this base address
struct PIT_t * const ledp = ((struct PIT_t *) 0xFF200000);
// The BUTTONS pit is at this base address
struct PIT_t *const buttonp = ((struct PIT_t *) 0xFF200050);
// The HEX digits 0 through 3 PIT
struct PIT_t *const hex03p = ((struct PIT_t *)0xFF200020);
// The Swicthes PIT
struct PIT_t *const swp = ((struct PIT_t *)0xFF200040);

void
led_set(unsigned int v) {
	ledp->DR = v;
}

/****************************************************************************************
* Subroutine to read KEYs
****************************************************************************************/
void buttons_check(int * KEY0, int * KEY1, int * counter) {
      int value = 0;
	  while (value == 0) 
           value = buttonp->EDGE; // read the pushbutton KEY values
	  
      if (value & 0x1) { // check KEY0
          // reset counter to start recording
          *counter = 0;
          // clear audio-in FIFO
          audiop->control = 0x4;
          audiop->control = 0x0;
          *KEY0 = 1;
      } else if (value & 0x2) {// check KEY1
          // reset counter to start playback
          *counter = 0;
          // clear audio-out FIFO
          audiop->control = 0x8;
          audiop->control = 0x0;
          *KEY1 = 1;
      }
	  buttonp->EDGE = value; // clear all edge bits that were 1
}

//======================================================
struct timer_t {
       volatile unsigned int status;
       volatile unsigned int control;
       volatile unsigned int periodlo;
       volatile unsigned int periodhi;
       volatile unsigned int snaplo;
       volatile unsigned int snaphi;
};

struct timer_t * const timer = (struct timer_t *) 0xFF202000;

#define TIMERSEC 100000000

	
// Uses timer polling to wait roughly 1/2 sec
// use the factor parameter to wait multiples of this
void
waithalfsecs(int factor) {
	   unsigned int howlong = (TIMERSEC >> 1) * factor;
       timer->control = 0x8; // stop the timer
       timer->status = 0;
	   timer->periodlo = (howlong & 0x0000FFFF);
       timer->periodhi = (howlong & 0xFFFF0000) >> 16;
       timer->control = 0x4;
       while ((timer->status & 0x1) == 0);
	   timer->status = 0;
}
