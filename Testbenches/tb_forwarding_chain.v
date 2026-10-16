`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 23:50:26
// Design Name: 
// Module Name: tb_forwarding_chain
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

module tb_forwarding_chain;

    //------------------------------------------------------------
    // Inputs
    //------------------------------------------------------------
    reg clk;
    reg reset;
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;

    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;

    //------------------------------------------------------------
    // Output
    //------------------------------------------------------------
    wire [31:0] write_back_data;

    //------------------------------------------------------------
    // DUT
    //------------------------------------------------------------
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

    //------------------------------------------------------------
    // Clock
    //------------------------------------------------------------
    always #5 clk = ~clk;

    //------------------------------------------------------------
    // Task
    //------------------------------------------------------------
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

    //------------------------------------------------------------
    // Test
    //------------------------------------------------------------
    initial begin

        clk = 0;
        reset = 1;
        load_enable = 0;
        fetch_enable = 0;
        reg_write_enable = 1;
        load_address = 0;
        load_data = 0;
        base_pc = 0;

        //-----------------------------------------
        // Reset
        //-----------------------------------------
        #20;
        reset = 0;

        //-----------------------------------------
        // Program
        //-----------------------------------------

        // addi x20,x0,5
        load_instruction(32'd0 ,32'h00500A13);

        // addi x21,x20,-1
        load_instruction(32'd4 ,32'hFFFA0A93);

        // sub x22,x21,x0
        load_instruction(32'd8 ,32'h400A8B33);

        // addi x23,x22,1
        load_instruction(32'd12,32'h001B0B93);

        // DONE
        load_instruction(32'd16,32'h00000063);

        //-----------------------------------------
        // Start CPU
        //-----------------------------------------
        @(negedge clk);
        fetch_enable = 1;

        //-----------------------------------------
        // Wait until DONE
        //-----------------------------------------
        wait(dut.pc == 32'h00000010);

        repeat(10)
            @(posedge clk);

        //-----------------------------------------
        // Report
        //-----------------------------------------
        $display("");
        $display("========================================");
        $display("   FORWARDING CHAIN TEST REPORT");
        $display("========================================");

        $display("");
        $display("EXPECTED");
        $display("x20 = 5");
        $display("x21 = 4");
        $display("x22 = 4");
        $display("x23 = 5");

        $display("");
        $display("OBSERVED");
        $display("x20 = %0d", dut.Register[20]);
        $display("x21 = %0d", dut.Register[21]);
        $display("x22 = %0d", dut.Register[22]);
        $display("x23 = %0d", dut.Register[23]);

        if(dut.Register[20]==5 &&
           dut.Register[21]==4 &&
           dut.Register[22]==4 &&
           dut.Register[23]==5)
        begin
            $display("");
            $display("RESULT : PASS");
        end
        else
        begin
            $display("");
            $display("RESULT : FAIL");
        end

        $finish;

    end

endmodule