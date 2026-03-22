module branch_comp(
    input [31:0] A, 
    input [31:0] B,
    input BrUn, // 1 for Unsigned comparison,0 for Signed comparison
    output BrEq, // 1 if A==B
    output BrLT // 1 if A<B
);

    // Equality 
    assign BrEq = (A == B);

    // Branch less than (unsigned and signed)
    assign BrLT = (BrUn) ? (A < B) : ($signed(A) < $signed(B));

endmodule