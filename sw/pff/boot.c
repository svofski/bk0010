#include <ansidecl.h>
#include "diskio.h"
#include "pff.h"

FATFS fatfs;
DIR dir;
FILINFO fno;

#define SYSREG *((unsigned int*)0177716)

void xmit() {}

static char fname[] = "BK0010/100000.ROM\0\0\0\0";

unsigned char buffer[512];

#if DEBUG
#define debug(x)    puts(x)
#else
#define debug(x)    {}
#endif

int main ()
{
    int x, n, i;
    unsigned count = 0;
    unsigned char* romptr = (unsigned char *)0100000;

	debug("boot "); debug(fname);

    /*disk_sbuf(buffer);*/

    *romptr = 0xab;

    do {
        debug("SD ");
        x = pf_mount(&fatfs);
        debug(x == FR_OK ? "mounted\n" : "fail\n");
    } while (x != FR_OK);

#if 0
    debug("Opening BK0010/ ");
    debug(pf_opndir(&dir, "BK0010") == FR_OK ?
        "opened\n" : "fail\n");
#endif

    *romptr = 0xac;

    if (pf_open(fname) == FR_OK) {
        /* disk_sbuf(0); */
        /* pf_read(romptr, fatfs.fsize, &n); */

        x = 0;
        pf_read(romptr, 32752, &n);
    } else {
        debug(" - couldn't open");
    }
#if DEBUG
    debug("read "); printhex(count); debug("\n");
#endif

    /*
    asm("mov $0, *$0177700 / disable shadow");
    asm("jmp *$0100000");
    */

	return 0;
}

int loadbin() {
    int n;
    unsigned length;
    unsigned char *ptr;

    if (pf_open(fname) == FR_OK) {
        if (pf_read(buffer, 4, &n) == FR_OK) {
            ptr = (unsigned char *) LD_WORD(buffer);
            ptr += 0120000;

            length = (unsigned) LD_WORD(buffer+2);

            if (pf_read(ptr, length, &n) == FR_OK) {
                return 1;
            }
        }
    }

    return 0;
}

void kenter() {
    int c;
    int i = 7;

    puts("Here's Johnny!\n");
    puts("File: ");
    /*for (i = 7; i < 7+12 && ((c = getchar()) != '\n'); fname[i++] = c);*/
    for (i = 7; i < 7+12; i++) {
        c = getchar();
        putchar(c);
        if (c == '\n') break;
        fname[i] = c;
    }
    fname[i] = '\0';
    puts("\nLoading "); puts(fname); puts(" ...");
    puts(loadbin() ? "Ok" : "Fail");
    putchar('\n');
}
