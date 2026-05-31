`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 10:53:46
// Design Name: 
// Module Name: if_id_register
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


module if_id_register(
    input clk,
    input reset,

    input [31:0] in_pc,
    input [31:0] in_instruction,

    output reg [31:0] out_pc,
    output reg [31:0] out_instruction
);

always @(posedge clk or posedge reset)
begin

    if(reset)
    begin
        out_pc <= 32'd0;
        out_instruction <= 32'd0;
    end

    else
    begin
        out_pc <= in_pc;
        out_instruction <= in_instruction;
    end

end

endmodule