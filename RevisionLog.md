Revision names are also Mercurial tags and can be checked out by tag.

## [Rev32](http://code.google.com/p/bk0010/source/browse/?r=Rev32) ##
_June 10, 2010_

Bugfix release.
  * VM1: Added nonexistent opcodes 177xxx, 070xxx-073xxx, 075xxx, 076xxx
  * Loader: doesn't touch EMT36 control block, saves info in addresses 0264, 0266 instead (see [d6.mac](http://code.google.com/p/vak-opensource/source/browse/trunk/bk/bk-0010-sources/d6.mac#771))
  * Automatically append .BIN suffix to file names if file with supplied name fails to open
  * Small usability fixes: handle ESC, longer delay before screen restoration

## [Rev31](http://code.google.com/p/bk0010/source/browse/?r=Rev31) ##
_June 8, 2010_

  * Multiple ROM image support: `M_BASIC.ROM` or `M_FOCAL.ROM` can be selected by holding F1 or F2 at start. `100000.ROM` is no longer used.
  * Cleaner EMT36 handling: nothing gets printed, returns error if file can't be loaded.
  * Loader interface: pagination in directory listing, clever TAB completion.
  * Joystick support
    * Joystick is emulated with numpad:<br><sub>num</sub>8, <sub>num</sub>2, <sub>num</sub>4, <sub>num</sub>6 for the stick<br><sub>num</sub>0, <sub>num</sub>5, <sub>num</sub>/, <sub>num</sub>Enter for the buttons</li></ul>


## [Rev30](http://code.google.com/p/bk0010/source/browse/?r=Rev30) ##
_June 5, 2010_

  * Timer/Counter support
  * Overlay support
    * EMT 36 hook emulates tape loading
    * Files can now be loaded via **M** monitor command for ultimate experience
    * Overlays get loaded by programs automatically, no user interaction required
    * Overlays that load over stack area also work (see MFPI below)
  * Kernel mode automatically Hypercharges the CPU: no need to be slow in SD driver
  * MFPI instruction (move from previous instruction space)
  * 50 MHz core option fixed. Speed optimizations must be on though.
  * Huge files that use screen area can be loaded
  * Project can be now compiled into DE1-compatible .pof programming file

## [Rev29](http://code.google.com/p/bk0010/source/browse/?r=Rev29) ##
_May 30, 2010_

  * SD Bootstrap and .bin file Loader
    * Memory Management
      * A basic MMU capable of 18-bits addressing is implemented. Although it is inspired by the PDP-11 MMU, it differs from the original very much.
      * CPU has the concept of user/kernel mode and keeps two separate stack pointers, but the mode of use is very different:
        * CPU starts in kernel mode: MMU and MMUCTL regs are only accessible in K-mode
        * To switch to usermode, kernel code must set up "user mode request" bit (bit 2) in MMUCTL and execute RTI instruction
        * To switch to kernel mode, hardware generates a keyboard interrupt and pulls low mode request line when IAKO is asserted. This is triggered by ScrollLock superkey.
    * Bootstrap
      * The bootstrap loader is self-contained in a virtual 4Kword (8192 bytes) bootrom module, which gets "shadow" mapped to address 0100000 at startup time. It initializes memory map, copies itself to 01000 in virtual kernel space, loads ROM image, disengages shadow mode and relays control to the BK ROM in user mode.
      * The other part of bootrom works as the bin-loader interface
    * All BK-0010 content must be located in a directory named `BK0010` on a FAT16-formatted SD card. This includes `100000.ROM` and all the .bin files.
    * ROM contents is loaded from file `100000.ROM` after power-on or reset
    * .bin file can be loaded at any time, but it makes sense to load files when the monitor is in control (type MO in Basic)
      * When you see `?` prompt, press ScrollLock. A `File:` prompt will appear.
      * You can type file name now. Pressing Enter with an empty name will list directory.
      * Pressing TAB will list names of all files with names that begin what's being input. If there is only one matching file, the input field will be autocompleted.
      * Press enter, the file will be loaded to the location specified in its header.
      * Ok or Fail will be reported and after a brief pause the screen will be restored and control will be returned to the monitor
      * The program may now be started, usually by entering `S1000`. Many programs autostart after the first keypress.
      * BIN-loader dialog may be aborted at any time by pressing STOP (F12) key
  * Made reset in all clocked datapath registers asynchronous. This remedies most reset problems, but there are more.

