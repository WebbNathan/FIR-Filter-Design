`timescale 1ns / 1ps

module fir_tb();

    localparam int INPUT_SIZE = 240000;

    localparam int TAPS = 101;
    localparam int MULTBITS = 32;
    
    logic clk, rst, in_valid, out_valid;
    logic [15:0] input_sample_arr [0 : INPUT_SIZE - 1];
    logic [15:0] in_sample, out_sample;
    
    integer outfile;
    integer i = 0;

    initial begin
        outfile = $fopen("output.mem","w");
        if (outfile == 0) $fatal("Could not open output.mem");
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
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            i         <= 0;
            in_valid  <= 0;
            in_sample <= '0;
        end
        else begin
            if (i < INPUT_SIZE + TAPS - 1) begin
                if (i < INPUT_SIZE) begin
                    in_sample <= input_sample_arr[i];
                    in_valid  <= 1;
                end
                else begin
                    in_sample <= '0;
                    in_valid  <= 1;   // flush filter
                end
                i <= i + 1;
            end
            else begin
                in_valid <= 0;
                $fclose(outfile);
                $display("Simulation done: %0d samples sent", i);
                $finish;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (out_valid) begin
            $fwrite(outfile, "%016b\n", out_sample[15:0]);
            $fflush(outfile);
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
        #15;
        rst <= 0;
       
    end 

endmodule