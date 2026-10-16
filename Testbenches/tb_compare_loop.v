`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 20:28:22
// Design Name: 
// Module Name: tb_compare_loop
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

module tb_compare_loop;
    
    reg clk;
    reg reset;
    
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;
    
    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;
    
    wire [31:0] write_back_data;
    
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
    
        always #5 clk = ~clk;
        
        task load_instruction;
        input [31:0] address;
        input [31:0] instruction;
        begin
            @(posedge clk);
            load_enable  <= 1'b1;
            load_address <= address;
            load_data    <= instruction;
        
            @(posedge clk);
            load_enable <= 1'b0;
        end
        endtask
        
        initial begin
            clk = 0;
            reset = 1;
            
            load_enable = 0;
            fetch_enable = 0;
            reg_write_enable = 1;
        
            load_address = 0;
            load_data = 0;
            base_pc = 0;
        
            repeat(2) @(posedge clk);
        
            //--------------------------------------------------
            // Program
            //--------------------------------------------------
        
            load_instruction(32'd0 , 32'h00500A13);
            load_instruction(32'd4 , 32'h00400A93);
            load_instruction(32'd8 , 32'h00000513);
            load_instruction(32'd12, 32'h00002103);
            load_instruction(32'd16, 32'h00402183);
            load_instruction(32'd20, 32'h00315663);
            load_instruction(32'd24, 32'h00310663);
            load_instruction(32'd28, 32'h00150513);
            load_instruction(32'd32, 32'hFF5546E3);
            load_instruction(32'd36, 32'h07B00293);
            load_instruction(32'd40, 32'h00000063);
        
            //--------------------------------------------------
            // Initialize Memory
            //--------------------------------------------------
        
            dut.mem_stage.Memory[0] = 10;
            dut.mem_stage.Memory[1] = 20;
        
            //--------------------------------------------------
        
            @(posedge clk);
            reset = 0;
            fetch_enable = 1;
        
            repeat(60) @(posedge clk);
        
            $display("");
            $display("========================================");
            $display("       COMPARE LOOP TEST REPORT");
            $display("========================================");
        
            $display("");
            $display("Registers");
            $display("x2  = %0d  | x3  = %0d  | x5 = %0d", 
            dut.Register[2], dut.Register[3], dut.Register[5]);
            $display("x10 = %0d   | x20 = %0d   | x21 = %0d", 
            dut.Register[10], dut.Register[20], dut.Register[21]);
        
            $display("");
            $display("Memory");
            $display("MEM[0] = %0d | MEM[1] = %0d", 
            dut.mem_stage.Memory[0], dut.mem_stage.Memory[1]);
        
            $display("");
            $display("EXPECTED");
            $display("x10 = 4    |  MEM[0] = 10");
            $display("x5  = 123  |  MEM[1] = 20");
            
        
            if(dut.Register[10] == 4 &&
               dut.Register[5]  == 123 &&
               dut.mem_stage.Memory[0] == 10 &&
               dut.mem_stage.Memory[1] == 20)
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
            $finish;    
            end
  
            endmodule
            
            
