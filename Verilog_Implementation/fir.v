`timescale 1ns / 1ps

module fir #(
    parameter integer TAPS = 401
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
    
    input wire clk, rst;
    input wire in_valid;
    input wire [15:0] in_sample;
    output reg out_ready, in_ready, out_valid;
    output reg [15:0] out_sample;



endmodule
