#include <stdbool.h>

#define AUDIO_BASE          0xFF203040

// Audio port structure
struct audio_t {
    volatile unsigned int control;  // The control/status register
    volatile unsigned char rarc;    // the 8 bit RARC register
    volatile unsigned char ralc;    // the 8 bit RALC register
    volatile unsigned char wsrc;    // the 8 bit WSRC register
    volatile unsigned char wslc;    // the 8 bit WSLC register
    volatile unsigned int ldata;    // the 32 bit (really 24) left data register
    volatile unsigned int rdata;    // the 32 bit (really 24) right data register
};

struct audio_t *const audiop = ((struct audio_t *) AUDIO_BASE);
volatile int *SW_ptr = (volatile int*)0xFF200040;
int SAMPLE_RATE = 8000; // Fixed sample rate
int frequency = 1000; // Initial square wave frequency
int prev_value = 0;

void generateSquareWave(int frequency) {
    int counter = 0;
    int samplesPerPeriod = SAMPLE_RATE / frequency;
    int halfPeriod = samplesPerPeriod / 2;

    while (1) {
        int value = *SW_ptr;
        if (value != prev_value) {
            // Adjusting frequency based on the switches
            switch (value) {
                case 1: frequency = 100; break;   
                case 2: frequency = 300; break; 
                case 4: frequency = 500; break;   
                case 8: frequency = 700; break; 
                case 16: frequency = 900; break; 
                case 32: frequency = 1100; break; 
                case 64: frequency = 1300; break; 
                case 128: frequency = 1500; break;
                case 256: frequency = 1700; break;
                case 512: frequency = 2000; break;
            }
            samplesPerPeriod = SAMPLE_RATE / frequency;
            halfPeriod = samplesPerPeriod / 2;
            prev_value = value;
            counter = 0; // apply frequency change immediately
        }

        // Check if there is space in the output FIFO
        if (audiop->wsrc) {
            if (counter < halfPeriod) {
                // Set to high for the first half
                audiop->ldata = 0x7FFFFFF; 
                audiop->rdata = 0x7FFFFFF; 
            } else {
                // Set to low for the second half
                audiop->ldata = 0; 
                audiop->rdata = 0; 
            }

            counter++;
            if (counter >= samplesPerPeriod) {
                counter = 0; // Reset counter at the end of each period
            }
        }
    }
}

int main(void) {
    while(1) {
        generateSquareWave(frequency);
    }
}
