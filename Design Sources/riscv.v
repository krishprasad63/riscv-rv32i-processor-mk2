`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.05.2026 08:30:39
// Design Name: 
// Module Name: riscv
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


module riscv(
    input clk,
    input reset,
    input load_enable, //for instruction memory in fetch
    input fetch_enable, //
    input reg_write_enable,
    input [31:0] load_address,
    input [31:0] load_data,
    input [31:0] base_pc,
    output [31:0] write_back_data
    //output zero,
    //output carry,
    //output overflow
    );
    reg [31:0] Register [0:31];// register_file
    
    //FETCH STAGE
    wire pc_write; //HAS TO BE DECLARED ABOVE
    wire [31:0]  fetched_instruction;
    wire [31:0] current_pc;
    wire [31:0] pc;

    // folllowing will be updated from execute stage
    wire branch_beq, branch_bneq, branch_bge, branch_blt, branch_jump;
    wire [31:0] branch_imm_address, branch_imm_address_jump;
    
    wire [31:0] ex_branch_imm;
    wire [31:0] branch_target;
    
    fetch_stage fetch(
        .clk(clk),
        .reset(reset),
        .load_enable(load_enable),
        .fetch_enable(fetch_enable),
        .pc_write(pc_write),
        .load_address(load_address),
        .load_data(load_data),
        .base_pc(base_pc),
        .beq(branch_beq),
        .bneq(branch_bneq),
        .blt(branch_blt),
        .bge(branch_bge),
        .jump(branch_jump),
        .imm_address(branch_target),
        .imm_address_jump(branch_imm_address_jump),
        .pc(pc),
        .current_pc(current_pc),
        .fetched_instruction(fetched_instruction)
    );
    
    //--------------------------------------------------
    // Control Hazard Flush
    //--------------------------------------------------
    
    // Flush IF/ID whenever a branch is taken.
    wire flush_ifid;
    
    wire pipeline_flush;
    
    assign pipeline_flush = flush_ifid;
    
    assign flush_ifid =
            branch_beq  |
            branch_bneq |
            branch_blt  |
            branch_bge;
    
    wire flush_idex = flush_ifid;
    
            
    //IF/ID Register
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instruction;
    wire if_id_write;
    
    if_id_register if_id_reg(
        .clk(clk),
        .reset(reset),
        .if_id_write(if_id_write),
        .flush(flush_ifid),
        .in_pc(pc),
        .in_instruction(fetched_instruction),
        .out_pc(if_id_pc),
        .out_instruction(if_id_instruction)
    );
    
    //DECODE STAGE
    wire [6:0]  decode_opcode; wire [4:0]  decode_rd;
    wire [2:0]  decode_funct3; wire [4:0]  decode_rs1;
    wire [4:0]  decode_rs2;  wire [6:0]  decode_funct7;
    wire [31:0] decode_imm;  wire [6:0] decode_alu_opcode;
    wire decode_alu_src;     wire decode_mem_read;
    wire decode_mem_write;   wire decode_mem_to_reg;
    wire decode_reg_write;
    wire decode_beq_control; wire decode_bneq_control;
    wire decode_blt_control; wire decode_bge_control;

    decode_stage decode(
        .clk(clk),
        .instruction(if_id_instruction),
        .opcode(decode_opcode),
        .rd(decode_rd),
        .funct3(decode_funct3),
        .rs1(decode_rs1),
        .rs2(decode_rs2),
        .funct7(decode_funct7),
        .imm(decode_imm),
        .alu_opcode(decode_alu_opcode),
        .alu_src(decode_alu_src),
        .mem_read(decode_mem_read),
        .mem_write(decode_mem_write),
        .mem_to_reg(decode_mem_to_reg),
        .reg_write(decode_reg_write),
        .beq_control(decode_beq_control),
        .bneq_control(decode_bneq_control),
        .blt_control(decode_blt_control),
        .bge_control(decode_bge_control),
        .imm_address(branch_imm_address)
    );
    
    
    // Register file read logic - happens in Decode stage
    wire [31:0] read_data_1;
    wire [31:0] read_data_2;
    
//    assign read_data_1 = Register[decode_rs1];
//    assign read_data_2 = Register[decode_rs2];
    
    //ID/EX WIRES DECLARATION
    wire [6:0] ex_alu_op; wire ex_alu_src; wire [31:0] ex_pc;
    wire ex_mem_read; wire ex_mem_write; wire [31:0] ex_imm;
    wire ex_mem_to_reg;   wire ex_beq_control;
    wire ex_reg_write;
    wire ex_bneq_control; wire ex_blt_control;
    wire [31:0] ex_read_data_1; wire ex_bge_control;
    wire [31:0] ex_read_data_2; 
    wire [4:0] ex_rd;  wire [4:0] ex_rs1;
    wire [4:0] ex_rs2; wire [6:0] ex_funct7;
    wire [2:0] ex_funct3; wire [31:0] ex_instruction;
    
    wire [4:0]  mem_rd;
    wire        mem_mem_read;
    wire        mem_mem_write;
    
    //--------------------------------------------------
    // Hazard Detection Wires
    //--------------------------------------------------
    
    wire control_mux;
    
    hazard_detection_unit HDU(
        .if_id_rs1(decode_rs1),
        .if_id_rs2(decode_rs2),
    
        .ex_mem_mem_read(mem_mem_read),   // NEW
        .ex_mem_rd(mem_rd),               // NEW
    
        .id_ex_rd(ex_rd),
        .id_ex_mem_read(ex_mem_read),
    
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .control_mux(control_mux)
    );


    wire stall_mem_read;
    wire stall_mem_write;
    wire stall_mem_to_reg;
    wire stall_reg_write;
    
    wire stall_beq;
    wire stall_bneq;
    wire stall_blt;
    wire stall_bge;
    
    assign stall_mem_read   = control_mux ? 1'b0 : decode_mem_read;
    assign stall_mem_write  = control_mux ? 1'b0 : decode_mem_write;
    assign stall_mem_to_reg = control_mux ? 1'b0 : decode_mem_to_reg;
    assign stall_reg_write  = control_mux ? 1'b0 : decode_reg_write;
    
    assign stall_beq  = control_mux ? 1'b0 : decode_beq_control;
    assign stall_bneq = control_mux ? 1'b0 : decode_bneq_control;
    assign stall_blt  = control_mux ? 1'b0 : decode_blt_control;
    assign stall_bge  = control_mux ? 1'b0 : decode_bge_control;
    
    // --- ID/EX PIPELINE REGISTER ---
    
    assign branch_target = ex_pc + ex_branch_imm;
    //something will add here ..
    
    id_ex_register id_ex_reg (
        .clk(clk),
        .reset(reset),
        .flush(flush_idex),
        .in_branch_imm(branch_imm_address),
        .in_pc(if_id_pc),
        // Inputs from Decode
        .in_alu_op(decode_alu_opcode),
        .in_alu_src(decode_alu_src),
        .in_mem_read(stall_mem_read),
        .in_mem_write(stall_mem_write),
        .in_mem_to_reg(stall_mem_to_reg),
        .in_reg_write(stall_reg_write),
        
        .in_beq_control(stall_beq),
        .in_bneq_control(stall_bneq),
        .in_blt_control(stall_blt),
        .in_bge_control(stall_bge),
        .in_read_data_1(read_data_1),
        .in_read_data_2(read_data_2),
        .in_imm(decode_imm),
        .in_rs1(decode_rs1),
        .in_rs2(decode_rs2),
        .in_rd(decode_rd),
        .in_funct7(decode_funct7),
        .in_funct3(decode_funct3),
        .in_instruction(if_id_instruction),
        // Outputs to Execute
        .out_alu_op(ex_alu_op),
        .out_alu_src(ex_alu_src),
        .out_mem_read(ex_mem_read),
        .out_mem_write(ex_mem_write),
        .out_mem_to_reg(ex_mem_to_reg),
        .out_reg_write(ex_reg_write),
        .out_beq_control(ex_beq_control),
        .out_bneq_control(ex_bneq_control),
        .out_blt_control(ex_blt_control),
        .out_bge_control(ex_bge_control),
        .out_read_data_1(ex_read_data_1),
        .out_read_data_2(ex_read_data_2),
        .out_imm(ex_imm),
        .out_rd(ex_rd),
        .out_funct7(ex_funct7),
        .out_funct3(ex_funct3),
        .out_branch_imm(ex_branch_imm),
        .out_pc(ex_pc),
        .out_rs1(ex_rs1),
        .out_rs2(ex_rs2),
        .out_instruction(ex_instruction)
    );
    
    // EX-MEM WIRES DECLARATION
    // Wires coming out of the EX/MEM register (inputs to Memory stage)

    wire        mem_mem_to_reg;
    wire        mem_reg_write;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_store_data;
    
    //MEM-WEB WIRE DECLARRATION
    wire [4:0]  wb_rd;
    wire wb_mem_to_reg;
    wire wb_reg_write;
    wire [31:0] wb_read_data, wb_alu_result;
    
    //--------------------------------------------------
    // Forwarding MUXes
    //--------------------------------------------------
    
    wire [1:0] forwardA;
    wire [1:0] forwardB;
    wire [31:0] alu_input_A;
    wire [31:0] alu_input_B;
    wire [31:0] forwarded_store_data;
    
    assign alu_input_A =
        (forwardA == 2'b00) ? ex_read_data_1 :
        (forwardA == 2'b10) ? mem_alu_result :
        (forwardA == 2'b01) ? write_back_data :
                              ex_read_data_1;
                              
    assign alu_input_B =
        (forwardB == 2'b00) ?
            (ex_alu_src ? ex_imm : ex_read_data_2) :

        (forwardB == 2'b10) ?
            (ex_alu_src ? ex_imm : mem_alu_result) :

        (forwardB == 2'b01) ?
            (ex_alu_src ? ex_imm : write_back_data) :
        (ex_alu_src ? ex_imm : ex_read_data_2);
        
    assign forwarded_store_data =
        (forwardB == 2'b00) ? ex_read_data_2 :
        (forwardB == 2'b10) ? mem_alu_result :
        (forwardB == 2'b01) ? write_back_data :
                              ex_read_data_2;
                              
    // --- EXECUTE STAGE ---

    wire [31:0] ex_alu_result;
    wire ex_zero, ex_carry, ex_overflow;
    
    

    execute_stage execute(
        .clk(clk),
        .A(alu_input_A),
        .B(alu_input_B),
        .opcode(ex_alu_op),
        .funct3(ex_funct3),
        .funct7(ex_funct7),
        .beq_control(ex_beq_control),
        .bneq_control(ex_bneq_control),
        .blt_control(ex_blt_control),
        .bge_control(ex_bge_control),
        .alu_result(ex_alu_result),
        .zero(ex_zero),
        .carry(ex_carry),
        .overflow(ex_overflow),
        .beq(branch_beq),
        .bneq(branch_bneq),
        .blt(branch_blt),
        .bge(branch_bge)
    );
    

    
    // --- EX/MEM PIPELINE REGISTER ---
    
    ex_mem_register ex_mem_reg (
        .clk(clk),
        .reset(reset),
        // Inputs from Execute
        .in_mem_read(ex_mem_read),
        .in_mem_write(ex_mem_write),
        .in_mem_to_reg(ex_mem_to_reg),
        .in_reg_write(ex_reg_write),
        .in_alu_result(ex_alu_result),
        .in_store_data(forwarded_store_data),
        .in_rd(ex_rd),
        // Outputs to Memory
        .out_mem_read(mem_mem_read),
        .out_mem_write(mem_mem_write),
        .out_mem_to_reg(mem_mem_to_reg),
        .out_reg_write(mem_reg_write),
        .out_alu_result(mem_alu_result),
        .out_store_data(mem_store_data),
        .out_rd(mem_rd)
    );
    
    
    //MEMORY STAGE

    wire [31:0] mem_read_data_out;
    
    memory_stage mem_stage (
        .clk(clk),
        .mem_write(mem_mem_write),
        .alu_result(mem_alu_result),    // result from EX stage
        .rs2_data(mem_store_data), // value to store (from rs2)
        .read_data_out(mem_read_data_out)
    );


    //MEM/WB PIPELINE REGISTER
    
    mem_wb_register mem_wb_reg (
        .clk(clk), .reset(reset),
        .in_mem_to_reg(mem_mem_to_reg), .in_reg_write(mem_reg_write),
        .in_read_data(mem_read_data_out),
        .in_alu_result(mem_alu_result), .in_rd(mem_rd),
        .out_mem_to_reg(wb_mem_to_reg), .out_reg_write(wb_reg_write),
        .out_read_data(wb_read_data),
        .out_alu_result(wb_alu_result), .out_rd(wb_rd)
    );
    
    // WRITE BACK DATA
    
    assign write_back_data = (wb_mem_to_reg) ? wb_read_data : wb_alu_result;
        
    //    always @(posedge clk) begin
    //        if (reg_write_enable && wb_rd != 5'b0) begin
    //            Register[wb_rd] <= write_back_data;
    //        end
    //    end
    integer i;
    
    always @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
            for(i=0;i<32;i=i+1)
                Register[i] <= 32'b0;
        end
        else if(reg_write_enable && wb_reg_write && wb_rd != 0)
        begin
            Register[wb_rd] <= write_back_data;
        end
    
        Register[0] <= 32'b0;
    end
    
    //fix suggested by claude
    assign read_data_1 = (wb_reg_write && wb_rd == decode_rs1 && wb_rd != 0)
                        ? write_back_data : Register[decode_rs1];
    
    assign read_data_2 = (wb_reg_write && wb_rd == decode_rs2 && wb_rd != 0)
                            ? write_back_data : Register[decode_rs2];

        
    //--------------------------------------------------
    // Forwarding Unit
    //--------------------------------------------------
    
    
//    forwarding_unit FU(
//        .id_ex_rs1(ex_rs1),
//        .id_ex_rs2(ex_rs2),
//        .ex_mem_rd(mem_rd),
//        .ex_mem_reg_write(mem_reg_write),
//        .mem_wb_rd(wb_rd),
//        .mem_wb_reg_write(wb_reg_write),
//        .forwardA(forwardA),
//        .forwardB(forwardB)
    
//    );
    forwarding_unit FU(
        .id_ex_rs1(ex_rs1),
        .id_ex_rs2(ex_rs2),
        .ex_mem_rd(mem_rd),
        .ex_mem_reg_write(mem_reg_write),
        .ex_mem_mem_read(mem_mem_read),
        .mem_wb_rd(wb_rd),
        .mem_wb_reg_write(wb_reg_write),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
    
endmodule





