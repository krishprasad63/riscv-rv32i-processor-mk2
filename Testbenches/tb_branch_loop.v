`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 09:15:43
// Design Name: 
// Module Name: tb_branch_loop
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

module tb_branch_loop();

    reg clk;
    reg reset;
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;
    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;

    wire [31:0] write_back_data;

    //--------------------------------------------------
    // DUT
    //--------------------------------------------------
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

    //--------------------------------------------------
    // CLOCK
    //--------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //--------------------------------------------------
    // TEST SEQUENCE
    //--------------------------------------------------
    initial begin

        $display("====================================");
        $display(" BRANCH LOOP TEST ");
        $display("====================================");

        base_pc          = 32'h00000000;
        load_enable      = 0;
        fetch_enable     = 0;
        reg_write_enable = 0;
        reset            = 1;

        #20;
        reset = 0;

        #1;
        $display("After reset:");
        $display("x0=%h", uut.Register[0]);
        $display("x1=%h", uut.Register[1]);

        //--------------------------------------------------
        // LOAD PROGRAM
        //--------------------------------------------------

        load_enable = 1;

        // addi x1,x0,5
        load_address = 32'h00000000;
        load_data    = 32'h00500093;
        #10;

        // nop
        load_address = 32'h00000004;
        load_data    = 32'h00000013;
        #10;

        // nop
        load_address = 32'h00000008;
        load_data    = 32'h00000013;
        #10;

        // nop
        load_address = 32'h0000000C;
        load_data    = 32'h00000013;
        #10;

        // nop
        load_address = 32'h00000010;
        load_data    = 32'h00000013;
        #10;

        // loop:
        // addi x1,x1,-1
        load_address = 32'h00000014;
        load_data    = 32'hFFF08093;
        #10;

        // nop
        load_address = 32'h00000018;
        load_data    = 32'h00000013;
        #10;

        // nop
        load_address = 32'h0000001C;
        load_data    = 32'h00000013;
        #10;

        // nop
        load_address = 32'h00000020;
        load_data    = 32'h00000013;
        #10;

        // nop
        load_address = 32'h00000024;
        load_data    = 32'h00000013;
        #10;

        // Placeholder branch instruction
        load_address = 32'h00000028;
        load_data    = 32'h00000063;
        #10;

        //--------------------------------------------------
        // START CPU
        //--------------------------------------------------

        load_enable      = 0;
        fetch_enable     = 1;
        reg_write_enable = 1;

        $display("------------------------------------");
        $display("Program Loaded");
        $display("------------------------------------");

        #700;

        $display("------------------------------------");
        $display("FINAL x1 = %0d", uut.Register[1]);
        $display("FINAL x1(hex) = %h", uut.Register[1]);
        $display("------------------------------------");

        $finish;
    end

    //--------------------------------------------------
    // MONITOR
    //--------------------------------------------------
    always @(posedge clk) begin

        if(fetch_enable) begin

            $display(
            "T=%0t | PC=%h | INST=%h | x1=%h | DEC_IMM=%h | EX_IMM=%h | BEQ=%b | BNE=%b | WB=%h",
            $time,
            uut.pc,
            uut.fetched_instruction,
            uut.Register[1],
            uut.branch_imm_address,
            uut.ex_branch_imm,
            uut.branch_beq,
            uut.branch_bneq,
            uut.write_back_data
            );

        end

    end

endmodule