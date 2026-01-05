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
    
    logic signed [15:0] sample_shftreg_out [0:TAPS-1]; //wires from shift register
    logic signed [15:0] sample_shftreg_pipeline_reg [0:TAPS-1]; //pipeline registers for shift register
    logic signed [15:0] sample_shftreg_pipeline_out [0:TAPS-1]; //wires out of pipeline
    
    logic signed [31:0] multiplier_out[0:TAPS-1]; //wires out of multipler
    logic signed [31:0] multiplier_pipeline_reg [0:TAPS-1]; //pipeline registers
    logic signed [31:0] multiplier_pipeline_out [0:TAPS-1]; //wire out of pipeline
    
    logic accu_in_valid; //will remove
    logic accu_out_valid; //will remove
    
    logic signed [ACCUBITS-1:0] accu_out;
    logic signed [ACCUBITS-1:0] accu_pipeline_reg;
    logic signed [ACCUBITS-1:0] accu_pipeline_out;
    
    logic signed [15:0] satu_out;
    logic signed [15:0] satu_pipeline_reg;
    
    logic valid_bits [0:4];
    logic valid_bits_reg [0:4];
    
    initial begin //Weighting coefficents
        $readmemb("weighting.mem", in_weights);
    end
    
    shftreg_16bit #(.N(TAPS)) sample_shftreg (
      .clk(clk),
      .rst(rst),
      .in_valid(in_valid),
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
                  .in_valid(valid_bits[2]), 
                  .multiplier_out(multiplier_pipeline_out), 
                  .out(accu_out), 
                  .out_valid(accu_out_valid)
                  );
                  
    saturator #(.N(ACCUBITS)) satu (.A(accu_pipeline_out), .out(satu_out));
    
    always_ff @(posedge clk) begin
        if(valid_bits[1]) begin
            sample_shftreg_pipeline_reg <= sample_shftreg_out;
        end
        if(valid_bits[2]) begin
            multiplier_pipeline_reg <= multiplier_out;
        end
        if(valid_bits[3]) begin
            accu_pipeline_reg <= accu_out;
        end
        if(valid_bits[4]) begin
            satu_pipeline_reg <= satu_out;
        end
    end
    
    assign sample_shftreg_pipeline_out = sample_shftreg_pipeline_reg;
    assign multiplier_pipeline_out = multiplier_pipeline_reg;
    assign accu_pipeline_out = accu_pipeline_reg;
    assign out_sample = satu_pipeline_reg;
    
    generate //4 components in this program that need a valid bit
        for(i = 0; i < 5; i++) begin : GEN_VALIDARRAY
            always_ff @(posedge clk) begin
                valid_bits_reg[i] <= valid_bits[i];
            end
            
            if(i == 0) begin
                assign valid_bits[i] = in_valid;
            end
            else if(i == 3) begin
                assign valid_bits[i] = accu_out_valid;
            end
            else begin
                assign valid_bits[i] = valid_bits_reg[i - 1];
            end
        end
    endgenerate
    
    assign out_valid = valid_bits[3];

endmodule
