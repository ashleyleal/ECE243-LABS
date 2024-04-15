#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#define NUM_BOXES 8
	
typedef struct {
    // xy location of box
	int x1;
	int x2;
	int x; 
	int y1;
	int y2;
    int y;
	// xy direction of box
    int dx1;
	int dx2;
	int dx;
	int dy1;
	int dy2;
    int dy;
	short int color;
	short int line_color;
} BoxPosition;

// an array to keep track of the box positions
BoxPosition box_positions[NUM_BOXES];

volatile int pixel_buffer_start; // global variable

// Global arrays for front and back buffers
short int Buffer1[512][240]; 	// 240 rows, 512 (320 + padding) columns
short int Buffer2[512][240];	// store the colour coresponding to each pixel

// Function prototypes
void clear_screen();
void draw_box(int x, int y, short int color);
void draw_line(int start_x, int start_y, int end_x, int end_y, short int color);
void move_boxes(int index);
void plot_pixel(int x, int y, short int line_color);
void wait_for_vsync();
void swap(int* point1, int* point2);

int main() {
	
	volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // declare other variables(not shown)
	
    // initialize location and direction of rectangles(not shown)
    for (int i = 0; i < NUM_BOXES; i++) {
        box_positions[i].x = rand() % 320;
        box_positions[i].y = rand() % 240;
        box_positions[i].dx = rand() % 2 == 0 ? 6 : -6; // Random initial direction for x-axis
        box_positions[i].dy = rand() % 2 == 0 ? 6 : -6; // Random initial direction for y-axis
		box_positions[i].color = rand() % 0xFFFFFF;
		box_positions[i].line_color = rand() % 0xFFFFFF;
    }
	
    /* set front pixel buffer to Buffer 1 */
    *(pixel_ctrl_ptr + 1) = (int) &Buffer1; // first store the address in the  back buffer
    
	/* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync(); // poll for s-bit to set to 0
	
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer

    /* set back pixel buffer to Buffer 2 */
    *(pixel_ctrl_ptr + 1) = (int) &Buffer2;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    
    clear_screen();

	 // Main animation loop
	while (1) {

    // Draw boxes and lines on the back buffer
    for (int i = 0; i < NUM_BOXES; i++) {
        // Calculate new position for each box and draw it
        // Move boxes function should update the positions of boxes
        draw_box(box_positions[i].x, box_positions[i].y, box_positions[i].color);
        move_boxes(i);

        // Draw red lines connecting boxes
        if (i > 0) {
            draw_line(box_positions[i-1].x, box_positions[i-1].y, box_positions[i].x, box_positions[i].y, box_positions[i -1].line_color);
        }
    }
	draw_line(box_positions[NUM_BOXES - 1].x, box_positions[NUM_BOXES - 1].y, box_positions[0].x, box_positions[0].y, box_positions[NUM_BOXES - 1].line_color);
    
    // Swap front and back buffers
    wait_for_vsync(); // Call the function to synchronize with VGA controller and swap buffers
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // Set pixel buffer to the back buffer
	// Clear back buffer
    clear_screen();
}
}


// we render the drawing only using this !!!
void plot_pixel(int x, int y, short int line_color)
{
    volatile short int *one_pixel_address;
        
        one_pixel_address = (short int *)(pixel_buffer_start + (y << 10) + (x << 1));
        
        *one_pixel_address = line_color;
}

// polling for rendering from front buffer done to switch buffers
void wait_for_vsync(){
	volatile int * pixel_ctrl_ptr = (int *) 0xff203020; // base address
	
	*pixel_ctrl_ptr = 1; // start the synchronization process
	// write 1 into front buffer address register
	volatile int * s_bit = (int *)0xFF20302C; // Use unsigned int pointer to read 32 bits
	// polling loop waiting for S bit to go to 0
	while ((*s_bit & 0x1) != 0);
}

