module Mux1(z, a, b, c);
    output z;
    input a, b, c;
    wire notC, upper, lower;
    not my_not(notC, c);
    and upperAnd(upper, a, notC);
    and lowerAnd(lower, c, b);
    or my_or(z, upper, lower);
endmodule

module Mux2(z, a, b, c);
    output [1:0] z;
    input [1:0] a, b;
    input c;
    Mux1 upper(z[0], a[0], b[0], c);
    Mux1 lower(z[1], a[1], b[1], c);
endmodule

module Mux(z, a, b, c);
    parameter SIZE = 2;
    output [SIZE-1:0] z;
    input [SIZE-1:0] a, b;
    input c;
    Mux1 mine[SIZE-1:0](z, a, b, c);
endmodule

module Mux4to1(z, a0, a1, a2, a3, c);
    parameter SIZE = 2;
    output [SIZE-1:0] z;
    input [SIZE-1:0] a0, a1, a2, a3;
    input [1:0] c;
    wire [SIZE-1:0] zLo, zHi;
    Mux #(SIZE) lo(zLo, a0, a1, c[0]);
    Mux #(SIZE) hi(zHi, a2, a3, c[0]);
    Mux #(SIZE) final(z, zLo, zHi, c[1]);
endmodule

module Adder1(z, cout, a, b, cin);
    output z, cout;
    input a, b, cin;
    xor left_xor(tmp, a, b);
    xor right_xor(z, cin, tmp);
    and left_and(outL, a, b);
    and right_and(outR, tmp, cin);
    or my_or(cout, outR, outL);
endmodule

module Adder(z, cout, a, b, cin);
    output [31:0] z;
    output cout;
    input [31:0] a, b;
    input cin;
    wire[31:0] in, out;
    Adder1 mine[31:0](z, out, a, b, in);
    assign in[0] = cin;
    assign in[31:1] = out[30:0];
endmodule

module Arith(z, cout, a, b, ctrl);
    output [31:0] z;
    output cout;
    input [31:0] a, b;
    input ctrl;
    wire[31:0] notB, tmp;
    wire cin;
    not c_not[31:0](notB, b);
    Mux #(.SIZE(32)) my_mux[31:0](tmp, b, notB, ctrl);
    assign cin = ctrl;
    Adder my_add[31:0](z, cout, a, tmp, cin);
endmodule

