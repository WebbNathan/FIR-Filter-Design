`timescale 1ns / 1ps

module pipeline #(
    parameter int DATA_WIDTH,
    parameter int DATA_COUNT
) (
    clk,
    rst,
    data_in,
    valid_in,
    data_out,
    valid_out
);

    input logic clk, rst;
    input  logic [DATA_WIDTH*DATA_COUNT-1:0] data_in;
    input  logic valid_in;
    output logic [DATA_WIDTH*DATA_COUNT-1:0] data_out;
    output logic valid_out;
    
    
    always_ff@(posedge clk or posedge rst) begin
        if(rst) begin
            valid_out <= '0;
            data_out <= 1'b0;
        end
        else if(valid_in)begin
            data_out <= data_in;
        end
        valid_out <= valid_in;
    end

endmodule