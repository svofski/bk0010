// ==================================================================================
// BK in FPGA
// ----------------------------------------------------------------------------------
//
// A BK-0010 FPGA Replica. VM1 CPU Instruction Decoder.
//
// This project is a work of many people. See file README for further information.
//
// Based on the original BK-0010 code by Alex Freed.
// ==================================================================================

//
// PDP-11 instruction decoder by Alex Freed
//
module myidc ( p_reset , m_clock , do , idc_opc , unused , cco , bra , nof ,
	       rsd , dop , sop , dmfps , dmtps , dspl , dsub ,
	       dtrap , demt , dsob , dexor , 
	       dadd , dbis , dbic , dbit , dcmp , dmov , 
	       dsxt , 
	       dmtpi , dmfpi , dmark , dasl , dasr , drol , dror , dtst , dsbc , 
	       dadc , 
	       dneg , ddec , dinc , dcom , dclr , djsr , dswab , dnop , drts , 
	       djmp , drtt , dreset , diot , dbpt , drti , diwait , dhalt );


   input p_reset, m_clock;
   input do;
   input [15:0] idc_opc;
   
   output 	unused;
   output 	cco;
   output 	bra;
   output 	nof;
   output 	rsd;
   output 	dop;
   output 	sop;
   output 	dmfps;
   output 	dmtps;
   output 	dspl; //10
   output 	dsub;
   output 	dtrap;//
   output 	demt;
   output 	dsob;
   output 	dexor;
   output 	dadd;//
   output 	dbis;
   output 	dbic;
   output 	dbit;
   output 	dcmp;
   output 	dmov;
   output 	dsxt;
   output 	dmtpi;
   output 	dmfpi;
   output 	dmark; //25 from bottom
   output 	dasl;
   output 	dasr;
   output 	drol;
   output 	dror;
   output 	dtst;
   output 	dsbc;
   output 	dadc;
   output 	dneg;
   output 	ddec;
   output 	dinc;
   output 	dcom;
   output 	dclr;
   output 	djsr;
   output 	dswab;
   output 	dnop;
   output 	drts;
   output 	djmp;
   output 	drtt;
   output 	dreset;
   output 	diot;
   output 	dbpt;
   output 	drti;
   output 	diwait;
   output 	dhalt;


   wire [2:0] 	double_op;
   wire [5:0] 	single_op;
   wire 	byte_flag;
   wire 	branches;
   wire 	not_double;
 	
 	

   assign 	byte_flag =  idc_opc[15];   
   assign 	double_op =  idc_opc[14:12];
   assign 	single_op =  idc_opc[11:6];

   assign  	not_double = (double_op == 3'b000);
   
      
   assign 	dmov = (double_op == 3'b001);
   assign 	dcmp = (double_op == 3'b010);
   assign 	dbit = (double_op == 3'b011);
   assign 	dbic = (double_op == 3'b100);
   assign 	dbis = (double_op == 3'b101);
   assign 	dadd = (double_op == 3'b110) & ~byte_flag ;
   assign 	dsub = (double_op == 3'b110) & byte_flag ;


   assign 	dswab = (not_double & (single_op == 3) & ~byte_flag);
   assign 	djmp = not_double & (single_op == 1) & ~byte_flag;
   assign 	drts = not_double & (single_op == 'o02) & ~byte_flag & 
		(idc_opc[5:3] == 0);
   assign 	dspl = not_double & (single_op == 'o02) & ~byte_flag &
		(idc_opc[5:3] == 3'o3);
   
   assign 	branches = not_double & (single_op == 3) & byte_flag;   

   assign 	dclr = not_double & (single_op == 'o050);
   assign 	dcom = not_double & (single_op == 'o051);
   assign 	dinc = not_double & (single_op == 'o052);
   assign 	ddec = not_double & (single_op == 'o053);
   assign 	dneg = not_double & (single_op == 'o054);
   assign 	dadc = not_double & (single_op == 'o055);
   assign 	dsbc = not_double & (single_op == 'o056);
   assign 	dtst = not_double & (single_op == 'o057);   
   assign 	dror = not_double & (single_op == 'o060);
   assign 	drol = not_double & (single_op == 'o061);
   assign 	dasr = not_double & (single_op == 'o062);
   assign 	dasl = not_double & (single_op == 'o063);

   assign 	dmark = ~byte_flag & not_double & (single_op == 'o064);
   assign 	dmfpi = ~byte_flag & not_double & (single_op == 'o065);
   assign 	dmtpi = ~byte_flag & not_double & (single_op == 'o066);
   assign 	dsxt  = ~byte_flag & not_double & (single_op == 'o067);   
   

   assign 	drtt = (idc_opc[15:0])==({1'b0,15'b000000000000110});
   assign 	dreset = (idc_opc[15:0])==({1'b0,15'b000000000000101});
   assign 	diot = (idc_opc[15:0])==({1'b0,15'b000000000000100});
   assign 	dbpt = (idc_opc[15:0])==({1'b0,15'b000000000000011});
   assign 	drti = (idc_opc[15:0])==({1'b0,15'b000000000000010});
   assign 	diwait = (idc_opc[15:0])==({1'b0,15'b000000000000001});
   assign 	dhalt = (idc_opc[15:0])==({1'b0,15'b000000000000000});
   assign 	dnop = (idc_opc[15:0])==(16'o0240);

   assign 	djsr = (idc_opc[15:9])==(7'o04);

   
   
   assign 	sop = ~(double_op == 3'b000) & ~nof;

   assign 	dop = ((double_op == 3'b000) & ~nof)  | djmp | djsr | drts
		| dclr |  dcom | dinc | ddec | dneg | dadc | dsbc | dtst |  dror
		| drol | dasr |  dasl | dmfpi;
      
		
   assign 	nof = (drtt | dreset | diot | dbpt | drti | diwait | dhalt | 
		       dtrap | dnop | dspl | dmark | dsob |demt );

   assign 	cco = ((idc_opc[15:4])==({{1'b0,9'b000000010},2'b10}))
   &(|(idc_opc[3:0])) | (idc_opc[15:4])==({{1'b0,9'b000000010},2'b11});
   
   assign 	bra = ((idc_opc[15:11])==({{1'b0,3'b000},1'b0}))
   &(|(idc_opc[10:8])) | (idc_opc[15:11])==({{1'b1,3'b000},1'b0});

   assign 	dexor = (idc_opc[15:9] == 'o074);
   
   assign 	rsd = dexor;
   assign 	dmtps = (idc_opc[15:6])==({1'b1,9'b000110100});
   assign 	dmfps = byte_flag & not_double & (single_op == 'o067);
   //assign 	dsub = 	idc_opc[15:12]=={1'b1,3'b110};
   assign       dtrap =	((idc_opc[15:9])==({1'b1,6'b000100}))&(idc_opc[8]);
   assign       demt =	((idc_opc[15:9])==({1'b1,6'b000100}))&(~idc_opc[8]);
   assign 	dsob = (idc_opc[15:9])==({1'b0,6'b111111});
endmodule // myidc
