#include <ansidecl.h>
#include "diskio.h"
#include "pff.h"

FATFS fatfs;
DIR dir;
FILINFO fno;

#define SYSREG *((unsigned int*)0177716)

void xmit() {}

static char fname[] = "BK0010/100000.ROM\0XXXXXXXXXXXX";
#define FNBUFL 30

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

	return 0;
}

int loadbin() {
    int n;
    unsigned length;
    unsigned char *ptr;

    for(n = 3; --n >= 0 || pf_open(fname) != FR_OK;);

    if (n) {
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

#define abs(x) ((x) > 0 ? (x):-(x))

void pputs(s, width)
char *s;
int width;
{
    int slen = strlen(s);
    int pad;

    puts(s);
    for (pad = width - slen; --pad >= 0;) putchar(' ');
}


int listdir() {
    FRESULT r;
    int i;

    for(i = 3; --i >= 0 || (r = pf_opndir(&dir, "BK0010")) != FR_OK;);

    if (i) {
        for(i = 0; pf_rddir(&dir, &fno) == FR_OK; i++) {
            if (!fno.fname[0]) break;
            pputs(fno.fname, 16);
        }
        return 0;
    } 

    return -1;
}

void kenter() {
    int c;
    int i = 7;

    for(;;) {
        puts("\nFile name: ");
        for (i = 7; 
             i < FNBUFL && ((c = getchar()) != '\n'); 
             fname[i] = c, 
             i += (c != 030) ? 1 : i > 7 ? -1 : 0,
             putchar(c));

        fname[i] = '\0';

        if (i == 7) {
            puts("\nDirectory:\n");
            if(listdir()) puts("Fail");
        } else {
            puts("\nLoading "); puts(fname); puts(" ...");
            puts(loadbin() ? "Ok" : "Fail");
            break;
        }
    }

    putchar('\n');
}
