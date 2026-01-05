`timescale 1ns / 1ps

module shftreg_16bit #(
    parameter int N = 8
)(
    clk,
    rst,
    in_valid,
    data_in,
    data_out     
);

    input logic clk, rst, in_valid;
    input logic [15:0] data_in;
    output logic [15:0] data_out [0:N -1];
    
    logic [15:0] registers [0:N-1];
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for (integer i = 0; i < N; i = i + 1) begin
                registers[i] <= 16'b0;
            end
        end
        
        else begin
           if(in_valid) begin
               for(integer i = 0; i < N - 1; i = i + 1) begin
                    registers[i + 1] <= registers[i];
               end
               registers[0] <= data_in;
           end
        end
    end
    
    genvar i;
    for(i = 0; i < N; i = i + 1) begin
        assign data_out[i] = registers[i]; 
    end
endmodule
