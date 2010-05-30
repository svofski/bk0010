#include <stdio.h>
#include <inttypes.h>

#include "bootico.h"

#define NLAYERS 1
#define NAME "gorilla"

main() {
	int ncolumns = width/16;
	int pixel_ofs;
	int layer, column, row, i;
	
	uint16_t datski;
	uint16_t tmp;
	
	printf("%s_columns = %d\n", NAME, ncolumns);
	printf("%s_rows    = %d\n", NAME, height);
	
	for (layer = 0; layer < NLAYERS; layer++) {
		printf("; layer %d\n", layer);
		printf("%s_%d:\n", NAME, layer);
		for (column = 0; column < ncolumns; column++) {
			printf(".word ");
			for (row = 0; row < height; row++) {
				pixel_ofs = row*width + column*16;
				datski = 0;
				for (i = 0; i < 16; i++) {
					tmp = header_data[pixel_ofs+i];
					//datski = (datski << 1) | (((tmp >> layer) & 1) <<0);
					datski = (datski >> 1) | (((tmp >> layer) & 1) <<15);
				}
				printf("%07o,", 0177777 & ~datski);
			}
			printf("\n");
		}
		printf("\n");
	}
	
	exit(0);
}