## [Rev28](http://code.google.com/p/bk0010/source/browse/?r=Rev28) ##
_May 14, 2010_

  * Reimplemented the RAM and register access cycle (see [Scratchpad](Scratchpad.md))
  * Thanks to the new, cleaner cycle, auto-wait cycles are not necessary now. Everything also works nicely @50MHz without  optimizations for speed; Just in case, the auto-wait-inserting code is left in the default branch, screened by `ifdef-s.
  * Mapped the top row of keyboard keys and some others, see [KeyboardMapping](KeyboardMapping.md)
  * Register access code cleanup in bkcore and lots of small things

## [Rev27](http://code.google.com/p/bk0010/source/browse/?r=Rev27) ##
_May 10, 2010_

My original version of VM1 was made in such a way that it needed two clocks for every cycle, or two phases of one clock. One for control unit, one for the datapath. A kind of stepback from POP11, this effectively divided maximum clock frequency by two.

A couple of weeks ago, I created a project clone to rewrite the CPU. The new version uses a FSM that produces the next state and datapath microinstruction vector as a function of the current state and registered inputs. This saved the need for negedge (microinstruction needs not to be clocked in) and allowed 2x extra time for the signals to settle between the clocks.

The memory exchange cycle is still somewhat quirky and is asynchronous in nature. After switching into the next state, the CPU sets DIN/DOUT, DATA and ADDR signals after the state is switched and skips clocks until REPLY signal is received from RAM or a device. To avoid a condition when the state has changed, but the REPLY signal is still being held, additional WAIT states are inserted automatically whenever such situation happens. I don't like it and this needs to be taken care of later.

With proper peripheral circuitry, the design runs at 50MHz (RAM reply module answers on posedge, skips one clock on every access) and at 25MHz with RAM I/O on negedge (saving one clock) and posedge alike. In a BK-0010 this results in absurdly high execution speeds. The ratio between BK-0010 (my BK, not the real one, which is slower) in the slowest mode of the negedgy version and the fastest mode with the current version is approximately 1:25. The fastest negedgy vs. the fastest posedgy ratio, in the same BK-0010, on same memory-intensive tests is 1:3.

#### Summary ####
  * Fixed scroll register bug that retained bit 8
  * New CPU code runs at up to 50MHz, using only posedge and needs fewer clock cycles than the negedgy
  * The design may be clocked by 25MHz and 50MHz clocks. 50MHz clock requires optimizer to be set for Speed
  * Source tree is branched:
    * [default](http://code.google.com/p/bk0010/source/browse/) branch has the new CPU
    * [negedgy](http://code.google.com/p/bk0010/source/browse/?r=8e7dce10cd55a4c527e2e1dfa6ec3d0e0df912cc) branch keeps the old CPU code that may be easier to read and understand
  * The "hyperdrive" toggle is KEY[3](3.md).

The development is going to continue in the **default**.

## [Rev26](http://code.google.com/p/bk0010/source/browse/?r=Rev26) ##
_April 26, 2010_

After a long hiatus, the project makes a comeback.

  * Awesome HG revision names. Symbolic tag names (like Rev26) don't show up in the changes tree but they exist.
  * Core
    * is clocked by 25 MHz clock. CE signals are derived from screen X, as before. No more derived clocks in the core
  * CPU
    * There's a verilog (Icarus) simulation testbench now, it was used for sorting out many nasty things
    * Fixed many bugs in control and datapath, test 401 passes, test 404 passes until too much peripheral hardware gets involved. Things like interrupt priorities might need to be sorted out yet. Bus cycles are a little vague yet, too.
    * Fixed SWAB instruction. Somehow it got past all CPU tests. FP now works in BASIC.
    * Datapath changed to operate on every other clk instead of former negedge. This requires 2x more enabled clocks for the CPU to operate at the same speed. This is cleaner than doing stuff secretly on negedge, but I'm not sure if this is very good. There's abundance of free cycles in the core anyway, though.
    * One particular nasty in byte-bit in opcode handling is (hopefully) fixed.


  * JTAG
    * just to be always sure JTAG now _only_ works when the CPU is paused (SW7=0)
    * special debug features accessible from the control panel
      * Address 0x8000 (write-only): breakpoint address
      * Adresses 0x8010-0x8017 (read-only): CPU registers [R0](https://code.google.com/p/bk0010/source/detail?r=0)-[R7](https://code.google.com/p/bk0010/source/detail?r=7)
      * Address 0x8018: CPU PS

Big thanks to **Felix Lazarev** for helping me out with _a lot_ of things in this revision.


## Rev.25 ##
  * ported to DE1
  * JTAG -- works but disrupts the CPU workflow, better to reset the CPU after memory upload
  * Added STOP button (F12)
  * AR2 register by Alt modifier
  * sound i/o
  * slowed the CPU down 2x (SW5) -- feels much more like real BK then.
  * a lot of original stuff that was allegedly used for development/debugging is removed or commented out.
  * tape loader works, sort of, but can't load stuff saved by BK/FPGA -- only emulator-generated files can be loaded. Same sound driver works in vector06cc very well.
  * the whole thing experiences some degree of randomness.

## Rev.0 ##
  * initial BK-0010 by Alex Freed. Unchanged source.zip exists in the repository.