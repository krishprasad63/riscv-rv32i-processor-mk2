`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.04.2026 00:13:37
// Design Name: 
// Module Name: fetch_stage
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


module fetch_stage(
    input clk,
    input reset,
    input load_enable,
    input fetch_enable,
    input pc_write,
    input [31:0] load_address,
    input [31:0] load_data,
    input [31:0] base_pc,
    input [31:0] imm_address,
    input [31:0] imm_address_jump,
    input beq,bneq,bge,blt,jump,
    output [31:0] pc,
    output [31:0] current_pc,
    output [31:0] fetched_instruction
    );

    program_counter m1(
    .clk(clk),
    .reset(reset),
    .enable(fetch_enable),
    .pc_write(pc_write),
    .beq(beq),
    .bneq(bneq),
    .blt(blt),
    .bge(bge),
    .jump(jump),
    .imm_address(imm_address),
    .imm_address_jump(imm_address_jump),
    .base_address(base_pc),
    .pc(pc),
    .current_pc(current_pc)
    );

    instruction_memory m2(
    .clk(clk),
    .write_en(load_enable),
    .pc(pc),
    .address(load_address),
    .data_in(load_data),
    .instruction(fetched_instruction)
    );
endmodule



