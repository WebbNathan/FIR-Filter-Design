`timescale 1ns / 1ps

module fir #(
    parameter int TAPS = 401,
    parameter int MULTBITS = 32
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

    localparam int ACCUBITS = MULTBITS + $clog2(TAPS);
    
    input logic clk, rst;
    input logic in_valid;
    input logic [15:0] in_sample;
    input logic [15:0] in_weights [0 : TAPS - 1];
    output logic out_ready, in_ready, out_valid;
    output logic [15:0] out_sample;
    
    logic [15:0] sample_shftreg_out [0:TAPS-1]; //wires from shift register
    logic [15:0] sample_shftreg_pipeline_reg [0:TAPS-1]; //pipeline registers for shift register
    logic [15:0] sample_shftreg_pipeline_out [0:TAPS-1]; //wires out of pipeline
    
    logic [32:0] multiplier_out[0:TAPS-1]; //wires out of multipler
    logic [32:0] multiplier_pipeline_reg [0:TAPS-1]; //pipeline registers
    logic [32:0] multiplier_pipeline_out [0:TAPS-1]; //wire out of pipeline
    
    logic accu_in_valid;
    logic accu_out_valid;
    logic [ACCUBITS-1:0] accu_out;

    shftreg_16bit #(.N(TAPS)) sample_shftreg (
      .clk(clk),
      .rst(rst),
      .data_in (in_sample),
      .data_out(sample_shftreg_out)
    );
    
    genvar i;
    generate
      for(i = 0; i < TAPS; i++) begin : GEN_BLOCK
        multiplier_16bit mult (
          .A(sample_shftreg_pipeline_out[i]),
          .B(in_weights[i]),
          .out(multiplier_out[i])
        );
      end
    endgenerate   
    
    accumulator #(.TAPS(TAPS), .MULTBITS(MULTBITS)) accu 
                  (
                  .clk(clk), 
                  .in_valid(accu_in_valid), 
                  .multiplier_out(multiplier_pipeline_out), 
                  .out(accu_out), 
                  .out_valid(accu_out_valid)
                  );
    
    always_ff @(posedge clk) begin
        sample_shftreg_pipeline_reg <= sample_shftreg_out;
        multiplier_pipeline_reg <= multiplier_out;
    end
    
    assign multiplier_pipeline_out = multiplier_pipeline_reg;
    assign sample_shftreg_pipeline_out = sample_shftreg_pipeline_reg;

endmodule
