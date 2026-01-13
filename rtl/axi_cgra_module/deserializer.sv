// Copyright 2024 CEI-UPM
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Daniel Vazquez (daniel.vazquez@upm.es)

// Note: Used as a configuration word destination register. Once a full
// word is loaded into this shift register, it can be loaded in one of
// the CGRA's PEs.

module deserializer #(
    parameter int DATA_WIDTH = 32
) (
    // Clock and reset
    input  logic         clk_i,
    input  logic         rst_ni,
    // Input data and control
    input  logic [DATA_WIDTH-1:0] data_i,
    input  logic         enable_i,
    // Output data
    output logic [159:0] kernel_config_o
);

  generate
  	if (DATA_WIDTH == 32) begin
      deserializer32 d32 (.clk_i(clk_i), .rst_ni(rst_ni), .data_i(data_i), .enable_i(enable_i), .kernel_config_o(kernel_config_o));
    end else if (DATA_WIDTH == 64) begin
      deserializer64 d64 (.clk_i(clk_i), .rst_ni(rst_ni), .data_i(data_i), .enable_i(enable_i), .kernel_config_o(kernel_config_o));
    end else begin
        assign kernel_config_o = '0;
    end
  endgenerate
endmodule

module deserializer32 (
    // Clock and reset
    input  logic         clk_i,
    input  logic         rst_ni,
    // Input data and control
    input  logic [31:0] data_i,
    input  logic         enable_i,
    // Output data
    output logic [159:0] kernel_config_o
);

  logic [4:0][31:0] registers;
  logic [2:0] counter;

  // Counter and output
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      counter <= '0;
    end else if (enable_i) begin
      if (counter == 4) begin
        counter <= '0;
      end else begin
        counter <= counter + 1;
      end
    end
  end

  // Shift registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      registers <= '{default: '0};
    end else if (enable_i) begin
      registers[4] <= data_i;
      registers[3] <= registers[4];
      registers[2] <= registers[3];
      registers[1] <= registers[2];
      registers[0] <= registers[1];
    end
  end

  assign kernel_config_o = (counter == 0) ? {registers} : '0;

endmodule

module deserializer64 (
    // Clock and reset
    input  logic         clk_i,
    input  logic         rst_ni,
    // Input data and control
    input  logic [63:0] data_i,
    input  logic         enable_i,
    // Output data
    output logic [159:0] kernel_config_o
);

  logic [2:0][63:0] registers;
  logic [2:0] counter;

  // Counter and output control
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      counter <= '0;
    end else if (enable_i) begin
      if (counter == 4) begin
        counter <= '0;
      end else begin
        counter <= counter + 1;
      end
    end
  end

  // Shift registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      registers <= '{default: '0};
    end else if (enable_i) begin
      registers[2] <= data_i;
      registers[1] <= registers[2];
      registers[0] <= registers[1];
    end
  end

  assign kernel_config_o = (counter == 3) ? { registers[2][31:0], registers[1], registers[0] } : (counter == 0) ? { registers[2], registers[1], registers[0][63:32] } : '0;

endmodule