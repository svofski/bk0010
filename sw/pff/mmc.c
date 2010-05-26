/*-----------------------------------------------------------------------*/
/* PFF - Low level disk control module for ATtiny85     (C)ChaN, 2009    */
/*-----------------------------------------------------------------------*/

#include <ansidecl.h>

#define _WRITE_FUNC	0

#include "diskio.h"

#define SPI_REG     0177714
#define SYS_REG     0177716

/* Definitions for MMC/SDC command */
#define CMD0	(0x40+0)	/* GO_IDLE_STATE */
#define CMD1	(0x40+1)	/* SEND_OP_COND (MMC) */
#define	ACMD41	(0xC0+41)	/* SEND_OP_COND (SDC) */
#define CMD8	(0x40+8)	/* SEND_IF_COND */
#define CMD16	(0x40+16)	/* SET_BLOCKLEN */
#define CMD17	(0x40+17)	/* READ_SINGLE_BLOCK */
#define CMD24	(0x40+24)	/* WRITE_BLOCK */
#define CMD55	(0x40+55)	/* APP_CMD */
#define CMD58	(0x40+58)	/* READ_OCR */


/* USI control functions (Defined in usi.S, Platform dependent) */
BYTE xmit_spi PARAMS((BYTE));	    /* Send a byte */

#define rcv_spi() xmit_spi(0377)    /* Send 0xFF and receive a byte */

#define SELECT()      asm("bic $1, *$0177716")
#define DESELECT()    asm("bis $1, *$0177716")

#define MMC_SEL       1
#define INIT_SPI()    {}

BYTE* rbuf = 0;
DWORD rbuflba = 0xffffffffL;

/* Set cache buffer */
void disk_sbuf(bptr)
BYTE* bptr;
{
    rbuf = bptr;
    rbuflba = 0xffffffffL;
}

/*--------------------------------------------------------------------------

   Module Private Functions

---------------------------------------------------------------------------*/

static
BYTE CardType;


/*-----------------------------------------------------------------------*/
/* Deselect the card and release SPI bus                                 */
/*-----------------------------------------------------------------------*/

static
void release_spi ()
{
	DESELECT();
	rcv_spi();
}

static void xmit32(arg) 
DWORD arg;
{
	xmit_spi((BYTE)(arg >> 24));		/* Argument[31..24] */
	xmit_spi((BYTE)(arg >> 16));		/* Argument[23..16] */
	xmit_spi((BYTE)(arg >> 8));			/* Argument[15..8] */
	xmit_spi((BYTE)(arg & 0377));		/* Argument[7..0] */

#if 0
    puts("[");
	printhex((BYTE)(arg >> 24));puts(":");		/* Argument[31..24] */
	printhex((BYTE)(arg >> 16));puts(":");		/* Argument[23..16] */
	printhex((BYTE)(arg >> 8));puts(":");			/* Argument[15..8] */
	printhex((BYTE)(arg & 0377));		/* Argument[7..0] */
    puts("]");
#endif
}

/*-----------------------------------------------------------------------*/
/* Send a command packet to MMC                                          */
/*-----------------------------------------------------------------------*/

static BYTE send_cmd(unsigned char, unsigned long);

static
BYTE send_cmd (
	cmd,		/* Command byte */
	arg		    /* Argument */
)
BYTE cmd;
DWORD arg;
{
	BYTE n, res;

	/* Select the card */
	DESELECT();
	rcv_spi();
	SELECT();
	rcv_spi();

	if (cmd & 0x80) {	/* ACMD<n> is the command sequense of CMD55-CMD<n> */
		cmd &= 0x7F;
		res = send_cmd(CMD55, 0L);
		if (res > 1) return res;
	}

	/* Send a command packet */
	xmit_spi(cmd);						/* Start + Command index */
#if 0
	xmit_spi((BYTE)(arg >> 24));		/* Argument[31..24] */
	xmit_spi((BYTE)(arg >> 16));		/* Argument[23..16] */
	xmit_spi((BYTE)(arg >> 8));			/* Argument[15..8] */
	xmit_spi((BYTE)arg);				/* Argument[7..0] */
#else
    xmit32((DWORD)arg);
#endif
	n = 0x01;							/* Dummy CRC + Stop */
	if (cmd == CMD0) n = 0x95;			/* Valid CRC for CMD0(0) */
	if (cmd == CMD8) n = 0x87;			/* Valid CRC for CMD8(0x1AA) */
	xmit_spi(n);

	/* Receive a command response */
	n = 10;								/* Wait for a valid response in timeout of 10 attempts */
	do {
		res = rcv_spi();
	} while ((res & 0x80) && --n);

    /*puts("c:"); printhex(cmd); puts("r:"); printhex(res); puts(" ");*/

	return res;			/* Return with the response value */
}



/*--------------------------------------------------------------------------

   Public Functions

---------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------*/
/* Initialize Disk Drive                                                 */
/*-----------------------------------------------------------------------*/

