`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.05.2026 20:49:28
// Design Name: 
// Module Name: ex_mem_register
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


module ex_mem_register(
    input clk,
    input reset,

    // --- Inputs from Execute Stage ---
    // Control Signals
    input in_mem_read,
    input in_mem_write,
    input in_mem_to_reg,
    input in_reg_write,

    // Data
    input [31:0] in_alu_result,
    // Data from rs2, for store instructions
    input [31:0] in_store_data,
    input [4:0]  in_rd,

    // --- Outputs to Memory Stage ---
    // Control Signals
    output reg out_mem_read,
    output reg out_mem_write,
    output reg out_mem_to_reg,
    output reg out_reg_write,

    // Data
    output reg [31:0] out_alu_result,
    output reg [31:0] out_store_data,
    output reg [4:0]  out_rd
);

    always @(posedge clk or posedge reset)
    begin
        if (reset) begin
            /* On reset, clear control signals
             to prevent memory operations*/
            out_mem_read    <= 1'b0;
            out_mem_write   <= 1'b0;
            out_mem_to_reg  <= 1'b0;
            out_reg_write   <= 1'b0;
            
            out_alu_result  <= 32'b0;
            out_store_data  <= 32'b0;
            out_rd          <= 5'b0;
            
        end
        else begin
            /*   On a clock edge, capture all 
            the inputs from the Execute stage*/
            out_mem_read    <= in_mem_read;
            out_mem_write   <= in_mem_write;
            out_mem_to_reg  <= in_mem_to_reg;
            out_reg_write   <= in_reg_write;
            
            out_alu_result  <= in_alu_result;
            out_store_data  <= in_store_data;
            out_rd          <= in_rd;
            
        end
    end
endmodule

