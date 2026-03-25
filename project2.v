
module project2(
    input reset_n,
    input clock,
    input [7:0] d_in,
    input [1:0] op,
    input capture,
    output [9:0] result,
    output valid
);

    // linking wires between control and datapath
    wire l_a, l_b, l_c, l_d;
    
    wire [7:0] reg8A, reg8B, reg8C, reg8D;

    // hook up the two main modules and naming them u1 and u2
    controller u1(clock, reset_n, op, capture, l_a, l_b, l_c, l_d, valid);
    datapath u2(clock, reset_n, d_in, l_a, l_b, l_c, l_d, result, reg8A, reg8B, reg8C, reg8D);

endmodule


// --- CONTROLLER ---
module controller(
    input clock,
    input reset_n,
    input [1:0] op,
    input capture,
    output l_a,
    output l_b,
    output l_c,
    output l_d,
    output valid
);
    // figure out which operand is coming in based on op code
    assign l_a = capture & (~op[1]) & (~op[0]);
    assign l_b = capture & (~op[1]) & (op[0]);
    assign l_c = capture & (op[1]) & (~op[0]);
    assign l_d = capture & (op[1]) & (op[0]);

    // flags to remember what we've seen so far
    wire f_a, f_b, f_c, f_d;
    
    // keep flag high once we get the load signal
    wire nxt_a = f_a | l_a;
    wire nxt_b = f_b | l_b;
    wire nxt_c = f_c | l_c;
    wire nxt_d = f_d | l_d;

    // track state with our custom dffs
    my_dff dff_a(clock, reset_n, nxt_a, f_a);
    my_dff dff_b(clock, reset_n, nxt_b, f_b);
    my_dff dff_c(clock, reset_n, nxt_c, f_c);
    my_dff dff_d(clock, reset_n, nxt_d, f_d);

    // go signal when we have all 4 pieces
    wire ok_signal = f_a & f_b & f_c & f_d;
    
    // bump valid by 1 cycle so the data has time to latch
    my_dff vld_reg(clock, reset_n, ok_signal, valid);

endmodule


