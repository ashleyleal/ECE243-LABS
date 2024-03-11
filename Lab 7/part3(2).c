#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

volatile int pixel_buffer_start;  // global variable
short int Buffer1[240][512];      // 240 rows, 512 (320 + padding) columns
short int Buffer2[240][512];

volatile int *pixel_ctrl_ptr = (int *)0xFF203020;

void clear_screen();
void plot_pixel(int x, int y, short int line_color);
void draw_box(int locx, int locy, short int color, int size);
void wait_for_vsync();
void set_boxes(int x_box[], int y_box[], int colour_box[], int dx[], int dy[]);
void draw_line(int x0, int y0, int x1, int y1, short int color);
void swap(int *x, int *y);

int main(void) {
    // declare other variables(not shown)
    // initialize location and direction of rectangles(not shown)
    int x_box[8];
    int y_box[8];
    int colour_box[8];
    int dx[8];
    int dy[8];

    int old_x_box[8];
    int old_y_box[8];
    // set random initial directions, locations and colors of boxes
    set_boxes(x_box, y_box, colour_box, dx, dy);

    /* set front pixel buffer to Buffer 1 */
    *(pixel_ctrl_ptr + 1) = (int)&Buffer1;  // first store the address in the  back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen();  // pixel_buffer_start points to the pixel buffer

    /* set back pixel buffer to Buffer 2 */
    *(pixel_ctrl_ptr + 1) = (int)&Buffer2;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1);  // we draw on the back buffer
    clear_screen();                              // pixel_buffer_start points to the pixel buffer

    while (true) {

        // draw every box and line and update their locations
        for (int i = 0; i < 8; i++) {
            int j = i + 1;
            old_x_box[i] = x_box[i];
            old_y_box[i] = y_box[i];
            x_box[i] += dx[i];
            y_box[i] += dy[i];

            if (x_box[i] <= 0 || x_box[i] >= 310) dx[i] = -dx[i];
            if (y_box[i] <= 0 || y_box[i] >= 230) dy[i] = -dy[i];
            draw_box(x_box[i], y_box[i], colour_box[i], 10);

            // lines
            if (j == 8) {
                j = 0;
            }
            draw_line(x_box[i], y_box[i], x_box[j], y_box[j], 0xFFFF);
        }

        wait_for_vsync();
        pixel_buffer_start = *(pixel_ctrl_ptr + 1);
		
		for (int i = 0; i < 8; i++) {
           int j = i + 1;
           draw_box(old_x_box[i], old_y_box[i], 0x0000, 10);

            if (j == 8) {
                j = 0;
            }
            draw_line(old_x_box[i], old_y_box[i], old_x_box[j], old_y_box[j], 0x0000);
        }
    }
}

// code for subroutines (not shown)

void plot_pixel(int x, int y, short int line_color) {
    volatile short int *one_pixel_address;
    one_pixel_address = pixel_buffer_start + (y << 10) + (x << 1);
    *one_pixel_address = line_color;
}

void draw_box(int locx, int locy, short int color, int size) {
    for (int x = locx; x < locx + size; x++) {
        for (int y = locy; y < locy + size; y++) {
            plot_pixel(x, y, color);
        }
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

void set_boxes(int x_box[], int y_box[], int colour_box[], int dx[], int dy[]) {
    for (int i = 0; i < 8; i++) {
        dx[i] = ((rand() % 2) * 2) - 1;
        dy[i] = ((rand() % 2) * 2) - 1;

        x_box[i] = rand() % 320;
        y_box[i] = rand() % 240;

        colour_box[i] = rand() % 0xFFFF;
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

void swap(int *x, int *y) {
    int temp = *x;
    *x = *y;
    *y = temp;
}
