`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2026 20:30:15
// Design Name: 
// Module Name: write_back_stage
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


module write_back_stage(
    input clk,
    input [31:0]fetched_instruction,
    input [31:0] wb_result,
    input reg_write_enable,
    output reg [4:0] final_rd
    );
    always @(posedge clk) begin
      if (reg_write_enable ) begin
        final_rd <= fetched_instruction[11:7];
      end
    end

endmodule