// --- DATAPATH --- 
module datapath(
    input clock,
    input reset_n,
    input [7:0] d_in,
    input l_a,
    input l_b,
    input l_c,
    input l_d,
    output [9:0] result,
    output [7:0] reg8A,  
    output [7:0] reg8B,  
    output [7:0] reg8C,  
    output [7:0] reg8D   
);
    wire [7:0] nxt_a, nxt_b, nxt_c, nxt_d;

    // grab new data if load is high, otherwise loop the old data
    m8 mux_1(reg8A, d_in, l_a, nxt_a);
    m8 mux_2(reg8B, d_in, l_b, nxt_b);
    m8 mux_3(reg8C, d_in, l_c, nxt_c);
    m8 mux_4(reg8D, d_in, l_d, nxt_d);

    // main operand registers
    r8 rA(clock, reset_n, nxt_a, reg8A);
    r8 rB(clock, reset_n, nxt_b, reg8B);
    r8 rC(clock, reset_n, nxt_c, reg8C);
    r8 rD(clock, reset_n, nxt_d, reg8D);

    // do the subtractions first
    wire [8:0] s1_out, s2_out;
    RCA8 sub_A(reg8A, reg8B, s1_out); // A minus B
    RCA8 sub_B(reg8C, reg8D, s2_out); // C minus D

    // add the results together 
    wire [9:0] sum_wire;
    RCA9 final_adder(s1_out, s2_out, 1'b0, sum_wire);

    // final latch for the answer
    r10 output_r(clock, reset_n, sum_wire, result);

endmodule


// basic D flip-flop with reset
module my_dff(input clk, input rst_n, input d, output reg q);
    always @(posedge clk) begin
        if (!rst_n) q <= 1'b0;
        else q <= d;
    end
endmodule

// standard 8-bit 2-to-1 multiplexer
module m8(input [7:0] i0, input [7:0] i1, input s, output [7:0] y);
    assign y = s ? i1 : i0;
endmodule

// 1-bit full adder
module f_add(input a, input b, input ci, output s, output co);
    assign s = a ^ b ^ ci;
    assign co = (a & b) | (b & ci) | (a & ci);
endmodule

// 8-bit Subtractor (Strictly Structural)
module RCA8(input [7:0] a, input [7:0] b, output [8:0] d);
    wire [7:0] b_not;
    wire [8:1] c; // 
    
    // strictly structural inversion of B for 2s comp
    not n0(b_not[0], b[0]);
    not n1(b_not[1], b[1]);
    not n2(b_not[2], b[2]);
    not n3(b_not[3], b[3]);
    not n4(b_not[4], b[4]);
    not n5(b_not[5], b[5]);
    not n6(b_not[6], b[6]);
    not n7(b_not[7], b[7]);

    // pump in 1 directly to f0 to finish the 2s complement
    f_add f0(a[0], b_not[0], 1'b1, d[0], c[1]);
    f_add f1(a[1], b_not[1], c[1], d[1], c[2]);
    f_add f2(a[2], b_not[2], c[2], d[2], c[3]);
    f_add f3(a[3], b_not[3], c[3], d[3], c[4]);
    f_add f4(a[4], b_not[4], c[4], d[4], c[5]);
    f_add f5(a[5], b_not[5], c[5], d[5], c[6]);
    f_add f6(a[6], b_not[6], c[6], d[6], c[7]);
    f_add f7(a[7], b_not[7], c[7], d[7], c[8]);
    
    // structural logic for the sign bit extension
    wire xor_tmp;
    xor x1(xor_tmp, c[8], c[7]);
    xor x2(d[8], d[7], xor_tmp);
endmodule

// 9-bit Adder (Strictly Structural)
module RCA9(input [8:0] a, input [8:0] b, input ci, output [9:0] s);
    wire [10:1] c; //
    
    // pass the carry-in directly to the first full adder
    f_add fa0(a[0], b[0], ci, s[0], c[1]);
    f_add fa1(a[1], b[1], c[1], s[1], c[2]);
    f_add fa2(a[2], b[2], c[2], s[2], c[3]);
    f_add fa3(a[3], b[3], c[3], s[3], c[4]);
    f_add fa4(a[4], b[4], c[4], s[4], c[5]);
    f_add fa5(a[5], b[5], c[5], s[5], c[6]);
    f_add fa6(a[6], b[6], c[6], s[6], c[7]);
    f_add fa7(a[7], b[7], c[7], s[7], c[8]);
    f_add fa8(a[8], b[8], c[8], s[8], c[9]);
    
    // structural logic for the sign bit extension
    wire xor_tmp_9;
    xor x3(xor_tmp_9, c[9], c[8]);
    xor x4(s[9], s[8], xor_tmp_9);
endmodule

// 8-bit register block
module r8(input clk, input rst_n, input [7:0] d, output [7:0] q);
    my_dff d0(clk, rst_n, d[0], q[0]);
    my_dff d1(clk, rst_n, d[1], q[1]);
    my_dff d2(clk, rst_n, d[2], q[2]);
    my_dff d3(clk, rst_n, d[3], q[3]);
    my_dff d4(clk, rst_n, d[4], q[4]);
    my_dff d5(clk, rst_n, d[5], q[5]);
    my_dff d6(clk, rst_n, d[6], q[6]);
    my_dff d7(clk, rst_n, d[7], q[7]);
endmodule

// 10-bit register block for the final answer
module r10(input clk, input rst_n, input [9:0] d, output [9:0] q);
    my_dff d0(clk, rst_n, d[0], q[0]);
    my_dff d1(clk, rst_n, d[1], q[1]);
    my_dff d2(clk, rst_n, d[2], q[2]);
    my_dff d3(clk, rst_n, d[3], q[3]);
    my_dff d4(clk, rst_n, d[4], q[4]);
    my_dff d5(clk, rst_n, d[5], q[5]);
    my_dff d6(clk, rst_n, d[6], q[6]);
    my_dff d7(clk, rst_n, d[7], q[7]);
    my_dff d8(clk, rst_n, d[8], q[8]);
    my_dff d9(clk, rst_n, d[9], q[9]);
endmodule
