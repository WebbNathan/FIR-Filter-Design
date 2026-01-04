`timescale 1ns / 1ps

module multiplier_16bit(
    A,
    B,
    out
);

    input logic signed [15:0] A, B;
    output logic signed [31:0] out;
    
    assign out = $signed(A) * $signed(B); 
endmodule