`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 11:57:24
// Design Name: 
// Module Name: tb_fibonacci
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

module tb_fibonacci();

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

    //--------------------------------------------------
    // CLOCK
    //--------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //--------------------------------------------------
    // PROGRAM LOAD
    //--------------------------------------------------
    initial begin

        $display("====================================");
        $display(" FIBONACCI TEST ");
        $display("====================================");

        base_pc          = 0;
        load_enable      = 0;
        fetch_enable     = 0;
        reg_write_enable = 0;
        reset            = 1;

        #20;
        reset = 0;

        load_enable = 1;
            
        // x1 = 0
        load_address = 32'h00000000;
        load_data    = 32'h00000093;   // addi x1,x0,0
        #10;

        // x2 = 1
        load_address = 32'h00000004;
        load_data    = 32'h00100113;   // addi x2,x0,1
        #10;

        // x4 = 10
        load_address = 32'h00000008;
        load_data    = 32'h00A00213;   // addi x4,x0,10
        #10;

        //--------------------------------------------------
        // NOPs before loop
        //--------------------------------------------------
        load_address = 32'h0000000C; load_data = 32'h00000013; #10;
        load_address = 32'h00000010; load_data = 32'h00000013; #10;
        load_address = 32'h00000014; load_data = 32'h00000013; #10;
        load_address = 32'h00000018; load_data = 32'h00000013; #10;

        //--------------------------------------------------
        // LOOP START = 0x1C
        //--------------------------------------------------

        // add x3,x1,x2
        load_address = 32'h0000001C;
        load_data    = 32'h002081B3;
        #10;

        // wait for x3 writeback
        load_address = 32'h00000020; load_data = 32'h00000013; #10;
        load_address = 32'h00000024; load_data = 32'h00000013; #10;
        load_address = 32'h00000028; load_data = 32'h00000013; #10;
        load_address = 32'h0000002C; load_data = 32'h00000013; #10;

        // x1 = x2
        load_address = 32'h00000030;
        load_data    = 32'h00010093;   // addi x1,x2,0
        #10;

        // wait
        load_address = 32'h00000034; load_data = 32'h00000013; #10;
        load_address = 32'h00000038; load_data = 32'h00000013; #10;
        load_address = 32'h0000003C; load_data = 32'h00000013; #10;
        load_address = 32'h00000040; load_data = 32'h00000013; #10;

        // x2 = x3
        load_address = 32'h00000044;
        load_data    = 32'h00018113; #10;  // addi x2,x3,0 

        // wait
        load_address = 32'h00000048; load_data = 32'h00000013; #10;
        load_address = 32'h0000004C; load_data = 32'h00000013; #10;
        load_address = 32'h00000050; load_data = 32'h00000013; #10;
        load_address = 32'h00000054; load_data = 32'h00000013; #10;

        // x4 = x4 - 1
        load_address = 32'h00000058;
        load_data    = 32'hFFF20213;
        #10;

        // wait
        load_address = 32'h0000005C; load_data = 32'h00000013; #10;
        load_address = 32'h00000060; load_data = 32'h00000013; #10;
        load_address = 32'h00000064; load_data = 32'h00000013; #10;
        load_address = 32'h00000068; load_data = 32'h00000013; #10;

        //--------------------------------------------------
        // bne x4,x0,loop
        // loop = 0x1C
        // branch @0x6C
        // offset = 0x1C - 0x6C = -80
        //--------------------------------------------------
        load_address = 32'h0000006C;
        load_data    = 32'hFA0218E3;
        #10;

        //--------------------------------------------------
        // branch flush protection
        //--------------------------------------------------
        load_address = 32'h00000070; load_data = 32'h00000013; #10;
        load_address = 32'h00000074; load_data = 32'h00000013; #10;
        load_address = 32'h00000078; load_data = 32'h00000013; #10;
        load_address = 32'h0000007C; load_data = 32'h00000013; #10;

        //--------------------------------------------------
        // START CPU
        //--------------------------------------------------
        load_enable      = 0;
        fetch_enable     = 1;
        reg_write_enable = 1;

        $display("------------------------------------");
        $display("Program Loaded");
        $display("------------------------------------");
        
        #50000;
        
        $display("------------------------------------");
        $display("FINAL RESULTS");
        $display("------------------------------------");
        $display("x1 = %0d", uut.Register[1]); $display("x2 = %0d", uut.Register[2]);
        $display("x3 = %0d", uut.Register[3]); $display("x4 = %0d", uut.Register[4]);
        $finish;
    end

    //--------------------------------------------------
    // MONITOR
    //--------------------------------------------------
    always @(posedge clk)
    begin
        if(fetch_enable)
        begin
            $display(
            "T=%0t | PC=%h | x1=%0d | x2=%0d | x3=%0d | x4=%0d",
            $time,
            uut.pc,
            uut.Register[1], uut.Register[2],
            uut.Register[3], uut.Register[4]
            );
        end
    end
    always @(posedge clk)
    begin
        if(fetch_enable &&
           uut.Register[4] == 0 &&
           uut.pc > 32'h00000050)
        begin
            $display("------------------------------------");
            $display("FINAL RESULTS");
            $display("------------------------------------");
    
            $display("x1 = %0d", uut.Register[1]); $display("x2 = %0d", uut.Register[2]);
            $display("x3 = %0d", uut.Register[3]); $display("x4 = %0d", uut.Register[4]);
            
            $finish;
        end
        $display(
        "PC=%h wb_rd=%0d WB=%h x1=%h x2=%h x3=%h",
        uut.pc, uut.wb_rd, uut.write_back_data,
        uut.Register[1], uut.Register[2], uut.Register[3]
        );
    end
endmodule