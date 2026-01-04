`timescale 1ns / 1ps

module accumulator #(
    parameter int TAPS = 401,
    parameter int MULTBITS = 32
)(
    clk,
    in_valid,
    multiplier_out,
    out,
);
    localparam int ACCUBITS  = MULTBITS + $clog2(TAPS);
    localparam int P = 1 << $clog2(TAPS); //get closest power of 2 for binary tree
    
    input logic clk, in_valid;
    input [MULTBITS-1:0] multiplier_out [0:TAPS-1];
    output [ACCUBITS-1:0] out;
    
    logic [MULTBITS-1:0] padded_mult_out [0:P-1];
    logic [ACCUBITS-1:0] sum [0:P-1];

    genvar i;
    generate
        for(i = 0; i < P; i++) begin : GEN_PAD
            if (i < TAPS) begin
                assign padded_mult_out[i] = {{(ACCUBITS-MULTBITS){multiplier_out[i][MULTBITS-1]}}, 
                                            multiplier_out[i]};
            end
            else begin
                assign padded_mult_out[i] = '0; 
            end
        end
    endgenerate
    
    generate
        for(i = 0; i < P - 1; i++) begin : GEN_SUM
            if(i < (P >> 1)) begin
                assign sum[P - i - 1] = padded_mult_out[2 * i] + padded_mult_out[2 * i + 1];
            end
            else begin
                assign sum[P - i - 1] = sum[2 * (P - i - 1)] + sum[2 * (P - i - 1)  + 1];
            end
        end
    endgenerate
    
    assign out = sum[0];
    
endmodule