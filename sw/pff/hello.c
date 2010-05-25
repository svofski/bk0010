#include <ansidecl.h>
#include "diskio.h"
#include "pff.h"

FATFS fatfs;
DIR dir;
FILINFO fno;

void xmit() {}


static char fname[] = "BK0010/XXXXXXXX.XXX";

char buffer[512];
char buf[128];

int main ()
{
    int x, n, i;
    unsigned int* spi = (unsigned int *)0177714;

	puts ("hello.jpg\n");

    disk_sbuf(buffer);

    do {
        puts("SD ");
        x = pf_mount(&fatfs);
        puts(x == FR_OK ? "mounted\n" : "fail\n");
    } while (x != FR_OK);


    puts("Opening BK0010/ ");
    puts(pf_opndir(&dir, "BK0010") == FR_OK ?
        "opened\n" : "fail\n");

    /*return 0;*/

    for (x=0;;x++) {
        if (pf_rddir(&dir,&fno) == FR_OK) {
            if (!fno.fname[0]) break;
            puts(fno.fname);
            if (fno.fattrib & AM_DIR) {
                puts("/");
            } else {
                for(i=0;fname[i+7]=fno.fname[i];i++);
                puts("\nTrying to open: "); puts(fname); puts(" size=0x"); printq(fno.fsize,1);
                if (pf_open(fname) == FR_OK) {
                    for(;pf_read(buf, sizeof(buf), &n) == FR_OK;) {
                        /*putchar('[');printhex(n);putchar(']');*/
                        for (i = 0; i < n; i++) { putchar(buf[i]); }
                        if (n < sizeof(buf)) break;
                    }
                } else {
                    puts(" - couldn't open");
                }
            }
            puts("\n"); 
        }
    }
   
	return 0;
}
