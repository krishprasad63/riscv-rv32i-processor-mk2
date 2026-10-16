`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 21:35:27
// Design Name: 
// Module Name: tb_forwarding
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

    module tb_forwarding;

    reg clk;
    reg reset;
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;
    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;
    wire [31:0] write_back_data;

    //---------------------------------------
    // DUT
    //---------------------------------------
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

    //---------------------------------------
    // Clock
    //---------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //---------------------------------------
    // Test
    //---------------------------------------

    initial begin

        reset = 1;
        load_enable = 1;
        fetch_enable = 0;
        reg_write_enable = 1;
        base_pc = 32'd0;

        #20;
        reset = 0;

        //------------------------------------
        // Program
        //------------------------------------

        // addi x1,x0,10
        load_address = 32'd0;
        load_data    = 32'h00A00093; #10;

        // add x2,x1,x1
        load_address = 32'd4;
        load_data    = 32'h00108133; #10;

        // add x3,x2,x2
        load_address = 32'd8;
        load_data    = 32'h002101B3; #10;

        // add x4,x3,x3
        load_address = 32'd12;
        load_data    = 32'h00318233; #10;

        // add x5,x4,x4
        load_address = 32'd16;
        load_data    = 32'h004202B3; #10;

        //--------------------------------------------------
        // Some NOPs
        //--------------------------------------------------
        
        // NOP
        load_address = 32'd20;
        load_data    = 32'h00000013;
        #10;

        // NOP
        load_address = 32'd24;
        load_data    = 32'h00000013;
        #10;

        // NOP
        load_address = 32'd28;
        load_data    = 32'h00000013;
        #10;

        // NOP
        load_address = 32'd32;
        load_data    = 32'h00000013;
        #10;

        //--------------------------------------------------
        // Start Execution
        //--------------------------------------------------
        load_enable = 0;
        fetch_enable = 1;

        // Allow pipeline to finish
        #250;

        //--------------------------------------------------
        // Results
        //--------------------------------------------------
        $display("=========================================");
        $display("      FORWARDING UNIT TEST");
        $display("=========================================");
        $display("x1 = %0d", uut.Register[1]);
        $display("x2 = %0d", uut.Register[2]);
        $display("x3 = %0d", uut.Register[3]);
        $display("x4 = %0d", uut.Register[4]);
        $display("x5 = %0d", uut.Register[5]);
        $display("=========================================");

        if( uut.Register[1] == 10 &&
            uut.Register[2] == 20 &&
            uut.Register[3] == 40 &&
            uut.Register[4] == 80 &&
            uut.Register[5] == 160 )
        begin
            $display("PASS : EX Forwarding Working Correctly");
        end
        else
        begin
            $display("FAIL : Forwarding Error Detected");
        end
        $finish;

        end
        endmodule