// Function to clear the back buffer
void clear_screen() {
   // Draw boxes and lines on the back buffer
    for (int i = 0; i < NUM_BOXES; i++) {
        // Calculate new position for each box and draw it
        // Move boxes function should update the positions of boxes
		
		draw_box(box_positions[i].x2, box_positions[i].y2, 0);

        // Draw red lines connecting boxes
        if (i > 0) {
            draw_line(box_positions[i-1].x1, box_positions[i-1].y1, box_positions[i].x1, box_positions[i].y1, 0);
        }
    }
	draw_line(box_positions[NUM_BOXES - 1].x1, box_positions[NUM_BOXES - 1].y1, box_positions[0].x1, box_positions[0].y1, 0);
}

void draw_box(int x, int y, short int color) {
    // Draw box at position (x, y) in back buffer
    // Implement your drawing logic here
    
    // Adjust box size to fit within screen boundaries
    int box_size = 10;
    
    // Ensure x and y are within bounds
    if (x < 0) x = 0;
    if (x + box_size >= 320) x = 320 - box_size - 1;
    if (y < 0) y = 0;
    if (y + box_size >= 240) y = 240 - box_size - 1;

    // Draw box within screen boundaries
    for (int i = 0; i < box_size; i++) {
        for (int j = 0; j < box_size; j++) {
            plot_pixel(x + i, y + j, color);
        }
    }
}



void draw_line(int start_x, int start_y, int end_x, int end_y, short int color)
{
    bool is_steep = abs(end_y - start_y) > abs(end_x - start_x);
    if (is_steep){
        swap(&start_x, &start_y);
        swap(&end_x, &end_y);
    }
    if (end_x < start_x){
        swap(&start_x, &end_x);
        swap(&start_y, &end_y);
    }
    int delta_x = end_x - start_x;
    int delta_y = abs(end_y - start_y);
    int error = -delta_x/2;
    int y = start_y;
    int y_step = start_y < end_y ? 1 : -1;

    for (int x = start_x; x <= end_x; x++) {
        if (is_steep) {
            plot_pixel(y, x, color);
            plot_pixel(y+1, x, color); // Draw adjacent line to make it thicker
			plot_pixel(y+1, x+1, color); // Draw adjacent line to make it thicker
        } else {
            plot_pixel(x, y, color);
            plot_pixel(x, y+1, color); // Draw adjacent line to make it thicker
			plot_pixel(x+1, y+1, color); // Draw adjacent line to make it thicker
        }
        error += delta_y;
        if (error >= 0){
            y += y_step;
            error -= delta_x;
        }
    }
}

void move_boxes(int index) {
    // Move box at index to the next position
	box_positions[index].x2 =  box_positions[index].x1;
    box_positions[index].y2 = box_positions[index].y1;
	box_positions[index].x1 =  box_positions[index].x;
    box_positions[index].y1 = box_positions[index].y;
    box_positions[index].x += box_positions[index].dx;
    box_positions[index].y += box_positions[index].dy;

    // Check for collision with screen edges and reverse direction if needed
    if (box_positions[index].x <= 0 || box_positions[index].x >= 319) {
        // Reset box position to the edge of the screen
        box_positions[index].x = box_positions[index].x <= 0 ? 0 : 319;
        // Reverse direction
		box_positions[index].dx2 = box_positions[index].dx1;
		box_positions[index].dx1 = box_positions[index].dx;
		box_positions[index].dx = -box_positions[index].dx;
    }
    if (box_positions[index].y <= 0 || box_positions[index].y >= 239) {
        // Reset box position to the edge of the screen
        box_positions[index].y = box_positions[index].y <= 0 ? 0 : 239;
        // Reverse direction
        box_positions[index].dy2 = box_positions[index].dy1;
		box_positions[index].dy1 = box_positions[index].dy;
		box_positions[index].dy = -box_positions[index].dy;
    }
}


// swapping the values in two ints
void swap(int* point1, int* point2)
{
    int temp = *point1;
    *point1 = *point2;
    *point2 = temp;
}