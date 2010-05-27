#include <ansidecl.h>
#include "diskio.h"
#include "pff.h"

FATFS fatfs;
DIR dir;
FILINFO fno;

#define SYSREG *((unsigned int*)0177716)

void xmit() {}

static char fname[] = "BK0010/100000.ROM";

unsigned char buffer[512];
unsigned char buf[128];

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
/*
        for(; pf_read(buf, sizeof(buf), &n) == FR_OK;) {
            for (i = 0; i < sizeof(buf); i++) {
                *romptr++ = buf[i];
                if (romptr >= 0177600) break;
            }
            x += n;
            if (romptr >= 0177600) break;
            if (n < sizeof(buf)) break;
        }
*/
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
