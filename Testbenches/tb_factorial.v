`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 11:47:52
// Design Name: 
// Module Name: tb_factorial
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


module tb_factorial();

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
    // TEST
    //--------------------------------------------------
    initial begin

        $display("====================================");
        $display(" FACTORIAL TEST ");
        $display("====================================");

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

        //--------------------------------------
        // addi x1,x0,5
        //--------------------------------------
        load_address = 32'h00000000;
        load_data    = 32'h00500093;
        #10;

        //--------------------------------------
        // NOPs
        //--------------------------------------
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

        //--------------------------------------
        // addi x2,x0,1
        //--------------------------------------
        load_address = 32'h00000014;
        load_data    = 32'h00100113;
        #10;

        //--------------------------------------
        // NOPs
        //--------------------------------------
        load_address = 32'h00000018;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h0000001C;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000020;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000024;
        load_data    = 32'h00000013;
        #10;

        //--------------------------------------------------
        // LOOP START
        //--------------------------------------------------

        //--------------------------------------
        // mul x2,x2,x1
        //--------------------------------------
        load_address = 32'h00000028;
        load_data    = 32'h02110133;
        #10;

        //--------------------------------------
        // addi x1,x1,-1
        //--------------------------------------
        load_address = 32'h0000002C;
        load_data    = 32'hFFF08093;
        #10;

        //--------------------------------------
        // bne x1,x0,loop
        //
        // target = 0x28
        // current = 0x30
        // offset = -8
        //--------------------------------------
        load_address = 32'h00000030;
        load_data    = 32'hFE009CE3;
        #10;

        //--------------------------------------
        // NOPs
        //--------------------------------------
        load_address = 32'h00000034;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000038;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h0000003C;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000040;
        load_data    = 32'h00000013;
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

        //--------------------------------------------------
        // WAIT FOR FACTORIAL TO FINISH
        //--------------------------------------------------
        wait(fetch_enable &&
             uut.Register[1] == 0 &&
             uut.pc >= 32'h00000030);

        #20;

        //--------------------------------------------------
        // RESULTS
        //--------------------------------------------------
        $display("------------------------------------");
        $display("FINAL RESULTS");
        $display("------------------------------------");

        $display("x1 = %0d (%h)", uut.Register[1], uut.Register[1]);
        $display("x2 = %0d (%h)", uut.Register[2], uut.Register[2]);

        if(uut.Register[2] == 120)
            $display("PASS : FACTORIAL WORKING");
        else
            $display("FAIL : FACTORIAL FAILED");

        $finish;

    end

    //--------------------------------------------------
    // MONITOR
    //--------------------------------------------------
    always @(posedge clk) begin

        if(fetch_enable) begin

            $display(
            "T=%0t | PC=%h | INST=%h | x1=%h | x2=%h | WB=%h",
            $time,
            uut.pc,
            uut.fetched_instruction,
            uut.Register[1],
            uut.Register[2],
            uut.write_back_data
            );

        end

    end

endmodule