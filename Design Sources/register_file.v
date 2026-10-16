`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.05.2026 11:20:10
// Design Name: 
// Module Name: register_file
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


module register_file(
    input clk,
    input reset,

    input write_enable,
    input [4:0] write_addr,
    input [31:0] write_data,

    input [4:0] rs1,
    input [4:0] rs2,

    output [31:0] read_data_1,
    output [31:0] read_data_2
);

    reg [31:0] Register [0:31];

    integer i;

    assign read_data_1 = Register[rs1];
    assign read_data_2 = Register[rs2];

    always @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
            for(i=0;i<32;i=i+1)
                Register[i] <= 32'b0;
        end
        else if(write_enable)
        begin
            Register[write_addr] <= write_data;
        end

        Register[0] <= 32'b0;
    end

endmodule
