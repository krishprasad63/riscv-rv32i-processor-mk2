`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 20:56:10
// Design Name: 
// Module Name: hazard_detection_unit
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

//module hazard_detection_unit(

//    // Source registers of instruction currently in Decode stage
//    input [4:0] if_id_rs1,
//    input [4:0] if_id_rs2,

//    //--------------------------------------------------
//    // Experimental Inputs (Debug Hypothesis)
//    //
//    // These inputs allow us to also observe the instruction
//    // currently in the EX/MEM stage.
//    //
//    // Motivation:
//    // During debugging of:
//    //
//    //      lw
//    //      lw
//    //      blt
//    //
//    // the branch was observed entering Execute while the
//    // second load was still in MEM, causing the forwarded
//    // value to be the load ADDRESS instead of loaded DATA.
//    //
//    // This experiment checks whether an additional stall
//    // is required while the load is in EX/MEM.
//    //--------------------------------------------------
//    input       ex_mem_mem_read,
//    input [4:0] ex_mem_rd,

//    // Instruction currently in ID/EX stage
//    input [4:0] id_ex_rd,
//    input       id_ex_mem_read,

//    // Pipeline Control Outputs
//    output reg pc_write,
//    output reg if_id_write,
//    output reg control_mux

//);

//    always @(*) begin

//        //--------------------------------------------------
//        // Default : Normal pipeline operation
//        //--------------------------------------------------
//        pc_write    = 1'b1;
//        if_id_write = 1'b1;
//        control_mux = 1'b0;

//        //--------------------------------------------------
//        // Case 1 : Standard Load-Use Hazard
//        //
//        // Example:
//        //
//        //      lw  x2,0(x0)
//        //      add x3,x2,x4
//        //
//        // The instruction in Decode depends on the load
//        // currently in Execute.
//        //--------------------------------------------------
//        if ( id_ex_mem_read &&
//             (id_ex_rd != 5'd0) &&
//             ((id_ex_rd == if_id_rs1) ||
//              (id_ex_rd == if_id_rs2)) )
//        begin

//            pc_write    = 1'b0;
//            if_id_write = 1'b0;
//            control_mux = 1'b1;

//        end

//        //--------------------------------------------------
//        // Case 2 : Experimental Consecutive-Load Hazard
//        //
//        // Example:
//        //
//        //      lw  x2,...
//        //      lw  x3,...
//        //      blt x2,x3,...
//        //
//        // Observation:
//        // During debugging, BLT entered Execute while the
//        // second load was still in MEM.
//        //
//        // This temporary experiment keeps the branch in Decode
//        // for one additional cycle if it depends on a load
//        // currently residing in EX/MEM.
//        //
//        // NOTE:
//        // This is a DEBUG hypothesis, not necessarily the
//        // final implementation.
//        //--------------------------------------------------
//        else if ( ex_mem_mem_read &&
//                  (ex_mem_rd != 5'd0) &&
//                  ((ex_mem_rd == if_id_rs1) ||
//                   (ex_mem_rd == if_id_rs2)) )
//        begin

//            pc_write    = 1'b0;
//            if_id_write = 1'b0;
//            control_mux = 1'b1;

//        end

//    end

//endmodule

module hazard_detection_unit(
    // Source registers of instruction currently in Decode stage
    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,
    //--------------------------------------------------
    // Retained for port compatibility with riscv.v.
    // No longer used for stalling (see Revision 0.02 note above).
    //--------------------------------------------------
    input       ex_mem_mem_read,
    input [4:0] ex_mem_rd,
    // Instruction currently in ID/EX stage
    input [4:0] id_ex_rd,
    input       id_ex_mem_read,
    // Pipeline Control Outputs
    output reg pc_write,
    output reg if_id_write,
    output reg control_mux
);
    // Verilog-2001: explicitly mark intentionally-unused inputs to avoid
    // lint warnings now that Case 2 no longer references them.
    wire _unused_ok = &{1'b0, ex_mem_mem_read, ex_mem_rd};
 
    always @(*) begin
        //--------------------------------------------------
        // Default : Normal pipeline operation
        //--------------------------------------------------
        pc_write    = 1'b1;
        if_id_write = 1'b1;
        control_mux = 1'b0;
        //--------------------------------------------------
        // Case 1 : Standard Load-Use Hazard
        //
        // Example:
        //
        //      lw  x2,0(x0)
        //      add x3,x2,x4
        //
        // The instruction in Decode depends on the load
        // currently in Execute.
        //--------------------------------------------------
        if ( id_ex_mem_read &&
             (id_ex_rd != 5'd0) &&
             ((id_ex_rd == if_id_rs1) ||
              (id_ex_rd == if_id_rs2)) )
        begin
            pc_write    = 1'b0;
            if_id_write = 1'b0;
            control_mux = 1'b1;
        end
    end
endmodule
 