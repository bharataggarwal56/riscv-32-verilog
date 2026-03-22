module control_unit(
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    
    output reg RegWEn, // 1 = Write to Register File
    output reg [2:0] ImmSel, // for type of inst.
    output reg BSel, // if 0, ALU gets Register 2, if 1, ALU gets Immediate
    output reg ASel, // if 0,ALU gets Register 1, if 1 ALU gets PC
    output reg [3:0] ALUSel,// used in alu module
    output reg MemRead, // 1 = Read from Data Memory
    output reg MemWrite, // 1 = Write to Data Memory
    output reg [1:0] WBSel, // 0 = ALU to Reg, 1 = Mem to Reg, 2 = PC+4 to Reg
    output reg BrUn // 1 for Unsigned branch compare
);
    always @(*) begin
        // Default all 0
        RegWEn = 0; ImmSel = 3'b000; BSel = 0; ASel = 0; ALUSel = 4'b0000; 
        MemRead = 0; MemWrite = 0; WBSel = 2'b00; BrUn = 0;

        case(opcode)
            // R-Type
            7'b0110011: begin
                RegWEn = 1; ASel = 0; BSel = 0; WBSel = 2'b00;
                
                if (funct3==3'b000 && funct7==7'b0000000) ALUSel = 4'b0000; // ADD
                else if (funct3==3'b000 && funct7==7'b0100000) ALUSel = 4'b0001; // SUB
                else if (funct3== 3'b111) ALUSel = 4'b0010; // AND
                else if (funct3== 3'b110) ALUSel = 4'b0011; // OR
                else if (funct3== 3'b100) ALUSel = 4'b0100; // XOR
                else if (funct3== 3'b001) ALUSel = 4'b0101; // SLL
                else if (funct3==3'b101 && funct7==7'b0000000) ALUSel = 4'b0110; // SRL
                else if (funct3==3'b101 && funct7==7'b0100000) ALUSel = 4'b0111; // SRA
                else if (funct3== 3'b010) ALUSel = 4'b1000; // SLT
                else if (funct3== 3'b011) ALUSel = 4'b1001; // SLTU
            end

            // I-Type
            7'b0010011: begin
                RegWEn = 1; ImmSel = 3'b000; ASel = 0; BSel = 1; WBSel = 2'b00;
                
                if (funct3 == 3'b000) ALUSel = 4'b0000; // ADDI
                else if (funct3 == 3'b111) ALUSel = 4'b0010; // ANDI
                else if (funct3 == 3'b110) ALUSel = 4'b0011; // ORI
                else if (funct3 == 3'b100) ALUSel = 4'b0100; // XORI
                else if (funct3 == 3'b010) ALUSel = 4'b1000; // SLTI
                else if (funct3 == 3'b011) ALUSel = 4'b1001; // SLTIU 
                else if (funct3 == 3'b001) ALUSel = 4'b0101; // SLLI
                else if (funct3 == 3'b101 && funct7 == 7'b0000000) ALUSel = 4'b0110; // SRLI
                else if (funct3 == 3'b101 && funct7 == 7'b0100000) ALUSel = 4'b0111; // SRAI
            end
            //I-Type Load (lw,lh,lb)
            7'b0000011: begin
                RegWEn = 1; ImmSel = 3'b000; ASel = 0; BSel = 1; 
                ALUSel = 4'b0000; MemRead = 1; WBSel = 2'b01;      
            end

            // S-Type
            7'b0100011: begin
                RegWEn = 0; ImmSel = 3'b001; ASel = 0; BSel = 1; 
                ALUSel = 4'b0000; MemWrite = 1;       
            end

            // B-Type
            7'b1100011: begin
                RegWEn = 0; ImmSel = 3'b010; ASel = 1; BSel = 1; ALUSel = 4'b0000;   
                if (funct3 == 3'b110 || funct3 == 3'b111) BrUn = 1; // Unsigned compare
            end
            
            // J-Type jal
            7'b1101111: begin
                RegWEn = 1; ImmSel = 3'b100; ASel = 1; BSel = 1; ALUSel = 4'b0000; WBSel = 2'b10;      
            end

            // I-Type jalr
            7'b1100111: begin
                RegWEn = 1; ImmSel = 3'b000; ASel = 0; BSel = 1; ALUSel = 4'b0000; WBSel = 2'b10;
            end

            // U-Type lui
            7'b0110111: begin
                RegWEn = 1; ImmSel = 3'b011; ASel = 0; BSel = 1; ALUSel = 4'b0000; WBSel = 2'b00;      
            end

            // U-Type auipc
            7'b0010111: begin
                RegWEn = 1; ImmSel = 3'b011; ASel = 1; BSel = 1; ALUSel = 4'b0000; WBSel = 2'b00;
            end
        endcase
    end
endmodule