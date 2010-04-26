module adder(A, B, CI, SUM, CO, VO); 
   input  CI; 
   input [15:0] A; 
   input [15:0] B; 
   output [15:0] SUM; 
   output 	CO,VO; 
   wire [16:0] 	tmp;
   wire [15:0] 	tmp1;
   wire 	v1;
   
   
   assign 	tmp = A + B + CI;
   assign 	tmp1 = A[14:0] + B[14:0] + CI;   
   assign 	SUM = tmp [15:0];   
   assign 	CO  = tmp [16];
   assign 	VO  = tmp1[15] ^ CO;
 	
endmodule

module adder8(A, B, CI, SUM, CO, VO); 
   input  CI; 
   input [7:0] A; 
   input [7:0] B; 
   output [7:0] SUM; 
   output 	CO,VO; 
   wire [8:0] 	tmp;
   wire [7:0] 	tmp1;
   wire 	v1;
   
   
   assign 	tmp = A + B + CI;
   assign 	tmp1 = A[6:0] + B[6:0] + CI;   
   assign 	SUM = tmp [7:0];   
   assign 	CO  = tmp [8];
   assign 	VO  = tmp1[7] ^ CO;
 	
endmodule

module myalu(in1,in2,ni,ci,byte,final_result,final_flags, 
	     add, adc,sub,sbc,inc2,dec2, inc,dec, clr,
	     com,neg,tst,ror,rol,asr,asl,sxt,mov,cmp,bit,bic,bis,exor,swab);
   
   input [15:0] in1;
   input [15:0] in2;
   input 	ni,ci,byte;
   input 	add, adc,sub,sbc,inc2,dec2,inc,dec, clr,com,neg;
   input 	tst,ror,rol,asr,asl,sxt,mov,cmp,bit,bic,bis,exor,swab;
 	
   output [3:0] final_flags;

   output [15:0] final_result;   

   reg [15:0] 	X;
   reg [15:0] 	Y;
   reg 		_ci;
   reg  [3:0] flags;
   reg  [3:0] xflags;
   
   wire [15:0] 	adder_result;
   wire [7:0] 	adder_8_result;

   wire 	co,v,z,n,c08,v8,z8,n8;
   wire 	use_adder;
   
   reg [15:0] 	res;
   wire [15:0] 	bit_res;
   
   
   adder adder(X,Y,_ci, adder_result, co,v);
   adder8 adder8(X[7:0],Y[7:0],_ci, adder_8_result, co8,v8);


   assign z= (adder_result == 0);
   assign z8= (adder_8_result == 0);
   assign n = adder_result[15];
   assign n8 = adder_8_result[7];
   
   assign final_result = (use_adder)? (cmp? 0: adder_result): res;
   assign final_flags = (use_adder)? flags: xflags;
   assign use_adder = (add | adc | sub | sbc | inc | dec |inc2 |dec2 |neg|cmp );
   assign bit_res = in1 & in2;
 
  
