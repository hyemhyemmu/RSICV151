module alu (
    input [3:0] alu_op, // sel, coming from control logic
    input [31:0] alu_in1,   
    input [31:0] alu_in2,
    output [31:0] alu_out
);

    // ALU operations coding (R/I type)
    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_AND    = 4'b0010;
    localparam ALU_OR     = 4'b0011;
    localparam ALU_XOR    = 4'b0100;
    localparam ALU_SLT    = 4'b0101;
    localparam ALU_SLTU   = 4'b0110;
    localparam ALU_SLL    = 4'b0111;
    localparam ALU_SRL    = 4'b1000;
    localparam ALU_SRA    = 4'b1001;
    
    // signed versions
    wire signed [31:0] alu_in1_signed = $signed(alu_in1);
    wire signed [31:0] alu_in2_signed = $signed(alu_in2);
    wire [4:0] shamt = alu_in2[4:0]; // shift amount (lower 5 bits)
    
    // ALU logic
    assign alu_out = 
        (alu_op == ALU_ADD)    ? alu_in1 + alu_in2 :
        (alu_op == ALU_SUB)    ? alu_in1 - alu_in2 :
        (alu_op == ALU_AND)    ? alu_in1 & alu_in2 :
        (alu_op == ALU_OR)     ? alu_in1 | alu_in2 :
        (alu_op == ALU_XOR)    ? alu_in1 ^ alu_in2 :
        (alu_op == ALU_SLT)    ? {{31{1'b0}}, alu_in1_signed < alu_in2_signed} :
        (alu_op == ALU_SLTU)   ? {{31{1'b0}}, alu_in1 < alu_in2} :
        (alu_op == ALU_SLL)    ? alu_in1 << shamt :
        (alu_op == ALU_SRL)    ? alu_in1 >> shamt :
        (alu_op == ALU_SRA)    ? $signed(alu_in1_signed) >>> shamt :
        32'b0; // default
        
endmodule
