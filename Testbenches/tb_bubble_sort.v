`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2026 20:41:26
// Design Name: 
// Module Name: tb_bubble_sort
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//   CORRECTED VERSION:
//     - Restored the second NOP bubble after each lw (LW->USE hazard guard)
//     - Recomputed all branch offsets (BGE/BLT/BEQ) to match the resulting
//       34-instruction layout (program now ends at byte address 132)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Fixed missing NOP bubble + branch offset recalculation
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

 



module tb_bubble_sort;
 
    // ---------------- DUT I/O ----------------
    
    reg clk, reset;
    reg load_enable, fetch_enable, reg_write_enable;
    reg  [31:0] load_address, load_data, base_pc;
    
    wire [31:0] write_back_data;
 
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
 
 
    // ---------------- Clock: 10 ns period ----------------
    
    initial clk = 0;
    always #5 clk = ~clk;
    
 
    // ---------------- Task: load one instruction --------------
    
    task load_instruction(input [31:0] addr, input [31:0] instr);
        begin
            @(negedge clk);
            load_enable  = 1;
            load_address = addr;
            load_data    = instr;
            @(negedge clk);
            load_enable  = 0;
        end
    endtask
 
    // ---------------- Program (instruction memory image) ----------------
    // Addr  Instr        Mnemonic                     Notes
    task load_program;
        begin
            // -- Store input array via sw x1, N(x2); x2 = sp = 0 after reset --
            load_instruction('h00, 32'h02800093); // addi x1, x0, 40
            load_instruction('h04, 32'h00112023); // sw   x1, 0(x2)   MEM[0]=40
            load_instruction('h08, 32'h00A00093); // addi x1, x0, 10
            load_instruction('h0C, 32'h00112223); // sw   x1, 4(x2)   MEM[1]=10
            load_instruction('h10, 32'h01E00093); // addi x1, x0, 30
            load_instruction('h14, 32'h00112423); // sw   x1, 8(x2)   MEM[2]=30
            load_instruction('h18, 32'h01400093); // addi x1, x0, 20
            load_instruction('h1C, 32'h00112623); // sw   x1, 12(x2)  MEM[3]=20
            load_instruction('h20, 32'h03200093); // addi x1, x0, 50
            load_instruction('h24, 32'h00112823); // sw   x1, 16(x2)  MEM[4]=50
 
            // -- x5 = base pointer (copy of sp, keeps x2 free) --
            load_instruction('h28, 32'h00010293); // addi x5, x2, 0
 
            // -- Outer loop init: x6=n=5, x7=i=0, x8=n-1=4 --
            load_instruction('h2C, 32'h00500313); // addi x6, x0, 5
            load_instruction('h30, 32'h00000393); // addi x7, x0, 0
            load_instruction('h34, 32'hFFF30413); // addi x8, x6, -1
 
            // -- OUTER_LOOP (0x38): if i >= n-1 goto DONE (0x84) --
            load_instruction('h38, 32'h0483D663); // bge x7, x8, DONE
 
            // -- Inner loop init: x9=n-1-i, x11=(n-1-i)*4, x10=j_byte=0 --
            load_instruction('h3C, 32'h407404B3); // sub  x9,  x8, x7
            load_instruction('h40, 32'h00249593); // slli x11, x9, 2
            load_instruction('h44, 32'h00000513); // addi x10, x0, 0
 
            // -- INNER_LOOP (0x48): if j_byte >= limit goto OUTER_INC (0x7C) --
            load_instruction('h48, 32'h02B55A63); // bge x10, x11, OUTER_INC
 
            // -- Load arr[j], arr[j+1] (2-bubble guard after each lw) --
            load_instruction('h4C, 32'h00A28733); // add x14, x5, x10
            load_instruction('h50, 32'h00072603); // lw  x12, 0(x14)
            load_instruction('h54, 32'h00000013); // nop  (LW->USE bubble)
            load_instruction('h58, 32'h00000013); // nop  (LW->USE bubble)
            load_instruction('h5C, 32'h00472683); // lw  x13, 4(x14)
            load_instruction('h60, 32'h00000013); // nop  (LW->USE bubble)
            load_instruction('h64, 32'h00000013); // nop  (LW->USE bubble)
 
            // -- Compare: if arr[j+1] >= arr[j] skip swap --
            load_instruction('h68, 32'h00C6D663); // bge x13, x12, NO_SWAP
 
            // -- Swap --
            load_instruction('h6C, 32'h00D72023); // sw x13, 0(x14)
            load_instruction('h70, 32'h00C72223); // sw x12, 4(x14)
 
            // -- NO_SWAP (0x74): j_byte += 4, loop to INNER_LOOP --
            load_instruction('h74, 32'h00450513); // addi x10, x10, 4
            load_instruction('h78, 32'hFCB548E3); // blt  x10, x11, INNER_LOOP
 
            // -- OUTER_INC (0x7C): i++, loop to OUTER_LOOP --
            load_instruction('h7C, 32'h00138393); // addi x7, x7, 1
            load_instruction('h80, 32'hFA83CCE3); // blt  x7, x8, OUTER_LOOP
 
            // -- DONE (0x84): halt (infinite self-loop) --
            load_instruction('h84, 32'h00000063); // beq x0, x0, 0
        end
    endtask
 
    // ---------------- Result checking ----------------
    integer pass;
 
    task report_results;
        begin
            $display("");
            $display("========================================");
            $display("      BUBBLE SORT TEST REPORT");
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
            $display("RESULT : %s", pass ? "PASS" : "FAIL");
            $display("========================================");
        end
    endtask
 
    // ---------------- Main sequence ----------------
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
 
        load_program();
 
        @(negedge clk);
        fetch_enable = 1;
 
        // 34 instructions x ~8 cycles avg + drain; 
        // for branch misprediction refills.
        repeat (800) @(posedge clk);
 
        report_results();
 
        #20;
        $finish;
    end
 
    endmodule

//module tb_bubble_sort;
 
//    //------------------------------------------------------------
//    // Inputs
//    //------------------------------------------------------------
//    reg clk;
//    reg reset;
//    reg load_enable;
//    reg fetch_enable;
//    reg reg_write_enable;
 
//    reg [31:0] load_address;
//    reg [31:0] load_data;
//    reg [31:0] base_pc;
 
//    //------------------------------------------------------------
//    // Output
//    //------------------------------------------------------------
//    wire [31:0] write_back_data;
 
//    //------------------------------------------------------------
//    // DUT
//    //------------------------------------------------------------
//    riscv dut (
//        .clk             (clk),
//        .reset           (reset),
//        .load_enable     (load_enable),
//        .fetch_enable    (fetch_enable),
//        .reg_write_enable(reg_write_enable),
//        .load_address    (load_address),
//        .load_data       (load_data),
//        .base_pc         (base_pc),
//        .write_back_data (write_back_data)
//    );
 
//    //------------------------------------------------------------
//    // Clock: 10 ns period
//    //------------------------------------------------------------
//    initial clk = 0;
//    always  #5 clk = ~clk;
 
//    //------------------------------------------------------------
//    // Task: write one instruction word into instruction memory
//    //------------------------------------------------------------
//    task load_instruction;
//        input [31:0] addr;
//        input [31:0] instr;
//        begin
//            @(negedge clk);
//            load_enable  = 1;
//            load_address = addr;
//            load_data    = instr;
//            @(negedge clk);
//            load_enable  = 0;
//        end
//    endtask
 
//    //------------------------------------------------------------
//    // Main test
//    //------------------------------------------------------------
//    integer pass;
 
//    initial begin
 
//        reset            = 1;
//        load_enable      = 0;
//        fetch_enable     = 0;
//        reg_write_enable = 1;
//        load_address     = 0;
//        load_data        = 0;
//        base_pc          = 0;
 
//        #20;
//        reset = 0;
 
//        // --------------------------------------------------------
//        // Phase 1: Store input array {40,10,30,20,50} via sw x1,N(x2)
//        //          x2 = sp = 0 after reset -> data at absolute addrs 0..16
//        // --------------------------------------------------------
//        load_instruction(32'd  0, 32'h02800093);  // addi x1, x0, 40
//        load_instruction(32'd  4, 32'h00112023);  // sw   x1, 0(x2)     MEM[0]=40
//        load_instruction(32'd  8, 32'h00A00093);  // addi x1, x0, 10
//        load_instruction(32'd 12, 32'h00112223);  // sw   x1, 4(x2)     MEM[1]=10
//        load_instruction(32'd 16, 32'h01E00093);  // addi x1, x0, 30
//        load_instruction(32'd 20, 32'h00112423);  // sw   x1, 8(x2)     MEM[2]=30
//        load_instruction(32'd 24, 32'h01400093);  // addi x1, x0, 20
//        load_instruction(32'd 28, 32'h00112623);  // sw   x1, 12(x2)    MEM[3]=20
//        load_instruction(32'd 32, 32'h03200093);  // addi x1, x0, 50
//        load_instruction(32'd 36, 32'h00112823);  // sw   x1, 16(x2)    MEM[4]=50
 
//        // --------------------------------------------------------
//        // Copy sp into x5 - keeps x2 intact as the fixed base pointer
//        // --------------------------------------------------------
//        load_instruction(32'd 40, 32'h00010293);  // addi x5, x2, 0     x5=base
 
//        // --------------------------------------------------------
//        // Outer loop init: x6=n=5, x7=i=0, x8=n-1=4
//        // --------------------------------------------------------
//        load_instruction(32'd 44, 32'h00500313);  // addi x6, x0, 5
//        load_instruction(32'd 48, 32'h00000393);  // addi x7, x0, 0
//        load_instruction(32'd 52, 32'hFFF30413);  // addi x8, x6, -1
 
//        // --------------------------------------------------------
//        // OUTER_LOOP (0x38): if i >= n-1 goto DONE (0x84)
//        // --------------------------------------------------------
//        load_instruction(32'd 56, 32'h0483D663);  // bge x7, x8, DONE
 
//        // --------------------------------------------------------
//        // Inner loop init
//        //   x9  = n-1-i  (sub x9, x8, x7)
//        //   x11 = (n-1-i)*4  (slli x11, x9, 2)
//        //   x10 = 0  (j_byte)
//        // --------------------------------------------------------
//        load_instruction(32'd 60, 32'h407404B3);  // sub  x9,  x8, x7
//        load_instruction(32'd 64, 32'h00249593);  // slli x11, x9, 2
//        load_instruction(32'd 68, 32'h00000513);  // addi x10, x0, 0
 
//        // --------------------------------------------------------
//        // INNER_LOOP (0x48): if j_byte >= limit goto OUTER_INC (0x7C)
//        // --------------------------------------------------------
//        load_instruction(32'd 72, 32'h02B55A63);  // bge x10, x11, OUTER_INC
 
//        // --------------------------------------------------------
//        // Compute effective address, load both elements
//        //   x14 = base + j_byte
//        //   x12 = arr[j]     lw x12, 0(x14)
//        //   NOP, NOP          (LW->USE hazard guard, 2 bubbles so the
//        //                      consumer sees forwardA/B == 01, i.e. WB,
//        //                      not 10, i.e. MEM/addr-only)
//        //   x13 = arr[j+1]   lw x13, 4(x14)
//        //   NOP, NOP          (LW->USE hazard guard)
//        // --------------------------------------------------------
//        load_instruction(32'd 76, 32'h00A28733);  // add x14, x5, x10
//        load_instruction(32'd 80, 32'h00072603);  // lw  x12, 0(x14)
//        load_instruction(32'd 84, 32'h00000013);  // nop  <--- LW->USE bubble 1
//        load_instruction(32'd 88, 32'h00000013);  // nop  <--- LW->USE bubble 2 (ensures x12 in WB before use)
//        load_instruction(32'd 92, 32'h00472683);  // lw  x13, 4(x14)
//        load_instruction(32'd 96, 32'h00000013);  // nop  <--- LW->USE bubble 1
//        load_instruction(32'd100, 32'h00000013);  // nop  <--- LW->USE bubble 2 (ensures x13 in WB before use)
 
//        // --------------------------------------------------------
//        // Compare: if arr[j+1] >= arr[j] skip swap (-> NO_SWAP @ 0x74)
//        // --------------------------------------------------------
//        load_instruction(32'd104, 32'h00C6D663);  // bge x13, x12, NO_SWAP
 
//        // --------------------------------------------------------
//        // Swap
//        //   sw x13, 0(x14)   arr[j]   = arr[j+1]
//        //   sw x12, 4(x14)   arr[j+1] = arr[j]
//        // --------------------------------------------------------
//        load_instruction(32'd108, 32'h00D72023);  // sw x13, 0(x14)
//        load_instruction(32'd112, 32'h00C72223);  // sw x12, 4(x14)
 
//        // --------------------------------------------------------
//        // NO_SWAP (0x74): j_byte += 4, loop back to INNER_LOOP (0x48)
//        // --------------------------------------------------------
//        load_instruction(32'd116, 32'h00450513);  // addi x10, x10, 4
//        load_instruction(32'd120, 32'hFCB548E3);  // blt  x10, x11, INNER_LOOP
 
//        // --------------------------------------------------------
//        // OUTER_INC (0x7C): i++, loop back to OUTER_LOOP (0x38)
//        // --------------------------------------------------------
//        load_instruction(32'd124, 32'h00138393);  // addi x7, x7, 1
//        load_instruction(32'd128, 32'hFA83CCE3);  // blt  x7, x8, OUTER_LOOP
 
//        // --------------------------------------------------------
//        // DONE (0x84): infinite self-loop (halt)
//        // --------------------------------------------------------
//        load_instruction(32'd132, 32'h00000063);  // beq x0, x0, 0
 
//        // --------------------------------------------------------
//        // Start CPU
//        // --------------------------------------------------------
//        @(negedge clk);
//        fetch_enable = 1;
 
//        // --------------------------------------------------------
//        // Wait: 34 instructions x ~8 cycles avg + 200 drain ~= 472
//        // Using 800 for safety (includes branch misprediction refills)
//        // --------------------------------------------------------
//        repeat(800) @(posedge clk);
 
       
//        // --------------------------------------------------------
//        // Report
//        // --------------------------------------------------------
//        $display("");
//        $display("========================================");
//        $display("      BUBBLE SORT TEST REPORT");
//        $display("========================================");
//        $display("");
//        $display("INPUT    : {40, 10, 30, 20, 50}");
//        $display("EXPECTED : {10, 20, 30, 40, 50}");
//        $display("");
//        $display("OBSERVED:");
//        $display("  MEM[0] = %0d", dut.mem_stage.Memory[0]);
//        $display("  MEM[1] = %0d", dut.mem_stage.Memory[1]);
//        $display("  MEM[2] = %0d", dut.mem_stage.Memory[2]);
//        $display("  MEM[3] = %0d", dut.mem_stage.Memory[3]);
//        $display("  MEM[4] = %0d", dut.mem_stage.Memory[4]);
 
//        pass = (dut.mem_stage.Memory[0] == 10) &&
//               (dut.mem_stage.Memory[1] == 20) &&
//               (dut.mem_stage.Memory[2] == 30) &&
//               (dut.mem_stage.Memory[3] == 40) &&
//               (dut.mem_stage.Memory[4] == 50);
 
//        $display("");
//        if (pass) begin
//            $display("RESULT : PASS");
//        end else begin
//            $display("RESULT : FAIL");
//            $display("");
//        end
 
//        $display("========================================");
//        #20;
//        $finish;
//    end
 
//endmodule