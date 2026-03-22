module regfile(
    input clk,
    input RegWEn, // write enable flag
    input [4:0] rs1,// source register1
    input [4:0] rs2,// source register2 
    input [4:0] rd,//destination register
    input [31:0] data_in, // data to write in rd
    output [31:0] data_out1, // data read from rs1
    output [31:0] data_out2  // data read from rs2
); 
    reg [31:0] registers [31:0]; //2d array of 32 registers(of 32bits)
    
    //Initialize all registers to 0
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'd0;
        end
    end
    // x0 hardwired to 0.
    // values in registers rs1 and rs2 (instantaneous)
    assign data_out1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign data_out2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

    // rd= data_in when RegWEn=1 && rd is not x0
    always @(posedge clk) begin
        if (RegWEn && (rd != 5'd0)) begin
            registers[rd] <= data_in;
        end
    end

endmodule