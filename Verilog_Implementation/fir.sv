`timescale 1ns / 1ps

module fir #(
    parameter int TAPS = 401
)(
    clk,
    rst,
    in_valid, //ensure input is a valid value
    in_sample,
    in_weights,
    out_ready, //ensure high levels ready for an output
    in_ready, //module ready for new input
    out_valid, //current ouput is valid
    out_sample,
);
    
    input logic clk, rst;
    input logic in_valid;
    input logic [15:0] in_sample;
    input logic [15:0] in_weights [0 : TAPS - 1];
    output logic out_ready, in_ready, out_valid;
    output logic [15:0] out_sample;
    
    logic [15:0] sample_shftreg_out [0:TAPS-1];

    shftreg_16bit #(.N(TAPS)) sample_shftreg (
      .clk(clk),
      .rst(rst),
      .data_in (in_sample),
      .data_out(sample_shftreg_out)
    );
    
    genvar i;
    generate
      for (i = 0; i < TAPS; i = i + 1) begin : GEN_BLOCK
        multiplier_16bit mult (
          .A(sample_shftreg_out[i]),
          .B(in_weights[i]),
          .out()
        );
      end
    endgenerate
    

endmodule
