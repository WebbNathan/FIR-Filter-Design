`timescale 1ns / 1ps

module fir #(
    parameter int TAPS = 401
)(
    clk,
    rst,
    in_valid, //ensure input is a valid value
    in_sample,
    out_ready, //ensure high levels ready for an output
    in_ready, //module ready for new input
    out_valid, //current ouput is valid
    out_sample,
);
    
    input logic clk, rst;
    input logic in_valid;
    input logic [15:0] in_sample;
    output logic out_ready, in_ready, out_valid;
    output logic [15:0] out_sample;

    shftreg_16bit #(.N(TAPS)) sample_shftreg (
      .clk(clk),
      .rst(rst),
      .data_in (in_sample),
      .data_out(sample_shftreg_out)
    );

endmodule
