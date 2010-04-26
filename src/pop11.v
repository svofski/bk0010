
module data11 ( p_reset , m_clock , dbi , psw , opc , dba , dbo , swab , exor , sub , add , bis , bic , bit , cmp , mov , sxt , asl , asr , rol , ror , tst , sbc , adc , neg , com , clr , dec , inc , dec2 , inc2 , setPCrom , dbiFP , FPpc , save_stat , adrPC , SRCadr , DSTadr , SELpc , SELsrc , SELdst , ALUcc , ALUsrc , ALUdstb , ALUdst , ALUsp , ALUpc , PCreg , DSTreg , ALUreg , setReg2 , setReg , regSEL2 , regSEL , selALU1 , ofs6ALU2 , ofs8ALU2 , srcALU2 , dstALU2 , srcALU1 , dstALU1 , spALU1 , pcALU1 , dboAdr , dboDst , dboSEL , dbaAdr , dbaSrc , dbaDst , dbaSP , dbaPC , dbiPS , dbiReg , dbiPC , dbiSrc , dbiDst , setopc , my_mtps , vectorPS , reset_byte , change_opr , cctaken , ccset , segerr , svc , iot , emt , bpt , err , buserr , ccget , spl , out_alucc , taken );
 input p_reset, m_clock;
   wire _net_47;
  wire _net_46;
  wire _net_45;
  wire _net_44;
  wire _net_43;
  wire _net_42;
  wire _net_41;
  wire _net_40;
  wire _net_39;
  wire _net_38;
  wire _net_37;
  wire _net_36;
  wire _net_35;
  wire _net_34;
  wire _net_33;
  wire _net_32;
  wire _net_31;
  wire _net_30;
  wire _net_29;
  wire _net_28;
  wire _net_27;
  wire _net_26;
  wire _net_25;
  wire _net_24;
  wire _net_23;
  wire _net_22;
  wire _net_21;
  wire _net_20;
  wire _net_19;
  wire _net_18;
  wire _net_17;
  wire _net_16;
  wire _net_15;
  wire _net_14;
  wire _net_13;
  wire _net_12;
  wire _net_11;
  wire _net_10;
  wire _net_9;
  wire _net_8;
  wire _net_7;
  wire [15:0] _alu_src;
  wire [15:0] _alu_dst;
  wire _alu_ni;
  wire _alu_ci;
  wire _alu_bi;
  wire [15:0] _alu_out;
  wire [3:0] _alu_ccmask;
  wire [3:0] _alu_ccout;
  wire _alu_cc;
  wire _alu_inc2;
  wire _alu_dec2;
  wire _alu_inc;
  wire _alu_dec;
  wire _alu_clr;
  wire _alu_com;
  wire _alu_neg;
  wire _alu_adc;
  wire _alu_sbc;
  wire _alu_tst;
  wire _alu_ror;
  wire _alu_rol;
  wire _alu_asr;
  wire _alu_asl;
  wire _alu_sxt;
  wire _alu_mov;
  wire _alu_cmp;
  wire _alu_bit;
  wire _alu_bic;
  wire _alu_bis;
  wire _alu_add;
  wire _alu_sub;
  wire _alu_exor;
  wire _alu_swab;
  wire [15:0] REGin;
  wire [15:0] REGsel;
  wire [15:0] ALU2;
  wire [15:0] ALU1;
  reg fc;
  reg fv;
  reg fz;
  reg fn;
  reg trapbit;
  reg [2:0] priority;
  reg [1:0] pmode;
  reg [1:0] cmode;
  reg [15:0] ADR;
  reg [15:0] DST;
  reg [15:0] SRC;
  reg [14:0] OPC;
  reg OPC_BYTE;
  reg [15:0] kSP;
  reg [15:0] R5;
  reg [15:0] R4;
  reg [15:0] R3;
  reg [15:0] R2;
  reg [15:0] R1;
  reg [15:0] R0;
  reg [15:0] PC;

input [15:0] dbi;
output [7:0] psw;
output [15:0] opc;
output [15:0] dba;
output [15:0] dbo;
input swab;
input exor;
input sub;
input add;
input bis;
input bic;
input bit;
input cmp;
input mov;
input sxt;
input asl;
input asr;
input rol;
input ror;
input tst;
input sbc;
input adc;
input neg;
input com;
input clr;
input dec;
input inc;
input dec2;
input inc2;
input setPCrom;
input dbiFP;
input FPpc;
input save_stat;
input adrPC;
input SRCadr;
input DSTadr;
input SELpc;
input SELsrc;
input SELdst;
input ALUcc;
input ALUsrc;
input ALUdstb;
input ALUdst;
input ALUsp;
input ALUpc;
input PCreg;
input DSTreg;
input ALUreg;
input setReg2;
input setReg;
input regSEL2;
input regSEL;
input selALU1;
input ofs6ALU2;
input ofs8ALU2;
input srcALU2;
input dstALU2;
input srcALU1;
input dstALU1;
input spALU1;
input pcALU1;
input dboAdr;
input dboDst;
input dboSEL;
input dbaAdr;
input dbaSrc;
input dbaDst;
input dbaSP;
input dbaPC;
input dbiPS;
input dbiReg;
input dbiPC;
input dbiSrc;
input dbiDst;
input setopc;
input my_mtps;
input vectorPS;
input reset_byte;
input change_opr;
input cctaken;
input ccset;
input segerr;
input svc;
input iot;
input emt;
input bpt;
input err;
input buserr;
input ccget;
input spl;
output [3:0] out_alucc;
output taken;

/*   
alu11 alu (.p_reset(p_reset), .m_clock(m_clock), .swab(_alu_swab), 
.exor(_alu_exor), .sub(_alu_sub), .add(_alu_add), .bis(_alu_bis), 
.bic(_alu_bic), .bit(_alu_bit), .cmp(_alu_cmp), .mov(_alu_mov), 
.sxt(_alu_sxt), .asl(_alu_asl), .asr(_alu_asr), .rol(_alu_rol), 
.ror(_alu_ror), .tst(_alu_tst), .sbc(_alu_sbc), .adc(_alu_adc), 
.neg(_alu_neg), .com(_alu_com), .clr(_alu_clr), .dec(_alu_dec), 
.inc(_alu_inc), .dec2(_alu_dec2), .inc2(_alu_inc2), .cc(_alu_cc), 
.ccout(_alu_ccout), .ccmask(_alu_ccmask), .out(_alu_out), 
.bi(_alu_bi), .ci(_alu_ci), .ni(_alu_ni), .dst(_alu_dst), 
.src(_alu_src));
   
*/

