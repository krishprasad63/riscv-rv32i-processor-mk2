`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.04.2026 19:29:12
// Design Name: 
// Module Name: control_unit
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


module control_unit(
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,

    output reg [6:0] alu_op,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg reg_write,

    output reg beq_control,
    output reg bneq_control,
    output reg blt_control,
    output reg bge_control
);

    parameter ALU_ADD   = 7'b0000000,
              ALU_AND   = 7'b0000001,
              ALU_OR    = 7'b0000010,
              ALU_SUB   = 7'b0000011,
              ALU_XOR   = 7'b0000100,
              ALU_SLT   = 7'b0000101,
              ALU_NOR   = 7'b0000110,
              ALU_SHIFT = 7'b0000111,
              ALU_MUL   = 7'b0001000,

              ALU_BEQ   = 7'b0100000,
              ALU_BNEQ  = 7'b0100001,
              ALU_BLT   = 7'b0100010,
              ALU_BGE   = 7'b0100011;

    always @(*) begin

        // Defaults
        alu_op       = ALU_ADD;
        alu_src      = 0;
        mem_read     = 0;
        mem_write    = 0;
        mem_to_reg   = 0;
        reg_write    = 0;

        beq_control  = 0;
        bneq_control = 0;
        blt_control  = 0;
        bge_control  = 0;

        case(opcode)

            //--------------------------------------------------
            // R-TYPE (RV32I + M)
            //--------------------------------------------------
            7'b0110011: begin

                alu_src = 0;
                reg_write = 1;

                case(funct3)

                    // ADD / SUB / MUL
                    3'b000: begin

                        if(funct7 == 7'b0000000)
                            alu_op = ALU_ADD;

                        else if(funct7 == 7'b0100000)
                            alu_op = ALU_SUB;

                        else if(funct7 == 7'b0000001)
                            alu_op = ALU_MUL;

                        else
                            alu_op = 7'b1111111;
                    end

                    3'b111: alu_op = ALU_AND;
                    3'b110: alu_op = ALU_OR;
                    3'b100: alu_op = ALU_XOR;
                    3'b010: alu_op = ALU_SLT;

                    // SLL
                    3'b001: alu_op = ALU_SHIFT;

                    // SRL / SRA
                    3'b101: alu_op = ALU_SHIFT;

                    default: alu_op = 7'b1111111;

                endcase
            end

            //--------------------------------------------------
            // I-TYPE
            //--------------------------------------------------
            7'b0010011: begin

                alu_src = 1;
                reg_write = 1;

                case(funct3)

                    3'b000: alu_op = ALU_ADD;    // ADDI
                    3'b111: alu_op = ALU_AND;    // ANDI
                    3'b110: alu_op = ALU_OR;     // ORI
                    3'b100: alu_op = ALU_XOR;    // XORI
                    3'b010: alu_op = ALU_SLT;    // SLTI

                    3'b001: alu_op = ALU_SHIFT;  // SLLI
                    3'b101: alu_op = ALU_SHIFT;  // SRLI/SRAI

                    default: alu_op = 7'b1111111;

                endcase
            end

            //--------------------------------------------------
            // BRANCHES
            //--------------------------------------------------
            7'b1100011: begin

                case(funct3)

                    3'b000: begin
                        alu_op      = ALU_BEQ;
                        beq_control = 1;
                    end

                    3'b001: begin
                        alu_op       = ALU_BNEQ;
                        bneq_control = 1;
                    end

                    // Standard RV32I encoding
                    3'b100: begin
                        alu_op      = ALU_BLT;
                        blt_control = 1;
                    end

                    // Standard RV32I encoding
                    3'b101: begin
                        alu_op      = ALU_BGE;
                        bge_control = 1;
                    end

                    default:
                        alu_op = 7'b1111111;

                endcase
            end

            //--------------------------------------------------
            // LOAD WORD
            //--------------------------------------------------
            7'b0000011: begin

                alu_op     = ALU_ADD;
                alu_src    = 1;
                mem_read   = 1;
                mem_to_reg = 1;
                reg_write  = 1;

            end

            //--------------------------------------------------
            // STORE WORD
            //--------------------------------------------------
            7'b0100011: begin

                alu_op    = ALU_ADD;
                alu_src   = 1;
                mem_write = 1;

            end

            //--------------------------------------------------
            // INVALID
            //--------------------------------------------------
            default: begin

                alu_op = 7'b1111111;

            end

        endcase
    end

endmodule