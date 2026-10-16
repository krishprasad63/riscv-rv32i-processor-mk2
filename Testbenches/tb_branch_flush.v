`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 22:06:43
// Design Name: 
// Module Name: tb_branch_flush
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

module tb_branch_flush;

    reg clk;
    reg reset;
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;

    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;

    wire [31:0] write_back_data;

    //-----------------------------------------
    // DUT
    //-----------------------------------------

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

    //-----------------------------------------
    // Clock
    //-----------------------------------------

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //--------------------------------------------------------
    // Test
    //--------------------------------------------------------

    initial begin
        reset            = 1;
        load_enable      = 1;
        fetch_enable     = 0;
        reg_write_enable = 1;
        base_pc          = 32'd0;

        #20; reset = 0;

        //----------------------------------------------------
        // Program
        //----------------------------------------------------

        // addi x1,x0,5
        load_address = 32'd0;  load_data = 32'h00500093; #10;

        // addi x2,x0,5
        load_address = 32'd4;  load_data = 32'h00500113; #10;

        // beq x1,x2,+12
        // Skip next TWO instructions
        load_address = 32'd8;  load_data = 32'h00208663; #10;

        // addi x3,x0,100
        load_address = 32'd12; load_data = 32'h06400193; #10;

        // addi x4,x0,200
        load_address = 32'd16; load_data = 32'h0C800213; #10;

        // L1:
        // addi x5,x0,300
        load_address = 32'd20; load_data = 32'h12C00293; #10;

        // Start Execution
        load_enable  = 0; fetch_enable = 1;

        #400; //Wait

        //--------------------------------------------------
        // Report
        //--------------------------------------------------

        $display("");
        $display("========================================");
        $display("      BRANCH FLUSH TEST REPORT");
        $display("========================================");

        $display("");
        $display("EXPECTED");
        $display("x1 = 5");
        $display("x2 = 5");
        $display("x3 = 0");
        $display("x4 = 0");
        $display("x5 = 300");

        $display("");
        $display("OBSERVED");
        $display("x1 = %0d", uut.Register[1]);
        $display("x2 = %0d", uut.Register[2]);
        $display("x3 = %0d", uut.Register[3]);
        $display("x4 = %0d", uut.Register[4]);
        $display("x5 = %0d", uut.Register[5]);

        $display("");

        if( uut.Register[1] == 5 &&
            uut.Register[2] == 5 &&
            uut.Register[3] == 0 &&
            uut.Register[4] == 0 &&
            uut.Register[5] == 300)
        begin
            $display("RESULT : PASS");
        end
        else
        begin
            $display("RESULT : FAIL");
        end

        $finish;
        end
        endmodule

