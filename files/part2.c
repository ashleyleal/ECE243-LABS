/*
Write a C-language program that moves a horizontal line up and down on the screen and
“bounces” the line off the top and bottom edges of the display. Your program should first clear the screen and
draw the line at a starting row on the screen. Then, in an endless loop you should erase the line (by drawing the
line using black), and redraw it one row above or below the last one. When the line reaches the top, or bottom, of
the screen it should start moving in the opposite direction.
*/

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

int pixel_buffer_start;  // global variable
volatile int *pixel_ctrl_ptr = (int *)0xFF203020;

void wait_for_vsync();
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int color);
void plot_pixel(int x, int y, short int line_color);
void swap(int *x, int *y);

int main(void) {

    volatile int *back_buffer;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    int current_y = 0;
    bool is_moving_up = true;

    clear_screen();

    // continuously move the line up and down
    while (true) {
        draw_line(0, current_y, 319, current_y, 0x0000); // erase old line by drawing black

        // increment or decrement the current_y based on the direction
        if (is_moving_up) {
            if (current_y > 0) {
                current_y--;
            } else {
                is_moving_up = false;  // change direction when hitting the top
            }
        } else {
            if (current_y < 239) {
                current_y++;
            } else {
                is_moving_up = true;  // change direction when hitting the bottom
            }
        }

        draw_line(0, current_y, 319, current_y, 0xF81F);  // Draw the line in its new position

        wait_for_vsync();
        back_buffer = *(pixel_ctrl_ptr + 1);
    }
}

void wait_for_vsync() {
    {
        int status;
        *pixel_ctrl_ptr = 1;  // start the synchronization process
        // - write 1 into front buffer address register
        status = *(pixel_ctrl_ptr + 3);  // read the status register
        while ((status & 0x01) != 0)     // polling loop waiting for S bit to go to 0
        {
            status = *(pixel_ctrl_ptr + 3);
        }
    }
}

void clear_screen() {
    int x, y;
    for (x = 0; x < 320; x++)
        for (y = 0; y < 240; y++)
            plot_pixel(x, y, 0x0000);  // clear pixel at (x, y)
}

void draw_line(int x0, int y0, int x1, int y1, short int color) {
    bool is_steep = abs(y1 - y0) > abs(x1 - x0);
    if (is_steep) {
        swap(&x0, &y0);
        swap(&x1, &y1);
    }
    if (x0 > x1) {
        swap(&x0, &x1);
        swap(&y0, &y1);
    }
    int deltax = x1 - x0;
    int deltay = abs(y1 - y0);
    int error = -(deltax / 2);
    int y = y0;

    int ystep;

    if (y0 < y1) {
        ystep = 1;
    } else {
        ystep = -1;
    }

    for (int x = x0; x <= x1; x++) {
        if (is_steep) {
            plot_pixel(y, x, color);
        } else {
            plot_pixel(x, y, color);
        }
        error = error + deltay;
        if (error >= 0) {
            y = y + ystep;
            error = error - deltax;
        }
    }
}

void plot_pixel(int x, int y, short int line_color) {
    volatile short int *one_pixel_address;

    one_pixel_address = pixel_buffer_start + (y << 10) + (x << 1);

    *one_pixel_address = line_color;
}

void swap(int *x, int *y) {
    int temp = *x;
    *x = *y;
    *y = temp;
}
