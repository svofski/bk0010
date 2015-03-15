## Memory Cycle ##
```
always @(posedge clk_cpu or posedge reset_in) begin: _ramcycle
    if (reset_in) begin
        {cpu_oe_n,cpu_we_n} <= 2'b11;
        ram_reply <= 0;
    end else begin
        if (ce_cpu) begin
            ram_reply <= 0;
            cpu_oe_n <= (~cpu_rd) | ram_reply | ~cpu_oe_n;  
            cpu_we_n <= (~cpu_wt) | ram_reply | ~cpu_we_n;
        end else begin
            {cpu_oe_n,cpu_we_n} <= 2'b11;
        end
        
        if (~cpu_oe_n) begin
            latched_ram_data <= ram_a_data;
            ram_reply <= 1;
        end else if (~cpu_we_n) begin
            ram_reply <= 1;
        end 
    end
end
```

![http://bk0010.googlecode.com/hg/doc/012721.png?r=d3f6231d211d295598332ab3bf6837c05624cec2&wtf.png](http://bk0010.googlecode.com/hg/doc/012721.png?r=d3f6231d211d295598332ab3bf6837c05624cec2&wtf.png)
(from newclock branch)

## Shadowing ##
1. Boot configuration
| Addr   | Normal state| Boot state  | Bin loading|
|:-------|:------------|:------------|:-----------|
| 000000 | ...         |
| 001000 | RAM         | R:Shadow BOOT | R:Shadow BOOT |
|        |             | W:RAM | W:RAM           |
| 040000 | Display RAM |
| 100000 | ROM         | W:Selectable page | ROM |
| 120000 | ROM         | RW:Shadow BSS+Stack    | RW:Shadow BSS+Stack |
| 140000 | ROM         | ROM (page)  | ROM |
| 177600 | Registers   |

### Initial boot ###
Program in shadow ROM @ 01000, Shadow RAM mapped to 0120000.
8K window in area 0100000-0120000 maps to one of the pages: 0100000, 0120000, 0140000, 0160000. Boot program flips the pages as it loads the ROMs. After bootstrap is complete, shadow mode is reset and system is booted from 0100000.

### BIN loading ###
Program in shadow ROM @ 01000, Shadow RAM mapped to 0120000 and used for BSS and stack. The loader program may now use monitor EMTs to implement its user interface. BINs get loaded into regular RAM. Escape from shadow mode... not sure yet