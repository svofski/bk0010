CC		= gcc -g -Wall
CFLAGS		= -O
DESTDIR		= /usr/local
PROG		= pdp11-bkbin 

all:		$(PROG)

install:	$(PROG)
		install -s pdp11-bkbin  ${DESTDIR}/bin/pdp11-bkbin

clean:
		rm -f *~ *.o $(PROG)

pdp11-bkbin:	bkbin.o
		$(CC) $(LDFLAGS) -o $@ $<

depend:
		@cp Makefile Makefile~~
		(sed '/^### DO NOT DELETE THIS LINE/,$$d' Makefile;\
		echo '### DO NOT DELETE THIS LINE';\
		gcc -MM $(CFLAGS) *.c |\
		sed ':1;/\.o: .* \\/{;N;s/ *\\\n */ /;};s/ \/[^ ]*h */ /;t1';\
		echo '# DEPENDENCIES MUST END AT END OF FILE';\
		echo '# IF YOU PUT STUFF HERE IT WILL GO AWAY';\
		echo '# see make depend above') > Makefile~ &&\
		mv Makefile~ Makefile

### DO NOT DELETE THIS LINE
ar.o: ar.c ar.h
disasm.o: disasm.c a.out.h
ld.o: ld.c a.out.h ar.h
nm.o: nm.c a.out.h
reloc.o: reloc.c a.out.h
size.o: size.c a.out.h
strip.o: strip.c a.out.h
# DEPENDENCIES MUST END AT END OF FILE
# IF YOU PUT STUFF HERE IT WILL GO AWAY
# see make depend above
