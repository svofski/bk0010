#ifndef _UTIL_H
#define _UTIL_H

#define abs(x) ((x) > 0 ? (x):-(x))

/*!int toupper(int c);
 *
 * convert character to uppercase
 */
int toupper();

/*!pputs(char *s, int width)
 *
 * print string and pad to specified width with spaces
 */
void pputs();

/*!int strprefx(char *s1, char *s2);
 *
 * Return true if s1 is a prefix of s2 
 */
int strprefx();

/*!void strcpy(char* s1, char *s2);
 * 
 * Copy contents of s2 to s1, \0 included.
 */
void strcpy();


#ifdef PRINTQ
void printq();
#endif

#endif
