`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2026 20:55:20
// Design Name: 
// Module Name: tb_array_sum
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


module tb_array_sum();

reg clk;
reg reset;
reg load_enable;
reg fetch_enable;
reg reg_write_enable;
reg [31:0] load_address;
reg [31:0] load_data;
reg [31:0] base_pc;

wire [31:0] write_back_data;

//--------------------------------------------------
// DUT
//--------------------------------------------------
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
// PROGRAM LOAD + RUN
//--------------------------------------------------
initial begin

    $display("====================================");
    $display(" ARRAY SUM TEST ");
    $display("====================================");

    reset            = 1;
    load_enable      = 0;
    fetch_enable     = 0;
    reg_write_enable = 0;
    base_pc          = 0;

    #20;
    reset = 0;

    //--------------------------------------------------
    // LOAD PROGRAM
    //--------------------------------------------------
    load_enable = 1;

    //==================================================
    // STORE ARRAY
    //==================================================

    load_address = 32'h00000000; load_data = 32'h00A00093; #10; // addi x1,x0,10
    load_address = 32'h00000004; load_data = 32'h00000013; #10;
    load_address = 32'h00000008; load_data = 32'h00000013; #10;
    load_address = 32'h0000000C; load_data = 32'h00000013; #10;
    load_address = 32'h00000010; load_data = 32'h00000013; #10;
    load_address = 32'h00000014; load_data = 32'h00102023; #10; // sw

    load_address = 32'h00000018; load_data = 32'h01400093; #10; // addi x1,x0,20
    load_address = 32'h0000001C; load_data = 32'h00000013; #10;
    load_address = 32'h00000020; load_data = 32'h00000013; #10;
    load_address = 32'h00000024; load_data = 32'h00000013; #10;
    load_address = 32'h00000028; load_data = 32'h00000013; #10;
    load_address = 32'h0000002C; load_data = 32'h00102223; #10; // sw

    load_address = 32'h00000030; load_data = 32'h01E00093; #10; // addi x1,x0,30
    load_address = 32'h00000034; load_data = 32'h00000013; #10;
    load_address = 32'h00000038; load_data = 32'h00000013; #10;
    load_address = 32'h0000003C; load_data = 32'h00000013; #10;
    load_address = 32'h00000040; load_data = 32'h00000013; #10;
    load_address = 32'h00000044; load_data = 32'h00102423; #10; // sw

    load_address = 32'h00000048; load_data = 32'h02800093; #10; // addi x1,x0,40
    load_address = 32'h0000004C; load_data = 32'h00000013; #10;
    load_address = 32'h00000050; load_data = 32'h00000013; #10;
    load_address = 32'h00000054; load_data = 32'h00000013; #10;
    load_address = 32'h00000058; load_data = 32'h00000013; #10;
    load_address = 32'h0000005C; load_data = 32'h00102623; #10; // sw

    //==================================================
    // SUM ARRAY
    //==================================================

    load_address = 32'h00000060; load_data = 32'h00002103; #10; // lw x2,0(x0)

    load_address = 32'h00000064; load_data = 32'h00000013; #10;
    load_address = 32'h00000068; load_data = 32'h00000013; #10;
    load_address = 32'h0000006C; load_data = 32'h00000013; #10;
    load_address = 32'h00000070; load_data = 32'h00000013; #10;

    load_address = 32'h00000074; load_data = 32'h00402183; #10; // lw x3,4(x0)

    load_address = 32'h00000078; load_data = 32'h00000013; #10;
    load_address = 32'h0000007C; load_data = 32'h00000013; #10;
    load_address = 32'h00000080; load_data = 32'h00000013; #10;
    load_address = 32'h00000084; load_data = 32'h00000013; #10;

    load_address = 32'h00000088; load_data = 32'h003102B3; #10; // add x5,x2,x3

    load_address = 32'h0000008C; load_data = 32'h00000013; #10;
    load_address = 32'h00000090; load_data = 32'h00000013; #10;
    load_address = 32'h00000094; load_data = 32'h00000013; #10;
    load_address = 32'h00000098; load_data = 32'h00000013; #10;

    load_address = 32'h0000009C; load_data = 32'h00802103; #10; // lw x2,8(x0)

    load_address = 32'h000000A0; load_data = 32'h00000013; #10;
    load_address = 32'h000000A4; load_data = 32'h00000013; #10;
    load_address = 32'h000000A8; load_data = 32'h00000013; #10;
    load_address = 32'h000000AC; load_data = 32'h00000013; #10;

    load_address = 32'h000000B0; load_data = 32'h002282B3; #10; // add x5,x5,x2

    load_address = 32'h000000B4; load_data = 32'h00000013; #10;
    load_address = 32'h000000B8; load_data = 32'h00000013; #10;
    load_address = 32'h000000BC; load_data = 32'h00000013; #10;
    load_address = 32'h000000C0; load_data = 32'h00000013; #10;

    load_address = 32'h000000C4; load_data = 32'h00C02103; #10; // lw x2,12(x0)

    load_address = 32'h000000C8; load_data = 32'h00000013; #10;
    load_address = 32'h000000CC; load_data = 32'h00000013; #10;
    load_address = 32'h000000D0; load_data = 32'h00000013; #10;
    load_address = 32'h000000D4; load_data = 32'h00000013; #10;

    load_address = 32'h000000D8; load_data = 32'h002282B3; #10; // add x5,x5,x2

    load_address = 32'h000000DC; load_data = 32'h00000013; #10;
    load_address = 32'h000000E0; load_data = 32'h00000013; #10;
    load_address = 32'h000000E4; load_data = 32'h00000013; #10;
    load_address = 32'h000000E8; load_data = 32'h00000013; #10;

    load_address = 32'h000000EC; load_data = 32'h00502823; #10; // sw x5,16(x0)

    //--------------------------------------------------
    // START CPU
    //--------------------------------------------------
    load_enable      = 0;
    fetch_enable     = 1;
    reg_write_enable = 1;

    $display("------------------------------------");
    $display("PROGRAM LOADED");
    $display("------------------------------------");

    #7000;

    //--------------------------------------------------
    // FINAL REPORT
    //--------------------------------------------------
    $display("");
    $display("====================================");
    $display("FINAL REPORT");
    $display("====================================");

    $display("");
    $display("REGISTERS");
    $display("x1 = %0d", uut.Register[1]);
    $display("x2 = %0d", uut.Register[2]);
    $display("x3 = %0d", uut.Register[3]);
    $display("x5 = %0d", uut.Register[5]);

    $display("");
    $display("MEMORY");
    $display("MEM[0] = %0d", uut.mem_stage.Memory[0]);
    $display("MEM[1] = %0d", uut.mem_stage.Memory[1]);
    $display("MEM[2] = %0d", uut.mem_stage.Memory[2]);
    $display("MEM[3] = %0d", uut.mem_stage.Memory[3]);
    $display("MEM[4] = %0d", uut.mem_stage.Memory[4]);

    $display("");
    $display("PIPELINE");
    $display("ex_pc          = %h", uut.ex_pc);
    $display("ex_alu_result  = %h", uut.ex_alu_result);
    $display("mem_addr       = %h", uut.mem_alu_result);
    $display("mem_store_data = %h", uut.mem_store_data);
    $display("wb_rd          = %0d", uut.wb_rd);
    $display("write_back     = %h", uut.write_back_data);

    $display("");

    if(uut.mem_stage.Memory[4] == 100)
        $display("PASS");
    else
        $display("FAIL");

    $finish;
end

//--------------------------------------------------
// DEBUG
//--------------------------------------------------
always @(posedge clk)
begin
    if(fetch_enable)
    begin
        $display(
        "T=%0t PC=%h INST=%h x1=%0d x2=%0d x3=%0d x5=%0d",
        $time,
        uut.pc,
        uut.if_id_instruction,
        uut.Register[1],
        uut.Register[2],
        uut.Register[3],
        uut.Register[5]
        );

        $display(
        "EX_ALU=%h MEM_ADDR=%h MEM_WR=%b MEM_RD=%b WB=%h",
        uut.ex_alu_result,
        uut.mem_alu_result,
        uut.mem_mem_write,
        uut.mem_mem_read,
        uut.write_back_data
        );

        $display(
        "M0=%0d M1=%0d M2=%0d M3=%0d M4=%0d",
        uut.mem_stage.Memory[0],
        uut.mem_stage.Memory[1],
        uut.mem_stage.Memory[2],
        uut.mem_stage.Memory[3],
        uut.mem_stage.Memory[4]
        );

        $display("------------------------------------------------");
    end
end

endmodule