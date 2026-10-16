`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.04.2026 10:21:53
// Design Name: 
// Module Name: decode_stage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// ======UPDATED DECODED STAGE =============

module decode_stage(
    input  clk,
    input  [31:0] instruction,

    output reg [6:0]  opcode,
    output reg [4:0]  rd,
    output reg [2:0]  funct3,
    output reg [4:0]  rs1,
    output reg [4:0]  rs2,
    output reg [6:0]  funct7,

    output reg [31:0] imm,
    output [6:0] alu_opcode,

    output wire mem_read,
    output alu_src,
    output wire mem_write,
    output wire mem_to_reg,
    output wire reg_write,

    output beq_control,
    output bneq_control,
    output blt_control,
    output bge_control,

    output reg [31:0] imm_address // B-type branch immediate
);

    control_unit CU(
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_opcode),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .beq_control(beq_control),
        .bneq_control(bneq_control),
        .blt_control(blt_control),
        .bge_control(bge_control)
    );

    always @(*) begin

        opcode = instruction[6:0];
        rd     = instruction[11:7];
        funct3 = instruction[14:12];
        rs1    = instruction[19:15];
        rs2    = instruction[24:20];
        funct7 = instruction[31:25];

        //--------------------------------------------------
        // Immediate Generation
        //--------------------------------------------------
        case(instruction[6:0])

            // I-Type (ADDI, LW, ANDI, ORI, XORI, etc.)
            7'b0010011,
            7'b0000011:
            begin
                imm = {{20{instruction[31]}},
                       instruction[31:20]};
            end

            // S-Type (SW)
            7'b0100011:
            begin
                imm = {{20{instruction[31]}},
                       instruction[31:25],
                       instruction[11:7]};
            end

            // Default
            default:
            begin
                imm = {{20{instruction[31]}},
                       instruction[31:20]};
            end

        endcase

        //--------------------------------------------------
        // B-Type Branch Immediate
        //--------------------------------------------------
        imm_address = {
            {20{instruction[31]}},
            instruction[31],
            instruction[7],
            instruction[30:25],
            instruction[11:8],
            1'b0
        };

    end

endmodule



/* ========DECODE STAGE-BEFORE===============
module decode_stage(
    input  clk, input  [31:0] instruction,
    output reg [6:0]  opcode, output reg [4:0]  rd,
    output reg [2:0]  funct3, output reg [4:0]  rs1,
    output reg [4:0]  rs2,    output reg [6:0]  funct7,
    output reg [31:0] imm,    output [6:0] alu_opcode,
    output wire mem_read,     output alu_src,
    output wire mem_write,    output wire mem_to_reg,
    output  beq_control,      output  bneq_control,
    output  blt_control,      output  bge_control,
    output reg [31:0] imm_address //for B-type
    );
    
    control_unit CU(
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_opcode),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .beq_control(beq_control),
        .bneq_control(bneq_control),
        .blt_control(blt_control),
        .bge_control(bge_control)
    );

    always @(*)
    begin
        opcode = instruction[6:0];
        rd     = instruction[11:7];
        funct3 = instruction[14:12];
        rs1    = instruction[19:15];
        rs2    = instruction[24:20];
        funct7 = instruction[31:25];
    
        imm = {{20{instruction[31]}}, instruction[31:20]};
    
        imm_address = {
            {20{instruction[31]}},
            instruction[31],
            instruction[7],
            instruction[30:25],
            instruction[11:8],
            1'b0
        };
    end 
endmodule

*/