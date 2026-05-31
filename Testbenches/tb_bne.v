`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 10:09:45
// Design Name: 
// Module Name: tb_bne
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

module tb_bne();

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
    riscv uut (
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
    // TEST
    //--------------------------------------------------
    initial begin

        $display("====================================");
        $display(" BNE TEST ");
        $display("====================================");

        //--------------------------------------------------
        // RESET
        //--------------------------------------------------
        base_pc          = 32'h00000000;
        load_enable      = 0;
        fetch_enable     = 0;
        reg_write_enable = 0;
        reset            = 1;

        #20;
        reset = 0;

        //--------------------------------------------------
        // PROGRAM LOAD
        //--------------------------------------------------
        load_enable = 1;

        // addi x1,x0,5
        load_address = 32'h00000000;
        load_data    = 32'h00500093;
        #10;

        // addi x2,x0,0
        load_address = 32'h00000004;
        load_data    = 32'h00000113;
        #10;

        // bne x1,x2,label
        load_address = 32'h00000008;
        load_data    = 32'h00209C63;
        #10;

        // NOPs
        load_address = 32'h0000000C;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000010;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000014;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000018;
        load_data    = 32'h00000013;
        #10;

        // This instruction should be skipped
        // addi x3,x0,99
        load_address = 32'h0000001C;
        load_data    = 32'h06300193;
        #10;

        // Extra NOP
        load_address = 32'h00000020;
        load_data    = 32'h00000013;
        #10;

        // label:
        // addi x4,x0,55
        load_address = 32'h00000024;
        load_data    = 32'h03700213;
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

        //--------------------------------------------------
        // RESULTS
        //--------------------------------------------------
        $display("------------------------------------");
        $display("FINAL RESULTS");
        $display("------------------------------------");

        $display("x1 = %0d", uut.Register[1]);
        $display("x2 = %0d", uut.Register[2]);
        $display("x3 = %0d", uut.Register[3]);
        $display("x4 = %0d", uut.Register[4]);

        $display("------------------------------------");

        if ((uut.Register[1] == 5) &&
            (uut.Register[2] == 0) &&
            (uut.Register[3] == 0) &&
            (uut.Register[4] == 55))
        begin
            $display("PASS : BNE WORKING");
        end
        else
        begin
            $display("FAIL : CHECK BRANCH PATH");
        end

        $finish;
    end

    //--------------------------------------------------
    // MONITOR
    //--------------------------------------------------
    always @(posedge clk) begin

        if(fetch_enable) begin

            $display(
            "T=%0t | PC=%h | INST=%h | x1=%h | x2=%h | x3=%h | x4=%h",
            $time,
            uut.pc,
            uut.fetched_instruction,
            uut.Register[1],
            uut.Register[2],
            uut.Register[3],
            uut.Register[4]
            );

            $display(
            "ex_op=%b | bneq_ctrl=%b | alu=%h | branch_bneq=%b | branch_target=%h",
            uut.ex_alu_op,
            uut.ex_bneq_control,
            uut.ex_alu_result,
            uut.branch_bneq,
            uut.branch_target
            );

            $display("------------------------------------");

        end

    end

endmodule
