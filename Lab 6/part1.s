struct PIT_t {
    volatile unsigned int DR;
    volatile unsigned int DIR;
    volatile unsigned int MASK;
    volatile unsigned int EDGE;
};

// The LED pit is at this base address
struct PIT_t *const ledp = ((struct PIT_t *)0xFF200000);
// The BUTTONS pit is at this base address
struct PIT_t *const buttonp = ((struct PIT_t *)0xFF200050);

// bit patterns for KEY0 and KEY1 
#define KEY0_BIT (1U << 0) // KEY0 first bit
#define KEY1_BIT (1U << 1) // KEY1 second bit
#define ALL_LEDS_ON 0xFFFFFFFF

int main() {
    // Initialize LEDs to be off
    ledp->DR = 0;

    while (1) {
        // Read the edge capture register
        unsigned int edge_capture = buttonp->EDGE;

        // Check if KEY0 was pressed and released
        if ((edge_capture & KEY0_BIT) != 0) {
            // Turn all LEDs on
            ledp->DR = ALL_LEDS_ON;
        }
        
        // Check if KEY1 was pressed and released
        if ((edge_capture & KEY1_BIT) != 0) {
            // Turn LEDs off
            ledp->DR = 0;
        }

        // Clear the edge capture register 
        if (edge_capture != 0) {
            buttonp->EDGE = edge_capture;
        }
    }

    return 0; 
}
