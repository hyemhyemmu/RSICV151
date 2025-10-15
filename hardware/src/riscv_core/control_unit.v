`include "opcode.vh"

module control_unit (
    input [31:0] inst,           // 32-bit instruction
    
    // Control signals
    output reg [3:0] alu_op,     // ALU operation select
    output reg [2:0] imm_type,   // Immediate type
    output reg [2:0] funct3_out, // funct3 (for Load/Store/Branch)
    output reg reg_write,        // Register write enable
    output reg mem_read,         // Memory read enable
    output reg mem_write,        // Memory write enable
    output reg [1:0] alu_src1,   // ALU source 1 select
    output reg [1:0] alu_src2,   // ALU source 2 select
    output reg [1:0] wb_sel,     // Writeback data select
    output reg branch,           // Branch instruction flag
    output reg jump              // Jump instruction flag
);

    // Extract instruction fields
    wire [6:0] opcode = inst[6:0];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];
    
    // ALU operation encoding (must match alu.v)
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
    
    // Immediate type encoding (must match imm_gen.v)
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;
    
    // ALU source 1 select encoding
    localparam ALU1_RS1 = 2'b00;  // rs1
    localparam ALU1_PC  = 2'b01;  // PC
    localparam ALU1_ZERO = 2'b10; // 0 (for LUI)
    
    // ALU source 2 select encoding
    localparam ALU2_RS2 = 2'b00;  // rs2
    localparam ALU2_IMM = 2'b01;  // Imm
    
    // Writeback select encoding
    localparam WB_ALU = 2'b00;
    localparam WB_MEM = 2'b01;
    localparam WB_PC4 = 2'b10;
    
    // MAIN CONTROL LOGIC
    always @(*) begin
        // default values (prevent latches)
        alu_op = ALU_ADD;
        imm_type = IMM_I;
        funct3_out = funct3;     // Pass through funct3 by default
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        alu_src1 = ALU1_RS1;
        alu_src2 = ALU2_RS2;
        wb_sel = WB_ALU;
        branch = 1'b0;
        jump = 1'b0;
        
        case(opcode)
            // R-type
            `OPC_ARI_RTYPE: begin
                reg_write = 1'b1;
                alu_src1 = ALU1_RS1;  // rs1
                alu_src2 = ALU2_RS2;  // rs2
                wb_sel = WB_ALU;
                
                case(funct3)
                    `FNC_ADD_SUB: alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;
                    `FNC_SLL:     alu_op = ALU_SLL;
                    `FNC_SLT:     alu_op = ALU_SLT;
                    `FNC_SLTU:    alu_op = ALU_SLTU;
                    `FNC_XOR:     alu_op = ALU_XOR;
                    `FNC_OR:      alu_op = ALU_OR;
                    `FNC_AND:     alu_op = ALU_AND;
                    `FNC_SRL_SRA: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    default:      alu_op = ALU_ADD;
                endcase
            end
            
            // I-type
            `OPC_ARI_ITYPE: begin
                reg_write = 1'b1;
                imm_type = IMM_I;
                alu_src1 = ALU1_RS1;  // rs1
                alu_src2 = ALU2_IMM;  // immediate
                wb_sel = WB_ALU;
                
                case(funct3)
                    `FNC_ADD_SUB: alu_op = ALU_ADD;  // ADDI
                    `FNC_SLL:     alu_op = ALU_SLL;  // SLLI
                    `FNC_SLT:     alu_op = ALU_SLT;  // SLTI
                    `FNC_SLTU:    alu_op = ALU_SLTU; // SLTIU
                    `FNC_XOR:     alu_op = ALU_XOR;  // XORI
                    `FNC_OR:      alu_op = ALU_OR;   // ORI
                    `FNC_AND:     alu_op = ALU_AND;  // ANDI
                    `FNC_SRL_SRA: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL; // SRAI/SRLI
                    default:      alu_op = ALU_ADD;
                endcase
            end
            
            // Load instructions
            `OPC_LOAD: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                imm_type = IMM_I;
                alu_src1 = ALU1_RS1;  // rs1 (base address)
                alu_src2 = ALU2_IMM;  // offset
                alu_op = ALU_ADD;     // address = rs1 + offset
                wb_sel = WB_MEM;      // write memory data to register
                funct3_out = funct3;  // Pass funct3 to memory controller
                // funct3 determines: LB(000), LH(001), LW(010), LBU(100), LHU(101)
            end
            
            // Store instructions
            `OPC_STORE: begin
                reg_write = 1'b0;     // no register write
                mem_write = 1'b1;
                imm_type = IMM_S;
                alu_src1 = ALU1_RS1;  // rs1 (base address)
                alu_src2 = ALU2_IMM;  // offset
                alu_op = ALU_ADD;     // address = rs1 + offset
                funct3_out = funct3;  // Pass funct3 to memory controller
                // funct3 determines: SB(000), SH(001), SW(010)
            end
            
            // Branch instructions
            `OPC_BRANCH: begin
                reg_write = 1'b0;     // no register write
                branch = 1'b1;
                imm_type = IMM_B;
                alu_src1 = ALU1_RS1;  // rs1
                alu_src2 = ALU2_RS2;  // rs2
                
                // ALU performs comparison
                case(funct3)
                    `FNC_BEQ:  alu_op = ALU_SUB;  // check if rs1 == rs2
                    `FNC_BNE:  alu_op = ALU_SUB;  // check if rs1 != rs2
                    `FNC_BLT:  alu_op = ALU_SLT;  // check if rs1 < rs2 (signed)
                    `FNC_BGE:  alu_op = ALU_SLT;  // check if rs1 >= rs2 (signed)
                    `FNC_BLTU: alu_op = ALU_SLTU; // check if rs1 < rs2 (unsigned)
                    `FNC_BGEU: alu_op = ALU_SLTU; // check if rs1 >= rs2 (unsigned)
                    default:   alu_op = ALU_SUB;
                endcase
            end
            
            // JAL (Jump and Link)
            `OPC_JAL: begin
                reg_write = 1'b1;
                jump = 1'b1;
                imm_type = IMM_J;
                wb_sel = WB_PC4;      // save PC+4 to rd
                alu_src1 = ALU1_PC;   // PC
                alu_src2 = ALU2_IMM;  // offset
                alu_op = ALU_ADD;     // target = PC + offset
            end
            
            // JALR (Jump and Link Register)
            `OPC_JALR: begin
                reg_write = 1'b1;
                jump = 1'b1;
                imm_type = IMM_I;
                wb_sel = WB_PC4;      // save PC+4 to rd
                alu_src1 = ALU1_RS1;  // rs1
                alu_src2 = ALU2_IMM;  // offset
                alu_op = ALU_ADD;     // target = rs1 + offset
            end
            
            // LUI (Load Upper Immediate)
            `OPC_LUI: begin
                reg_write = 1'b1;
                imm_type = IMM_U;
                alu_src1 = ALU1_ZERO; // 0
                alu_src2 = ALU2_IMM;  // immediate << 12
                alu_op = ALU_ADD;     // rd = 0 + immediate
                wb_sel = WB_ALU;
            end
            
            // AUIPC (Add Upper Immediate to PC)
            `OPC_AUIPC: begin
                reg_write = 1'b1;
                imm_type = IMM_U;
                alu_src1 = ALU1_PC;   // PC
                alu_src2 = ALU2_IMM;  // immediate << 12
                alu_op = ALU_ADD;     // rd = PC + immediate
                wb_sel = WB_ALU;
            end
            
            default: begin
                // Keep default values
            end
        endcase
    end
    
endmodule
