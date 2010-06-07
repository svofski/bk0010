#ifdef BK0011
#define BIOS_GETC() (((int(*)()) *(int*) 0140076) ())
#define BIOS_PUTC() (((void(*)()) *(int*) 0140156) ())
#else
#define BIOS_GETC() (((int(*)()) 0101010) ())
#define BIOS_PUTC() (((void(*)()) 0102234) ())
#endif

int
getchar ()
{
    register int c;

	asm ("mov r5,-(sp)");
	c = BIOS_GETC();
	asm ("mov (sp)+,r5");
	return c;
}

int
putchar (c)
        int c;
{
again:
	asm ("mov 4(r5),r0");
	asm ("mov r5,-(sp)");
	BIOS_PUTC();
	asm ("mov (sp)+,r5");
	if (c == '\n') {
		c = '\r';
		goto again;
	}
}

void
puts (str)
	char *str;
{
	while (*str)
		putchar (*str++);
}
