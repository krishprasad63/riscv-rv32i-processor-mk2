`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 20:32:17
// Design Name: 
// Module Name: tb_lw_sw_address
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

module tb_lw_sw_address();

    reg clk;
    reg reset;
    reg load_enable;
    reg fetch_enable;
    reg reg_write_enable;
    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;

    wire [31:0] write_back_data;

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

    //--------------------------------
    // CLOCK
    //--------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //--------------------------------
    // TEST
    //--------------------------------
    initial begin

        $display("==========================");
        $display(" LW / SW ADDRESS TEST ");
        $display("==========================");

        reset            = 1;
        load_enable      = 0;
        fetch_enable     = 0;
        reg_write_enable = 0;
        base_pc          = 0;

        #20; reset = 0;

        //--------------------------------
        // PROGRAM LOAD
        //--------------------------------
        load_enable = 1;

        // addi x1,x0,55
        load_address = 32'h00000000;
        load_data    = 32'h03700093;
        #10;

        // pipeline spacing
        load_address = 32'h00000004; 
        load_data    = 32'h00000013; #10;
        load_address = 32'h00000008; 
        load_data    = 32'h00000013; #10;
        load_address = 32'h0000000C; 
        load_data    = 32'h00000013; #10;
        load_address = 32'h00000010; 
        load_data    = 32'h00000013; #10;

        //--------------------------------
        // sw x1,4(x0)
        //--------------------------------
        load_address = 32'h00000014; load_data = 32'h00102223; #10;

        // wait for store
        load_address = 32'h00000018; load_data = 32'h00000013; #10;
        load_address = 32'h0000001C; load_data = 32'h00000013; #10;
        load_address = 32'h00000020; load_data = 32'h00000013; #10;
        load_address = 32'h00000024; load_data = 32'h00000013; #10;

        //--------------------------------
        // lw x2,4(x0)
        //--------------------------------
        load_address = 32'h00000028;
        load_data    = 32'h00402103;
        #10;

        // wait for writeback
        load_address = 32'h0000002C; load_data = 32'h00000013; #10;
        load_address = 32'h00000030; load_data = 32'h00000013; #10;
        load_address = 32'h00000034; load_data = 32'h00000013; #10;
        load_address = 32'h00000038; load_data = 32'h00000013; #10;

        //--------------------------------
        // START CPU
        //--------------------------------
        load_enable      = 0;
        fetch_enable     = 1;
        reg_write_enable = 1;

        $display("------------------------------------");
        $display("Program Loaded");
        $display("------------------------------------");

        #1000;

        //---------------------------------------------
        // FINAL RESULTS
        //---------------------------------------------
        
        $display("------------------------------------");
        $display("FINAL RESULTS");
        $display("------------------------------------");

        $display("x1      = %0d", uut.Register[1]);
        $display("x2      = %0d", uut.Register[2]);

        $display("MEM[0]  = %0d", uut.mem_stage.Memory[0]);
        $display("MEM[1]  = %0d", uut.mem_stage.Memory[1]);

        if((uut.Register[1] == 55) &&
           (uut.Register[2] == 55) &&
           (uut.mem_stage.Memory[1] == 55))
        begin
        
            $display("PASS : ADDRESSING WORKING");
        
        end
        else
        begin
        
            $display("FAIL : ADDRESSING ERROR");
            
        end

        $finish;

    end

    endmodule


//    //--------------------------------
//    // MONITOR
//    //--------------------------------
//    always @(posedge clk)
//    begin
//        if(fetch_enable)
//        begin

//            $display(
//            "PC=%h x1=%0d x2=%0d MEM0=%0d MEM1=%0d",
//            uut.pc,
//            uut.Register[1],
//            uut.Register[2],
//            uut.mem_stage.Memory[0],
//            uut.mem_stage.Memory[1]
//            );

//            $display(
//            "ALU=%h MEM_WR=%b MEM_RD=%b WB_RD=%0d WB=%h",
//            uut.mem_alu_result,
//            uut.mem_mem_write,
//            uut.mem_mem_read,
//            uut.wb_rd,
//            uut.write_back_data
//            );

//            $display("------------------------------------");
//            $display(
//            "INST=%h IMM=%h ALU=%h",
//            uut.if_id_instruction,
//            uut.ex_imm,
//            uut.ex_alu_result
//            );
//        end
//    end


