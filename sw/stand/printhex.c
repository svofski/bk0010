void
phexdigit (val)
{
    val &= 15;
    if (val <= 9)
        val += '0';
    else
        val += 'a' - 10;
    putchar (val);
}

asm (".text");
asm ("_rol4: .globl _rol4");
asm ("mov 2(sp),r0");
asm ("mov r0,r1");
asm ("rol r1");
asm ("rol r0");
asm ("rol r1");
asm ("rol r0");
asm ("rol r1");
asm ("rol r0");
asm ("rol r1");
asm ("rol r0");
asm ("rts pc");



void
printhex (val)
{
	val = rol4 (val);
	phexdigit (val);
	val = rol4 (val);
	phexdigit (val);
	val = rol4 (val);
	phexdigit (val);
	val = rol4 (val);
	phexdigit (val);
}


void
phex8(val)
{
    val = rol4 (val);
    val = rol4 (val);
    val = rol4 (val);
    phexdigit (val);
    val = rol4 (val);
    phexdigit (val);
}

