module alu(
    input [31:0] A,
    input [31:0] B,
    input [3:0] ALUSel,
    output reg [31:0] Result
);
    always @(*) begin
        case(ALUSel)
            4'b0000: Result = A + B; //add
            4'b0001: Result = A - B; //sub
            4'b0010: Result = A & B; //and
            4'b0011: Result = A | B; //or
            4'b0100: Result = A ^ B; //xor
            4'b0101: Result = A << B[4:0]; //sll
            4'b0110: Result = A >> B[4:0];  //srl
            4'b0111: Result = $signed(A) >>> B[4:0]; //sra
            4'b1000: Result = ($signed(A) < $signed(B)) ? 1 : 0;// slt
            4'b1001: Result = (A < B) ? 1 : 0; // sltu
            default: Result = 32'd0; //Default 0
        endcase
    end
endmodule