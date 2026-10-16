`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2026 11:09:11
// Design Name: 
// Module Name: writeback_stage
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


module writeback_stage(

    input reg_write_enable,

    input mem_to_reg,
    input [31:0] read_data,
    input [31:0] alu_result,
    input [4:0] rd,

    output [31:0] write_back_data,
    output [4:0] write_back_rd,
    output write_back_enable
);

    assign write_back_data =
        (mem_to_reg) ? read_data : alu_result;

    assign write_back_rd = rd;

    assign write_back_enable =
        reg_write_enable && (rd != 5'd0);

endmodule