DSTATUS disk_initialize ()
{
	BYTE cmd, ty, ocr[4];
	WORD tmr;
    int n;

	INIT_SPI();

#if _WRITE_FUNC
	if (MMC_SEL) disk_writep(0, 0);		/* Finalize write process if it is in progress */
#endif
	for (n = 100; n; n--) rcv_spi();	/* Dummy clocks */

	ty = 0;
	if (send_cmd(CMD0, 0L) == 1) {			/* Enter Idle state */
		if (send_cmd(CMD8, 0x1AAL) == 1) {	/* SDv2 */
			for (n = 0; n < 4; n++) ocr[n] = rcv_spi();		/* Get trailing return value of R7 resp */
			if (ocr[2] == 0x01 && ocr[3] == 0xAA) {				/* The card can work at vdd range of 2.7-3.6V */
#if 0
				for (tmr = 12000; tmr && send_cmd(ACMD41, 1UL << 30); tmr--) ;	/* Wait for leaving idle state (ACMD41 with HCS bit) */
#else
				for (tmr = 12000; tmr && send_cmd(ACMD41, (DWORD)(1L << 30)); tmr--) ;	/* Wait for leaving idle state (ACMD41 with HCS bit) */
#endif
				if (tmr && send_cmd(CMD58, 0L) == 0) {		/* Check CCS bit in the OCR */
					for (n = 0; n < 4; n++) ocr[n] = rcv_spi();
					ty = (ocr[0] & 0x40) ? CT_SD2 | CT_BLOCK : CT_SD2;	/* SDv2 (HC or SC) */
				}
			}
		} else {							/* SDv1 or MMCv3 */
			if (send_cmd(ACMD41, 0L) <= 1) 	{
				ty = CT_SD1; cmd = ACMD41;	/* SDv1 */
			} else {
				ty = CT_MMC; cmd = CMD1;	/* MMCv3 */
			}
			for (tmr = 25000; tmr && send_cmd(cmd, 0L); tmr--) ;	/* Wait for leaving idle state */
			if (!tmr || send_cmd(CMD16, 512L) != 0)			/* Set R/W block length to 512 */
				ty = 0;
		}
	}
	CardType = ty;
	release_spi();
	return ty ? 0 : STA_NOINIT;
}


/*-----------------------------------------------------------------------*/
/* Read partial sector                                                   */
/*-----------------------------------------------------------------------*/

DRESULT disk_readp (
	buff,		/* Pointer to the read buffer (NULL:Read bytes are forwarded to the stream) */
	lba,		/* Sector number (LBA) */
	ofs,		/* Byte offset to read from (0..511) */
	cnt		/* Number of bytes to read (ofs + cnt mus be <= 512) */
)
BYTE *buff;
DWORD lba;
WORD ofs;
WORD cnt;
{
	DRESULT res;
	BYTE rc;
	WORD bc;
    WORD rbidx = 0;

#define NO_INSANELYVERBOSE
#ifdef INSANELYVERBOSE
#endif    
	if (!(CardType & CT_BLOCK)) {
#ifdef INSANELYVERBOSE
        puts("lbain="); printq((DWORD)lba,0);
#endif
        lba *= 512;		/* Convert to byte address if needed */
    }

#ifdef INSANELYVERBOSE
    puts(" lba="); printq((DWORD)lba,1); puts(" o="); printhex(ofs); putchar(' ');
#endif

    /* Use buffered data if any */
    if (rbuf != 0 && lba == rbuflba) {
        do {
            *buff++ = rbuf[ofs++];
        } while (--cnt);
        return RES_OK;
    }

	res = RES_ERROR;
	if (send_cmd(CMD17, (DWORD)lba) == 0) {		/* READ_SINGLE_BLOCK */

		bc = 30000;
		do {							/* Wait for data packet in timeout of 100ms */
			rc = rcv_spi();
		} while (rc == 0xFF && --bc);

		if (rc == 0xFE) {				/* A data packet arrived */
			bc = 514 - ofs - cnt;

			/* Skip leading bytes */
			if (ofs) {
				do { 
                    rc = rcv_spi();
                    if (rbuf) {
                        rbuf[rbidx++] = rc;
                    }
                } while (--ofs);
			}

			/* Receive a part of the sector */
			if (buff) {	/* Store data to the memory */
				do {
                    rc = rcv_spi();
                    if (rbuf) { rbuf[rbidx++] = rc; }
                    *buff++ = rc;
				} while (--cnt);
			} else {	/* Forward data to the outgoing stream (depends on the project) */
				do
					xmit(rcv_spi());	/* (Console output) */
				while (--cnt);
			}

			/* Skip trailing bytes and CRC */
			do { 
                rc = rcv_spi(); 
                if (rbuf) { rbuf[rbidx++] = rc; }
            } while (--bc);

            if (rbuf) rbuflba = lba;

			res = RES_OK;
		}
	}

	release_spi();

	return res;
}



/*-----------------------------------------------------------------------*/
/* Write partial sector                                                  */
/*-----------------------------------------------------------------------*/
#if _WRITE_FUNC

DRESULT disk_writep (
	buff,	    /* Pointer to the bytes to be written (NULL:Initiate/Finalize sector write) */
	sa			/* Number of bytes to send, Sector number (LBA) or zero */
)
const BYTE *buff;
DWORD sa;
{
	DRESULT res;
	WORD bc;
	static WORD wc;


	res = RES_ERROR;

	if (buff) {		/* Send data bytes */
		bc = (WORD)sa;
		while (bc && wc) {		/* Send data bytes to the card */
			xmit_spi(*buff++);
			wc--; bc--;
		}
		res = RES_OK;
	} else {
		if (sa) {	/* Initiate sector write process */
			if (!(CardType & CT_BLOCK)) sa *= 512;	/* Convert to byte address if needed */
			if (send_cmd(CMD24, (DWORD)sa) == 0) {			/* WRITE_SINGLE_BLOCK */
				xmit_spi(0xFF); xmit_spi(0xFE);		/* Data block header */
				wc = 512;							/* Set byte counter */
				res = RES_OK;
			}
		} else {	/* Finalize sector write process */
			bc = wc + 2;
			while (bc--) xmit_spi(0);	/* Fill left bytes and CRC with zeros */
			if ((rcv_spi() & 0x1F) == 0x05) {	/* Receive data resp and wait for end of write process in timeout of 300ms */
				for (bc = 65000; rcv_spi() != 0xFF && bc; bc--) ;	/* Wait ready */
				if (bc) res = RES_OK;
			}
			release_spi();
		}
	}

	return res;
}
#endif
