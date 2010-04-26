module capture(res,clk25,cap_addr,cap_dat,flags,cap_wr,read_cap_l,cap_rd, cap_rd_sel);
	input res, clk25;
    input [15:0] cap_addr;
    input [15:0] cap_dat;
    input [3:0] flags;
    input cap_wr;
    output [7:0] read_cap_l;
    reg [7:0] read_cap_l;
    wire [7:0] read_cap;
    
    input cap_rd;
    input [2:0] cap_rd_sel;


    wire logic0, logic1;
    assign logic0 = 0;
    assign logic1 = 1;

    reg [8:0] capt_address;
    reg [8:0] read_address;
    wire [31:0] mem_input;
    wire [31:0] mem_output;
    wire [3:0] DOPB;

    reg [2:0] read_state;    
    reg [2:0] read_state_next;
    
    reg [1:0] one_shot_rd;
    wire starting_rd;
    wire done_rd_data;

    wire reading_addr, reading_data, reading_flags;
    assign reading_addr = cap_rd & (cap_rd_sel[2:1] == 2'b00); // regs 8 and 9
    assign reading_data = cap_rd & (cap_rd_sel == 3'b010); // regs 10
    assign reading_read_addr = cap_rd & ((cap_rd_sel == 3) | (cap_rd_sel == 4)); // regs 11 and 12
    //assign reading_flags  = cap_rd & (cap_rd_sel[1] == 1'b1);

   always @ (posedge clk25 or posedge res) begin
      if (res == 1)
         one_shot_rd <= 2'b00;
      else
         one_shot_rd <= {one_shot_rd[0], reading_data};
   end

   assign starting_rd = one_shot_rd[0] & ~one_shot_rd[1];
   assign done_rd_data =  ~one_shot_rd[0] & one_shot_rd[1];


    always @ (posedge clk25 or posedge res ) begin
    		if(res ) begin
    			read_state <= 0;
		end
		else	begin
			if(done_rd_data)
				read_state <= read_state_next;
		end
	end
	
	//or posedge res
	always @ (posedge clk25 ) begin
		if(res | reading_addr) begin
			read_address <= capt_address -1 ;
		//	read_address <= 0;
		end
		else if(done_rd_data & (read_state == 4)) 
			read_address <= read_address - 1;
		//else read_address <= read_address;	
	end	 	


	always @(read_state or read_state_next  ) begin
	  //if(reading_addr) begin
	//		   	read_state_next <= 0;
	//  end  else 
	//begin
	    	case (read_state)
	   		0:  read_state_next <= 1;
			1:  read_state_next <= 2;
			2:  read_state_next <= 3;
			3:  read_state_next <= 4;
			4:  read_state_next <= 0;
			default: 
				read_state_next <= 0;
		endcase
	  //end 
	 end 		      

    assign mem_input = {cap_dat, cap_addr}; // low word is addr 

    always @(negedge cap_wr or posedge res) begin
    		if (res)
			capt_address <= 0;
		else
			capt_address <= capt_address + 1;
	end
			  


	always @(negedge clk25 ) begin
		if(starting_rd | reading_addr | reading_read_addr)
			read_cap_l <= read_cap;
	end

	 assign read_cap = (cap_rd_sel == 0)? capt_address[7:0]:
	 			(cap_rd_sel == 1)? {7'b0,  capt_address[8]}:
				(cap_rd_sel == 3)?   read_address[7:0]:
				(cap_rd_sel == 4)?   { 2'b0, read_state, 3'b0, read_address[8]}:
				(reading_data & (read_state == 0))? mem_output[7:0]:
				(reading_data & (read_state == 1))? mem_output[15:8]:
				(reading_data & (read_state == 2))? mem_output[23:16]:
				(reading_data & (read_state == 3))? mem_output[31:24]:
				(reading_data & (read_state == 4))? {4'b0, DOPB} : 0;

    RAMB16_S36_S36 RAMB16_S36_S36_inst (
      //.DOA(DOA),      // Port A 32-bit Data Output
      .DOB(mem_output),      // Port B 32-bit Data Output
//      .DOPA(DOPA),    // Port A 4-bit Parity Output
      .DOPB(DOPB),    // Port B 4-bit Parity Output
      .ADDRA(capt_address),  // Port A 9-bit Address Input
      .ADDRB(read_address),  // Port B 9-bit Address Input
      .CLKA(clk25),    // Port A Clock
      .CLKB(clk25),    // Port B Clock
      .DIA(mem_input),      // Port A 32-bit Data Input
//      .DIB(DIB),      // Port B 32-bit Data Input
      .DIPA(flags),    // Port A 4-bit parity Input
//      .DIPB(DIPB),    // Port-B 4-bit parity Input
      .ENA(cap_wr),      // Port A RAM Enable Input
      .ENB(reading_data),      // PortB RAM Enable Input
      .SSRA(res),    // Port A Synchronous Set/Reset Input
      .SSRB(res),    // Port B Synchronous Set/Reset Input
      .WEA(logic1),      // Port A Write Enable Input
      .WEB(logic0)       // Port B Write Enable Input
   );


endmodule

