`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 12:11:17
// Design Name: 
// Module Name: tb_move
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

module tb_move();

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
    // TEST
    //--------------------------------------------------
    initial begin

        $display("====================================");
        $display(" MOVE TEST ");
        $display("====================================");

        base_pc          = 32'h00000000;
        load_enable      = 0;
        fetch_enable     = 0;
        reg_write_enable = 0;
        reset            = 1;

        #20;
        reset = 0;

        //--------------------------------------------------
        // LOAD PROGRAM
        //--------------------------------------------------
        load_enable = 1;

        //--------------------------------------
        // addi x3,x0,9
        //--------------------------------------
        load_address = 32'h00000000;
        load_data    = 32'h00900193;
        #10;

        //--------------------------------------
        // NOPs
        //--------------------------------------
        load_address = 32'h00000004;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000008;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h0000000C;
        load_data    = 32'h00000013;
        #10;

        load_address = 32'h00000010;
        load_data    = 32'h00000013;
        #10;

        //--------------------------------------
        // addi x2,x3,0
        //--------------------------------------
        load_address = 32'h00000014;
        load_data    = 32'h00018113;
        #10;

        //--------------------------------------------------
        // START CPU
        //--------------------------------------------------
        load_enable      = 0;
        fetch_enable     = 1;
        reg_write_enable = 1;

        #600;

        //--------------------------------------------------
        // RESULTS
        //--------------------------------------------------
        $display("------------------------------------");
        $display("FINAL RESULTS");
        $display("------------------------------------");

        $display("x2 = %0d (%h)", uut.Register[2], uut.Register[2]);
        $display("x3 = %0d (%h)", uut.Register[3], uut.Register[3]);

        if(uut.Register[2] == 9)
            $display("PASS : MOVE WORKING");
        else
            $display("FAIL : MOVE FAILED");

        $finish;

    end

    //--------------------------------------------------
    // MONITOR
    //--------------------------------------------------
    always @(posedge clk) begin

        if(fetch_enable) begin
            $display(
            "T=%0t | PC=%h | x2=%h | x3=%h | WB=%h",
            $time,
            uut.pc,
            uut.Register[2],
            uut.Register[3],
            uut.write_back_data
            );
        end

    end

endmodule