myalu alu (.swab(_alu_swab), 
.exor(_alu_exor), .sub(_alu_sub), .add(_alu_add), .bis(_alu_bis), 
.bic(_alu_bic), .bit(_alu_bit), .cmp(_alu_cmp), .mov(_alu_mov), 
.sxt(_alu_sxt), .asl(_alu_asl), .asr(_alu_asr), .rol(_alu_rol), 
.ror(_alu_ror), .tst(_alu_tst), .sbc(_alu_sbc), .adc(_alu_adc), 
.neg(_alu_neg), .com(_alu_com), .clr(_alu_clr), .dec(_alu_dec), 
.inc(_alu_inc), .dec2(_alu_dec2), .inc2(_alu_inc2), .cc(_alu_cc), 
.final_flags(_alu_ccout), .ccmask(_alu_ccmask), .final_result(_alu_out), 
.byte(_alu_bi), .ci(_alu_ci), .ni(_alu_ni), .in1(_alu_dst), 
.in2(_alu_src));


   assign _net_47 = ~OPC_BYTE;
   assign _net_46 = (OPC[8:6])==(3'b000);
   assign _net_45 = (OPC[8:6])==(3'b001);
   assign _net_44 = (OPC[8:6])==(3'b010);
   assign _net_43 = (OPC[8:6])==(3'b011);
   assign _net_42 = (OPC[8:6])==(3'b100);
   assign _net_41 = (OPC[8:6])==(3'b101);
   assign _net_40 = (OPC[8:6])==(3'b111);
   assign _net_39 = (OPC[8:6])==(3'b110);
   assign _net_38 = (OPC[2:0])==(3'b000);
   assign _net_37 = (OPC[2:0])==(3'b001);
   assign _net_36 = (OPC[2:0])==(3'b010);
   assign _net_35 = (OPC[2:0])==(3'b011);
   assign _net_34 = (OPC[2:0])==(3'b100);
   assign _net_33 = (OPC[2:0])==(3'b101);
   assign _net_32 = (OPC[2:0])==(3'b111);
   assign _net_31 = (OPC[2:0])==(3'b110);
   assign _net_30 = (OPC[8:6])==(3'b000);
   assign _net_29 = (OPC[8:6])==(3'b001);
   assign _net_28 = (OPC[8:6])==(3'b010);
   assign _net_27 = (OPC[8:6])==(3'b011);
   assign _net_26 = (OPC[8:6])==(3'b100);
   assign _net_25 = (OPC[8:6])==(3'b101);
   assign _net_24 = (OPC[8:6])==(3'b111);
   assign _net_23 = (OPC[8:6])==(3'b110);
   assign _net_22 = (OPC[2:0])==(3'b000);
   assign _net_21 = (OPC[2:0])==(3'b001);
   assign _net_20 = (OPC[2:0])==(3'b010);
   assign _net_19 = (OPC[2:0])==(3'b011);
   assign _net_18 = (OPC[2:0])==(3'b100);
   assign _net_17 = (OPC[2:0])==(3'b101);
   assign _net_16 = (OPC[2:0])==(3'b111);
   assign _net_15 = (OPC[2:0])==(3'b110);
   assign _net_14 = OPC[3];
   assign _net_13 = OPC[2];
   assign _net_12 = OPC[1];
   assign _net_11 = OPC[0];
   assign _net_10 = _alu_ccmask[3];
   assign _net_9 = _alu_ccmask[2];
   assign _net_8 = _alu_ccmask[1];
   assign _net_7 = _alu_ccmask[0];
   assign _alu_src = ((sub|swab|exor|add|bis|bic|bit|cmp|mov|sxt|asl|asr|rol|ror|tst|sbc|adc|neg|com|clr|dec|inc|dec2|inc2)?ALU1:16'b0);
   assign _alu_dst = ((sub|exor|add|bis|bic|bit|cmp)?ALU2:16'b0);
   assign _alu_ni = fn;
   assign _alu_ci = fc;
   assign _alu_bi = OPC_BYTE;
   assign _alu_inc2 = inc2;
   assign _alu_dec2 = dec2;
   assign _alu_inc = inc;
   assign _alu_dec = dec;
   assign _alu_clr = clr;
   assign _alu_com = com;
   assign _alu_neg = neg;
   assign _alu_adc = adc;
   assign _alu_sbc = sbc;
   assign _alu_tst = tst;
   assign _alu_ror = ror;
   assign _alu_rol = rol;
   assign _alu_asr = asr;
   assign _alu_asl = asl;
   assign _alu_sxt = sxt;
   assign _alu_mov = mov;
   assign _alu_cmp = cmp;
   assign _alu_bit = bit;
   assign _alu_bic = bic;
   assign _alu_bis = bis;
   assign _alu_add = add;
   assign _alu_sub = sub;
   assign _alu_exor = exor;
   assign _alu_swab = swab;
   assign REGin = (PCreg?PC:16'b0)|
	(DSTreg?DST:16'b0)|
	(ALUreg?_alu_out:16'b0)|
	(dbiReg?dbi:16'b0);
   assign REGsel = (((regSEL2&_net_30)|(regSEL&_net_22))?R0:16'b0)|
	(((regSEL2&_net_29)|(regSEL&_net_21))?R1:16'b0)|
	(((regSEL2&_net_28)|(regSEL&_net_20))?R2:16'b0)|
	(((regSEL2&_net_27)|(regSEL&_net_19))?R3:16'b0)|
	(((regSEL2&_net_26)|(regSEL&_net_18))?R4:16'b0)|
	(((regSEL2&_net_25)|(regSEL&_net_17))?R5:16'b0)|
	(((regSEL2&_net_24)|(regSEL&_net_16))?PC:16'b0)|
	(((regSEL2&_net_23)|(regSEL&_net_15))?kSP:16'b0);
   assign ALU2 = (ofs6ALU2?{8'b00000000,{1'b0,opc[5:0]},1'b0}:16'b0)|
	(ofs8ALU2?{{{opc[7],opc[7],opc[7],opc[7],opc[7],opc[7],opc[7]},opc[7:0]},1'b0}:16'b0)|
	(srcALU2?SRC:16'b0)|
	(dstALU2?DST:16'b0);
   assign ALU1 = (selALU1?REGsel:16'b0)|
	(srcALU1?SRC:16'b0)|
	(dstALU1?DST:16'b0)|
	(spALU1?kSP:16'b0)|
	(pcALU1?PC:16'b0);
   assign taken = (cctaken?(((((((({OPC_BYTE,OPC[10:9]})==(3'b000))|((({OPC_BYTE,OPC[10:9]})==(3'b001))&((~(OPC[8]))^fz)))|((({OPC_BYTE,OPC[10:9]})==(3'b010))&((~(OPC[8]))^(fn^fv))))|((({OPC_BYTE,OPC[10:9]})==(3'b011))&((~(OPC[8]))^((fn^fv)|fz))))|((({OPC_BYTE,OPC[10:9]})==(3'b100))&((~(OPC[8]))^fn)))|((({OPC_BYTE,OPC[10:9]})==(3'b101))&((~(OPC[8]))^(fc|fz))))|((({OPC_BYTE,OPC[10:9]})==(3'b110))&((~(OPC[8]))^fv)))|((({OPC_BYTE,OPC[10:9]})==(3'b111))&((~(OPC[8]))^fc)):1'b0);
   assign out_alucc = (ccget?_alu_ccout:4'b0);
   assign psw = {{{{{priority,trapbit},fn},fz},fv},fc};
   assign opc = {OPC_BYTE,OPC};
   assign dba = (dbaAdr?ADR:16'b0)|
	(dbaSrc?SRC:16'b0)|
	(dbaDst?DST:16'b0)|
	(dbaSP?kSP:16'b0)|
	(dbaPC?PC:16'b0);
   assign dbo = (dboAdr?ADR:16'b0)|
	(dboDst?DST:16'b0)|
	(dboSEL?REGsel:16'b0);
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 fc <= 1'b0;
else if (vectorPS|dbiPS)
	  fc <= dbi[0];
else if (ccset&_net_11)
	  fc <= OPC[4];
else if (ALUcc&_net_7)
	  fc <= _alu_ccout[0];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 fv <= 1'b0;
else if (vectorPS|dbiPS)
	  fv <= dbi[1];
else if (ccset&_net_12)
	  fv <= OPC[4];
else if (ALUcc&_net_8)
	  fv <= _alu_ccout[1];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 fz <= 1'b0;
else if (vectorPS|dbiPS)
	  fz <= dbi[2];
else if (ccset&_net_13)
	  fz <= OPC[4];
else if (ALUcc&_net_9)
	  fz <= _alu_ccout[2];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 fn <= 1'b0;
else if (vectorPS|dbiPS)
	  fn <= dbi[3];
else if (ccset&_net_14)
	  fn <= OPC[4];
else if (ALUcc&_net_10)
	  fn <= _alu_ccout[3];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 trapbit <= 1'b0;
else if (vectorPS|dbiPS)
	  trapbit <= dbi[4];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 priority <= 3'b000;
else if (vectorPS|dbiPS|my_mtps)
	  priority <= dbi[7:5];
else if (spl)
	  priority <= OPC[2:0];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 pmode <= 2'b00;
else if (dbiPS)
	  pmode <= dbi[13:12];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 cmode <= 2'b00;
else if (dbiPS)
	  cmode <= dbi[15:14];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 ADR <= 16'b0000000000000000;
else if (SRCadr)
	  ADR <= SRC;
else if (DSTadr)
	  ADR <= DST;
else if (save_stat)
	  ADR <= PC;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 DST <= 16'b0000000000000000;
else if (SELdst)
	  DST <= REGsel;
else if (ALUdstb&OPC_BYTE)
	  DST <= {DST[15:8],_alu_out[7:0]};
else if ((ALUdstb&_net_47)|ALUdst)
	  DST <= _alu_out;
else if (save_stat)
	  DST <= {{{{{{{{cmode,pmode},4'b0000},priority},trapbit},fn},fz},fv},fc};
else if (dbiDst)
	  DST <= dbi;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 SRC <= 16'b0000000000000000;
else if (svc)
	  SRC <= {1'b0,15'b000000000011100};
else if (iot)
	  SRC <= {1'b0,15'b000000000010000};
else if (emt)
	  SRC <= {1'b0,15'b000000000011000};
else if (bpt)
	  SRC <= {1'b0,15'b000000000001100};
else if (err)
	  SRC <= {1'b0,15'b000000000001000};
else if (segerr)
	  SRC <= {1'b0,15'b000000010101000};
else if (buserr)
	  SRC <= {1'b0,15'b000000000000100};
else if (SELsrc)
	  SRC <= REGsel;
else if (ALUsrc)
	  SRC <= _alu_out;
else if (dbiSrc)
	  SRC <= dbi;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 OPC <= 15'b000000000000000;
else if (change_opr)
	  OPC <= {{OPC[14:12],OPC[5:0]},OPC[11:6]};
else if (setopc)
	  OPC <= dbi[14:0];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 OPC_BYTE <= 1'b0;
else if (reset_byte)
	  OPC_BYTE <= 1'b0;
else if (setopc)
	  OPC_BYTE <= dbi[15];
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 kSP <= 16'b0000000000000000;
else if (ALUsp)
	  kSP <= _alu_out;
else if ((setReg2&_net_39)|(setReg&_net_31))
	  kSP <= REGin;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 R5 <= 16'b0000000000000000;
else if ((setReg2&_net_41)|(setReg&_net_33))
	  R5 <= REGin;
else if (dbiFP)
	  R5 <= dbi;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 R4 <= 16'b0000000000000000;
else if ((setReg2&_net_42)|(setReg&_net_34))
	  R4 <= REGin;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 R3 <= 16'b0000000000000000;
else if ((setReg2&_net_43)|(setReg&_net_35))
	  R3 <= REGin;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 R2 <= 16'b0000000000000000;
else if ((setReg2&_net_44)|(setReg&_net_36))
	  R2 <= REGin;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 R1 <= 16'b0000000000000000;
else if ((setReg2&_net_45)|(setReg&_net_37))
	  R1 <= REGin;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 R0 <= 16'b0000000000000000;
else if ((setReg2&_net_46)|(setReg&_net_38))
	  R0 <= REGin;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 PC <= 16'b0000000000000000;
else if (adrPC)
	  PC <= ADR;
else if (SELpc)
	  PC <= REGsel;
else if (ALUpc)
	  PC <= _alu_out;
else if (FPpc)
	  PC <= R5;
else if ((setReg2&_net_40)|(setReg&_net_32))
	  PC <= REGin;
else if (dbiPC)
	  PC <= dbi;
else if (setPCrom)
	  PC <= 16'b1000000000000000;
end
/* The sfl2vl by Naohiko Shimizu generated this module. */
/* Without valid license, you are only allowed to use generated module for educational and/or your personal projects.  */
endmodule

module idc ( p_reset , m_clock , do , idc_opc , unused , cco , bra , nof , rsd , dop , sop , dmfps , dmtps , dspl , dfloat , dsub , dmtpd , dmfpd , dtrap , demt , dsob , dfdiv , dfmul , dfsub , dfadd , dexor , dashc , dash , ddiv , dmul , dadd , dbis , dbic , dbit , dcmp , dmov , dsxt , dmtpi , dmfpi , dmark , dasl , dasr , drol , dror , dtst , dsbc , dadc , dneg , ddec , dinc , dcom , dclr , djsr , dswab , dnop , drts , djmp , drtt , dreset , diot , dbpt , drti , diwait , dhalt );
 input p_reset, m_clock;
   wire _net_112;
  wire _net_111;
  wire _net_110;
  wire _net_109;
  wire _net_108;
  wire _net_107;
  wire _net_106;
  wire _net_105;
  wire _net_104;
  wire _net_103;
  wire _net_102;
  wire _net_101;
  wire _net_100;
  wire _net_99;
  wire _net_98;
  wire _net_97;
  wire _net_96;
  wire _net_95;
  wire _net_94;
  wire _net_93;
  wire _net_92;
  wire _net_91;
  wire _net_90;
  wire _net_89;
  wire _net_88;
  wire _net_87;
  wire _net_86;
  wire _net_85;
  wire _net_84;
  wire _net_83;
  wire _net_82;
  wire _net_81;
  wire _net_80;
  wire _net_79;
  wire _net_78;
  wire _net_77;
  wire _net_76;
  wire _net_75;
  wire _net_74;
  wire _net_73;
  wire _net_72;
  wire _net_71;
  wire _net_70;
  wire _net_69;
  wire _net_68;
  wire _net_67;
  wire _net_66;
  wire _net_65;
  wire _net_64;
  wire _net_63;
  wire _net_62;
  wire _net_61;
  wire _net_60;
  wire _net_59;
  wire _net_58;
  wire _net_57;
  wire _net_56;
  wire _net_55;
  wire _net_54;
  wire _net_53;
  wire _net_52;
  wire _net_51;
  wire _net_50;
  wire _net_49;
  wire _net_48;

input do;
input [15:0] idc_opc;
output unused;
output cco;
output bra;
output nof;
output rsd;
output dop;
output sop;
output dmfps;
output dmtps;
output dspl;
output dfloat;
output dsub;
output dmtpd;
output dmfpd;
output dtrap;
output demt;
output dsob;
output dfdiv;
output dfmul;
output dfsub;
output dfadd;
output dexor;
output dashc;
output dash;
output ddiv;
output dmul;
output dadd;
output dbis;
output dbic;
output dbit;
output dcmp;
output dmov;
output dsxt;
output dmtpi;
output dmfpi;
output dmark;
output dasl;
output dasr;
output drol;
output dror;
output dtst;
output dsbc;
output dadc;
output dneg;
output ddec;
output dinc;
output dcom;
output dclr;
output djsr;
output dswab;
output dnop;
output drts;
output djmp;
output drtt;
output dreset;
output diot;
output dbpt;
output drti;
output diwait;
output dhalt;
   assign _net_112 = (idc_opc[15:0])==({1'b0,15'b000000000000000});
   assign _net_111 = (idc_opc[15:0])==({1'b0,15'b000000000000001});
   assign _net_110 = (idc_opc[15:0])==({1'b0,15'b000000000000010});
   assign _net_109 = (idc_opc[15:0])==({1'b0,15'b000000000000011});
   assign _net_108 = (idc_opc[15:0])==({1'b0,15'b000000000000100});
   assign _net_107 = (idc_opc[15:0])==({1'b0,15'b000000000000101});
   assign _net_106 = (idc_opc[15:0])==({1'b0,15'b000000000000110});
   assign _net_105 = (idc_opc[15:0])==({1'b0,15'b000000000000111});
   assign _net_104 = (idc_opc[15:6])==({1'b0,9'b000000001});
   assign _net_103 = (idc_opc[15:3])==({1'b0,12'b000000010000});
   assign _net_102 = (idc_opc[15:3])==({1'b0,12'b000000010001});
   assign _net_101 = (idc_opc[15:3])==({1'b0,12'b000000010010});
   assign _net_100 = (idc_opc[15:3])==({1'b0,12'b000000010011});
   assign _net_99 = ((idc_opc[15:4])==({{1'b0,9'b000000010},2'b10}))&(~(|(idc_opc[3:0])));
   assign _net_98 = ((idc_opc[15:4])==({{1'b0,9'b000000010},2'b10}))&(|(idc_opc[3:0]));
   assign _net_97 = (idc_opc[15:4])==({{1'b0,9'b000000010},2'b11});
   assign _net_96 = (idc_opc[15:6])==({1'b0,9'b000000011});
   assign _net_95 = ((idc_opc[15:11])==({{1'b0,3'b000},1'b0}))&(|(idc_opc[10:8]));
   assign _net_94 = (idc_opc[15:11])==({{1'b1,3'b000},1'b0});
   assign _net_93 = (idc_opc[15:9])==({1'b0,6'b000100});
   assign _net_92 = (idc_opc[14:6])==(9'b000101000);
   assign _net_91 = (idc_opc[14:6])==(9'b000101001);
   assign _net_90 = (idc_opc[14:6])==(9'b000101010);
   assign _net_89 = (idc_opc[14:6])==(9'b000101011);
   assign _net_88 = (idc_opc[14:6])==(9'b000101100);
   assign _net_87 = (idc_opc[14:6])==(9'b000101101);
   assign _net_86 = (idc_opc[14:6])==(9'b000101110);
   assign _net_85 = (idc_opc[14:6])==(9'b000101111);
   assign _net_84 = (idc_opc[14:6])==(9'b000110000);
   assign _net_83 = (idc_opc[14:6])==(9'b000110001);
   assign _net_82 = (idc_opc[14:6])==(9'b000110010);
   assign _net_81 = (idc_opc[14:6])==(9'b000110011);
   assign _net_80 = (idc_opc[15:6])==({1'b0,9'b000110100});
   assign _net_79 = (idc_opc[15:6])==({1'b0,9'b000110101});
   assign _net_78 = (idc_opc[15:6])==({1'b0,9'b000110110});
   assign _net_77 = (idc_opc[15:6])==({1'b0,9'b000110111});
   assign _net_76 = (idc_opc[15:9])==({1'b0,6'b000111});
   assign _net_75 = (idc_opc[14:12])==(3'b001);
   assign _net_74 = (idc_opc[14:12])==(3'b010);
   assign _net_73 = (idc_opc[14:12])==(3'b011);
   assign _net_72 = (idc_opc[14:12])==(3'b100);
   assign _net_71 = (idc_opc[14:12])==(3'b101);
   assign _net_70 = (idc_opc[15:12])==({1'b0,3'b110});
   assign _net_69 = (idc_opc[15:12])==({1'b1,3'b110});
   assign _net_68 = (idc_opc[15:9])==({1'b0,6'b111000});
   assign _net_67 = (idc_opc[15:9])==({1'b0,6'b111001});
   assign _net_66 = (idc_opc[15:9])==({1'b0,6'b111010});
   assign _net_65 = (idc_opc[15:9])==({1'b0,6'b111011});
   assign _net_64 = (idc_opc[15:9])==({1'b0,6'b111100});
   assign _net_63 = (idc_opc[15:3])==({1'b0,12'b111101000000});
   assign _net_62 = (idc_opc[15:3])==({1'b0,12'b111101000001});
   assign _net_61 = (idc_opc[15:3])==({1'b0,12'b111101000010});
   assign _net_60 = (idc_opc[15:3])==({1'b0,12'b111101000011});
   assign _net_59 = (idc_opc[15:5])==({{1'b0,9'b111101000},1'b1});
   assign _net_58 = ((idc_opc[15:9])==({1'b0,6'b111101}))&(|(idc_opc[8:6]));
   assign _net_57 = (idc_opc[15:9])==({1'b0,6'b111110});
   assign _net_56 = (idc_opc[15:9])==({1'b0,6'b111111});
   assign _net_55 = ((idc_opc[15:9])==({1'b1,6'b000100}))&(~(idc_opc[8]));
   assign _net_54 = ((idc_opc[15:9])==({1'b1,6'b000100}))&(idc_opc[8]);
   assign _net_53 = (idc_opc[15:6])==({1'b1,9'b000110100});
   assign _net_52 = (idc_opc[15:6])==({1'b1,9'b000110101});
   assign _net_51 = (idc_opc[15:6])==({1'b1,9'b000110110});
   assign _net_50 = (idc_opc[15:6])==({1'b1,9'b000110111});
   assign _net_49 = (idc_opc[15:9])==({1'b1,6'b000111});
   assign _net_48 = (idc_opc[15:12])==({1'b1,3'b111});
   assign dmtps = do&_net_53;
   assign dspl = do&_net_100;
   assign dfloat = do&_net_48;
   assign dsub = do&_net_69;
   assign dmtpd = do&_net_51;
   assign dmfpd = (do&_net_52)|(do&_net_50);
   assign dtrap = do&_net_54;
   assign demt = do&_net_55;
   assign dsob = do&_net_56;
   assign dfdiv = do&_net_60;
   assign dfmul = do&_net_61;
   assign dfsub = do&_net_62;
   assign dfadd = do&_net_63;
   assign dexor = do&_net_64;
   assign dashc = do&_net_65;
   assign dash = do&_net_66;
   assign ddiv = do&_net_67;
   assign dmul = do&_net_68;
   assign dadd = do&_net_70;
   assign dbis = do&_net_71;
   assign dbic = do&_net_72;
   assign dbit = do&_net_73;
   assign dcmp = do&_net_74;
   assign dmov = do&_net_75;
   assign dsxt = do&_net_77;
   assign dmtpi = do&_net_78;
   assign dmfpi = do&_net_79;
   assign dmark = do&_net_80;
   assign dasl = do&_net_81;
   assign dasr = do&_net_82;
   assign drol = do&_net_83;
   assign dror = do&_net_84;
   assign dtst = do&_net_85;
   assign dsbc = do&_net_86;
   assign dadc = do&_net_87;
   assign dneg = do&_net_88;
   assign ddec = do&_net_89;
   assign dinc = do&_net_90;
   assign dcom = do&_net_91;
   assign dclr = do&_net_92;
   assign djsr = do&_net_93;
   assign dswab = do&_net_96;
   assign dnop = do&_net_99;
   assign drts = do&_net_103;
   assign djmp = do&_net_104;
   assign drtt = do&_net_106;
   assign dreset = do&_net_107;
   assign diot = do&_net_108;
   assign dbpt = do&_net_109;
   assign drti = do&_net_110;
   assign diwait = do&_net_111;
   assign dhalt = do&_net_112;
   assign unused = (do&_net_105)|(do&_net_102)|(do&_net_101)|(do&_net_76)|(do&_net_59)|(do&_net_58)|(do&_net_57)|(do&_net_49);
   assign cco = (do&_net_98)|(do&_net_97);
   assign bra = (do&_net_95)|(do&_net_94);
   assign nof = (do&_net_112)|(do&_net_111)|(do&_net_110)|(do&_net_109)|(do&_net_108)|(do&_net_107)|(do&_net_106)|(do&_net_105)|(do&_net_102)|(do&_net_101)|(do&_net_100)|(do&_net_99)|(do&_net_80)|(do&_net_76)|(do&_net_59)|(do&_net_58)|(do&_net_57)|(do&_net_56)|(do&_net_55)|(do&_net_54)|(do&_net_52)|(do&_net_51)|(do&_net_49)|(do&_net_48);
   assign rsd = (do&_net_68)|(do&_net_67)|(do&_net_66)|(do&_net_65)|(do&_net_64)|(do&_net_63)|(do&_net_62)|(do&_net_61)|(do&_net_60);
   assign dop = (do&_net_104)|(do&_net_103)|(do&_net_96)|(do&_net_93)|(do&_net_92)|(do&_net_91)|(do&_net_90)|(do&_net_89)|(do&_net_88)|(do&_net_87)|(do&_net_86)|(do&_net_85)|(do&_net_84)|(do&_net_83)|(do&_net_82)|(do&_net_81)|(do&_net_79)|(do&_net_78)|(do&_net_77);
   assign sop = (do&_net_75)|(do&_net_74)|(do&_net_73)|(do&_net_72)|(do&_net_71)|(do&_net_70)|(do&_net_69)|(do&_net_50);
/* The sfl2vl by Naohiko Shimizu generated this module. */
/* Without valid license, you are only allowed to use generated module for educational and/or your personal projects.  */
endmodule

module pop11 ( p_reset , m_clock , dati , dato , adrs , fault , error , rdy , irq_in , wt , rd , byte , int_ack , pswout , inst );
   parameter _state_trap__trap0 = 0;
  parameter _state_trap__trap1 = 1;
  parameter _state_trap__trap2 = 2;
  parameter _state_trap__trap3 = 3;
  parameter _state_trap__trap4 = 4;
  parameter _state_wb__wb_s0 = 0;
  parameter _state_ifetch__if0 = 0;
  parameter _state_ifetch__id0 = 1;
  parameter _state_ifetch__of0 = 2;
  parameter _state_ifetch__of1 = 3;
  parameter _state_ifetch__of2 = 4;
  parameter _state_ifetch__of3 = 5;
  parameter _state_ifetch__of4 = 6;
  parameter _state_ifetch__cc0 = 7;
  parameter _state_ifetch__br0 = 8;
  parameter _state_ifetch__my0 = 9;
  parameter _state_ifetch__my1 = 10;
input p_reset, m_clock;
   wire _net_252;
  wire _net_251;
  wire _net_250;
  wire _net_249;
  wire _net_248;
  wire _net_247;
  wire _net_246;
  reg [2:0] _stage_trap_state_reg;
  wire _net_245;
  wire _net_244;
  wire _net_243;
  wire _net_242;
  wire _net_241;
  wire _net_240;
  wire _net_239;
  wire _net_238;
  wire _net_237;
  reg _stage_wb_state_reg;
  wire _net_236;
  wire _net_235;
  wire _net_234;
  wire _net_233;
  wire _net_232;
  reg _stage_ex_state_reg;
  wire _net_231;
  wire _net_230;
  wire _net_229;
  wire _net_228;
  wire _net_227;
  wire _net_226;
  wire _net_225;
  wire _net_224;
  wire _net_223;
  wire _net_222;
  wire _net_221;
  wire _net_220;
  wire _net_219;
  wire _net_218;
  wire _net_217;
  wire _net_216;
  wire _net_215;
  wire _net_214;
  wire _net_213;
  wire _net_212;
  wire _net_211;
  wire _net_210;
  wire _net_209;
  wire _net_208;
  wire _net_207;
  wire _net_206;
  wire _net_205;
  wire _net_204;
  wire _net_203;
  wire _net_202;
  wire _net_201;
  wire _net_200;
  wire _net_199;
  wire _net_198;
  wire _net_197;
  wire _net_196;
  wire _net_195;
  wire _net_194;
  wire _net_193;
  wire _net_192;
  wire _net_191;
  wire _net_190;
  wire _net_189;
  wire _net_188;
  wire _net_187;
  wire _net_186;
  wire _net_185;
  wire _net_184;
  wire _net_183;
  wire _net_182;
  wire _net_181;
  wire _net_180;
  wire _net_179;
  wire _net_178;
  wire _net_177;
  wire _net_176;
  wire _net_175;
  wire _net_174;
  reg [3:0] _stage_ifetch_state_reg;
  wire _net_173;
  wire _net_172;
  wire _net_171;
  wire _net_170;
  wire _net_169;
  wire _net_168;
  wire _net_167;
  wire _net_166;
  wire _net_165;
  wire _net_164;
  wire _net_163;
  wire _net_162;
  wire _net_161;
  wire _net_160;
  wire _net_159;
  wire _net_158;
  wire _net_157;
  wire _net_156;
  wire _net_155;
  wire _net_154;
  wire _net_153;
  wire _net_152;
  wire _net_151;
  wire _net_150;
  wire _net_149;
  wire _net_148;
  wire _net_147;
  wire _net_146;
  wire _net_145;
  wire _net_144;
  wire _net_143;
  wire _net_142;
  wire _net_141;
  wire _net_140;
  wire _net_139;
  wire _net_138;
  wire _net_137;
  wire _net_136;
  wire _net_135;
  wire _net_134;
  wire _net_133;
  wire _net_132;
  wire _net_131;
  wire _net_130;
  wire _net_129;
  wire _net_128;
  wire _net_127;
  wire _net_126;
  wire _net_125;
  wire _net_124;
  wire _net_123;
  wire _net_122;
  wire _net_121;
  wire _net_120;
  wire _net_119;
  wire _net_118;
  wire _net_117;
  wire _net_116;
  wire _net_115;
  wire _net_114;
  wire _net_113;
  wire _task_trap_int_req_set;
  reg _task_trap_int_req;
  wire _task_trap_int_svc_set;
  reg _task_trap_int_svc;
  wire _task_trap_trace_set;
  reg _task_trap_trace;
  reg _stage_trap;
  wire _stage_trap_reset;
  wire _stage_trap_set;
  wire _task_wb_run_set;
  reg _task_wb_run;
  reg _stage_wb;
  wire _stage_wb_reset;
  wire _stage_wb_set;
  wire _task_ex_tsk0_set;
  reg _task_ex_tsk0;
  wire _task_ex_tsk1_set;
  reg _task_ex_tsk1;
  wire _task_ex_tsk2_set;
  reg _task_ex_tsk2;
  reg _stage_ex;
  wire _stage_ex_reset;
  wire _stage_ex_set;
  wire _task_ifetch_run_set;
  reg _task_ifetch_run;
  wire _task_ifetch_src_op_set;
  reg _task_ifetch_src_op;
  wire _task_ifetch_dst_op_set;
  reg _task_ifetch_dst_op;
  reg _stage_ifetch;
  wire _stage_ifetch_reset;
  wire _stage_ifetch_set;
  wire _id_do;
  wire [15:0] _id_idc_opc;
  wire _id_sop;
  wire _id_dop;
  wire _id_rsd;
  wire _id_nof;
  wire _id_bra;
  wire _id_cco;
  wire _id_unused;
  wire _id_dhalt;
  wire _id_diwait;
  wire _id_drti;
  wire _id_dbpt;
  wire _id_diot;
  wire _id_dreset;
  wire _id_drtt;
  wire _id_djmp;
  wire _id_drts;
  wire _id_dnop;
  wire _id_dswab;
  wire _id_djsr;
  wire _id_dclr;
  wire _id_dcom;
  wire _id_dinc;
  wire _id_ddec;
  wire _id_dneg;
  wire _id_dadc;
  wire _id_dsbc;
  wire _id_dtst;
  wire _id_dror;
  wire _id_drol;
  wire _id_dasr;
  wire _id_dasl;
  wire _id_dmark;
  wire _id_dmfpi;
  wire _id_dmtpi;
  wire _id_dsxt;
  wire _id_dmov;
  wire _id_dcmp;
  wire _id_dbit;
  wire _id_dbic;
  wire _id_dbis;
  wire _id_dadd;
  wire _id_dmul;
  wire _id_ddiv;
  wire _id_dash;
  wire _id_dashc;
  wire _id_dexor;
  wire _id_dfadd;
  wire _id_dfsub;
  wire _id_dfmul;
  wire _id_dfdiv;
  wire _id_dsob;
  wire _id_demt;
  wire _id_dtrap;
  wire _id_dmfpd;
  wire _id_dmtpd;
  wire _id_dsub;
  wire _id_dfloat;
  wire _id_dspl;
  wire _id_dmtps;
  wire _id_dmfps;
  wire [15:0] _dp_dbi;
  wire [15:0] _dp_dbo;
  wire [15:0] _dp_dba;
  wire [15:0] _dp_opc;
  wire [7:0] _dp_psw;
  wire _dp_my_mtps;
  wire _dp_inc2;
  wire _dp_dec2;
  wire _dp_inc;
  wire _dp_dec;
  wire _dp_clr;
  wire _dp_com;
  wire _dp_neg;
  wire _dp_adc;
  wire _dp_sbc;
  wire _dp_tst;
  wire _dp_ror;
  wire _dp_rol;
  wire _dp_asr;
  wire _dp_asl;
  wire _dp_sxt;
  wire _dp_mov;
  wire _dp_cmp;
  wire _dp_bit;
  wire _dp_bic;
  wire _dp_bis;
  wire _dp_add;
  wire _dp_sub;
  wire _dp_exor;
  wire _dp_swab;
  wire _dp_setopc;
  wire _dp_dbiDst;
  wire _dp_dbiSrc;
  wire _dp_dbiPC;
  wire _dp_dbiReg;
  wire _dp_dbiPS;
  wire _dp_dbaPC;
  wire _dp_dbaSP;
  wire _dp_dbaDst;
  wire _dp_dbaSrc;
  wire _dp_dbaAdr;
  wire _dp_dboSEL;
  wire _dp_dboDst;
  wire _dp_dboAdr;
  wire _dp_pcALU1;
  wire _dp_spALU1;
  wire _dp_dstALU1;
  wire _dp_srcALU1;
  wire _dp_dstALU2;
  wire _dp_srcALU2;
  wire _dp_ofs8ALU2;
  wire _dp_ofs6ALU2;
  wire _dp_selALU1;
  wire _dp_regSEL;
  wire _dp_regSEL2;
  wire _dp_setReg;
  wire _dp_setReg2;
  wire _dp_ALUreg;
  wire _dp_DSTreg;
  wire _dp_PCreg;
  wire _dp_ALUpc;
  wire _dp_ALUsp;
  wire _dp_ALUdst;
  wire _dp_ALUdstb;
  wire _dp_ALUsrc;
  wire _dp_ALUcc;
  wire _dp_SELdst;
  wire _dp_SELsrc;
  wire _dp_SELpc;
  wire _dp_DSTadr;
  wire _dp_SRCadr;
  wire _dp_adrPC;
  wire _dp_save_stat;
  wire _dp_FPpc;
  wire _dp_dbiFP;
  wire _dp_setPCrom;
  wire _dp_change_opr;
  wire _dp_reset_byte;
  wire _dp_vectorPS;
  wire _dp_ccset;
  wire _dp_cctaken;
  wire _dp_buserr;
  wire _dp_err;
  wire _dp_bpt;
  wire _dp_emt;
  wire _dp_iot;
  wire _dp_svc;
  wire _dp_segerr;
  wire _dp_spl;
  wire _dp_ccget;
  wire [3:0] _dp_out_alucc;
  wire _dp_taken;
  wire byte_sel;
  reg rsub;
  reg st2;
  reg st1;
  reg st0;
  wire s2;
  wire s1;
  wire s0;
  wire decop;
  wire write;
  wire read;
  wire svcall;
  wire wback;
  wire ifrun;
  wire start;

input [15:0] dati;
output [15:0] dato;
output [15:0] adrs;
input fault;
input error;
input rdy;
input irq_in;
output wt;
output rd;
output byte;
output int_ack;
output [7:0] pswout;
output inst;
data11 dp (.p_reset(p_reset), .m_clock(m_clock), .taken(_dp_taken), .out_alucc(_dp_out_alucc), .ccget(_dp_ccget), .spl(_dp_spl), .segerr(_dp_segerr), .svc(_dp_svc), .iot(_dp_iot), .emt(_dp_emt), .bpt(_dp_bpt), .err(_dp_err), .buserr(_dp_buserr), .cctaken(_dp_cctaken), .ccset(_dp_ccset), .vectorPS(_dp_vectorPS), .reset_byte(_dp_reset_byte), .change_opr(_dp_change_opr), .setPCrom(_dp_setPCrom), .dbiFP(_dp_dbiFP), .FPpc(_dp_FPpc), .save_stat(_dp_save_stat), .adrPC(_dp_adrPC), .SRCadr(_dp_SRCadr), .DSTadr(_dp_DSTadr), .SELpc(_dp_SELpc), .SELsrc(_dp_SELsrc), .SELdst(_dp_SELdst), .ALUcc(_dp_ALUcc), .ALUsrc(_dp_ALUsrc), .ALUdstb(_dp_ALUdstb), .ALUdst(_dp_ALUdst), .ALUsp(_dp_ALUsp), .ALUpc(_dp_ALUpc), .PCreg(_dp_PCreg), .DSTreg(_dp_DSTreg), .ALUreg(_dp_ALUreg), .setReg2(_dp_setReg2), .setReg(_dp_setReg), .regSEL2(_dp_regSEL2), .regSEL(_dp_regSEL), .selALU1(_dp_selALU1), .ofs6ALU2(_dp_ofs6ALU2), .ofs8ALU2(_dp_ofs8ALU2), .srcALU2(_dp_srcALU2), .dstALU2(_dp_dstALU2), .srcALU1(_dp_srcALU1), .dstALU1(_dp_dstALU1), .spALU1(_dp_spALU1), .pcALU1(_dp_pcALU1), .dboAdr(_dp_dboAdr), .dboDst(_dp_dboDst), .dboSEL(_dp_dboSEL), .dbaAdr(_dp_dbaAdr), .dbaSrc(_dp_dbaSrc), .dbaDst(_dp_dbaDst), .dbaSP(_dp_dbaSP), .dbaPC(_dp_dbaPC), .dbiPS(_dp_dbiPS), .dbiReg(_dp_dbiReg), .dbiPC(_dp_dbiPC), .dbiSrc(_dp_dbiSrc), .dbiDst(_dp_dbiDst), .setopc(_dp_setopc), .swab(_dp_swab), .exor(_dp_exor), .sub(_dp_sub), .add(_dp_add), .bis(_dp_bis), .bic(_dp_bic), .bit(_dp_bit), .cmp(_dp_cmp), .mov(_dp_mov), .sxt(_dp_sxt), .asl(_dp_asl), .asr(_dp_asr), .rol(_dp_rol), .ror(_dp_ror), .tst(_dp_tst), .sbc(_dp_sbc), .adc(_dp_adc), .neg(_dp_neg), .com(_dp_com), .clr(_dp_clr), .dec(_dp_dec), .inc(_dp_inc), .dec2(_dp_dec2), .inc2(_dp_inc2), .my_mtps(_dp_my_mtps), .psw(_dp_psw), .opc(_dp_opc), .dba(_dp_dba), .dbo(_dp_dbo), .dbi(_dp_dbi));
idc id (.p_reset(p_reset), .m_clock(m_clock), .dmfps(_id_dmfps), .dmtps(_id_dmtps), .dspl(_id_dspl), .dfloat(_id_dfloat), .dsub(_id_dsub), .dmtpd(_id_dmtpd), .dmfpd(_id_dmfpd), .dtrap(_id_dtrap), .demt(_id_demt), .dsob(_id_dsob), .dfdiv(_id_dfdiv), .dfmul(_id_dfmul), .dfsub(_id_dfsub), .dfadd(_id_dfadd), .dexor(_id_dexor), .dashc(_id_dashc), .dash(_id_dash), .ddiv(_id_ddiv), .dmul(_id_dmul), .dadd(_id_dadd), .dbis(_id_dbis), .dbic(_id_dbic), .dbit(_id_dbit), .dcmp(_id_dcmp), .dmov(_id_dmov), .dsxt(_id_dsxt), .dmtpi(_id_dmtpi), .dmfpi(_id_dmfpi), .dmark(_id_dmark), .dasl(_id_dasl), .dasr(_id_dasr), .drol(_id_drol), .dror(_id_dror), .dtst(_id_dtst), .dsbc(_id_dsbc), .dadc(_id_dadc), .dneg(_id_dneg), .ddec(_id_ddec), .dinc(_id_dinc), .dcom(_id_dcom), .dclr(_id_dclr), .djsr(_id_djsr), .dswab(_id_dswab), .dnop(_id_dnop), .drts(_id_drts), .djmp(_id_djmp), .drtt(_id_drtt), .dreset(_id_dreset), .diot(_id_diot), .dbpt(_id_dbpt), .drti(_id_drti), .diwait(_id_diwait), .dhalt(_id_dhalt), .unused(_id_unused), .cco(_id_cco), .bra(_id_bra), .nof(_id_nof), .rsd(_id_rsd), .dop(_id_dop), .sop(_id_sop), .idc_opc(_id_idc_opc), .do(_id_do));
   assign _net_252 = ((_stage_trap_state_reg)==(_state_trap__trap4))&_stage_trap;
   assign _net_251 = ((_stage_trap_state_reg)==(_state_trap__trap3))&_stage_trap;
   assign _net_250 = ((_stage_trap_state_reg)==(_state_trap__trap2))&_stage_trap;
   assign _net_249 = ((_stage_trap_state_reg)==(_state_trap__trap1))&_stage_trap;
   assign _net_248 = _task_trap_int_svc;
   assign _net_247 = _task_trap_int_req;
   assign _net_246 = ((_stage_trap_state_reg)==(_state_trap__trap0))&_stage_trap;
   assign _net_245 = _dp_psw[4];
   assign _net_244 = (~(_dp_psw[4]))&irq_in;
   assign _net_243 = (~(_dp_psw[4]))&(~irq_in);
   assign _net_242 = ~(|(_dp_opc[5:3]));
   assign _net_241 = rdy&(_dp_psw[4]);
   assign _net_240 = (rdy&(~(_dp_psw[4])))&irq_in;
   assign _net_239 = (rdy&(~(_dp_psw[4])))&(~irq_in);
   assign _net_238 = |(_dp_opc[5:3]);
   assign _net_237 = ((_stage_wb_state_reg)==(_state_wb__wb_s0))&_stage_wb;
   assign _net_236 = ~(error|fault);
   assign _net_235 = (ifrun&(~(_dp_psw[4])))&(~irq_in);
   assign _net_234 = (ifrun&(~(_dp_psw[4])))&irq_in;
   assign _net_233 = (ifrun&(_dp_psw[4]))&(~(_id_drtt));
   assign _net_232 = (ifrun&(_dp_psw[4]))&(_id_drtt);
   assign _net_231 = _task_ifetch_dst_op;
   assign _net_230 = _task_ifetch_src_op;
   assign _net_229 = ((_stage_ifetch_state_reg)==(_state_ifetch__of4))&_stage_ifetch;
   assign _net_228 = _dp_opc[3];
   assign _net_227 = (_task_ifetch_dst_op)&(~(_dp_opc[3]));
   assign _net_226 = (_task_ifetch_src_op)&(~(_dp_opc[3]));
   assign _net_225 = _task_ifetch_src_op;
   assign _net_224 = _task_ifetch_dst_op;
   assign _net_223 = _task_ifetch_src_op;
   assign _net_222 = _task_ifetch_dst_op;
   assign _net_221 = ~(_dp_opc[3]);
   assign _net_220 = _dp_opc[3];
   assign _net_219 = ((_stage_ifetch_state_reg)==(_state_ifetch__of3))&_stage_ifetch;
   assign _net_218 = _task_ifetch_src_op;
   assign _net_217 = _task_ifetch_dst_op;
   assign _net_216 = ((_stage_ifetch_state_reg)==(_state_ifetch__of2))&_stage_ifetch;
   assign _net_215 = _dp_opc[3];
   assign _net_214 = (_task_ifetch_dst_op)&(~(_dp_opc[3]));
   assign _net_213 = (_task_ifetch_src_op)&(~(_dp_opc[3]));
   assign _net_212 = _task_ifetch_src_op;
   assign _net_211 = _task_ifetch_dst_op;
   assign _net_210 = (_dp_opc[5:4])==(2'b00);
   assign _net_209 = _task_ifetch_src_op;
   assign _net_208 = _task_ifetch_dst_op;
   assign _net_207 = (~(_dp_opc[15]))|(_dp_opc[3])|((_dp_opc[2])&(_dp_opc[1]));
   assign _net_206 = (_dp_opc[15])&(~((_dp_opc[3])|((_dp_opc[2])&(_dp_opc[1]))));
   assign _net_205 = (_dp_opc[5:4])==(2'b01);
   assign _net_204 = _task_ifetch_src_op;
   assign _net_203 = _task_ifetch_dst_op;
   assign _net_202 = (~(_dp_opc[15]))|(_dp_opc[3])|((_dp_opc[2])&(_dp_opc[1]));
   assign _net_201 = (_dp_opc[15])&(~((_dp_opc[3])|((_dp_opc[2])&(_dp_opc[1]))));
   assign _net_200 = (_dp_opc[5:4])==(2'b10);
   assign _net_199 = _task_ifetch_src_op;
   assign _net_198 = _task_ifetch_dst_op;
   assign _net_197 = (_dp_opc[5:4])==(2'b11);
   assign _net_196 = ((_stage_ifetch_state_reg)==(_state_ifetch__of1))&_stage_ifetch;
   assign _net_195 = ((_stage_ifetch_state_reg)==(_state_ifetch__of0))&_stage_ifetch;
   assign _net_194 = ((_stage_ifetch_state_reg)==(_state_ifetch__my1))&_stage_ifetch;
   assign _net_193 = ((_stage_ifetch_state_reg)==(_state_ifetch__my0))&_stage_ifetch;
   assign _net_192 = _dp_psw[4];
   assign _net_191 = (~(_dp_psw[4]))&irq_in;
   assign _net_190 = _dp_taken;
   assign _net_189 = ((_stage_ifetch_state_reg)==(_state_ifetch__br0))&_stage_ifetch;
   assign _net_188 = _dp_psw[4];
   assign _net_187 = (~(_dp_psw[4]))&irq_in;
   assign _net_186 = ((_stage_ifetch_state_reg)==(_state_ifetch__cc0))&_stage_ifetch;
   assign _net_185 = _id_dmtps;
   assign _net_184 = _id_unused;
   assign _net_183 = _id_dsub;
   assign _net_182 = _id_dadd;
   assign _net_181 = _id_bra;
   assign _net_180 = _id_cco;
   assign _net_179 = _id_nof;
   assign _net_178 = _id_rsd;
   assign _net_177 = _id_dop;
   assign _net_176 = _id_sop;
   assign _net_175 = ((_stage_ifetch_state_reg)==(_state_ifetch__id0))&_stage_ifetch;
   assign _net_174 = ((_stage_ifetch_state_reg)==(_state_ifetch__if0))&_stage_ifetch;
   assign _net_173 = _id_dclr;
   assign _net_172 = _id_dcom;
   assign _net_171 = _id_dinc;
   assign _net_170 = _id_ddec;
   assign _net_169 = _id_dneg;
   assign _net_168 = _id_dadc;
   assign _net_167 = _id_dsbc;
   assign _net_166 = _id_dtst;
   assign _net_165 = _id_dror;
   assign _net_164 = _id_drol;
   assign _net_163 = _id_dasr;
   assign _net_162 = _id_dasl;
   assign _net_161 = _id_dsxt;
   assign _net_160 = _id_dmov;
   assign _net_159 = _id_dcmp;
   assign _net_158 = _id_dbit;
   assign _net_157 = _id_dbic;
   assign _net_156 = _id_dbis;
   assign _net_155 = (_id_dadd)&(~rsub);
   assign _net_154 = (_id_dadd)&rsub;
   assign _net_153 = _id_dexor;
   assign _net_152 = _id_dswab;
   assign _net_151 = _id_dnop;
   assign _net_150 = _id_djmp;
   assign _net_149 = _id_dbpt;
   assign _net_148 = _id_diot;
   assign _net_147 = _id_demt;
   assign _net_146 = _id_dtrap;
   assign _net_145 = _id_dspl;
   assign _net_144 = _id_dfloat;
   assign _net_143 = _id_dreset;
   assign _net_142 = _id_dhalt;
   assign _net_141 = ~irq_in;
   assign _net_140 = _id_diwait;
   assign _net_139 = _task_ex_tsk0;
   assign _net_138 = _task_ex_tsk1;
   assign _net_137 = _id_dmtps;
   assign _net_136 = _dp_out_alucc[2];
   assign _net_135 = ~(_dp_out_alucc[2]);
   assign _net_134 = _task_ex_tsk0;
   assign _net_133 = _task_ex_tsk1;
   assign _net_132 = _id_dsob;
   assign _net_131 = _task_ex_tsk0;
   assign _net_130 = ~rdy;
   assign _net_129 = _task_ex_tsk1;
   assign _net_128 = _id_dmark;
   assign _net_127 = ~rdy;
   assign _net_126 = _task_ex_tsk0;
   assign _net_125 = ~rdy;
   assign _net_124 = _task_ex_tsk1;
   assign _net_123 = (_id_drti)|(_id_drtt);
   assign _net_122 = _task_ex_tsk0;
   assign _net_121 = ~rdy;
   assign _net_120 = _task_ex_tsk1;
   assign _net_119 = _task_ex_tsk2;
   assign _net_118 = _id_djsr;
   assign _net_117 = _task_ex_tsk0;
   assign _net_116 = ~rdy;
   assign _net_115 = _task_ex_tsk1;
   assign _net_114 = _id_drts;
   assign _net_113 = ((st2)==(1'b0))&((st1)==(1'b1));
   assign _task_trap_int_req_set = ((_net_237&_net_242)&_net_244)|((_net_237&_net_238)&_net_240)|(_stage_ex&_net_234)|(_net_189&_net_191)|(_net_186&_net_187);
   assign _task_trap_int_svc_set = ((_net_237&_net_242)&_net_245)|((_net_237&_net_238)&fault)|((_net_237&_net_238)&error)|((_net_237&_net_238)&_net_241)|(_stage_ex&error)|(_stage_ex&fault)|(_stage_ex&svcall)|(_stage_ex&_net_233)|((_net_229&_net_231)&fault)|((_net_229&_net_231)&error)|((_net_229&_net_230)&fault)|((_net_229&_net_230)&error)|(_net_219&fault)|(_net_219&error)|((_net_196&_net_197)&fault)|((_net_196&_net_197)&error)|(_net_189&_net_192)|(_net_186&_net_188)|(_net_175&_net_184)|(_net_174&fault)|(_net_174&error);
   assign _task_trap_trace_set = 1'b0;
   assign _stage_trap_reset = _net_252&rdy;
   assign _stage_trap_set = ((_net_237&_net_242)&_net_245)|((_net_237&_net_242)&_net_244)|((_net_237&_net_238)&fault)|((_net_237&_net_238)&error)|((_net_237&_net_238)&_net_241)|((_net_237&_net_238)&_net_240)|(_stage_ex&error)|(_stage_ex&fault)|(_stage_ex&svcall)|(_stage_ex&_net_234)|(_stage_ex&_net_233)|((_net_229&_net_231)&fault)|((_net_229&_net_231)&error)|((_net_229&_net_230)&fault)|((_net_229&_net_230)&error)|(_net_219&fault)|(_net_219&error)|((_net_196&_net_197)&fault)|((_net_196&_net_197)&error)|(_net_189&_net_192)|(_net_189&_net_191)|(_net_186&_net_188)|(_net_186&_net_187)|(_net_175&_net_184)|(_net_174&fault)|(_net_174&error);
   assign _task_wb_run_set = _stage_ex&wback;
   assign _stage_wb_reset = ((_net_237&_net_242)&_net_245)|((_net_237&_net_242)&_net_244)|((_net_237&_net_242)&_net_243)|((_net_237&_net_238)&fault)|((_net_237&_net_238)&error)|((_net_237&_net_238)&_net_241)|((_net_237&_net_238)&_net_240)|((_net_237&_net_238)&_net_239);
   assign _stage_wb_set = _stage_ex&wback;
   assign _task_ex_tsk0_set = ((_stage_ex&_net_236)&s0)|((_net_229&_net_231)&rdy)|((_net_219&rdy)&_net_227)|((_net_196&_net_210)&_net_214)|(_net_175&_net_179);
   assign _task_ex_tsk1_set = (_stage_ex&_net_236)&s1;
   assign _task_ex_tsk2_set = (_stage_ex&_net_236)&s2;
   assign _stage_ex_reset = ((_stage_ex&_net_236)&s0)|((_stage_ex&_net_236)&s1)|((_stage_ex&_net_236)&s2)|(_stage_ex&error)|(_stage_ex&fault)|(_stage_ex&wback)|(_stage_ex&svcall)|(_stage_ex&_net_235)|(_stage_ex&_net_234)|(_stage_ex&_net_233)|(_stage_ex&_net_232);
   assign _stage_ex_set = ((_stage_ex&_net_236)&s0)|((_stage_ex&_net_236)&s1)|((_stage_ex&_net_236)&s2)|((_net_229&_net_231)&rdy)|((_net_219&rdy)&_net_227)|((_net_196&_net_210)&_net_214)|(_net_175&_net_179);
   assign _task_ifetch_run_set = (_net_252&rdy)|((_net_237&_net_242)&_net_243)|((_net_237&_net_238)&_net_239)|(_stage_ex&_net_235)|(_stage_ex&_net_232)|start;
   assign _task_ifetch_src_op_set = _net_175&_net_176;
   assign _task_ifetch_dst_op_set = ((_net_229&_net_230)&rdy)|((_net_219&rdy)&_net_226)|((_net_196&_net_210)&_net_213)|(_net_175&_net_178)|(_net_175&_net_177);
   assign _stage_ifetch_reset = ((_net_229&_net_231)&rdy)|((_net_229&_net_231)&fault)|((_net_229&_net_231)&error)|((_net_229&_net_230)&rdy)|((_net_229&_net_230)&fault)|((_net_229&_net_230)&error)|((_net_219&rdy)&_net_227)|((_net_219&rdy)&_net_226)|(_net_219&fault)|(_net_219&error)|((_net_196&_net_210)&_net_214)|((_net_196&_net_210)&_net_213)|((_net_196&_net_197)&fault)|((_net_196&_net_197)&error)|(_net_189&_net_192)|(_net_189&_net_191)|(_net_186&_net_188)|(_net_186&_net_187)|(_net_175&_net_184)|(_net_175&_net_179)|(_net_175&_net_178)|(_net_175&_net_177)|(_net_175&_net_176)|(_net_174&fault)|(_net_174&error);
   assign _stage_ifetch_set = (_net_252&rdy)|((_net_237&_net_242)&_net_243)|((_net_237&_net_238)&_net_239)|(_stage_ex&_net_235)|(_stage_ex&_net_232)|((_net_229&_net_230)&rdy)|((_net_219&rdy)&_net_226)|((_net_196&_net_210)&_net_213)|(_net_175&_net_178)|(_net_175&_net_177)|(_net_175&_net_176)|start;
   assign _id_do = _stage_ex|_net_175;
   assign _id_idc_opc = ((_stage_ex|_net_175)?_dp_opc:16'b0);
   assign _dp_dbi = (((_net_246&_net_247)|(_net_193&rdy)|(((decop&_net_137)&_net_139)&rdy)|(read&rdy))?dati:16'b0);
   assign _dp_my_mtps = _net_193;
   assign _dp_inc2 = (_net_249&rdy)|((_net_196&_net_205)&_net_207)|((_net_196&_net_197)&rdy)|_net_193|(_net_174&rdy)|((decop&_net_137)&_net_139)|(((decop&_net_128)&_net_129)&rdy)|(((decop&_net_123)&_net_126)&rdy)|(((decop&_net_123)&_net_124)&rdy)|(((decop&_net_114)&_net_115)&rdy);
   assign _dp_dec2 = (_net_251&rdy)|(_net_250&rdy)|((_net_196&_net_200)&_net_202)|((decop&_net_118)&_net_122);
   assign _dp_inc = ((_net_196&_net_205)&_net_206)|(decop&_net_171);
   assign _dp_dec = ((_net_196&_net_200)&_net_201)|(decop&_net_170)|((decop&_net_132)&_net_134);
   assign _dp_clr = decop&_net_173;
   assign _dp_com = decop&_net_172;
   assign _dp_neg = decop&_net_169;
   assign _dp_adc = decop&_net_168;
   assign _dp_sbc = decop&_net_167;
   assign _dp_tst = decop&_net_166;
   assign _dp_ror = decop&_net_165;
   assign _dp_rol = decop&_net_164;
   assign _dp_asr = decop&_net_163;
   assign _dp_asl = decop&_net_162;
   assign _dp_sxt = decop&_net_161;
   assign _dp_mov = decop&_net_160;
   assign _dp_cmp = decop&_net_159;
   assign _dp_bit = decop&_net_158;
   assign _dp_bic = decop&_net_157;
   assign _dp_bis = decop&_net_156;
   assign _dp_add = _net_216|(_net_189&_net_190)|(decop&_net_155)|((decop&_net_128)&_net_131);
   assign _dp_sub = (decop&_net_154)|((decop&_net_132)&_net_133);
   assign _dp_exor = decop&_net_153;
   assign _dp_swab = decop&_net_152;
   assign _dp_setopc = _net_174&rdy;
   assign _dp_dbiDst = ((_net_229&_net_231)&rdy)|((_net_219&rdy)&_net_224)|(((_net_196&_net_197)&rdy)&_net_198);
   assign _dp_dbiSrc = (_net_246&_net_247)|((_net_229&_net_230)&rdy)|((_net_219&rdy)&_net_225)|(((_net_196&_net_197)&rdy)&_net_199);
   assign _dp_dbiPC = (_net_249&rdy)|(((decop&_net_123)&_net_126)&rdy);
   assign _dp_dbiReg = ((decop&_net_114)&_net_115)&rdy;
   assign _dp_dbiPS = ((decop&_net_123)&_net_124)&rdy;
   assign _dp_dbaPC = (_net_196&_net_197)|_net_193|_net_174|((decop&_net_137)&_net_139);
   assign _dp_dbaSP = _net_252|_net_251|((decop&_net_128)&_net_129)|((decop&_net_123)&_net_126)|((decop&_net_123)&_net_124)|((decop&_net_118)&_net_120)|((decop&_net_114)&_net_115);
   assign _dp_dbaDst = (_net_229&_net_231)|(_net_219&_net_222);
   assign _dp_dbaSrc = _net_250|_net_249|(_net_229&_net_230)|(_net_219&_net_223);
   assign _dp_dbaAdr = _net_237&_net_238;
   assign _dp_dboSEL = (decop&_net_118)&_net_120;
   assign _dp_dboDst = _net_251|(_net_237&_net_238);
   assign _dp_dboAdr = _net_252;
   assign _dp_pcALU1 = ((_net_196&_net_197)&rdy)|_net_193|(_net_189&_net_190)|(_net_174&rdy)|((decop&_net_137)&_net_139)|((decop&_net_132)&_net_133);
   assign _dp_spALU1 = (_net_251&rdy)|(_net_250&rdy)|((decop&_net_128)&_net_131)|(((decop&_net_128)&_net_129)&rdy)|(((decop&_net_123)&_net_126)&rdy)|(((decop&_net_123)&_net_124)&rdy)|((decop&_net_118)&_net_122)|(((decop&_net_114)&_net_115)&rdy);
   assign _dp_dstALU1 = (decop&_net_173)|(decop&_net_172)|(decop&_net_171)|(decop&_net_170)|(decop&_net_169)|(decop&_net_168)|(decop&_net_167)|(decop&_net_166)|(decop&_net_165)|(decop&_net_164)|(decop&_net_163)|(decop&_net_162)|(decop&_net_161)|(decop&_net_154)|(decop&_net_152);
   assign _dp_srcALU1 = (_net_249&rdy)|(decop&_net_160)|(decop&_net_159)|(decop&_net_158)|(decop&_net_157)|(decop&_net_156)|(decop&_net_155)|(decop&_net_153);
   assign _dp_dstALU2 = (_net_216&_net_217)|(decop&_net_159)|(decop&_net_158)|(decop&_net_157)|(decop&_net_156)|(decop&_net_155)|(decop&_net_153);
   assign _dp_srcALU2 = (_net_216&_net_218)|(decop&_net_154);
   assign _dp_ofs8ALU2 = _net_189&_net_190;
   assign _dp_ofs6ALU2 = ((decop&_net_132)&_net_133)|((decop&_net_128)&_net_131);
   assign _dp_selALU1 = _net_216|(_net_196&_net_205)|(_net_196&_net_200)|((decop&_net_132)&_net_134);
   assign _dp_regSEL = _net_216|(_net_196&_net_210)|(_net_196&_net_205)|(_net_196&_net_200)|_net_195|((decop&_net_114)&_net_117);
   assign _dp_regSEL2 = ((decop&_net_132)&_net_134)|((decop&_net_118)&_net_120);
   assign _dp_setReg = (_net_237&_net_242)|(_net_196&_net_205)|(_net_196&_net_200)|(((decop&_net_114)&_net_115)&rdy);
   assign _dp_setReg2 = ((decop&_net_132)&_net_134)|(((decop&_net_118)&_net_120)&rdy);
   assign _dp_ALUreg = (_net_196&_net_205)|(_net_196&_net_200)|((decop&_net_132)&_net_134);
   assign _dp_DSTreg = _net_237&_net_242;
   assign _dp_PCreg = ((decop&_net_118)&_net_120)&rdy;
   assign _dp_ALUpc = ((_net_196&_net_197)&rdy)|_net_193|(_net_189&_net_190)|(_net_174&rdy)|((decop&_net_137)&_net_139)|((decop&_net_132)&_net_133);
   assign _dp_ALUsp = (_net_251&rdy)|(_net_250&rdy)|((decop&_net_128)&_net_131)|(((decop&_net_128)&_net_129)&rdy)|(((decop&_net_123)&_net_126)&rdy)|(((decop&_net_123)&_net_124)&rdy)|((decop&_net_118)&_net_122)|(((decop&_net_114)&_net_115)&rdy);
   assign _dp_ALUdst = (_net_216&_net_217)|((_net_196&_net_200)&_net_203)|(decop&_net_160);
   assign _dp_ALUdstb = (decop&_net_173)|(decop&_net_172)|(decop&_net_171)|(decop&_net_170)|(decop&_net_169)|(decop&_net_168)|(decop&_net_167)|(decop&_net_165)|(decop&_net_164)|(decop&_net_163)|(decop&_net_162)|(decop&_net_161)|(decop&_net_157)|(decop&_net_156)|(decop&_net_155)|(decop&_net_154)|(decop&_net_153)|(decop&_net_152);
   assign _dp_ALUsrc = (_net_249&rdy)|(_net_216&_net_218)|((_net_196&_net_200)&_net_204);
   assign _dp_ALUcc = (decop&_net_173)|(decop&_net_172)|(decop&_net_171)|(decop&_net_170)|(decop&_net_169)|(decop&_net_168)|(decop&_net_167)|(decop&_net_166)|(decop&_net_165)|(decop&_net_164)|(decop&_net_163)|(decop&_net_162)|(decop&_net_161)|(decop&_net_160)|(decop&_net_159)|(decop&_net_158)|(decop&_net_157)|(decop&_net_156)|(decop&_net_155)|(decop&_net_154)|(decop&_net_153)|(decop&_net_152);
   assign _dp_SELdst = ((_net_196&_net_210)&_net_211)|((_net_196&_net_205)&_net_208);
   assign _dp_SELsrc = ((_net_196&_net_210)&_net_212)|((_net_196&_net_205)&_net_209)|_net_195;
   assign _dp_SELpc = (decop&_net_114)&_net_117;
   assign _dp_DSTadr = ((_net_229&_net_231)&rdy)|((_net_219&rdy)&_net_224);
   assign _dp_SRCadr = ((_net_229&_net_230)&rdy)|((_net_219&rdy)&_net_225);
   assign _dp_adrPC = (decop&_net_150)|((decop&_net_118)&_net_119);
   assign _dp_save_stat = _net_246;
   assign _dp_FPpc = (decop&_net_128)&_net_131;
   assign _dp_dbiFP = ((decop&_net_128)&_net_129)&rdy;
   assign _dp_setPCrom = start;
   assign _dp_change_opr = ((_net_229&_net_230)&rdy)|((_net_219&rdy)&_net_226)|((_net_196&_net_210)&_net_213)|_net_195|(_net_175&_net_178)|(_net_175&_net_176);
   assign _dp_reset_byte = _net_246|(_net_175&_net_183);
   assign _dp_vectorPS = _net_250&rdy;
   assign _dp_ccset = _net_186;
   assign _dp_cctaken = _net_189;
   assign _dp_buserr = ((_net_237&_net_238)&error)|(_stage_ex&error)|((_net_229&_net_231)&error)|((_net_229&_net_230)&error)|(_net_219&error)|((_net_196&_net_197)&error)|(_net_174&error);
   assign _dp_err = _net_175&_net_184;
   assign _dp_bpt = ((_net_237&_net_242)&_net_245)|((_net_237&_net_238)&_net_241)|(_stage_ex&_net_233)|(_net_189&_net_192)|(_net_186&_net_188)|(decop&_net_149);
   assign _dp_emt = decop&_net_147;
   assign _dp_iot = decop&_net_148;
   assign _dp_svc = decop&_net_146;
   assign _dp_segerr = ((_net_237&_net_238)&fault)|(_stage_ex&fault)|((_net_229&_net_231)&fault)|((_net_229&_net_230)&fault)|(_net_219&fault)|((_net_196&_net_197)&fault)|(_net_174&fault);
   assign _dp_spl = decop&_net_145;
   assign _dp_ccget = (decop&_net_132)&_net_134;
   assign byte_sel = ((_net_252|_net_251|(_net_237&_net_238)|(_net_229&_net_231)|(_net_229&_net_230)|(_net_219&_net_221))?_dp_opc[15]:1'b0)|
	((_net_250|_net_249|(_net_219&_net_220)|(_net_196&_net_197)|_net_174|((decop&_net_128)&_net_129)|((decop&_net_123)&_net_126)|((decop&_net_123)&_net_124)|((decop&_net_118)&_net_120)|((decop&_net_114)&_net_115))?1'b0:1'b0);
   assign s2 = ((decop&_net_118)&_net_120)&rdy;
   assign s1 = ((decop&_net_137)&_net_139)|(((decop&_net_132)&_net_134)&_net_135)|((decop&_net_128)&_net_131)|(((decop&_net_128)&_net_129)&_net_130)|(((decop&_net_123)&_net_126)&rdy)|(((decop&_net_123)&_net_124)&_net_125)|((decop&_net_118)&_net_122)|(((decop&_net_118)&_net_120)&_net_121)|((decop&_net_114)&_net_117)|(((decop&_net_114)&_net_115)&_net_116);
   assign s0 = ((decop&_net_140)&_net_141)|(((decop&_net_123)&_net_126)&_net_127);
   assign decop = _stage_ex;
   assign write = _net_252|_net_251|(_net_237&_net_238)|((decop&_net_118)&_net_120);
   assign read = _net_250|_net_249|(_net_229&_net_231)|(_net_229&_net_230)|(_net_219&_net_221)|(_net_219&_net_220)|(_net_196&_net_197)|_net_174|((decop&_net_128)&_net_129)|((decop&_net_123)&_net_126)|((decop&_net_123)&_net_124)|((decop&_net_114)&_net_115);
   assign svcall = (decop&_net_149)|(decop&_net_148)|(decop&_net_147)|(decop&_net_146);
   assign wback = (decop&_net_173)|(decop&_net_172)|(decop&_net_171)|(decop&_net_170)|(decop&_net_169)|(decop&_net_168)|(decop&_net_167)|(decop&_net_165)|(decop&_net_164)|(decop&_net_163)|(decop&_net_162)|(decop&_net_161)|(decop&_net_160)|(decop&_net_157)|(decop&_net_156)|(decop&_net_155)|(decop&_net_154)|(decop&_net_153)|(decop&_net_152);
   assign ifrun = _net_194|(decop&_net_166)|(decop&_net_159)|(decop&_net_158)|(decop&_net_151)|(decop&_net_150)|(decop&_net_145)|(decop&_net_144)|(decop&_net_143)|((decop&_net_140)&irq_in)|((decop&_net_137)&_net_138)|(((decop&_net_132)&_net_134)&_net_136)|((decop&_net_132)&_net_133)|(((decop&_net_128)&_net_129)&rdy)|(((decop&_net_123)&_net_124)&rdy)|((decop&_net_118)&_net_119)|(((decop&_net_114)&_net_115)&rdy);
   assign start = _net_113;
   assign inst = _net_174;
   assign pswout = _dp_psw;
   assign int_ack = _net_246&_net_247;
   assign byte = ((write|read)?byte_sel:1'b0);
   assign wt = write;
   assign rd = _net_193|((decop&_net_137)&_net_139)|read;
   assign adrs = ((_net_193|((decop&_net_137)&_net_139)|write|read)?_dp_dba:16'b0);
   assign dato = (write?_dp_dbo:16'b0);
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _stage_trap_state_reg <= _state_trap__trap0;
else if (_net_252&rdy)
	  _stage_trap_state_reg <= _state_trap__trap0;
else if (_net_251&rdy)
	  _stage_trap_state_reg <= _state_trap__trap4;
else if (_net_250&rdy)
	  _stage_trap_state_reg <= _state_trap__trap3;
else if (_net_249&rdy)
	  _stage_trap_state_reg <= _state_trap__trap2;
else if (_net_246)
	  _stage_trap_state_reg <= _state_trap__trap1;
end
always @(posedge p_reset)
 begin
if (p_reset)
	 _stage_wb_state_reg <= _state_wb__wb_s0;
end
always @(posedge p_reset)
 begin
if (p_reset)
	 _stage_ex_state_reg <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _stage_ifetch_state_reg <= _state_ifetch__if0;
else if (((_net_219&rdy)&_net_228)|((_net_196&_net_210)&_net_215))
	  _stage_ifetch_state_reg <= _state_ifetch__of4;
else if (_net_216|(_net_196&_net_205)|(_net_196&_net_200))
	  _stage_ifetch_state_reg <= _state_ifetch__of3;
else if ((_net_196&_net_197)&rdy)
	  _stage_ifetch_state_reg <= _state_ifetch__of2;
else if (_net_193)
	  _stage_ifetch_state_reg <= _state_ifetch__my1;
else if (_net_175&_net_185)
	  _stage_ifetch_state_reg <= _state_ifetch__my0;
else if (_net_175&_net_181)
	  _stage_ifetch_state_reg <= _state_ifetch__br0;
else if (_net_175&_net_180)
	  _stage_ifetch_state_reg <= _state_ifetch__cc0;
else if (((_net_229&_net_231)&rdy)|((_net_229&_net_231)&fault)|((_net_229&_net_231)&error)|((_net_229&_net_230)&fault)|((_net_229&_net_230)&error)|((_net_219&rdy)&_net_227)|(_net_219&fault)|(_net_219&error)|((_net_196&_net_210)&_net_214)|((_net_196&_net_197)&fault)|((_net_196&_net_197)&error)|_net_194|_net_189|_net_186|(_net_175&_net_184)|(_net_175&_net_179))
	  _stage_ifetch_state_reg <= _state_ifetch__if0;
else if (_net_175&_net_178)
	  _stage_ifetch_state_reg <= _state_ifetch__of0;
else if (((_net_229&_net_230)&rdy)|((_net_219&rdy)&_net_226)|((_net_196&_net_210)&_net_213)|_net_195|(_net_175&_net_177)|(_net_175&_net_176))
	  _stage_ifetch_state_reg <= _state_ifetch__of1;
else if (_net_174&rdy)
	  _stage_ifetch_state_reg <= _state_ifetch__id0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_trap_int_req <= 1'b0;
else if (_task_trap_int_req_set)
	  _task_trap_int_req <= 1'b1;
else if ((~_task_trap_int_req_set)&_stage_trap_reset)
	  _task_trap_int_req <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_trap_int_svc <= 1'b0;
else if (_task_trap_int_svc_set)
	  _task_trap_int_svc <= 1'b1;
else if ((~_task_trap_int_svc_set)&_stage_trap_reset)
	  _task_trap_int_svc <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_trap_trace <= 1'b0;
else if (_task_trap_trace_set)
	  _task_trap_trace <= 1'b1;
else if ((~_task_trap_trace_set)&_stage_trap_reset)
	  _task_trap_trace <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _stage_trap <= 1'b0;
else if (_stage_trap_set)
	  _stage_trap <= 1'b1;
else if ((~_stage_trap_set)&_stage_trap_reset)
	  _stage_trap <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_wb_run <= 1'b0;
else if (_task_wb_run_set)
	  _task_wb_run <= 1'b1;
else if ((~_task_wb_run_set)&_stage_wb_reset)
	  _task_wb_run <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _stage_wb <= 1'b0;
else if (_stage_wb_set)
	  _stage_wb <= 1'b1;
else if ((~_stage_wb_set)&_stage_wb_reset)
	  _stage_wb <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_ex_tsk0 <= 1'b0;
else if (_task_ex_tsk0_set)
	  _task_ex_tsk0 <= 1'b1;
else if ((~_task_ex_tsk0_set)&_stage_ex_reset)
	  _task_ex_tsk0 <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_ex_tsk1 <= 1'b0;
else if (_task_ex_tsk1_set)
	  _task_ex_tsk1 <= 1'b1;
else if ((~_task_ex_tsk1_set)&_stage_ex_reset)
	  _task_ex_tsk1 <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_ex_tsk2 <= 1'b0;
else if (_task_ex_tsk2_set)
	  _task_ex_tsk2 <= 1'b1;
else if ((~_task_ex_tsk2_set)&_stage_ex_reset)
	  _task_ex_tsk2 <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _stage_ex <= 1'b0;
else if (_stage_ex_set)
	  _stage_ex <= 1'b1;
else if ((~_stage_ex_set)&_stage_ex_reset)
	  _stage_ex <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_ifetch_run <= 1'b0;
else if (_task_ifetch_run_set)
	  _task_ifetch_run <= 1'b1;
else if ((~_task_ifetch_run_set)&_stage_ifetch_reset)
	  _task_ifetch_run <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_ifetch_src_op <= 1'b0;
else if (_task_ifetch_src_op_set)
	  _task_ifetch_src_op <= 1'b1;
else if ((~_task_ifetch_src_op_set)&_stage_ifetch_reset)
	  _task_ifetch_src_op <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _task_ifetch_dst_op <= 1'b0;
else if (_task_ifetch_dst_op_set)
	  _task_ifetch_dst_op <= 1'b1;
else if ((~_task_ifetch_dst_op_set)&_stage_ifetch_reset)
	  _task_ifetch_dst_op <= 1'b0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 _stage_ifetch <= 1'b0;
else if (_stage_ifetch_set)
	  _stage_ifetch <= 1'b1;
else if ((~_stage_ifetch_set)&_stage_ifetch_reset)
	  _stage_ifetch <= 1'b0;
end
always @(posedge m_clock  )
  begin
if (_net_175&_net_183)
	  rsub <= 1'b1;
else if (_net_175&_net_182)
	  rsub <= 1'b0;
end
always @(posedge m_clock  )
  begin
  st2 <= st1;
end
always @(posedge m_clock  )
  begin
  st1 <= st0;
end
always @(posedge m_clock or posedge p_reset)
  begin
if (p_reset)
	 st0 <= 1'b0;
else   st0 <= 1'b1;
end
/* The sfl2vl by Naohiko Shimizu generated this module. */
/* Without valid license, you are only allowed to use generated module for educational and/or your personal projects.  */
endmodule
