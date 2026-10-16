`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 18:46:04
// Design Name: 
// Module Name: tb_blt
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

module tb_blt;

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
    // Load Instruction Task
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

        //--------------------------------------------------------
        // Reset
        //--------------------------------------------------------
        #20;
        reset = 0;

        //--------------------------------------------------------
        // Program
        //
        // addi x2,x0,40
        // addi x3,x0,10
        // blt  x2,x3,L1
        // addi x4,x0,111
        // L1:
        // addi x5,x0,222
        // DONE:
        // beq x0,x0,DONE
        //--------------------------------------------------------

        load_instruction(32'd0 , 32'h02800113);
        load_instruction(32'd4 , 32'h00A00193);
        load_instruction(32'd8 , 32'h00314463);
        load_instruction(32'd12, 32'h06F00213);
        load_instruction(32'd16, 32'h0DE00293);
        load_instruction(32'd20, 32'h00000063);

        //--------------------------------------------------------
        // Start CPU
        //--------------------------------------------------------
        @(negedge clk);
        fetch_enable = 1;

        //--------------------------------------------------------
        // Execute
        //--------------------------------------------------------
        repeat (30)
            @(posedge clk);

        //--------------------------------------------------------
        // Report
        //--------------------------------------------------------

        $display("");
        $display("========================================");
        $display("          BLT TEST REPORT");
        $display("========================================");

        $display("");
        $display("Registers");
        $display("x2 = %0d", dut.Register[2]);
        $display("x3 = %0d", dut.Register[3]);
        $display("x4 = %0d", dut.Register[4]);
        $display("x5 = %0d", dut.Register[5]);

        $display("");
        $display("EXPECTED");
        $display("x2 = 40");
        $display("x3 = 10");
        $display("x4 = 111");
        $display("x5 = 222");

        if (dut.Register[2] == 40 &&
            dut.Register[3] == 10 &&
            dut.Register[4] == 111 &&
            dut.Register[5] == 222)
        begin
            $display("");
            $display("RESULT : PASS");
        end
        else
        begin
            $display("");
            $display("RESULT : FAIL");
        end

        //--------------------------------------------------------
        // Debug
        //--------------------------------------------------------

        $display("");
        $display("Current PC         = %0d", dut.pc);
        $display("IF Instruction     = %h", dut.if_id_instruction);
        $display("EX Instruction     = %h", dut.ex_instruction);
        $display("Branch BLT         = %b", dut.branch_blt);
        $display("EX ALU Result      = %0d", dut.ex_alu_result);

        #20;
        $finish;

    end

endmodule