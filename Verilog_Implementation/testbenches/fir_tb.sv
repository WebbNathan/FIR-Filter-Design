`timescale 1ns / 1ps

module fir_tb();

    localparam int TAPS = 10;
    localparam int MULTBITS = 32;
    
    logic clk, rst, in_valid, out_valid;
    logic [15:0] in_sample, out_sample;

    fir #(.TAPS(TAPS), .MULTBITS(32)) fir_tb (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_sample(in_sample),
        .out_valid(out_valid),
        .out_sample(out_sample)
    );
    
    always begin
        clk <= 0;
        #10;
        clk <= 1;
        #10;
    end
    
    initial begin
        rst <= 1;
        #10;
        rst <= 0;
        #10;
    
        in_sample <= 16'sd1;
        #10;
        in_valid = 1;

    end 

endmodule