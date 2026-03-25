// Module for CGRA integration in the target platform
//
// Interfaces:
// - AXI Master port for DMA, AXI Slave port for configuration
// - Clock and Reset
//
// Includes:
// - Strela CGRA
// - Custom DMA Interface
// - Control-Status Registers
// - Miscelaneous protocol adapters

`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

module axi_cgra_top #(
    parameter int unsigned AXI_ID_WIDTH_MASTER = -1,
    parameter int unsigned AXI_ADDR_WIDTH      = -1,
    parameter int unsigned AXI_DATA_WIDTH      = -1,
    parameter int unsigned AXI_USER_WIDTH      = -1
) (
    input logic clk_i,
    input logic rst_ni,
    output logic axi_awvalid,
    input logic axi_awready,
    output logic [AXI_ID_WIDTH_MASTER-1:0] axi_awid,
    output logic [7:0] axi_awlen,
    output logic [AXI_ADDR_WIDTH-1:0] axi_awaddr,
    output logic axi_wvalid,
    input logic axi_wready,
    output logic [AXI_DATA_WIDTH-1:0] axi_wdata,
    output logic [AXI_DATA_WIDTH/8-1:0] axi_wstrb,
    output logic axi_wlast,
    output logic axi_arvalid,
    input logic axi_arready,
    output logic [AXI_ID_WIDTH_MASTER-1:0] axi_arid,
    output logic [7:0] axi_arlen,
    output logic [AXI_ADDR_WIDTH-1:0] axi_araddr,
    input logic [1:0] axi_bresp,
    input logic axi_bvalid,
    output logic axi_bready,
    input logic [AXI_ID_WIDTH_MASTER-1:0] axi_bid,
    input logic axi_rvalid,
    output logic axi_rready,
    input logic [AXI_ID_WIDTH_MASTER-1:0] axi_rid,
    input logic axi_rlast,
    input logic [AXI_DATA_WIDTH-1:0] axi_rdata,
    input logic [1:0] axi_rresp,
    output logic [2:0] axi_awsize,
    output logic [2:0] axi_arsize,
    output logic [1:0] axi_awburst,
    output logic [1:0] axi_arburst,
    output logic axi_awlock,
    output logic axi_arlock,
    output logic [3:0] axi_awcache,
    output logic [3:0] axi_arcache,
    output logic [2:0] axi_awprot,
    output logic [2:0] axi_arprot,
    output logic [3:0] axi_awqos,
    output logic [5:0] axi_awatop,
    output logic [3:0] axi_awregion,
    output logic [3:0] axi_arqos,
    output logic [3:0] axi_arregion,
    output logic [AXI_USER_WIDTH-1:0] axi_awuser,
    output logic [AXI_USER_WIDTH-1:0] axi_wuser,
    output logic [AXI_USER_WIDTH-1:0] axi_aruser,
    input logic [AXI_USER_WIDTH-1:0] axi_buser,
    input logic [AXI_USER_WIDTH-1:0] axi_ruser,
    input logic apb_reg_bus_penable,
    input logic apb_reg_bus_pwrite,
    input logic [31:0] apb_reg_bus_paddr,
    input logic apb_reg_bus_psel,
    input logic [31:0] apb_reg_bus_pwdata,
    output logic [31:0] apb_reg_bus_prdata,
    output logic apb_reg_bus_pready,
    output logic apb_reg_bus_pslverr,
    output logic[1:0]  int_lines, // two - one to signal exec done index [1], other to signal config loading done index [0]
    output logic int_line_shared // shared IRQ, combined int_lines from above, ok to be shared since config and exec operations should be executed sequentially
);

  localparam INPUT_NODES_NUM = 4;
  localparam OUTPUT_NODES_NUM = 4;

  // define types regbus_req_t, regbus_rsp_t
  `REG_BUS_TYPEDEF_ALL(regbus, logic[31:0], logic[31:0], logic[3:0])
  regbus_req_t regbus_req;
  regbus_rsp_t regbus_rsp;

  AXI_BUS #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH_MASTER),
      .AXI_USER_WIDTH(AXI_USER_WIDTH)
  ) aux_axi_master ();

  //    AW
  assign axi_awid         = aux_axi_master.aw_id;
  assign axi_awaddr       = aux_axi_master.aw_addr;
  assign axi_awlen        = aux_axi_master.aw_len;
  assign axi_awsize       = aux_axi_master.aw_size;
  assign axi_awburst      = aux_axi_master.aw_burst;
  assign axi_awlock       = aux_axi_master.aw_lock;
  assign axi_awcache      = aux_axi_master.aw_cache;
  assign axi_awprot       = aux_axi_master.aw_prot;
  assign axi_awqos        = aux_axi_master.aw_qos;
  assign axi_awatop       = aux_axi_master.aw_atop;
  assign axi_awregion     = aux_axi_master.aw_region;
  assign axi_awvalid      = aux_axi_master.aw_valid;
  assign axi_awuser       = aux_axi_master.aw_user;

  assign aux_axi_master.aw_ready = axi_awready;
  //    W
  assign axi_wdata        = aux_axi_master.w_data;
  assign axi_wstrb        = aux_axi_master.w_strb;
  assign axi_wlast        = aux_axi_master.w_last;
  assign axi_wvalid       = aux_axi_master.w_valid;
  assign axi_wuser       = aux_axi_master.w_user;
  assign aux_axi_master.w_ready  = axi_wready;
  //    B
  assign aux_axi_master.b_id     = axi_bid;
  assign aux_axi_master.b_resp   = axi_bresp;
  assign aux_axi_master.b_valid  = axi_bvalid;
  assign aux_axi_master.b_user  = axi_buser;
  assign axi_bready       = aux_axi_master.b_ready;

  //    AR
  assign axi_arid         = aux_axi_master.ar_id;
  assign axi_araddr       = aux_axi_master.ar_addr;
  assign axi_arlen        = aux_axi_master.ar_len;
  assign axi_arsize       = aux_axi_master.ar_size;
  assign axi_arburst      = aux_axi_master.ar_burst;
  assign axi_arlock       = aux_axi_master.ar_lock;
  assign axi_arcache      = aux_axi_master.ar_cache;
  assign axi_arprot       = aux_axi_master.ar_prot;
  assign axi_arqos        = aux_axi_master.ar_qos;
  assign axi_arregion     = aux_axi_master.ar_region;
  assign axi_arvalid      = aux_axi_master.ar_valid;
  assign axi_aruser       = aux_axi_master.ar_user;
  assign aux_axi_master.ar_ready = axi_arready;
  //    R
  assign aux_axi_master.r_id     = axi_rid;
  assign aux_axi_master.r_data   = axi_rdata;
  assign aux_axi_master.r_resp   = axi_rresp;
  assign aux_axi_master.r_last   = axi_rlast;
  assign aux_axi_master.r_valid  = axi_rvalid;
  assign aux_axi_master.r_user = axi_ruser;
  assign axi_rready       = aux_axi_master.r_ready;

  AXI_LITE #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) axi_lite_bus ();

  apb_to_reg_adapter #(
      .regbus_req_t(regbus_req_t),
      .regbus_rsp_t(regbus_rsp_t)
  ) i_apb_to_reg_adapter (
      .clk_i       (clk_i),
      .rst_ni      (rst_ni),
      .apb_penable (apb_reg_bus_penable),
      .apb_pwrite  (apb_reg_bus_pwrite),
      .apb_paddr   (apb_reg_bus_paddr),
      .apb_psel    (apb_reg_bus_psel),
      .apb_pwdata  (apb_reg_bus_pwdata),
      .apb_prdata  (apb_reg_bus_prdata),
      .apb_pready  (apb_reg_bus_pready),
      .apb_pslverr (apb_reg_bus_pslverr),
      .regbus_req_o(regbus_req),
      .regbus_rsp_i(regbus_rsp)
  );

  axi_lite_to_axi_intf #(
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) i_axi_lite_to_axi_adapter (
      .in            (axi_lite_bus),
      .slv_aw_cache_i('0),
      .slv_ar_cache_i('0),
      .out           (aux_axi_master)
  );

  logic [31:0] data_input_addr  [ INPUT_NODES_NUM-1:0];
  logic [15:0] data_input_size  [ INPUT_NODES_NUM-1:0];
  logic [15:0] data_input_stride[ INPUT_NODES_NUM-1:0];

  logic [31:0] data_config_addr;
  logic [15:0] data_config_size;

  logic [31:0] data_output_addr [OUTPUT_NODES_NUM-1:0];
  logic [15:0] data_output_size [OUTPUT_NODES_NUM-1:0];
  logic done_exec, done_config;
  logic csr_execute_input_output;
  logic csr_load_config;

  logic reset_state_machines;
  logic [31:0] test_cycle_count;

  logic clear_cgra_config, clear_cgra_state;

  logic output_arbiter_hold;

  logic [1:0] clear_interrupt_lines;
  logic [1:0] interrupt_lines;
  logic interrupt_line_shared;

  logic [31:0] cycle_count_load_config, cycle_count_execute, cycle_count_stall;

  dma_config_csr #(
      .reg_req_t(regbus_req_t),
      .reg_rsp_t(regbus_rsp_t)
  ) i_dma_config_csr (
      .clk_i    (clk_i),
      .rst_ni   (rst_ni),
      .reg_req_i(regbus_req),
      .reg_rsp_o(regbus_rsp),

      .data_input_addr_o  (data_input_addr),
      .data_input_size_o  (data_input_size),
      .data_input_stride_o(data_input_stride),
      .data_config_addr_o (data_config_addr),
      .data_config_size_o (data_config_size),
      .data_output_addr_o (data_output_addr),
      .data_output_size_o (data_output_size),

      .done_exec_output_i  (done_exec),
      .done_config_i       (done_config),
      .start_execution_o   (csr_execute_input_output),
      .load_configuration_o(csr_load_config),

      // Performance counters
      .cycle_count_load_config_i(cycle_count_load_config),
      .cycle_count_execute_i    (cycle_count_execute),
      .cycle_count_stall_i      (cycle_count_stall),

      .clear_cgra_config_o(clear_cgra_config),
      .clear_cgra_state_o (clear_cgra_state),

      .reset_state_machines_o (reset_state_machines),
      .output_arbiter_hold_o  (output_arbiter_hold),
      .clear_interrupt_lines_o(clear_interrupt_lines),
      .pending_interrupts_i   (interrupt_lines)
  );


  logic control_execute_config, control_execute_input, control_execute_output;
  logic counters_read_stall, counters_write_stall;

  control_unit i_control_unit (
      // Clock and reset
      .clk_i (clk_i),
      .rst_ni(rst_ni),

      // From CSR
      .start_execution_i(csr_execute_input_output),
      .load_configuration_i(csr_load_config),

      // Control signals
      .execute_config_o(control_execute_config),
      .execute_input_o (control_execute_input),
      .execute_output_o(control_execute_output),

      // Input signals
      .data_config_done_i(done_config),
      .data_output_done_i(done_exec),

      .data_read_stall_i (counters_read_stall),
      .data_write_stall_i(counters_write_stall),

      // Performance counters
      .cycle_count_load_config_o(cycle_count_load_config),
      .cycle_count_execute_o    (cycle_count_execute),
      .cycle_count_stall_o      (cycle_count_stall)

  );

  logic [AXI_DATA_WIDTH*INPUT_NODES_NUM-1:0] cgra_data_input_data;
  logic [INPUT_NODES_NUM-1:0] cgra_data_input_valid;
  logic [INPUT_NODES_NUM-1:0] cgra_data_input_ready;

  logic [AXI_DATA_WIDTH*OUTPUT_NODES_NUM-1:0] cgra_data_output_data;
  logic [OUTPUT_NODES_NUM-1:0] cgra_data_output_valid;
  logic [OUTPUT_NODES_NUM-1:0] cgra_data_output_ready;

  logic [3:0] config_enable;

  dma_interface #(
    .DATA_WIDTH(AXI_DATA_WIDTH)
  ) i_dma_interface (
      .clk_i(clk_i),
      .rst_ni(!(!rst_ni | reset_state_machines)),
      .axi_master_port(axi_lite_bus),

      // Execute
      .execute_input_i (control_execute_input),
      .execute_output_i(control_execute_output),
      .execute_config_i(control_execute_config),

      // CGRA input data signals
      .data_input_o       (cgra_data_input_data),
      .data_input_valid_o (cgra_data_input_valid),
      .data_input_ready_i (cgra_data_input_ready),
      .data_input_addr_i  (data_input_addr),
      .data_input_size_i  (data_input_size),
      .data_input_stride_i(data_input_stride),

      // CGRA config data signals
      .data_config_addr_i  (data_config_addr),
      .data_config_size_i  (data_config_size),
      .data_config_done_o  (done_config),

      // CGRA output data signals
      .data_output_i        (cgra_data_output_data),
      .data_output_valid_i  (cgra_data_output_valid),
      .data_output_ready_o  (cgra_data_output_ready),
      .data_output_addr_i   (data_output_addr),
      .data_output_size_i   (data_output_size),
      .data_output_done_o   (done_exec),
      .output_arbiter_hold_i(output_arbiter_hold),

      .output_config_enable (config_enable),

      // For stall cycle calculation
      .input_outst_fifo_full_o (counters_read_stall),
      .output_outst_fifo_full_o(counters_write_stall)
  );

  cgra #(
      .DATA_WIDTH(AXI_DATA_WIDTH)
  ) cgra_i (
      .clk_i             (clk_i),
      .rst_ni            (rst_ni),   // Reset internal state
      .clr_i             (clear_cgra_state),
      .din_i           (cgra_data_input_data),
      .din_v_i     (cgra_data_input_valid),
      .din_r_o     (cgra_data_input_ready),
      .dout_o          (cgra_data_output_data),
      .dout_v_o    (cgra_data_output_valid),
      .dout_r_i    (cgra_data_output_ready),
      .conf_en_i         (config_enable)
  );

  interrupt_controller int_ctrl_conf (
      .clk_i          (clk_i),
      .rst_ni         (!(!rst_ni | clear_interrupt_lines[0])),
      .event_started_i(csr_load_config),
      .event_done_i   (done_config),
      .int_line_o     (interrupt_lines[0])
  );

  interrupt_controller int_ctrl_exec (
      .clk_i          (clk_i),
      .rst_ni         (!(!rst_ni | clear_interrupt_lines[1])),
      .event_started_i(csr_execute_input_output),
      .event_done_i   (done_exec),
      .int_line_o     (interrupt_lines[1])
  );

  assign interrupt_line_shared = interrupt_lines[0] | interrupt_lines[1];

  assign int_lines = interrupt_lines;
  assign int_line_shared = interrupt_line_shared;

endmodule
