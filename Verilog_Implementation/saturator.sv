`timescale 1ns / 1ps

module saturator #(
    parameter N = 32
)(
    A,
    out
);

    localparam signed [15:0] MAX = 16'sd32767;
    localparam signed [15:0] MIN = 16'sh8000;
    
    localparam signed [N-1:0] MAX_EX = {{(N-16){1'b0}}, MAX[15:0]};
    localparam signed [N-1:0] MIN_EX = {{(N-16){1'b1}}, MIN[15:0]};

    input logic signed [N-1:0] A;
    output logic signed [15:0] out;
    
    assign out = A > MAX_EX ? MAX :
                 A < MIN_EX ? MIN :
                 $signed(A[15:0]);
    
endmodule