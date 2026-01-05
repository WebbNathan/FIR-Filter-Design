`timescale 1ns / 1ps

module accumulator #(
    parameter int TAPS = 401,
    parameter int MULTBITS = 32
)(
    clk,
    in_valid,
    multiplier_out,
    out,
    out_valid
);
    localparam int ACCUBITS = MULTBITS + $clog2(TAPS);
    localparam int P = 1 << $clog2(TAPS); //get closest power of 2 for binary tree
    localparam int LOGP = $clog2(P);
    
    input logic clk, in_valid;
    input logic signed [MULTBITS-1:0] multiplier_out [0:TAPS-1];
    
    output logic signed [ACCUBITS-1:0] out;
    output logic out_valid;
    
    logic signed [MULTBITS-1:0] padded_mult_out [0:P-1];
    logic signed [ACCUBITS-1:0] sum [1:P-1];
    logic signed [ACCUBITS-1:0] sum_reg [1:P-1];
    
    logic valid_carry [1:LOGP];
    logic valid_carry_reg [1:LOGP];

    //First generate is to pad the input array with 0 if it is not a multiple of 2
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
                assign sum[P - i - 1] = $signed(padded_mult_out[2 * i]) 
                                      + $signed(padded_mult_out[2 * i + 1]);
            end
            else begin
                assign sum[P - i - 1] = $signed(sum_reg[2 * (P - i - 1)]) 
                                        + $signed(sum_reg[2 * (P - i - 1)  + 1]);
            end
            
            always_ff @(posedge clk) begin
                if(i < (P >> 1) && in_valid) begin //making sure inputs valid
                    sum_reg[P - i - 1] = $signed(sum[P - i - 1]);
                end
                else if (!(i < (P >> 1)))begin
                    sum_reg[P - i - 1] = $signed(sum[P - i - 1]);
                end
            end
        end
    endgenerate
    
    generate
        for(i = 1; i < LOGP + 1; i++) begin : GEN_VALID_CARRY
            if(i == 1) begin
                assign valid_carry[i] = in_valid;
            end
            else begin
                assign valid_carry[i] = valid_carry_reg[i-1];
            end
            
            always_ff @(posedge clk) begin
                valid_carry_reg[i] = valid_carry[i];
            end
        end
    endgenerate
    
    assign out = $signed(sum_reg[1]);
    assign out_valid = valid_carry_reg[LOGP];
    
endmodule