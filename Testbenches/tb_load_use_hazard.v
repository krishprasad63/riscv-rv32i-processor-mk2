`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 21:39:29
// Design Name: 
// Module Name: tb_load_use_hazard
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

module tb_load_use_hazard;

    reg clk;
    reg reset;
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;

    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;

    wire [31:0] write_back_data;

    //-------------------------------------------
    // DUT
    //-------------------------------------------

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

    //--------------------------------------------
    // Clock Generation
    //--------------------------------------------

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //--------------------------------------------
    // Test Sequence
    //--------------------------------------------

    initial begin
        reset            = 1;
        load_enable      = 1;
        fetch_enable     = 0;
        reg_write_enable = 1;
        base_pc          = 32'd0;

        #20;
        reset = 0;

        //-----------------------------------------
        // Program Loading
        //-----------------------------------------

        // addi x1,x0,25
        load_address = 32'd0;
        load_data    = 32'h01900093;
        #10;

        // sw x1,0(x0)
        load_address = 32'd4;
        load_data    = 32'h00102023;
        #10;

        // lw x2,0(x0)
        load_address = 32'd8;
        load_data    = 32'h00002103;
        #10;

        // add x3,x2,x2
        load_address = 32'd12;
        load_data    = 32'h002101B3;
        #10;

        //------------------------------------------
        // Begin Execution
        //------------------------------------------
        load_enable  = 0;
        fetch_enable = 1;

        //--------------------------------------------------
        // Allow Pipeline to Finish
        //--------------------------------------------------
        #350;
        //--------------------------------------------------
        // Report
        //--------------------------------------------------
        $display("");
        $display("========================================");
        $display("    LOAD-USE HAZARD TEST REPORT");
        $display("========================================");

        $display("");
        $display("EXPECTED");
        $display("MEM[0] = 25");
        $display("x1 = 25");
        $display("x2 = 25");
        $display("x3 = 50");

        $display("");
        $display("OBSERVED");
        $display("MEM[0] = %0d", uut.mem_stage.Memory[0]);
        $display("x1 = %0d", uut.Register[1]);
        $display("x2 = %0d", uut.Register[2]);
        $display("x3 = %0d", uut.Register[3]);

        $display("");

        if( uut.mem_stage.Memory[0] == 25 &&
            uut.Register[1] == 25 &&
            uut.Register[2] == 25 &&
            uut.Register[3] == 50)
        begin
            $display("RESULT : PASS");
        end else
        begin
            $display("RESULT : FAIL");
        end
        $finish;
        end
        
        endmodule
        
         