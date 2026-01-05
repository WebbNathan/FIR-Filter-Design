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
    out_valid, //current ouput is valid
    out_sample,
);

    localparam int ACCUBITS = MULTBITS + $clog2(TAPS);
    
    input logic clk, rst;
    input logic in_valid;
    input logic [15:0] in_sample;
    input logic [15:0] in_weights [0 : TAPS - 1];
    output logic out_valid;
    output logic [15:0] out_sample;
    
    logic [15:0] sample_shftreg_out [0:TAPS-1]; //wires from shift register
    logic [15:0] sample_shftreg_pipeline_reg [0:TAPS-1]; //pipeline registers for shift register
    logic [15:0] sample_shftreg_pipeline_out [0:TAPS-1]; //wires out of pipeline
    
    logic [32:0] multiplier_out[0:TAPS-1]; //wires out of multipler
    logic [32:0] multiplier_pipeline_reg [0:TAPS-1]; //pipeline registers
    logic [32:0] multiplier_pipeline_out [0:TAPS-1]; //wire out of pipeline
    
    logic accu_in_valid; //will remove
    logic accu_out_valid; //will remove
    
    logic [ACCUBITS-1:0] accu_out;
    logic [ACCUBITS-1:0] accu_pipeline_reg;
    logic [ACCUBITS-1:0] accu_pipeline_out;
    
    logic valid_bits [0:3];
    logic valid_bits_reg [0:3];

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
                  
    saturator #(.N(ACCUBITS)) satu (.A(accu_pipeline_out), .out(out_sample));
    
    always_ff @(posedge clk) begin
        sample_shftreg_pipeline_reg <= sample_shftreg_out;
        multiplier_pipeline_reg <= multiplier_out;
        accu_pipeline_reg <= accu_out;
    end
    
    assign sample_shftreg_pipeline_out = sample_shftreg_pipeline_reg;
    assign multiplier_pipeline_out = multiplier_pipeline_reg;
    assign accu_pipeline_out = accu_pipeline_reg;
    
    generate //4 components in this program that need a valid bit
        for(i = 0; i < 4; i++) begin : GEN_VALIDARRAY
            always_ff @(posedge clk) begin
                valid_bits_reg[i] <= valid_bits[i];
            end
            
            if(i == 0) begin
                assign valid_bits[i] = in_valid;
            end
            if(i == 2) begin
                assign valid_bits[i] = accu_out_valid;
            end
            else begin
                assign valid_bits[i] = valid_bits_reg[i - 1];
            end
        end
    endgenerate
    
    assign out_valid = valid_bits[3];

endmodule
