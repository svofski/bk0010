#include <ansidecl.h>
#include "diskio.h"
#include "pff.h"

FATFS fatfs;
DIR dir;
FILINFO fno;

#define SYSREG *((unsigned int*)0177716)

void xmit() {}

static char* M_FAIL = "\007Fail";
static char* M_OK   = "\007OK";

static char fname[] = "BK0010/100000.ROM\0XXXXXXXXXXXX";
#define FNBUFL 30

char lastfile[14];

unsigned char buffer[512];

unsigned char* romptr = (unsigned char *)0100000;

#if DEBUG
#define debug(x)    puts(x)
#else
#define debug(x)    {}
#endif

int findrom()
{
    int i;
    unsigned count = 0;

    disk_sbuf(buffer);

    *romptr = 0xab;

    for (i = 1000; --i > 0 && pf_mount(&fatfs) != FR_OK;);
    if (i) {
        *romptr = 0xac;

        if (pf_open(fname) == FR_OK) {
            /*pf_read(romptr, 32752, &i);*/

            return 0;
        }
    }

	return 1;
}

int loadrom() {
    int i;
    return pf_read(romptr, 32752, &i) != FR_OK;
}

int loadbin() {
    int n;
    unsigned length;
    unsigned char *ptr;
    unsigned char cbuf[4];

    for(n = 3; --n > 0 && pf_open(fname) != FR_OK;);

    if (n) {
        if (pf_read(cbuf, 4, &n) == FR_OK) {
            ptr = (unsigned char *) LD_WORD(cbuf) + 0120000;
            /*ptr += 0120000;*/

            length = (unsigned) LD_WORD(cbuf+2);

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

/* Return true if s1 is a prefix of s2 */
int strprefx(s1,s2) 
char *s1, *s2;
{
   for (;*s1 == *s2; s1++,s2++);
   return *s1 == 0;
}

void strcpy(s1,s2) 
char *s1, *s2;
{
    for (;*s1++ = *s2++;);
}

int listdir() {
    FRESULT r;
    int i;

    for(i = 3; --i > 0 && (r = pf_opndir(&dir, "BK0010")) != FR_OK;);

    if (i) {
        for(i = 0; pf_rddir(&dir, &fno) == FR_OK;) {
            if (!fno.fname[0]) break;
            if (strprefx(fname+7, fno.fname)) {
                pputs(fno.fname, 16);
                strcpy(lastfile, fno.fname);
                i++;
            }
        }
        if (i == 1) {
            strcpy(fname+7, lastfile);
        }
        return 0;
    } 

    return -1;
}

void kenter() {
    int c;
    int i;

    fname[7] = 0;

    for(;;) {
        for (i = 7; fname[i]; i++);

        puts("\nFile:"); puts(fname+7);
        for (; i < FNBUFL && ((c = toupper(getchar())) != '\n'); ) {
            if (c == 030) {
                if (i > 7) { 
                    --i; 
                } else {
                    continue;
                }
            } else if (c == 011) {
                break;
            } else {
                fname[i++] = c;
            }
            putchar(c);
        }

        fname[i] = '\0';

        if (i == 7 || c == 011) {
            putchar('\n');
            if(listdir()) puts(M_FAIL);
        } else {
            puts("\nLoading "); puts(fname); puts("...");
            puts(loadbin() ? M_OK : M_FAIL);
            break;
        }
    }

    putchar('\n');
}
