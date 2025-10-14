module imm_gen (
    input [31:0] inst,
    input [2:0] imm_type,
    output [31:0] imm
);

    // encoding for type
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    assign imm = 
        (imm_type == IMM_I)  ?  {{20{inst[31]}}, inst[31:20]} :
        (imm_type == IMM_S)  ?  {{20{inst[31]}}, inst[31:25], inst[11:7]} :
        (imm_type == IMM_B)  ?  {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0} :
        (imm_type == IMM_U)  ?  {inst[31:12], 12'b0} :
        (imm_type == IMM_J)  ?  {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0} :
        32'b0;
endmodule
