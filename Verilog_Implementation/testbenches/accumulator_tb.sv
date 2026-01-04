`timescale 1ns / 1ps

module accumulator_tb();

    localparam MULTBITS = 32;
    localparam TAPS = 33;
    localparam int ACCUBITS  = MULTBITS + $clog2(TAPS);

    logic clk, in_valid;
    logic [MULTBITS-1:0] mult_out [0:TAPS-1];
    logic [ACCUBITS-1:0] out;

    accumulator #(.TAPS(TAPS), .MULTBITS(MULTBITS)) accu_tb(
        .clk(clk),
        .in_valid(in_valid),
        .multiplier_out(mult_out),
        .out(out)
    );
    
    always begin
        clk <= 0;
        #10;
        clk <= 1;
        #10;
    end
    
    initial begin
       for(int i = 0; i < TAPS; i++) begin
            mult_out[i] = i;
       end
       
       in_valid <= 1;
       #15
       in_valid <=0;
    end

endmodule