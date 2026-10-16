`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2026 18:19:58
// Design Name: 
// Module Name: tb_bubble_sort_v2
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



module tb_bubble_sort_v2;
 
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
    riscv dut (
        .clk             (clk),
        .reset           (reset),
        .load_enable     (load_enable),
        .fetch_enable    (fetch_enable),
        .reg_write_enable(reg_write_enable),
        .load_address    (load_address),
        .load_data       (load_data),
        .base_pc         (base_pc),
        .write_back_data (write_back_data)
    );
 
    //------------------------------------------------------------
    // Clock: 10 ns period
    //------------------------------------------------------------
    initial clk = 0;
    always  #5 clk = ~clk;
 
    //------------------------------------------------------------
    // Task: write one instruction word into instruction memory
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
    // Main test
    //------------------------------------------------------------
    integer pass;
 
    initial begin
 
        reset            = 1;
        load_enable      = 0;
        fetch_enable     = 0;
        reg_write_enable = 1;
        load_address     = 0;
        load_data        = 0;
        base_pc          = 0;
 
        #20;
        reset = 0;
 
        // --------------------------------------------------------
        // Phase 1: Store input array {40,10,30,20,50} via sw x1,N(x2)
        //          x2 = sp = 0 after reset -> data at absolute addrs 0..16
        //          (addi -> sw back-to-back: rd=x1 forwarded EX/MEM ->
        //           EX as store-address-base read of x2, no hazard on
        //           x1 itself since sw's rs2=x1 needs only one cycle
        //           of forwarding, which forwarding_unit supplies)
        // --------------------------------------------------------
        load_instruction(32'd  0, 32'h02800093);  // addi x1, x0, 40
        load_instruction(32'd  4, 32'h00112023);  // sw   x1, 0(x2)     MEM[0]=40
        load_instruction(32'd  8, 32'h00A00093);  // addi x1, x0, 10
        load_instruction(32'd 12, 32'h00112223);  // sw   x1, 4(x2)     MEM[1]=10
        load_instruction(32'd 16, 32'h01E00093);  // addi x1, x0, 30
        load_instruction(32'd 20, 32'h00112423);  // sw   x1, 8(x2)     MEM[2]=30
        load_instruction(32'd 24, 32'h01400093);  // addi x1, x0, 20
        load_instruction(32'd 28, 32'h00112623);  // sw   x1, 12(x2)    MEM[3]=20
        load_instruction(32'd 32, 32'h03200093);  // addi x1, x0, 50
        load_instruction(32'd 36, 32'h00112823);  // sw   x1, 16(x2)    MEM[4]=50
 
        // --------------------------------------------------------
        // Copy sp into x5 - keeps x2 intact as the fixed base pointer
        // --------------------------------------------------------
        load_instruction(32'd 40, 32'h00010293);  // addi x5, x2, 0     x5=base
 
        // --------------------------------------------------------
        // Outer loop init: x6=n=5, x7=i=0, x8=n-1=4
        // --------------------------------------------------------
        load_instruction(32'd 44, 32'h00500313);  // addi x6, x0, 5
        load_instruction(32'd 48, 32'h00000393);  // addi x7, x0, 0
        load_instruction(32'd 52, 32'hFFF30413);  // addi x8, x6, -1   (rs1=x6, EX/MEM forward)
 
        // --------------------------------------------------------
        // OUTER_LOOP: if i >= n-1 goto DONE
        //   bge reads x7,x8 - both several instructions old by now,
        //   safely in register file, no forwarding even needed here.
        // --------------------------------------------------------
        load_instruction(32'd 56, 32'h0283DE63);  // bge x7, x8, DONE
 
        // --------------------------------------------------------
        // Inner loop init
        //   x9  = n-1-i  (sub x9, x8, x7)
        //   x11 = (n-1-i)*4  (slli x11, x9, 2)  <- rs1=x9 is the SUB's
        //                      own rd from the immediately preceding
        //                      instruction: pure EX/MEM->EX forward,
        //                      hardware-only, no NOP.
        //   x10 = 0  (j_byte)
        // --------------------------------------------------------
        load_instruction(32'd 60, 32'h407404B3);  // sub  x9,  x8, x7
        load_instruction(32'd 64, 32'h00249593);  // slli x11, x9, 2
        load_instruction(32'd 68, 32'h00000513);  // addi x10, x0, 0
 
        // --------------------------------------------------------
        // INNER_LOOP: if j_byte >= limit goto OUTER_INC
        // --------------------------------------------------------
        load_instruction(32'd 72, 32'h02B55263);  // bge x10, x11, OUTER_INC
 
        // --------------------------------------------------------
        // Compute effective address, load both elements, compare,
        // swap if needed - NO NOPs. The hazard_detection_unit's
        // Case 1 (load-use) stall is the ONLY thing protecting the
        // immediate consumers of x12/x13 below; if that hardware
        // path is broken, this sequence will expose it.
        //
        //   x14 = base + j_byte           (add x14, x5, x10)
        //   x12 = arr[j]                  (lw  x12, 0(x14))   <- rs1=x14,
        //                                   EX/MEM forward from 'add' above
        //   x13 = arr[j+1]                (lw  x13, 4(x14))   <- rs1=x14
        //                                   again, MEM/WB forward this time
        //   bge x13,x12,NO_SWAP                                <- rs1=x13 is
        //                                   the immediately preceding lw's
        //                                   rd: load-use hazard, caught by
        //                                   hazard_detection_unit's
        //                                   automatic 1-cycle stall.
        //                                   rs2=x12 is two instructions
        //                                   back: MEM/WB forward.
        // --------------------------------------------------------
        load_instruction(32'd 76, 32'h00A28733);  // add x14, x5, x10
        load_instruction(32'd 80, 32'h00072603);  // lw  x12, 0(x14)
        load_instruction(32'd 84, 32'h00472683);  // lw  x13, 4(x14)
        load_instruction(32'd 88, 32'h00C6D263);  // bge x13, x12, NO_SWAP
 
        // --------------------------------------------------------
        // Swap
        //   sw x13, 0(x14)   arr[j]   = arr[j+1]   <- rs2=x13 is the
        //                      'bge' comparison's own rs1 register,
        //                      already several cycles old by the time
        //                      sw reaches EX: register-file read or
        //                      MEM/WB forward, both hardware-only.
        //   sw x12, 4(x14)   arr[j+1] = arr[j]     <- rs2=x12, same.
        // --------------------------------------------------------
        load_instruction(32'd 92, 32'h00D72023);  // sw x13, 0(x14)
        load_instruction(32'd 96, 32'h00C72223);  // sw x12, 4(x14)
 
        // --------------------------------------------------------
        // NO_SWAP: j_byte += 4, loop back to INNER_LOOP
        // --------------------------------------------------------
        load_instruction(32'd100, 32'h00450513);  // addi x10, x10, 4
        load_instruction(32'd104, 32'hFEB540E3);  // blt  x10, x11, INNER_LOOP
 
        // --------------------------------------------------------
        // OUTER_INC: i++, loop back to OUTER_LOOP
        // --------------------------------------------------------
        load_instruction(32'd108, 32'h00138393);  // addi x7, x7, 1
        load_instruction(32'd112, 32'hFC83C4E3);  // blt  x7, x8, OUTER_LOOP
 
        // --------------------------------------------------------
        // DONE: infinite self-loop (halt)
        // --------------------------------------------------------
        load_instruction(32'd116, 32'h00000063);  // beq x0, x0, 0
 
        // --------------------------------------------------------
        // Start CPU
        // --------------------------------------------------------
        @(negedge clk);
        fetch_enable = 1;
 
        // --------------------------------------------------------
        // DEBUG: per-cycle hazard/forward trace.
        // Fires once every posedge clk from here until $finish.
        // Look at the rows right around the lw x13 -> bge x13,x12
        // boundary (roughly t=1600-1800ns) to see whether
        // control_mux asserts on the correct cycle, AND whether
        // forwardA correctly stays off EX/MEM (==10) when
        // ex_mem_mem_read=1 (i.e. EX/MEM holds a load).
        // ex_rs1/ex_rs2 are the actual operands forwarding_unit
        // compares against -- NOT the same as if_id_rs1/rs2 once
        // an instruction has moved past Decode.
        // --------------------------------------------------------
        $monitor("t=%0t pc=%0d if_id_rs1=%0d if_id_rs2=%0d ex_rs1=%0d ex_rs2=%0d id_ex_rd=%0d id_ex_mem_read=%b control_mux=%b forwardA=%b forwardB=%b ex_mem_rd=%0d ex_mem_mem_read=%b mem_wb_rd=%0d",
                 $time, dut.pc, dut.decode_rs1, dut.decode_rs2,
                 dut.ex_rs1, dut.ex_rs2,
                 dut.ex_rd, dut.ex_mem_read, dut.control_mux,
                 dut.forwardA, dut.forwardB, dut.mem_rd, dut.mem_mem_read, dut.wb_rd);
 
        // --------------------------------------------------------
        // Wait: 30 instructions, but with hardware load-use stalls
        // (1 cycle each, 8 occurrences: one per lw->use pair across
        // 4 outer passes x 2 inner-loop-iterations-with-back-to-back
        // load+compare worst case) plus branch refetch overhead.
        // 800 cycles retained for safety margin, same as before.
        // --------------------------------------------------------
        repeat(800) @(posedge clk);
 
        // --------------------------------------------------------
        // Debug readout
        // --------------------------------------------------------
        $display("");
        $display("=== DEBUG ===");
        $display("Final PC        = 0x%08h", dut.pc);
        $display("x2  (sp/base)   = %0d",    dut.Register[2]);
        $display("x5  (arr base)  = %0d",    dut.Register[5]);
        $display("x6  (n)         = %0d",    dut.Register[6]);
        $display("x7  (i)         = %0d",    dut.Register[7]);
        $display("x8  (n-1)       = %0d",    dut.Register[8]);
        $display("x10 (j_byte)    = %0d",    dut.Register[10]);
        $display("x11 (inner_lim) = %0d",    dut.Register[11]);
        $display("x12 (arr[j])    = %0d",    dut.Register[12]);
        $display("x13 (arr[j+1])  = %0d",    dut.Register[13]);
        $display("x14 (eff_addr)  = %0d",    dut.Register[14]);
 
        // --------------------------------------------------------
        // Report
        // --------------------------------------------------------
        $display("");
        $display("========================================");
        $display("   BUBBLE SORT TEST REPORT (NOP-FREE)");
        $display("   Pure hardware hazard/forward/flush test");
        $display("========================================");
        $display("");
        $display("INPUT    : {40, 10, 30, 20, 50}");
        $display("EXPECTED : {10, 20, 30, 40, 50}");
        $display("");
        $display("OBSERVED:");
        $display("  MEM[0] = %0d", dut.mem_stage.Memory[0]);
        $display("  MEM[1] = %0d", dut.mem_stage.Memory[1]);
        $display("  MEM[2] = %0d", dut.mem_stage.Memory[2]);
        $display("  MEM[3] = %0d", dut.mem_stage.Memory[3]);
        $display("  MEM[4] = %0d", dut.mem_stage.Memory[4]);
 
        pass = (dut.mem_stage.Memory[0] == 10) &&
               (dut.mem_stage.Memory[1] == 20) &&
               (dut.mem_stage.Memory[2] == 30) &&
               (dut.mem_stage.Memory[3] == 40) &&
               (dut.mem_stage.Memory[4] == 50);
 
        $display("");
        if (pass) begin
            $display("RESULT : PASS");
        end else begin
            $display("RESULT : FAIL");
            $display("");
            $display("  This testbench has ZERO software NOPs, so a FAIL");
            $display("  here (while the NOP-padded tb_bubble_sort PASSES)");
            $display("  isolates the bug specifically to hardware hazard");
            $display("  handling timing, e.g.:");
            $display("  A) hazard_detection_unit Case 1 stall window is");
            $display("     too short/long for back-to-back lw,lw,bge");
            $display("  B) forwarding_unit forwardB not covering the");
            $display("     store-data path for sw correctly in all cases");
            $display("  C) flush_ifid/flush_idex timing relative to a");
            $display("     stalled (control_mux) cycle");
        end
 
        $display("========================================");
        #20;
        $finish;
    end
 
endmodule
 