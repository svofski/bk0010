#
# Build standalone programs.
#

# Johnson's portable compiler.
CC		= pdp11-pcc

LIBSTAND = ../stand/libstand.a

CFLAGS		= -O
LIBS		= -L. -L/usr/local/lib/pdp11 -L../stand -lpff -lstand -lcrt

# Using ported AT&T UNIX utils.
AS		= pdp11-asm
AR		= pdp11-ar
LD		= pdp11-ld
SIZE		= pdp11-size -o
FSUTIL		= u6-fsutil -F
LDFLAGS		= -X

SRCS		= start.S romstart.S
OBJS		= pff.o mmc.o spi.o
PROG		= hello boot

HIBASE  = 01000
TOPSYS  = 040000
CPPFLAGS	= -I. -DKERNEL -DTOPSYS=$(TOPSYS)

# For BK-0011M model.
#CPPFLAGS	+= -DBK0011
#HIBASE		= 0100000

all:		$(PROG)
		$(SIZE) $(PROG)

clean:
		rm -f *~ *.o *.s *.a *.dis a.out *.bin *.bxx $(PROG)

libpff.a:	$(OBJS)
		@-rm -f $@
		$(AR) cru $@ $(OBJS)

hello:		start.o $(LIBSTAND) libpff.a hello.o
		$(LD) $(LDFLAGS) -a$(HIBASE) -o $@ start.o hello.o $(LIBS)
		pdp11-disasm -a$(HIBASE) $@ > $@.dis
		pdp11-bkbin -a$(HIBASE) $@
		pdp11-bkbin -b -a$(HIBASE) $@

boot:		romstart.o $(LIBSTAND) libpff.a boot.o
		$(LD) $(LDFLAGS) -a$(HIBASE) -o $@ romstart.o $@.o $(LIBS)
		pdp11-disasm -a$(HIBASE) $@ > $@.dis
		pdp11-bkbin -a$(HIBASE) $@
		pdp11-bkbin -b -a$(HIBASE) $@

.c.s:
		$(CC) $(CFLAGS) $(CPPFLAGS) -S $<

depend:
		@cp Makefile Makefile~~
		(sed '/^### DO NOT DELETE THIS LINE/,$$d' Makefile;\
		echo '### DO NOT DELETE THIS LINE';\
		gcc -MM $(CFLAGS) *.S *.c |\
		sed ':1;/\.o: .* \\/{;N;s/ *\\\n */ /;};s/ \/[^ ]*h */ /;t1';\
		echo '# DEPENDENCIES MUST END AT END OF FILE';\
		echo '# IF YOU PUT STUFF HERE IT WILL GO AWAY';\
		echo '# see make depend above') > Makefile~ &&\
		mv Makefile~ Makefile

### DO NOT DELETE THIS LINE
romstart.o: romstart.S
spi.o: spi.S
start.o: start.S
# DEPENDENCIES MUST END AT END OF FILE
# IF YOU PUT STUFF HERE IT WILL GO AWAY
# see make depend above
