`timescale 1ns / 1ps

module fir #(
    parameter int TAPS = 201,
    parameter int MULTBITS = 32
)(
    clk,
    rst,
    in_valid, //ensure input is a valid value
    in_sample,
    out_valid, //current ouput is valid
    out_sample,
);

    localparam int ACCUBITS = MULTBITS + $clog2(TAPS);
    
    input logic clk, rst;
    input logic in_valid;
    input logic signed [15:0] in_sample;
    output logic out_valid;
    output logic signed [15:0] out_sample;
    
    logic [15:0] in_weights [0 : TAPS - 1];
    
    //Packed outputs
    logic signed [16 * TAPS - 1 : 0] shft_out_packed;
    logic signed [MULTBITS * TAPS - 1 : 0] mult_out_packed;
    logic signed [16 * TAPS - 1 : 0] shft_reg_pipeline_out_packed;
    logic signed [MULTBITS * TAPS - 1 : 0] multiplier_pipeline_out_packed;
    
    logic signed [15:0] shft_reg_in;
    logic signed [15:0] sample_shftreg_out [0:TAPS-1]; //wires from shift register
    logic signed [15:0] sample_shftreg_pipeline_out [0:TAPS-1]; //wires out of pipeline
    logic shft_reg_out_valid;
    
    logic signed [31:0] multiplier_out[0:TAPS-1]; //wires out of multipler
    logic signed [31:0] multiplier_pipeline_out [0:TAPS-1]; //wire out of pipeline
    
    logic accu_in_valid; //will remove
    logic accu_out_valid; //will remove
    
    logic signed [ACCUBITS-1:0] accu_out;
    logic signed [ACCUBITS-1:0] accu_pipeline_out;
    
    logic signed [15:0] satu_out;
    
    logic input_pipeline_valid;
    logic sample_shft_pipeline_valid;
    logic multiplier_pipeline_valid;
    logic accu_pipeline_valid;
    
    initial begin //Weighting coefficents
        $readmemb("weighting.mem", in_weights);
    end
    
    shftreg_16bit #(.N(TAPS)) sample_shftreg (
      .clk(clk),
      .rst(rst),
      .in_valid(input_pipeline_valid),
      .out_valid(shft_reg_out_valid),
      .data_in (shft_reg_in),
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
                  .in_valid(multiplier_pipeline_valid), 
                  .multiplier_out(multiplier_pipeline_out), 
                  .out(accu_out), 
                  .out_valid(accu_out_valid)
                  );
                  
    saturator #(.N(ACCUBITS)) satu (.A(accu_pipeline_out), .out(satu_out));
    
    //Pipelining
    pipeline #(.DATA_WIDTH(16), .DATA_COUNT(1)) input_pipeline_reg (
        .clk(clk),
        .rst(rst),
        .data_in(in_sample),
        .valid_in(in_valid),
        .data_out(shft_reg_in),
        .valid_out(input_pipeline_valid)
        );
        
    pipeline #(.DATA_WIDTH(16), .DATA_COUNT(TAPS)) shft_reg_pipeline_reg (
        .clk(clk),
        .rst(rst),
        .data_in(shft_out_packed),
        .valid_in(shft_reg_out_valid),
        .data_out(shft_reg_pipeline_out_packed),
        .valid_out(sample_shft_pipeline_valid)
        );
        
     pipeline #(.DATA_WIDTH(32), .DATA_COUNT(TAPS)) mult_pipeline_reg (
        .clk(clk),
        .rst(rst),
        .data_in(mult_out_packed),
        .valid_in(sample_shft_pipeline_valid),
        .data_out(multiplier_pipeline_out_packed),
        .valid_out(multiplier_pipeline_valid)
        );
        
     pipeline #(.DATA_WIDTH(ACCUBITS), .DATA_COUNT(1)) accu_pipeline_reg (
        .clk(clk),
        .rst(rst),
        .data_in(accu_out),
        .valid_in(accu_out_valid),
        .data_out(accu_pipeline_out),
        .valid_out(accu_pipeline_valid)
     );
     
     pipeline #(.DATA_WIDTH(16), .DATA_COUNT(1)) satu_pipeline_reg (
        .clk(clk),
        .rst(rst),
        .data_in(satu_out),
        .valid_in(accu_pipeline_valid),
        .data_out(out_sample),
        .valid_out(out_valid)
     );
     
     //Packing
     generate
        for(i = 0; i < TAPS; i++) begin : GEN_PACKED
            assign shft_out_packed[16 * i +: 16] = sample_shftreg_out[i];
            assign mult_out_packed [MULTBITS * i +: MULTBITS] = multiplier_out[i];
        end
     endgenerate
     
     //Unpacking
     generate
        for(i = 0; i < TAPS; i++) begin : GEN_UNPACKED
            assign sample_shftreg_pipeline_out[i] = shft_reg_pipeline_out_packed [16 * i +: 16];
            assign multiplier_pipeline_out[i] = multiplier_pipeline_out_packed [MULTBITS * i +: MULTBITS];
        end
     endgenerate

endmodule
