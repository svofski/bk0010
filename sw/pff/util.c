#include <util.h>
#include <pff.h>

int toupper(c)
int c;
{
    if (IsLower(c)) c -= 0x20; /* toupper */
    return c;
}

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

#ifdef PRINTQ 
void printq(q,cr) 
DWORD q; 
int cr; 
{ 
    printhex((WORD)(q>>16)); printhex((WORD)q);  
    if (cr) puts("\n"); 
} 
#endif 

