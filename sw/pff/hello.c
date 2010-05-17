#include <ansidecl.h>
#include "diskio.h"
#include "pff.h"

FATFS fatfs;
DIR dir;
FILINFO fno;

void xmit() {}

int main ()
{
    int x;
    unsigned int* spi = (unsigned int *)0177714;

	puts ("Hello, World\n");
    puts("SD ");
    puts(pf_mount(&fatfs) == FR_OK ?
         "mounted\n" : "fail\n");

    puts("/ ");
    puts(pf_opndir(&dir, "VECTOR06") == FR_OK ?
        "opened\n" : "fail\n");

    /*return 0;*/

    for (x=0;;x++) {
        if (pf_rddir(&dir,&fno) == FR_OK) {
            if (!fno.fname[0]) break;
            puts(fno.fname);
            if (fno.fattrib & AM_DIR) puts("/");
            puts("\n"); 
        }
    }
   
	return 0;
}
