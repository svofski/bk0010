## CPU Modes ##
CPU mode is exposed on `psw` lines bits `[15:14]`, but cannot be seen by software.
|psw`[15:14`]| |
|:-----------|:|
|1 1| User Mode|
|0 0| Kernel Mode|

`psw` bits `[13:12]` contain previous mode. In the current arrangement, previous mode is always a user mode because only a kernel mode command MFPI makes use of this. MPFI is fully functional and can be used to retrieve usermode memory and uSP.

CPU has a copy of SP for each mode: uSP and kSP. All other registers are shared.

CPU starts in Kernel mode. The startup code must set up memory mapping, request switch to User mode by setting appropriate bit in `MMUCTL` register and relay control with an `RTI` instruction.

Re-entering kernel mode is possible when `usermode` CPU line is held low during interrupt acknowledgement cycle (`IAKO` is high), or when a software interrupt is being executed.

The Kernel-key is `ScrollLock` and it is used to invoke the BIN loader. Kernel mode entry through a software interrupt is used by the EMT36 hook.

## Memory Management Control Register (MMUCTL) ##
**177700** Only accessible in kernel mode (0)

| 15 | .. | 3|2|1|0|
|:---|:---|:-|:|:|:|
|     |    | current\_cpumode |cpumode\_req|mmu\_enabled|shadow mode|

  * `current_cpumode` must always read as 0 since this register is only accessible in K-mode
  * `cpumode_req` to switch to usermode, set this bit to "1" and execute RTI/RTT
  * `mmu_enabled` 0: mapping disabled, lower 64K of physical memory are used; 1: mapping enabled
  * `shadow_mode` 1: bootrom is plugged at physical address 0100000 (initial); 0: bootrom is unplugged

Attempting access to this register in user mode will trap through location 4.

## Memory Management Registers ##
**177600** - **177616** KISA0-7<br>
and<br>
<b>177620</b> - <b>177636</b> UISA0-7<br>
Only accessible in kernel mode (0)<br>
<br>
The MMU contains 2 sets of 8 PAR registers: KISA0-KISA7 for kernel instruction space and UISA0-UISA7 for user instruction space.  The physical address is formed from virtual address <code>vadr</code> in the following way:<br>
<ul><li>bits 15:13 of <code>vadr</code> select corresponding KISA or UISA register, PAR<br>
</li><li>physical address = <code> {PAR[14:0] + vadr[12:6], vadr[5:0]} </code>
</li><li>page access mode = <code> PAR[15] </code> (1 = RW, 0 = RO)<br>
Physical address can thus have up to 21 lines, but only 18 are currently used. Pages can't have variable sizes. But they can start anywhere in RAM, with 64-byte granularity.</li></ul>

<table><thead><th> Kernel </th><th> Address  </th><th> Name  </th><th> Virtual page </th><th> </th><th> User </th><th> Address  </th><th> Name  </th><th> Virtual page </th><th> Normal value </th></thead><tbody>
<tr><td>  </td><td> <b>177600</b> </td><td> KISA0 </td><td> 000000 </td><td>  </td><td>  </td><td> <b>177620</b> </td><td> UISA0 </td><td> 000000 </td><td> 100000 </td></tr>
<tr><td>  </td><td> <b>177602</b> </td><td> KISA1 </td><td> 020000 </td><td>  </td><td>  </td><td> <b>177622</b> </td><td> UISA1 </td><td> 020000 </td><td> 100200 </td></tr>
<tr><td>  </td><td> <b>177604</b> </td><td> KISA2 </td><td> 040000 </td><td>  </td><td>  </td><td> <b>177624</b> </td><td> UISA2 </td><td> 040000 </td><td> 100400 </td></tr>
<tr><td>  </td><td> <b>177606</b> </td><td> KISA3 </td><td> 060000 </td><td>  </td><td>  </td><td> <b>177626</b> </td><td> UISA3 </td><td> 060000 </td><td> 100600 </td></tr>
<tr><td>  </td><td> <b>177610</b> </td><td> KISA4 </td><td> 100000 </td><td>  </td><td>  </td><td> <b>177630</b> </td><td> UISA4 </td><td> 100000 </td><td> 001000 </td></tr>
<tr><td>  </td><td> <b>177612</b> </td><td> KISA5 </td><td> 120000 </td><td>  </td><td>  </td><td> <b>177632</b> </td><td> UISA5 </td><td> 120000 </td><td> 001200 </td></tr>
<tr><td>  </td><td> <b>177614</b> </td><td> KISA6 </td><td> 140000 </td><td>  </td><td>  </td><td> <b>177634</b> </td><td> UISA6 </td><td> 140000 </td><td> 001400 </td></tr>
<tr><td>  </td><td> <b>177616</b> </td><td> KISA7 </td><td> 160000 </td><td>  </td><td>  </td><td> <b>177636</b> </td><td> UISA7 </td><td> 160000 </td><td> 001600 </td></tr></tbody></table>

Attempting access to any of the above registers in user mode will trap through location 4.<br>
<br>
<h2>System memory usage</h2>

The system starts up in kernel mode, with mapping disabled and shadow ROM enabled. It is the job of the bootrom to  initialize memory mapping, relocate itself to virtual address 01000, disable shadow and relay control to the regular ROM.<br>
<br>
User mode 64K are mapped linearly to the lowest 64K of physical RAM. Pages that correspond to addresses 100000 and up are tagged as readonly.<br>
<br>
Kernel memory map:<br>
<table><thead><th> Virtual                  </th><th> Physical               </th><th> Description</th></thead><tbody>
<tr><td> 000000 - 037777 </td><td> 200000 - 237777 </td><td> BIN loader/EMT36 </td></tr>
<tr><td> 040000 - 077777 </td><td> 040000 - 077777 </td><td> Frame buffer </td></tr>
<tr><td> 100000 - 117777 </td><td> 100000 - 117777 </td><td> BK-0010 BIOS </td></tr>
<tr><td> 120000 - 157777 </td><td> 000000 - 037777<br>040000 - 077777</td><td> BIN loader destination </td></tr>
<tr><td>                             </td><td> 240000 - 257777 </td><td> Frame buffer save area </td></tr>
<tr><td> 160000 - 177600 </td><td> ... </td><td> Unused</td></tr></tbody></table>

Frame buffer hardware bypasses memory mapper and always uses physical addresses 040000-077777.