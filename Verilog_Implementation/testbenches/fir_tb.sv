`timescale 1ns / 1ps

module fir_tb();

    localparam int INPUT_SIZE = 4;

    localparam int TAPS = 4;
    localparam int MULTBITS = 32;
    
    logic clk, rst, in_valid, out_valid;
    logic [15:0] input_sample_arr [0 : INPUT_SIZE - 1];
    logic [15:0] in_sample, out_sample;
    
    integer outfile;
    integer i = 0;

    initial begin
        outfile = $fopen("output.mem", "w");
        if (outfile == 0) begin
            $display("ERROR: Could not open output file");
            $finish;
        end
    end
    
    initial begin
        $readmemb("input.mem", input_sample_arr);
    end

    fir #(.TAPS(TAPS), .MULTBITS(32)) fir_tb (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_sample(in_sample),
        .out_valid(out_valid),
        .out_sample(out_sample)
    );
    
    always_ff @(posedge clk) begin
        if(!(i == INPUT_SIZE)) begin
            in_sample = input_sample_arr[i];
            in_valid = 1;
            i = i + 1;
        end
        else begin
            in_valid <= 0;
        end
        
        if (out_valid) begin
            $fwrite(outfile, "%016b\n", out_sample[15:0]);
        end
    end
    
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
    end 

endmodule