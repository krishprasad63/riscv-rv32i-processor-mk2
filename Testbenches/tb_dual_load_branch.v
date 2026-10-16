`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 23:54:58
// Design Name: 
// Module Name: tb_dual_load_branch
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

module tb_dual_load_branch;

    //----------------------------------------------
    // Inputs
    //----------------------------------------------
    reg clk;
    reg reset;
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;

    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;

    //-----------------------------------------------
    // Output
    //-----------------------------------------------
    wire [31:0] write_back_data;

    //-----------------------------------------------
    // DUT
    //-----------------------------------------------
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

    //------------------------------------------------
    // Clock
    //------------------------------------------------
    always #5 clk = ~clk;

    //------------------------------------------------
    // Instruction Loader
    //------------------------------------------------
    task load_instruction;
        input [31:0] addr;
        input [31:0] instr;
        begin
            @(negedge clk);
            load_enable  = 1;
            load_address = addr;
            load_data    = instr;
            @(negedge clk);
            load_enable  = 0;
        end
    endtask

    //------------------------------------------------
    // Test
    //------------------------------------------------
    initial begin

        clk = 0;
        reset = 1;

        load_enable = 0;
        fetch_enable = 0;
        reg_write_enable = 1;

        load_address = 0;
        load_data = 0;
        base_pc = 0;

        //--------------------------------------------
        // Reset
        //--------------------------------------------
        #20;
        reset = 0;

        //--------------------------------------------
        // Program
        //--------------------------------------------

        // addi x10,x0,100
        load_instruction(32'd0 ,32'h06400513);

        // addi x1,x0,5
        load_instruction(32'd4 ,32'h00500093);

        // sw x1,0(x10)
        load_instruction(32'd8 ,32'h00152023);

        // addi x1,x0,10
        load_instruction(32'd12,32'h00A00093);

        // sw x1,4(x10)
        load_instruction(32'd16,32'h00152223);

        // lw x2,0(x10)
        load_instruction(32'd20,32'h00052103);

        // lw x3,4(x10)
        load_instruction(32'd24,32'h00452183);

        // blt x2,x3,LABEL
        load_instruction(32'd28,32'h00314463);

        // addi x4,x0,111
        load_instruction(32'd32,32'h06F00213);

        // LABEL:
        // addi x5,x0,222
        load_instruction(32'd36,32'h0DE00293);

        // DONE
        load_instruction(32'd40,32'h00000063);

        //--------------------------------------------
        // Start CPU
        //--------------------------------------------
        @(negedge clk);
        fetch_enable = 1;

        //----------------------------------------------
        // Wait until DONE
        //----------------------------------------------
        wait(dut.pc == 32'h00000028);

        repeat(12)
            @(posedge clk);

        //----------------------------------------------
        // Report
        //----------------------------------------------
        $display("");
        $display("======================================");
        $display("   DUAL LOAD -> BRANCH TEST REPORT");
        $display("======================================");

        $display("");
        $display("EXPECTED");
        $display("x2 = 5");
        $display("x3 = 10");
        $display("x4 = 0");
        $display("x5 = 222");

        $display("");
        $display("OBSERVED");
        $display("x2 = %0d", dut.Register[2]);
        $display("x3 = %0d", dut.Register[3]);
        $display("x4 = %0d", dut.Register[4]);
        $display("x5 = %0d", dut.Register[5]);

        if(dut.Register[2]==5 &&
           dut.Register[3]==10 &&
           dut.Register[4]==0 &&
           dut.Register[5]==222)
        begin
            $display("");
            $display("RESULT : PASS");
        end else
        begin
            $display("");
            $display("RESULT : FAIL");
        end
        $finish;
        
        end
        endmodule