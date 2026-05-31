`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 12:23:06
// Design Name: 
// Module Name: tb_bne_x4
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


`timescale 1ns / 1ps

module tb_bne_x4();

    reg clk;
    reg reset;
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;
    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;

    wire [31:0] write_back_data;

    riscv uut(
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

    //--------------------------------
    // CLOCK
    //--------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //--------------------------------
    // TEST
    //--------------------------------
    initial begin

        reset = 1;
        load_enable = 0;
        fetch_enable = 0;
        reg_write_enable = 0;
        base_pc = 0;

        #20;
        reset = 0;

        load_enable = 1;

        // addi x4,x0,5
        load_address = 32'h00000000;
        load_data    = 32'h00500213;
        #10;

        // NOPs
        load_address = 32'h00000004;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000008;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h0000000C;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000010;
        load_data    = 32'h00000013;
        #10;

        // loop:
        // addi x4,x4,-1
        load_address = 32'h00000014;
        load_data    = 32'hFFF20213;
        #10;

        // bne x4,x0,loop
        load_address = 32'h00000018;
        load_data    = 32'hFE021EE3;
        #10;

        load_enable = 0;
        fetch_enable = 1;
        reg_write_enable = 1;

        #1200;

        $display("--------------------------------");
        $display("FINAL");
        $display("--------------------------------");
        $display("x4 = %d", uut.Register[4]);

        if(uut.Register[4] == 0)
            $display("PASS");
        else
            $display("FAIL");

        $finish;

    end

    //--------------------------------
    // MONITOR
    //--------------------------------
    always @(posedge clk) begin

        if(fetch_enable) begin

            $display(
            "PC=%h  x4=%d",
            uut.pc,
            uut.Register[4]
            );

            $display(
            "ex_pc=%h ex_branch_imm=%h target=%h bne=%b",
            uut.ex_pc,
            uut.ex_branch_imm,
            uut.branch_target,
            uut.branch_bneq
            );

            $display("--------------------------------");

        end

    end

endmodule
