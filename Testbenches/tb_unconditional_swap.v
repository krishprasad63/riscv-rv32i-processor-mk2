`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 18:59:02
// Design Name: 
// Module Name: tb_unconditional_swap
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

module tb_unconditional_swap;

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
            load_enable  = 1'b1;
            load_address = addr;
            load_data    = instr;
            @(negedge clk);
            load_enable  = 1'b0;
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
        #20; reset = 0;

        //--------------------------------------------------------
        // Program
        //
        // addi x1,x0,40
        // sw   x1,0(x0)
        // addi x1,x0,10
        // sw   x1,4(x0)
        // lw   x2,0(x0)
        // lw   x3,4(x0)
        // sw   x3,0(x0)
        // sw   x2,4(x0)
        // DONE:
        // beq  x0,x0,DONE
        //--------------------------------------------------------

        load_instruction(32'd0 , 32'h02800093);   // addi x1,x0,40
        load_instruction(32'd4 , 32'h00102023);   // sw x1,0(x0)

        load_instruction(32'd8 , 32'h00A00093);   // addi x1,x0,10
        load_instruction(32'd12, 32'h00102223);   // sw x1,4(x0)

        load_instruction(32'd16, 32'h00002103);   // lw x2,0(x0)
        load_instruction(32'd20, 32'h00402183);   // lw x3,4(x0)

        load_instruction(32'd24, 32'h00302023);   // sw x3,0(x0)
        load_instruction(32'd28, 32'h00202223);   // sw x2,4(x0)

        load_instruction(32'd32, 32'h00000063);   // DONE

        //--------------------------------------------------------
        // Start CPU
        //--------------------------------------------------------
        @(negedge clk);
        fetch_enable = 1'b1;

        //--------------------------------------------------------
        // Execute
        //--------------------------------------------------------
        repeat (35) @(posedge clk);

        //--------------------------------------------------------
        // Report
        //--------------------------------------------------------
        $display("");
        $display("========================================");
        $display("     UNCONDITIONAL SWAP TEST REPORT");
        $display("========================================");

        $display("");
        $display("Registers");
        $display("x1 = %0d", dut.Register[1]);
        $display("x2 = %0d", dut.Register[2]);
        $display("x3 = %0d", dut.Register[3]);

        $display("");
        $display("Memory");
        $display("MEM[0] = %0d", dut.mem_stage.Memory[0]);
        $display("MEM[1] = %0d", dut.mem_stage.Memory[1]);

        $display("");
        $display("EXPECTED");
        $display("x2 = 40");
        $display("x3 = 10");
        $display("MEM[0] = 10");
        $display("MEM[1] = 40");

        if (dut.Register[2] == 40 &&
            dut.Register[3] == 10 &&
            dut.mem_stage.Memory[0] == 10 &&
            dut.mem_stage.Memory[1] == 40)
        begin
            $display("");
            $display("RESULT : PASS");
        end
        else
        begin
            $display("");
            $display("RESULT : FAIL");
        end
        $display("========================================");
        #20;
        $finish;
        end
        endmodule
        
        