//   assign 	Y = in2;
//   assign 	X = add?in1:0;
//   assign 	_ci = add?0:ci;
//   assign 	flags=  {n,z,v,co};
   wire   zero16,zero8;
   assign zero16 = (res==0);
   assign zero8 = (res[7:0] == 0);

   wire   zero16_1,zero8_1;
   assign zero16_1 = (in2==0);
   assign zero8_1 = (in2[7:0] == 0);
   

   always @* begin
      
          if(clr) begin
	     res <= 0;
	     xflags <= 4'b0100;
	  end   
          else
	    if(com) begin
       	       res <= ~in2;
	       if(byte)
		 xflags <= { ~in2[7],zero8, 2'b01};
	       else
		 xflags <= { ~in2[15],zero16, 2'b01};
	    end

          else
	    if(tst) begin
       	       res <= 0;
	       if(byte)
		 xflags <= { in2[7],zero8_1, 2'b00};
	       else
		 xflags <= { in2[15],zero16_1, 2'b00};
	    end
	   else
	      if(ror) begin
		 if(byte) begin
		    res <= {8'b0, ci, in2[7:1]};
		     xflags <= { res[7],zero8, ci^in2[0],in2[0]};
		 end
		 else begin
		    res <= {ci, in2[15:1]};
		     xflags <= { res[15],zero16, ci^in2[0],in2[0]};		    
		 end
	      end
      
	      else 
		if(rol) begin
		 if(byte) begin
		     res = {8'b0, in2[6:0], ci};
		     xflags = { res[7],zero8, ci^in2[7],in2[7]};
		 end
		 else begin
		    res = { in2[14:0],ci};
		     xflags = { res[15],zero16, ci^in2[15],in2[15]};		    
		 end
		end

	      else 
		if(asr) begin
		 if(byte) begin
		    res = {8'b0,in2[7], in2[7:1]};
		    xflags = { res[7],zero8, in2[0]^in2[7],in2[0]};
		 end
		 else begin
		    res = { in2[15],in2[15:1]};
		    xflags = { res[15],zero16, in2[0]^in2[15],in2[0]};
		 end
		end
	      else 
		if(asl) begin
		 if(byte) begin
		    res = {8'b0,in2[6:0], 1'b0};
		    xflags = { res[7],zero8, in2[6]^in2[7],in2[7]};
		 end
		 else begin
		    res = { in2[14:0],1'b0};
		    xflags = { res[15],zero16, in2[14]^in2[15],in2[15]};
		 end
		end

		else 
		  if(sxt) begin
		     if(ni)
		       res = 16'hffff;
		     else
		       res = 16'b0;
		     xflags = { 1'b0,~ni,2'b0};
		  end
      		 else 
		    if(mov) begin
      		       if(byte) begin
			  res =  in2[7]?{8'hff, in2[7:0]}:
				  {8'h00,in2[7:0]};
			  xflags = { res[7],zero8, 2'b0};
		       end
		       
		       else begin
			  res = in2;
 			  xflags = { res[15],zero16, 2'b0};		     
		       end
		    end // if (mov)
      
		  else if(bit) begin
		     res = 0; 
		     if(byte)
			xflags = {bit_res[7] ,(bit_res[7:0]==0)?1'b1:1'b0  ,2'b0};
		     else
		       xflags =  {bit_res[15] ,(bit_res[15:0]==0)?1'b1:1'b0  ,2'b0};
		  end
      
		  else if(bic) begin
		     res = in1 & ~in2; 
		     if(byte)
			xflags = {res[7] ,(res[7:0]==0)?1'b1:1'b0  ,2'b0};
		     else
		       xflags =  {res[15] ,(res[15:0]==0)?1'b1:1'b0  ,2'b0};
		  end
		     
		  else if(bis) begin
		     res = in1 | in2; 
		     if(byte)
			xflags = {res[7] ,(res[7:0]==0)?1'b1:1'b0  ,2'b0};
		     else
		       xflags =  {res[15] ,(res[15:0]==0)?1'b1:1'b0  ,2'b0};
		  end
		  else if(exor) begin
		     res = in1 ^ in2; 
		     xflags =  {res[15] ,(res[15:0]==0)?1'b1:1'b0  ,2'b0};
		  end

		  else if(swab) begin
		     res = {in2[7:0],  in2[15:8]}; 
		     xflags =  {res[7] ,(res[7:0]==0)?1'b1:1'b0  ,2'b0};
		  end
      
		else begin
	    	   res <= 0;
		   xflags <= 0;
		end
      		 
      
   end // always @ *
   

   always @* begin
      if(add) begin
   	X <= in1;	 
   	Y <= in2;
	_ci <= 0;
	 flags <=  {n,z,v,co};	
      end 
      else
	if(adc ) begin
	 X <= 0;	   
	 Y <= in2;
      	_ci <= ci;
	   if(byte) begin
	     flags <=  {n8,z8,v8,co8};
	   end   
	   else  begin
	     flags <=  {n,z,v,co};
	   end
        end
      else
	if(sub ) begin
	 X <= ~in1;	   
	 Y <= in2;
      	_ci <= 1;
	 flags <=  {n,z,v,~co};		   
        end
      else
	if(sbc ) begin
	 X <= 16'hFFFF;	   
	 Y <= in2;
      	_ci <= ~ci;
	   if(byte) begin
	     flags <=  {n8,z8,v8,~co8};
	   end   
	   else  begin
	     flags <=  {n,z,v,~co};
	   end
        end // if (sbc )
	else
	  if(inc2) begin
	     X <= 2;	 
   	     Y <= in2;
	     _ci <= 0;
	     flags <=  0;
	  end 
	else
	  if(dec2) begin
	     X <= in2;
   	     Y <= 'hfffe;
	     _ci <= 0;
	     flags <=  0;
	  end 
	else
	  if(inc) begin
	     X <= 0;	 
   	     Y <= in2;
	     _ci <= 1;
	     if(byte) begin
		flags <=  {n8,z8,v8,1'b0};
	     end   
	     else  begin
		flags <=  {n,z,v,1'b0};
	     end
	  end 
	else
	  if(dec) begin
	     X <= 'hffff;	 
   	     Y <= in2;
	     _ci <= 0;
	     if(byte) begin
		flags <=  {n8,z8,v8,1'b0};
	     end   
	     else  begin
		flags <=  {n,z,v,1'b0};
	     end
	  end // if (dec)
     	       
	else
	  if(neg) begin
	     X <= 'h0000;	 
   	     Y <= ~in2;
	     _ci <= 1;
	     if(byte) begin
		flags <=  {n8,z8,v8,~co8};
	     end   
	     else  begin
		flags <=  {n,z,v,~co};
	     end
	  end // if (neg)
	  else if(cmp) begin
	     X <= ~in1;
	     Y <= in2;
      	     _ci <= 1'b1;
	     if(byte) begin
		flags <=  {n8,z8,v8,~co8};
	     end   
	     else  begin
		flags <=  {n,z,v,~co};
	     end

	  end
      
      
	  else begin
	     X <= 'h0000;	 
   	     Y <= 'h0000;
	     _ci <= 0;
	     flags <= 4'b0;
	  end
        
   end

endmodule 	
   


module testalu;

   reg [15:0] X;
   reg [15:0] Y;
   wire [15:0] result;
   wire [15:0] result1;   
   wire [3:0]  ccmask;
   wire [3:0]  ccout;
   wire [3:0]  ccout1;

   wire        co,z,v,n;
   
   
   reg 	       mmu;
   reg 	       ni,ci,byte;
   wire	       tst,ror,rol,asr,asl, sxt, bit , cmp , mov ,bis , bic;

   wire        add, adc,sub,sbc,inc2,dec2, inc,dec, clr,com,neg,exor,swab;
   
 	       
  reg[15:0] data[0:17];



   reg [24:0] operation ;

   assign   add = operation[0];
   assign    adc = operation[1];
   assign    sub = operation[2];
   assign    sbc = operation[3];
   assign    inc2 = operation[4];
   assign    dec2  = operation[5];
   assign    inc  = operation[6];
   assign    dec = operation[7];
   assign    clr = operation[8];
   assign    com = operation[9];
   assign    neg = operation[10];
   assign    tst = operation[11];
   assign    ror = operation[12];
   assign    rol = operation[13];         
   assign    asr = operation[14];
   assign    asl = operation[15];
   assign    sxt = operation[16];
   assign    mov = operation[17];         
   assign    cmp = operation[18];         
   assign    bit = operation[19];
   assign    bic = operation[20];
   assign    bis = operation[21];
   assign    exor = operation[22];   
   assign    swab = operation[23];   

// VARIABLES NOT RELATED TO I/O , BUT REQUIRED FOR TESTBENCH //
integer  k, jma, cfa, maa,good_ops, tests;

 initial begin  
 //  pick 4 sample data values //
    data[0] = 16'h0000;
    data[1] = 16'h9999;
    data[2] = 16'hcdef;
    data[3] = 16'h1111;
 end
   
   myalu myalu (X,Y,ni,ci,byte, result1,ccout1,add,adc,sub,sbc,inc2,dec2,
		inc,dec, clr,com,neg,tst,ror,rol,asr,asl,sxt,mov,cmp,
		bit,bic,bis,exor,swab);

      
   alu11 alu11 (  .dst(X) , 
		  .src(Y) , 
		  .bi(byte) , 
		  .ci(ci) , 
		  .ni(ni) , 
		  .out(result) , 
		  .ccout(ccout) , 
		  .ccmask(ccmask) , 
		  .cc(cc) , 
		  .swab(swab) , 
		  .sub(sub) , 
		  .add(add) ,
		  .mmu(mmu),
		  .exor(exor),
		  .bis(bis) , .bic(bic) , .bit(bit) , .cmp(cmp) , 
		  .mov(mov) , .sxt(sxt) , .asl(asl) , .asr(asr) , 
		  .rol(rol) , .ror(ror) , .tst(tst) , .sbc(sbc) , 
		  .adc(adc) , .neg(neg) , .com(com) , .clr(clr) , 
		  .dec(dec) , .inc(inc) , .dec2(dec2), .inc2(inc2)
		  );
/*   
bis , bic , bit , cmp , mov , sxt , asl , asr , rol , ror , tst , sbc , adc , neg , com , clr , dec , inc , dec2 , 
*/


   
   initial begin
//      $monitor("X %x Y %x result %x ccmask %x ccout %x", 
//	       X,Y,result,ccmask,ccout);
      X='h1234;
      Y='h5678;
      ni=1;
      ci=1;

      byte = 0;
//      bis=0;
 //     bic=0;
//      bit=0;
//      cmp=0;
//      mov=0;
//      sxt=0;
//      asl=0;
//      asr=0;
//      rol=0;
//      ror=0;
//      tst=0;
//      neg=0;
//      exor = 0;
//      swab = 0;
      mmu = 0;


      operation = 1;
      
      for (tests=0; tests<24;tests=tests+1) begin     
	 // loop through possible  combitnaations of data inputs //
	 $display("Operation: %d %b", tests+1, operation);
	 good_ops = 0;
      
      for (jma=0; jma<=3; jma=jma+1)
	begin
	   X = data[jma];
	   for (cfa=0; cfa<=3; cfa=cfa+1)
	     begin
		Y = data[cfa];

		#10  if((result == result1) & (ccout == ccout1))
//		  $display("OK");
		  good_ops = good_ops+1;
		
		else begin
		   $display("X %x Y %x res %x %x ccm %x ccout %x %x  %x %x %x", 
			    X,Y,result,result1,ccmask,ccout, ccout1, 
			    myalu.X,myalu.Y,myalu._ci);

		   if(result != result1)
		     $display("Result ERROR!");

		   if(ccout != ccout1)
		     $display("flags ERROR!");
		end   
	     end
	   
	end // for (jma=0; jma<=3; jma=jma+1)

      $display("%d OK", good_ops);
      
      //  Y= 'h00FF;
	 operation = {operation[23:0],1'b0};
	 
	 
      end



/*	 
      Y= 'h0100;
      X= 'h0002;
      #10  $display("X %x Y %x result %x %x ccmask %x ccout %x %x  %x %x %x %x", 
		    X,Y,result,result1,ccmask,ccout, ccout1,
		    myalu.X,myalu.Y,myalu._ci,
		    alu11.bi
		    );
  */    
      
   end // initial begin

   initial begin
    $dumpfile("alu.vcd");
    $dumpvars(1, testalu);
    $dumpvars(1, myalu);     
  end

   

endmodule // testalu

   
