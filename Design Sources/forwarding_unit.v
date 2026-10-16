`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 19:47:28
// Design Name: 
// Module Name: forwarding_unit
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


//module forwarding_unit(

//    // Source registers currently in Execute stage
//    input [4:0] id_ex_rs1,
//    input [4:0] id_ex_rs2,

//    // Destination register in EX/MEM stage
//    input [4:0] ex_mem_rd,
//    input       ex_mem_reg_write,

//    // Destination register in MEM/WB stage
//    input [4:0] mem_wb_rd,
//    input       mem_wb_reg_write,

//    // Forwarding control outputs
//    output reg [1:0] forwardA,
//    output reg [1:0] forwardB

//);

//    //--------------------------------------------------
//    // ForwardA Encoding
//    //
//    // 00 : Register File
//    // 01 : MEM/WB
//    // 10 : EX/MEM
//    // 11 : Reserved
//    //--------------------------------------------------

//    always @(*) begin

//        // Default: no forwarding
//        forwardA = 2'b00;
//        forwardB = 2'b00;

//        //--------------------------------------------------
//        // EX Hazard
//        //--------------------------------------------------

//        if (ex_mem_reg_write &&
//            (ex_mem_rd != 5'b00000) &&
//            (ex_mem_rd == id_ex_rs1))
//        begin
//            forwardA = 2'b10;
//        end

//        if (ex_mem_reg_write &&
//            (ex_mem_rd != 5'b00000) &&
//            (ex_mem_rd == id_ex_rs2))
//        begin
//            forwardB = 2'b10;
//        end

//        //--------------------------------------------------
//        // MEM Hazard
//        //--------------------------------------------------

//        if (mem_wb_reg_write &&
//            (mem_wb_rd != 5'b00000) &&
//            !(ex_mem_reg_write &&
//              (ex_mem_rd != 5'b00000) &&
//              (ex_mem_rd == id_ex_rs1)) &&
//            (mem_wb_rd == id_ex_rs1))
//        begin
//            forwardA = 2'b01;
//        end

//        if (mem_wb_reg_write &&
//            (mem_wb_rd != 5'b00000) &&
//            !(ex_mem_reg_write &&
//              (ex_mem_rd != 5'b00000) &&
//              (ex_mem_rd == id_ex_rs2)) &&
//            (mem_wb_rd == id_ex_rs2))
//        begin
//            forwardB = 2'b01;
//        end

//    end

//endmodule

module forwarding_unit(
    // Source registers currently in Execute stage
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    // Destination register in EX/MEM stage
    input [4:0] ex_mem_rd,
    input       ex_mem_reg_write,
    // Whether the instruction in EX/MEM is a load. A load's
    // mem_alu_result is an address, not data -- EX/MEM cannot
    // supply a valid forward for it.
    input       ex_mem_mem_read,
    // Destination register in MEM/WB stage
    input [4:0] mem_wb_rd,
    input       mem_wb_reg_write,
    // Forwarding control outputs
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);
    //--------------------------------------------------
    // ForwardA / ForwardB Encoding
    //
    // 00 : Register File
    // 01 : MEM/WB
    // 10 : EX/MEM
    // 11 : Reserved
    //--------------------------------------------------
 
    // EX/MEM can only supply a valid forward when it actually holds
    // a usable ALU result -- i.e. reg_write is set AND it is NOT a
    // load (a load's "ALU result" is just the effective address).
    wire ex_mem_valid_a = ex_mem_reg_write &&
                          !ex_mem_mem_read &&
                          (ex_mem_rd != 5'b00000) &&
                          (ex_mem_rd == id_ex_rs1);
 
    wire ex_mem_valid_b = ex_mem_reg_write &&
                          !ex_mem_mem_read &&
                          (ex_mem_rd != 5'b00000) &&
                          (ex_mem_rd == id_ex_rs2);
 
    always @(*) begin
        // Default: no forwarding
        forwardA = 2'b00;
        forwardB = 2'b00;
        //--------------------------------------------------
        // EX Hazard (EX/MEM bypass)
        // Only valid for a genuine ALU result, never for a load.
        //--------------------------------------------------
        if (ex_mem_valid_a) begin
            forwardA = 2'b10;
        end
        if (ex_mem_valid_b) begin
            forwardB = 2'b10;
        end
        //--------------------------------------------------
        // MEM Hazard (MEM/WB bypass)
        // Fires whenever MEM/WB's rd matches and EX/MEM did NOT
        // already supply a valid forward for that register -- this
        // now correctly includes the case where EX/MEM's rd matches
        // but EX/MEM holds a load (ex_mem_valid_a/b false), so a
        // load's result is always picked up here, one cycle later,
        // instead of being incorrectly bypassed from EX/MEM.
        //--------------------------------------------------
        if (mem_wb_reg_write &&
            (mem_wb_rd != 5'b00000) &&
            !ex_mem_valid_a &&
            (mem_wb_rd == id_ex_rs1))
        begin
            forwardA = 2'b01;
        end
        if (mem_wb_reg_write &&
            (mem_wb_rd != 5'b00000) &&
            !ex_mem_valid_b &&
            (mem_wb_rd == id_ex_rs2))
        begin
            forwardB = 2'b01;
        end
    end
endmodule