`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 20:22:24
// Design Name: 
// Module Name: tb_loop_blt
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


`timescale 1ns/1ps

module tb_loop_blt;

reg clk;
reg reset;

reg load_enable;
reg fetch_enable;
reg reg_write_enable;

reg [31:0] load_address;
reg [31:0] load_data;
reg [31:0] base_pc;

wire [31:0] write_back_data;

riscv dut(
    .clk(clk),
    .reset(reset),
    .load_enable(load_enable),
    .fetch_enable(fetch_enable),
    .reg_write_enable(reg_write_enable),
    .load_address(load_address),
    .load_data(load_data),
    .base_pc(base_pc),
    .write_back_data(write_back_data)
);

always #5 clk = ~clk;

task load_instruction;
input [31:0] address;
input [31:0] instruction;
begin
    @(posedge clk);
    load_enable  <= 1;
    load_address <= address;
    load_data    <= instruction;

    @(posedge clk);
    load_enable <= 0;
end
endtask

initial begin

    clk = 0;
    reset = 1;

    load_enable = 0;
    fetch_enable = 0;
    reg_write_enable = 1;

    load_address = 0;
    load_data = 0;

    base_pc = 0;

    repeat(2) @(posedge clk);

    //--------------------------------------------------
    // Program
    //--------------------------------------------------

    load_instruction(32'd0 ,32'h00000093);
    load_instruction(32'd4 ,32'h00500113);
    load_instruction(32'd8 ,32'h00108093);
    load_instruction(32'd12,32'hFE20CEE3);
    load_instruction(32'd16,32'h07B00193);
    load_instruction(32'd20,32'h00000063);

    //--------------------------------------------------

    @(posedge clk);

    reset = 0;
    fetch_enable = 1;

    repeat(40) @(posedge clk);

    $display("");
    $display("========================================");
    $display("        SIMPLE LOOP TEST");
    $display("========================================");

    $display("x1 = %0d", dut.Register[1]);
    $display("x2 = %0d", dut.Register[2]);
    $display("x3 = %0d", dut.Register[3]);

    $display("");
    $display("EXPECTED");
    $display("x1 = 5");
    $display("x2 = 5");
    $display("x3 = 123");

    if(dut.Register[1]==5 &&
       dut.Register[2]==5 &&
       dut.Register[3]==123)
        $display("\nRESULT : PASS");
    else
        $display("\nRESULT : FAIL");

    $finish;

end

endmodule
