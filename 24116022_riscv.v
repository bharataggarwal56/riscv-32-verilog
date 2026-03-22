`include "alu.v"
`include "regfile.v"
`include "imm_gen.v"
`include "branch_comp.v"
`include "control_unit.v"

module riscv_processor #(
    parameter RESET_ADDR = 32'h00000000,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    output [31:0] mem_addr, //address bus
    output [31:0] mem_wdata, // data to be written
    output [3:0]  mem_wmask, //write masks for the 4 bytes of each word
    input  [31:0] mem_rdata, // input lines for both data and instr
    output mem_rstrb, //active to initiate memory read (used by IO)
    input mem_rbusy, // asserted if memory is busy reading value
    input mem_wbusy, // asserted if memory is busy writing value
    input reset // set to 0 to reset the processor
);

    reg [31:0] pc;
    reg [31:0] inst_reg;
    always @(posedge clk) begin
        if (state == STATE_EXEC) inst_reg <= mem_rdata;
    end
    wire [31:0] instruction = (state == STATE_LOAD) ? inst_reg : mem_rdata;

    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    wire RegWEn, BSel, ASel, MemRead, MemWrite, BrUn;
    wire [2:0] ImmSel;
    wire [3:0] ALUSel;
    wire [1:0] WBSel;

    wire [31:0] imm_out, reg_data1, reg_data2, alu_result;
    wire BrEq, BrLT;

    control_unit my_cu(
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .RegWEn(RegWEn), .ImmSel(ImmSel), .BSel(BSel), .ASel(ASel),
        .ALUSel(ALUSel), .MemRead(MemRead), .MemWrite(MemWrite),
        .WBSel(WBSel), .BrUn(BrUn)
    );

    imm_gen my_imm(.inst(instruction), .ImmSel(ImmSel), .imm(imm_out));

    wire actual_reg_write = RegWEn && (state == STATE_EXEC && !MemRead || state == STATE_LOAD);
    reg [31:0] write_back_data;

    regfile my_reg(
        .clk(clk), .RegWEn(actual_reg_write), 
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .data_in(write_back_data), 
        .data_out1(reg_data1), .data_out2(reg_data2)
    );

    branch_comp my_bc(.A(reg_data1), .B(reg_data2), .BrUn(BrUn), .BrEq(BrEq), .BrLT(BrLT));

    wire [31:0] alu_in_a = (opcode == 7'b0110111) ? 32'b0 : 
                           (opcode == 7'b0010111) ? pc : 
                           (ASel) ? pc : reg_data1; 

    wire [31:0] alu_in_b = (BSel) ? imm_out : reg_data2;
    
    alu my_alu(.A(alu_in_a), .B(alu_in_b), .ALUSel(ALUSel), .Result(alu_result));

    wire [1:0] byte_offset = alu_result[1:0];
    reg [31:0] formatted_load;
    wire [31:0] shifted_rdata = mem_rdata >> (byte_offset * 8);

    always @(*) begin
        case(funct3)
            3'b000: formatted_load = {{24{shifted_rdata[7]}}, shifted_rdata[7:0]};
            3'b001: formatted_load = {{16{shifted_rdata[15]}}, shifted_rdata[15:0]};
            3'b010: formatted_load = shifted_rdata;
            3'b100: formatted_load = {24'b0, shifted_rdata[7:0]};
            3'b101: formatted_load = {16'b0, shifted_rdata[15:0]};
            default: formatted_load = shifted_rdata;
        endcase
    end

    always @(*) begin
        case(WBSel)
            2'b00: write_back_data = alu_result; 
            2'b01: write_back_data = formatted_load; 
            2'b10: write_back_data = pc + 4; 
            default: write_back_data = 32'b0;
        endcase
    end

    wire take_branch = (opcode == 7'b1100011) &&
                       ((funct3 == 3'b000 && BrEq) || (funct3 == 3'b001 && !BrEq) ||
                        (funct3 == 3'b100 && BrLT) || (funct3 == 3'b101 && !BrLT) ||
                        (funct3 == 3'b110 && BrLT) || (funct3 == 3'b111 && !BrLT));
                        
    wire is_jump = (opcode == 7'b1101111) || (opcode == 7'b1100111);

    localparam STATE_FETCH = 2'd0;
    localparam STATE_EXEC  = 2'd1;
    localparam STATE_LOAD  = 2'd2;
    reg [1:0] state;

    assign mem_addr = (state == STATE_FETCH) ? pc : alu_result;
    assign mem_rstrb = (state == STATE_FETCH) || (state == STATE_EXEC && MemRead);
    
    reg [3:0] wmask_calc;
    always @(*) begin
        if (state == STATE_EXEC && MemWrite) begin
            case(funct3)
                3'b000: wmask_calc = 4'b0001 << byte_offset;
                3'b001: wmask_calc = 4'b0011 << byte_offset;
                3'b010: wmask_calc = 4'b1111 << byte_offset;
                default: wmask_calc = 4'b0000;
            endcase
        end else begin
            wmask_calc = 4'b0000;
        end
    end
    
    assign mem_wmask = wmask_calc;
    assign mem_wdata = reg_data2 << (byte_offset * 8);

    always @(posedge clk) begin
        if (!reset) begin
            state <= STATE_FETCH;
            pc <= RESET_ADDR;
        end else if (!mem_rbusy && !mem_wbusy) begin
            case (state)
                STATE_FETCH: state <= STATE_EXEC;
                STATE_EXEC: begin
                    if (MemRead) state <= STATE_LOAD;
                    else begin
                        if (take_branch || is_jump) pc <= alu_result;
                        else pc <= pc + 4;
                        state <= STATE_FETCH;
                    end
                end
                STATE_LOAD: begin
                    pc <= pc + 4;
                    state <= STATE_FETCH;
                end
            endcase
        end
    end

endmodule