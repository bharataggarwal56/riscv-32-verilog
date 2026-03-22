module imm_gen(
    input [31:0] inst, //encoded instruction from memory
    input [2:0]  ImmSel, // signal from control unit for type of instruction
    output reg [31:0] imm // 32 bit immediate
);
    always @(*) begin
        case (ImmSel)
            // I-Type Top 12 bits of instruction
            3'b000: imm = {{20{inst[31]}}, inst[31:20]}; 
            
            // S-Type Split between top 7 bits and bottom 5 bits
            3'b001: imm = {{20{inst[31]}}, inst[31:25], inst[11:7]}; 
            
            // B-Type 0 at the end
            3'b010: imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; 
            
            // U-Type Top 20 bits, lower 12 bits filled with zeros
            3'b011: imm = {inst[31:12], 12'b0}; 
            
            // J-Type 20-bit jump address, 0 at the end
            3'b100: imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; 
            
            default: imm = 32'b0;
        endcase
    end

endmodule