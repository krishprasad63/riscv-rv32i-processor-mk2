`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2026 18:42:00
// Design Name: 
// Module Name: tb_compare_swap
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

 
module tb_compare_swap;
 
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
    riscv dut(
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
 
    //------------------------------------------------------------
    // Clock
    //------------------------------------------------------------
    always #5 clk = ~clk;
 
    //------------------------------------------------------------
    // Load Instruction Task
    //------------------------------------------------------------
    task load_instruction;
        input [31:0] addr;
        input [31:0] instr;
        begin
            @(negedge clk);
            load_enable  = 1'b1;
            load_address = addr;
            load_data    = instr;
            @(negedge clk);
            load_enable  = 1'b0;
        end
    endtask
 
    //------------------------------------------------------------
    // Verification Statistics
    //------------------------------------------------------------
    integer cycle_count;
    integer instruction_count;
 
    integer register_writes;
    integer memory_reads;
    integer memory_writes;
 
    integer branch_instructions;
    integer branches_taken;
 
    integer forwarding_events;
    integer pipeline_stalls;
    integer pipeline_flushes;
 
    always @(posedge clk)
    begin
 
        //--------------------------------------------------------
        // Reset
        //--------------------------------------------------------
        if (reset)
        begin
            cycle_count         <= 0;
            instruction_count   <= 0;
 
            register_writes     <= 0;
 
            memory_reads        <= 0;
            memory_writes       <= 0;
 
            branch_instructions <= 0;
            branches_taken      <= 0;
 
            forwarding_events   <= 0;
            pipeline_stalls     <= 0;
            pipeline_flushes    <= 0;
        end
 
        //--------------------------------------------------------
        // Collect Statistics
        //--------------------------------------------------------
        else if (fetch_enable)
        begin
 
            //-----------------------------
            // Total Cycles
            //-----------------------------
            cycle_count <= cycle_count + 1;
 
            //-----------------------------
            // Instructions Entering Pipeline
            //-----------------------------
            instruction_count <= instruction_count + 1;
 
            //-----------------------------
            // Register Writes
            //-----------------------------
            if (dut.wb_reg_write)
                register_writes <= register_writes + 1;
 
            //-----------------------------
            // Memory Reads
            //-----------------------------
            if (dut.mem_mem_read)
                memory_reads <= memory_reads + 1;
 
            //-----------------------------
            // Memory Writes
            //-----------------------------
            if (dut.mem_mem_write)
                memory_writes <= memory_writes + 1;
 
            //-----------------------------
            // Branch Instructions
            //-----------------------------
            if (dut.ex_beq_control  ||
                dut.ex_bneq_control ||
                dut.ex_blt_control  ||
                dut.ex_bge_control)
            begin
                branch_instructions <= branch_instructions + 1;
            end
 
            //-----------------------------
            // Branches Taken
            //-----------------------------
            if (dut.branch_beq  ||
                dut.branch_bneq ||
                dut.branch_blt  ||
                dut.branch_bge)
            begin
                branches_taken <= branches_taken + 1;
            end
 
            //-----------------------------
            // Forwarding Events
            //-----------------------------
            if (dut.forwardA != 2'b00 ||
                dut.forwardB != 2'b00)
            begin
                forwarding_events <= forwarding_events + 1;
            end
 
            //-----------------------------
            // Pipeline Stalls
            //-----------------------------
            if (!dut.pc_write)
                pipeline_stalls <= pipeline_stalls + 1;
 
            //-----------------------------
            // Pipeline Flushes
            //-----------------------------
            if (dut.flush_ifid)
                pipeline_flushes <= pipeline_flushes + 1;
 
        end
 
    end
 
    //------------------------------------------------------------
    // Test
    //------------------------------------------------------------
    initial begin
 
        clk = 0;
        reset = 1;
 
        load_enable      = 0;
        fetch_enable     = 0;
        reg_write_enable = 1;
 
        load_address = 0;
        load_data    = 0;
        base_pc      = 0;
 
        //--------------------------------------------------------
        // Reset
        //--------------------------------------------------------
        #20;
        reset = 0;
 
        //--------------------------------------------------------
        // Program
        //--------------------------------------------------------
 
        load_instruction(32'd0 , 32'h02800093);   // addi x1,x0,40
        load_instruction(32'd4 , 32'h00102023);   // sw x1,0(x0)
 
        load_instruction(32'd8 , 32'h00A00093);   // addi x1,x0,10
        load_instruction(32'd12, 32'h00102223);   // sw x1,4(x0)
 
        load_instruction(32'd16, 32'h00002103);   // lw x2,0(x0)
        load_instruction(32'd20, 32'h00402183);   // lw x3,4(x0)
 
        load_instruction(32'd24, 32'h00314863);   // blt x2,x3,NO_SWAP  (+16 -> PC=40)
        load_instruction(32'd28, 32'h00310663);   // beq x2,x3,NO_SWAP  (+12 -> PC=40)
 
        load_instruction(32'd32, 32'h00302023);   // sw x3,0(x0)
        load_instruction(32'd36, 32'h00202223);   // sw x2,4(x0)
 
        load_instruction(32'd40, 32'h00000063);   // DONE (beq x0,x0,0 - self-loop)
 
        //--------------------------------------------------------
        // Start CPU
        //--------------------------------------------------------
        @(negedge clk);
        fetch_enable = 1'b1;
 
        //--------------------------------------------------------
        // Execute  (40 cycles is enough for 11 instructions + pipeline drain)
        //--------------------------------------------------------
        repeat (40)
            @(posedge clk);
 
        //--------------------------------------------------------
        // Stop fetch so stats counters freeze
        //--------------------------------------------------------
        fetch_enable = 1'b0;
        @(negedge clk);
 
        //--------------------------------------------------------
        // Report - functional
        //--------------------------------------------------------
 
        $display("");
        $display("========================================");
        $display("        COMPARE SWAP TEST REPORT");
        $display("========================================");
 
        $display("");
        $display("Registers");
        $display("x1 = %0d", dut.Register[1]);
        $display("x2 = %0d", dut.Register[2]);
        $display("x3 = %0d", dut.Register[3]);
 
        $display("");
        $display("Memory");
        $display("MEM[0] = %0d", dut.mem_stage.Memory[0]);
        $display("MEM[1] = %0d", dut.mem_stage.Memory[1]);
 
        $display("");
        $display("EXPECTED");
        $display("x2     = 40");
        $display("x3     = 10");
        $display("MEM[0] = 10");
        $display("MEM[1] = 40");
 
        $display("");
        if (dut.Register[2] == 40 &&
            dut.Register[3] == 10 &&
            dut.mem_stage.Memory[0] == 10 &&
            dut.mem_stage.Memory[1] == 40)
            $display("RESULT : PASS");
        else
            $display("RESULT : FAIL");
 
        //--------------------------------------------------------
        // Report - pipeline statistics
        //--------------------------------------------------------
 
        $display("");
        $display("========================================");
        $display("        PIPELINE STATISTICS");
        $display("========================================");
        $display("Total Cycles          : %0d", cycle_count);
        $display("Instructions Fetched  : %0d", instruction_count);
        $display("Register Writes       : %0d", register_writes);
        $display("Memory Reads          : %0d", memory_reads);
        $display("Memory Writes         : %0d", memory_writes);
        $display("Branch Instructions   : %0d", branch_instructions);
        $display("Branches Taken        : %0d", branches_taken);
        $display("Forwarding Events     : %0d", forwarding_events);
        $display("Pipeline Stalls       : %0d", pipeline_stalls);
        $display("Pipeline Flushes      : %0d", pipeline_flushes);
        $display("========================================");
        $display("");
 
        $finish;
 
    end
 
endmodule