module Alu(z, zero, a, b, op);
    input [31:0] a, b;
    input [2:0] op;
    output [31:0] z;
    output zero;
    wire [15:0] z16;
    wire [7:0] z8;
    wire [3:0] z4;
    wire [1:0] z2;
    wire z1;
    wire cout;
    wire [31:0] zAnd, zOr, zArith, slt;
    wire condition;
    wire [31:0] aSubB;
    assign slt[31:1] = 0; 
    and ab_and[31:0](zAnd, a, b);
    or ab_or[31:0](zOr, a, b);
    or or16[15:0](z16, z[15:0], z[31:16]);
    or or8[7:0](z8, z16[7:0], z16[15:8]);
    or or4[3:0](z4, z8[3:0], z8[7:4]);
    or or2[1:0](z2, z4[1:0], z4[3:2]);
    or or1(z1, z2[1], z2[0]);
    not zero_not(zero, z1);
    xor slt_xor(condition, a[31], b[31]);
    Arith slt_arith(aSubB, cout, a, b, 1'b1);
    Mux1 my_mux_slt(slt[0], aSubB[31], a[31], condition); 
    Arith ab_arith[31:0](zArith, cout, a, b, op[2]);
    Mux4to1 #(.SIZE(32)) my_mux(z, zAnd, zOr, zArith, slt, op[1:0]);
endmodule

module IF(ins, PCp4, PCin, clk);
    output [31:0] ins, PCp4;
    input [31:0] PCin;
    input clk;
    wire ex;
    wire [31:0] z;
    register #(32) PC_register(z, PCin, clk, 1'b1);
    Alu my_ALU(PCp4, ex, 4, z, 3'b010);
    mem my_mem(ins, z, , clk, 1'b1, 1'b0);
endmodule

module ID(rd1, rd2, imm, jTarget, ins, wd, RegDst, RegWrite, clk);
    output [31:0] rd1, rd2, imm;
    output [25:0] jTarget;
    input [31:0] ins, wd;
    input RegDst, RegWrite, clk;
    wire [4:0] rn1, rn2, wn;
    wire [15:0] zeros, ones;

    assign rn1 = ins[25:21];
    assign rn2 = ins[20:16];

    Mux #(5) my_MUX(wn, rn2, ins[15:11], RegDst);
    rf my_RF(rd1, rd2, rn1, rn2, wn, wd, clk, RegWrite);

    assign imm[15:0] = ins[15:0];
    assign zeros = 16'h0000;
    assign ones = 16'hFFFF;
    Mux #(16) se(imm[31:16], zeros, ones, ins[15]);
    assign jTarget[25:0] = ins[25:0];
endmodule

module EX(z, zero, rd1, rd2, imm, op, ALUSrc);
    output [31:0] z;
    output zero;
    input [31:0] rd1, rd2, imm;
    input [2:0] op;
    input ALUSrc;
    wire [31:0] a, b, z;

    assign a = rd1;
    Mux #(32) my_MUX(b, rd2, imm, ALUSrc);
    Alu my_ALU(z, zero, a, b, op);
endmodule

module DM(memOut, exeOut, rd2, clk, MemRead, MemWrite);
    output [31:0] memOut;
    input [31:0] exeOut, rd2;
    input clk, MemRead, MemWrite;
    mem my_MEM(memOut, exeOut, rd2, clk, MemRead, MemWrite);
endmodule

module WB(wb, exeOut, memOut, Mem2Reg);
    output [31:0] wb;
    input [31:0] exeOut, memOut;
    input Mem2Reg;
    Mux #(32) my_MUX(wb, exeOut, memOut, Mem2Reg);
endmodule

module PC(PCin, PCp4, INT, entryPoint, imm, jTarget, zero, branch, jump);
    output [31:0] PCin;
    input [31:0] PCp4, entryPoint, imm;
    input [25:0] jTarget;
    input INT, zero, branch, jump;
    wire [31:0] immX4, bTarget, jumping, choiceA, choiceB;
    wire doBranch, zf;
    assign immX4[31:2] = imm[29:0];
    assign immX4[1:0] = 2'b00; 
    Alu beq(bTarget, zf, PCp4, immX4, 3'b010);
    and (doBranch, branch, zero); 
    Mux #(32) mux1(choiceA, PCp4, bTarget, doBranch);
    assign jumping[31:28] = PCp4[31:28];
    assign jumping[27:2] = jTarget[25:0];
    assign jumping[1:0] = 2'b00;
    Mux #(32) mux2(choiceB, choiceA, jumping, jump);
    Mux #(32) mux3(PCin, choiceB, entryPoint, INT);
endmodule

module C1(rtype, lw, sw, jump, branch, opCode);
    output rtype, lw, sw, jump, branch;
    input [5:0] opCode;
    wire [0:0] not5, not4, not3, now2, not1, not0;
    not (not5, opCode[5]);
    not (not4, opCode[4]);
    not (not3, opCode[3]);
    not (now2, opCode[2]);
    not (not1, opCode[1]);
    not (not0, opCode[0]);
    and (rtype, not5, not4, not3, now2, not1, not0);
    and (jump, not5, not4, not3, now2, opCode[1], not0);
    and (branch, not5, not4, not3, opCode[2], not1, not0);
    and (sw, opCode[5], not4, opCode[3], now2, opCode[1], opCode[0]);
    and (lw, opCode[5], not4, not3, now2, opCode[1], opCode[0]);
endmodule

module C2(RegDst, ALUSrc, RegWrite, Mem2Reg, MemRead, MemWrite, rtype, lw, sw, branch);
    output RegDst, ALUSrc, RegWrite, Mem2Reg, MemRead, MemWrite;
    input rtype, lw, sw, branch;
    assign RegDst = rtype;
    nor (ALUSrc, rtype, branch);
    nor (RegWrite, sw, branch);
    assign Mem2Reg = lw;
    assign MemRead = lw;
    assign MemWrite = sw;
endmodule

module C3(ALUop, rtype, branch);
    output [1:0] ALUop;
    input rtype, branch;
    assign ALUop[0] = branch;
    assign ALUop[1] = rtype;
endmodule

module C4(op, ALUop, fnCode);
    output [2:0] op;
    input [5:0] fnCode;
    input [1:0] ALUop;
    wire w1, w2;
    or (w1, fnCode[0], fnCode[3]);
    and (w2, fnCode[1], ALUop[1]);
    and (op[0], ALUop[1], w1);
    nand (op[1], ALUop[1], fnCode[2]);
    or (op[2], w2, ALUop[0]);
endmodule

module Chip(ins, rd2, wb, entryPoint, INT, clk);
    output [31:0] ins, rd2, wb;
    input [31:0] entryPoint;
    input INT, clk;
    wire [31:0] wd, rd1, imm, PCp4, z, memOut, PCin;
    wire [25:0] jTarget;
    wire [5:0] opCode, fnCode;
    wire [2:0] op;
    wire [1:0] ALUop;
    wire zero, RegDst, RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg, jump, branch, rtype, lw, sw;

    IF myIF(ins, PCp4, PCin, clk);
    ID myID(rd1, rd2, imm, jTarget, ins, wd, RegDst, RegWrite, clk);
    EX myEX(z, zero, rd1, rd2, imm, op, ALUSrc);
    DM myDM(memOut, z, rd2, clk, MemRead, MemWrite);
    WB myWB(wb, z, memOut, Mem2Reg);
    assign wd = wb;
    PC myPC(PCin, PCp4, INT, entryPoint, imm, jTarget, zero, branch, jump);
    assign opCode = ins[31:26];
    C1 myC1(rtype, lw, sw, jump, branch, opCode);
    C2 myC2(RegDst, ALUSrc, RegWrite, Mem2Reg, MemRead, MemWrite, rtype, lw, sw, branch);
    assign fnCode = ins[5:0];
    C3 myC3(ALUop, rtype, branch);
    C4 myC4(op, ALUop, fnCode);
endmodule
