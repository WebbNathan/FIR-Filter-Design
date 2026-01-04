`timescale 1ns / 1ps

module NBitAdder #(
    parameter N  = 1
)(
    A,
    B,
    out 
);

    input logic signed [N-1:0] A, B;
    output logic signed [N-1:0] out;
    
    assign out = $signed(A) + $signed(B);

endmodule