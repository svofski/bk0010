/* xmit_spi(BYTE b) */

#define SPI_REG    0177714

    .globl _xmit_spi
_xmit_spi:
    mov     r5, -(sp)
    mov     sp, r5
    movb    4(r5), *$ SPI_REG
1:
    mov     *$ SPI_REG, r0
    bit     $0400, r0
    bne     1b

    bic     $0177400, r0

    mov     (sp)+, r5
    rts     pc

