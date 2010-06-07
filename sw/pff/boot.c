#include <ansidecl.h>
#include "util.h"
#include "diskio.h"
#include "pff.h"

FATFS fatfs;
DIR dir;
FILINFO fno;

#define SYSREG *((unsigned int*)0177716)    /*!< BK-0010 system control reg */

void xmit() {}  /*!< needed by mmc.c streaming feature, unused */

static char* M_FAIL = "\007Fail";   /*!< Failmessage */
static char* M_OK   = "\007OK";     /*!< Winmessage */


static char fname[] = "BK0010/100000.ROM\0XXXXXXXXXXXX";  /*!< file name buffer */
#define FNBUFL 30                                         /*!< file name buffer size */

char lastfile[14];              /*!< last valid file for tab completion */

unsigned char buffer[512];      /*!< disk i/o buffer */

unsigned char* romptr = (unsigned char *)0100000; /*!< rom will be read here */

/*! BIN file header */
struct binhdr {
    unsigned start;             /*!< load location */
    unsigned length;            /*!< file length   */
};

struct emtcb {
    unsigned cmd;
    unsigned start;
    unsigned length;
    char name[20];
} *emtCB;

static struct binhdr hdr;


#if DEBUG
#define debug(x)    puts(x)
#else
#define debug(x)    {}
#endif

void newline() { putchar('\n'); }

/**
 * Bootstrap Phase 1. Mount FS, find ROM and open it.
 */
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
            return 0;
        }
    }

	return 1;
}

/** 
 * Bootstrap Phase 2. Load the ROM.
 */
int loadrom() {
    int i;
    return pf_read(romptr, 32752, &i) != FR_OK;
}

/**
 * Load bin-file to virtual addresses 0120000-0157777
 */
int loadbin() {
    int n, max;

    for(n = 3; --n > 0 && pf_open(fname) != FR_OK;);

    if (n) {
        if (pf_read(&hdr, sizeof(hdr), &n) == FR_OK) {
            if (emtCB && emtCB->start) hdr.start = emtCB->start;

            max = hdr.length;
            if (hdr.start + hdr.length >= 040000) max -= (hdr.start+hdr.length) - 040000;

            if (pf_read((unsigned char *)hdr.start + 0120000, max, &n) == FR_OK) {
                max = hdr.length - max;
                if (max) {
                    /* map screen area to 12 and read the other part */
                    asm("jsr pc, _umap1");
                    pf_read((unsigned char*)0120000, max, &n);
                    asm("jsr pc, _umap0");
                    return 2;
                }
                return 1;
            }

        }
    }

    return 0;
}

/** 
 * List all files with names starting with (fname+7).
 * If there is only one matching file, copy its full name into (fname+7).
 */
int listdir() {
    FRESULT r;
    int i;

    for(i = 3; --i > 0 && (r = pf_opndir(&dir, "BK0010")) != FR_OK;);

    if (i) {
        for(i = 0; pf_rddir(&dir, &fno) == FR_OK;) {
            if (!fno.fname[0]) break;
            if (strprefx(fname+7, fno.fname)) {
                if (i == 1) {
                    newline();
                    pputs(lastfile, 16);
                }
                if (i != 0) pputs(fno.fname, 16);
                strcpy(lastfile, fno.fname);
                i++;
            }
        }
        if (i == 1) {
            strcpy(fname+7, lastfile);
        } else if (i > 1) {
            newline();
        }

        return 0;
    } 

    return -1;
}


/** 
 * ScrollLock and EMT36 entry point.
 *
 * If emtCB is NULL, this is a ScrollLock handler. 
 * Prompt for file name, list directory and load bin file.
 *
 * If emtCB is given, use data from it and skip all interactivity.
 */
int kenter() {
    int c;
    int i;

    fname[7] = 0;

    newline();
    for(;;) {
        for (i = 7; fname[i]; i++);

        if (emtCB) {
            for(c = 0; c < 20;) {
                if ((fname[i] = emtCB->name[c++]) == 040) break;
                i++;
            }
            c = 0;
        }
        else {
            puts("\025\032File:"); puts(fname+7);
            for (; i < FNBUFL && ((c = toupper(getchar())) != '\n'); ) {
                if (c == 030) {             /* Backspace/DEL */
                    if (i > 7) { 
                        --i; 
                    } else {
                        continue;
                    }
                } else if (c == 011) {      /* TAB (see below and listdir()) */
                    break;
                } else {
                    fname[i++] = c;
                }
                putchar(c);
            }
        }

        fname[i] = '\0';

        if (i == 7 || c == 011) {
            if(listdir()) puts(M_FAIL);
            if (emtCB) break;           /* avoid eternal loop if requested name is empty */
        } else {
            if (!emtCB) {
                puts("\nLoading "); puts(fname); puts("...");
            }
            c = loadbin();
            if(emtCB) {
                emtCB->cmd = 0;         /* Fill in response: 0 = no error (whatever) */
                emtCB->start = hdr.start;
                emtCB->length = hdr.length; 
            } else {
                puts(c ? M_OK : M_FAIL);
                newline();
            }

            return c == 2;
        }
    }
    return 0;
}
