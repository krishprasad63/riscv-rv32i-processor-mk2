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

    reg        clk;
    reg        reset;
    reg        load_enable;
    reg        fetch_enable;
    reg        reg_write_enable;
    reg [31:0] load_address;
    reg [31:0] load_data;
    reg [31:0] base_pc;
    
    wire [31:0] write_back_data;
    
    //--------------------------------------------------
    // DUT
    //--------------------------------------------------
    riscv uut (
        .clk              (clk),
        .reset            (reset),
        .load_enable      (load_enable),
        .fetch_enable     (fetch_enable),
        .reg_write_enable (reg_write_enable),
        .load_address     (load_address),
        .load_data        (load_data),
        .base_pc          (base_pc),
        .write_back_data  (write_back_data)
    );
    
    //--------------------------------------------------
    // CLOCK  (10 ns period → 100 MHz)
    //--------------------------------------------------
    initial begin clk = 0; forever #5 clk = ~clk; end
    
    //--------------------------------------------------
    // HELPER TASK
    //--------------------------------------------------
    task li;
        input [31:0] addr, data;
        begin load_address = addr; load_data = data; #10; end
    endtask
    
    //--------------------------------------------------
    // PARAMETERS  (change here if program changes)
    //--------------------------------------------------
    localparam INSTR_COUNT    = 15;
    localparam PIPELINE_DEPTH = 5;
    localparam CLK_PERIOD_NS  = 10;
    
    integer exec_start_ns;
    real cpi;
    //--------------------------------------------------
    // MAIN
    //--------------------------------------------------
    initial begin
    
        {reset, load_enable, fetch_enable, reg_write_enable} = 4'b1000;
        base_pc = 32'h0;
        #20; reset = 0;
    
        load_enable = 1;
    
        // ----- Store: mem[0..3] = {10, 20, 30, 40} -----
        li(32'h00, 32'h00A00093);  // addi x1, x0, 10
        li(32'h04, 32'h00102023);  // sw   x1,  0(x0)   → mem[0] = 10
    
        li(32'h08, 32'h01400093);  // addi x1, x0, 20
        li(32'h0C, 32'h00102223);  // sw   x1,  4(x0)   → mem[1] = 20
    
        li(32'h10, 32'h01E00093);  // addi x1, x0, 30
        li(32'h14, 32'h00102423);  // sw   x1,  8(x0)   → mem[2] = 30
    
        li(32'h18, 32'h02800093);  // addi x1, x0, 40
        li(32'h1C, 32'h00102623);  // sw   x1, 12(x0)   → mem[3] = 40
    
        // ----- Sum: x5 = mem[0]+mem[1]+mem[2]+mem[3] -----
        li(32'h20, 32'h00002103);  // lw   x2,  0(x0)   ; x2 = 10
        li(32'h24, 32'h00402183);  // lw   x3,  4(x0)   ; x3 = 20
        li(32'h28, 32'h003102B3);  // add  x5, x2, x3   ; x5 = 30
    
        li(32'h2C, 32'h00802103);  // lw   x2,  8(x0)   ; x2 = 30
        li(32'h30, 32'h002282B3);  // add  x5, x5, x2   ; x5 = 60
    
        li(32'h34, 32'h00C02103);  // lw   x2, 12(x0)   ; x2 = 40
        li(32'h38, 32'h002282B3);  // add  x5, x5, x2   ; x5 = 100
    
        li(32'h3C, 32'h00502823);  // sw   x5, 16(x0)   → mem[4] = 100
    
        //--------------------------------------------------
        // RUN - record time the CPU starts fetching
        //--------------------------------------------------
        load_enable      = 0;
        fetch_enable     = 1;
        reg_write_enable = 1;
        exec_start_ns    = $time;
    
        #500;
    
        //--------------------------------------------------
        // REPORT
        //--------------------------------------------------
        $display("------------------------------------------");
        $display("  Array Sum Test  {10, 20, 30, 40}");
        $display("------------------------------------------");
        $display("  Expected  : 100");
        $display("  Got       : %0d", uut.mem_stage.Memory[4]);
        $display("  Result    : %s",
            (uut.mem_stage.Memory[4] == 32'd100) ? "PASS" : "FAIL");
        $display("------------------------------------------");
        $display("  PERFORMANCE");
        $display("  Clock            : %0d MHz",
                    1000 / CLK_PERIOD_NS);
        $display("  Instructions     : %0d",
                    INSTR_COUNT);
        $display("  Pipeline stages  : %0d",
                    PIPELINE_DEPTH);
        $display("  CPU cycles       : %0d  (instr + drain)",
                    INSTR_COUNT + PIPELINE_DEPTH - 1);
        $display("  CPU exec time    : %0d ns",
                    (INSTR_COUNT + PIPELINE_DEPTH - 1) * CLK_PERIOD_NS);
        cpi = (INSTR_COUNT + PIPELINE_DEPTH - 1.0) / INSTR_COUNT;
        $display("  CPI              : %.2f", cpi);
        $display("  Sim window used  : %0d ns  (fetch -> $finish)",
                $time - exec_start_ns);
        $display("  Total sim time   : %0d ns", $time);
        $display("------------------------------------------");
    
        $finish;
        end

        endmodule
