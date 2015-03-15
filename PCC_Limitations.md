# Introduction #

PCC is a working compiler but it has a lot of quirks, at least the bkunix version of it. They're easy to avoid once they're known.

# Details #

## Prototypes ##
  * ANSI prototypes may work, but they can't accept typedef types
```
    typedef unsigned char BYTE; 

    static int foo(BYTE); /* error */
    static int foo(unsigned char); /* works */
```


## long types ##
  * long can be a function parameter but it needs to be explicitly typecast, even if an ANSI prototype is declared
```
    static void stroke(long);
    ...
 
    somewhere() { 
      long cat = 33L;
      stroke(cat); /* will pass only one half of the cat */
      stroke((long)cat); /* will pass the entire cat */
    }
```
  * a pointer is still a pointer, a pointer to long can be a function argument
  * a function can't return a long, no matter what
  * likewise, some expressions fail to produce long results: avoid ternary operations with longs
  * if (longcat) {} will probably fail, use if (longcat != 0L) {}

## Indexing and more ##
  * a byte-sized variable will act erroneously if used as an index or in pointer expressions. Either use int variables instead, or cast explicitly.
  * `static char* foo = "OH HAI";` — wil llikely be misplaced with something else. Use `char[]`, magically it's more reliable