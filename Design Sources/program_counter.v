`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 21:05:56
// Design Name: 
// Module Name: program_counter
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


module program_counter(
    input clk,
    input reset,
    input enable,

    input beq,
    input bneq,
    input bge,
    input blt,
    input jump,

    // Now contains COMPLETE target address
    input [31:0] imm_address,

    // Complete jump target address
    input [31:0] imm_address_jump,

    input [31:0] base_address,

    output reg [31:0] pc,
    output reg [31:0] current_pc
);

    //--------------------------------------------------
    // PROGRAM COUNTER
    //--------------------------------------------------
    always @(posedge clk) begin

        if(reset)
            pc <= base_address;

        else if(enable) begin

            // Branch taken
            if(beq || bneq || bge || blt)
                pc <= imm_address;

            // Jump taken
            else if(jump)
                pc <= imm_address_jump;

            // Normal sequential execution
            else
                pc <= pc + 32'd4;

        end
    end

    //--------------------------------------------------
    // RETURN ADDRESS (PC + 4)
    //--------------------------------------------------
    always @(posedge clk) begin

        if(reset)
            current_pc <= 32'd0;

        else
            current_pc <= pc + 32'd4;

    end

endmodule