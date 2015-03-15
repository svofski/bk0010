

# English Manual #
## Requirements ##

  * Altera/Terasic DE1 board
  * PS/2 Keyboard
  * SD card formatted with FAT16 filesystem
  * A standard VGA monitor
  * Headphones/speakers
  * A PC with Quartus II Web Edition software
  * To work with the sources, you will need Mercurial version control system

## Running BK0010-FPGA for the first time ##
  * Compile the source, or download a compiled bitstream
  * To configure in runtime, use .SOF file, to make the configuration persistent, use .POF.
  * Create a folder called `BK0010` on your FAT16 SD card and put `M_BASIC.ROM` and `M_FOCAL.ROM` in it.
  * Make sure that the rightmost 3 switches are switched up, the rest should be turned down
  * Plug in the peripherals, insert SD card into SD slot on DE1, press `RESET` button (KEY0 is RESET).
  * After a moment you should observe welcoming screen of Vilnus-BASIC
  * Hold F2 key during RESET to load FOCAL.

Enjoy your tiny PDP-11-ish computer. To load real stuff, enter the monitor by typing `MO`.

BIN files can be loaded as if they're loaded from tape (M, Enter, enter file name). Alternatively, `ScrollLock` key invokes an interactive loader. Enter lists complete directory, simple TAB completion for file names works.

Some programs autostart, some require typing `S1000`.

## Troubleshooting ##

If you see an SD icon in the middle of the screen saying “БК”, SD card can't be initialized or the filesystem can't be mounted. Either you have forgotten to insert the card, or it's an SDHC card, or it's formatted with FAT32, or something else is wrong.

If the icon says “ :( ”, it means that the ROM image could not be loaded. Check that you copied the ROM files to the right directory.

## Further Info ##
  * [KeyboardMapping](KeyboardMapping.md)
  * [RevisionLog](RevisionLog.md)
And for the more technical details:
  * [STOP key handling](STOP.md)
  * [BK Timer operation](Timer.md)
  * [memory mapping and CPU modes](Memory_Management.md)