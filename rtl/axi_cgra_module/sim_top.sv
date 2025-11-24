// Top file of the simulation

// Includes:
// - Module for CGRA integration
// - Simulated RAM memory
// - PULP AXI crossbar, the same used with CVA6

// Note: For initial testing, some stimuly was generated in this testbench.
// Note that Verilator lacks some functionality regarding SystemVerilog testbenches.

module sim_top (
    input  logic        clk_i,
    input  logic        rst_ni,
    output logic [31:0] count
);

  logic [31:0] count_q, count_d;

  assign count = count_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) count_q <= '0;

    // Default
    count_q <= count_q + 1;

    case (count_q)

      // 10: begin
      // // Start config
      // slave[0].aw_addr <= 32'h5000_0050;
      // slave[0].w_data  <= 32'h0000_0001;

      // slave[0].aw_size <= 3'b011;
      // slave[0].w_strb <= '1;
      // slave[0].w_last <= 1'b1;

      // slave[0].aw_valid <= 1;
      // slave[0].w_valid <= 1;

      // slave[0].b_ready <= 1;
      // end

      // 11: begin
      // slave[0].aw_valid <= 0;
      // slave[0].w_valid <= 0;
      // end

      // 40: begin

      // slave[0].aw_valid <= 1;
      // slave[0].w_valid <= 1;

      // end

      // 41: begin
      // slave[0].aw_valid <= 0;
      // slave[0].w_valid <= 0;
      // end

      // 10: begin
      // slave[0].aw_addr <= 32'h5000_0050;
      // slave[0].w_data  <= 32'h0000_0003;

      // slave[0].aw_size <= 3'b011;
      // slave[0].w_strb <= '1;
      // slave[0].w_last <= 1'b1;

      // slave[0].aw_valid <= 1;
      // slave[0].w_valid <= 1;

      // slave[0].b_ready <= 1;
      // end

      // 11: begin
      // slave[0].aw_valid <= 0;
      // slave[0].w_valid <= 0;
      // end

      // 40: begin
      // slave[0].aw_addr <= 32'h5000_0070;
      // slave[0].w_data  <= 32'h0000_0001;

      // slave[0].aw_valid <= 1;
      // slave[0].w_valid <= 1;
      // end

      // 41: begin
      // slave[0].aw_valid <= 0;
      // slave[0].w_valid <= 0;
      // end

      // 50: begin 
      // slave[0].aw_valid <= 1;
      // slave[0].w_valid <= 1;
      // end


      // 51: begin  
      // slave[0].aw_valid <= 0;
      // slave[0].w_valid <= 0;
      // end

      1000: $finish;
    endcase
  end

  AXI_BUS #(
      .AXI_ADDR_WIDTH(AxiAddrWidth),
      .AXI_DATA_WIDTH(AxiDataWidth),
      .AXI_ID_WIDTH  (AxiIdWidthMaster),
      .AXI_USER_WIDTH(AxiUserWidth)
  ) axi_bus_interface ();

  localparam NBSlave = 3;  // debug, ariane + CGRA // MODIFIED: Increased from 2 to 3
  localparam AxiAddrWidth = 64;
  localparam AxiDataWidth = 64;
  localparam AxiIdWidthMaster = 4;
  localparam AxiIdWidthSlaves = AxiIdWidthMaster + $clog2(NBSlave);  // 5
  localparam AxiUserWidth = 64;  //ariane_pkg::AXI_USER_WIDTH;

  AXI_BUS #(
      .AXI_ADDR_WIDTH(AxiAddrWidth),
      .AXI_DATA_WIDTH(AxiDataWidth),
      .AXI_ID_WIDTH  (AxiIdWidthMaster),
      .AXI_USER_WIDTH(AxiUserWidth)
  ) slave[NBSlave-1:0] ();

  AXI_BUS #(
      .AXI_ADDR_WIDTH(AxiAddrWidth),
      .AXI_DATA_WIDTH(AxiDataWidth),
      .AXI_ID_WIDTH  (AxiIdWidthSlaves),
      .AXI_USER_WIDTH(AxiUserWidth)
  ) master[ariane_soc::NB_PERIPHERALS-1:0] ();

  // ---------------
  // AXI Xbar
  // ---------------

  axi_pkg::xbar_rule_64_t [ariane_soc::NB_PERIPHERALS-1:0] addr_map;

  assign addr_map = '{
          '{
              idx: ariane_soc::Debug,
              start_addr: ariane_soc::DebugBase,
              end_addr: ariane_soc::DebugBase + ariane_soc::DebugLength
          },
          '{
              idx: ariane_soc::ROM,
              start_addr: ariane_soc::ROMBase,
              end_addr: ariane_soc::ROMBase + ariane_soc::ROMLength
          },
          '{
              idx: ariane_soc::CLINT,
              start_addr: ariane_soc::CLINTBase,
              end_addr: ariane_soc::CLINTBase + ariane_soc::CLINTLength
          },
          '{
              idx: ariane_soc::PLIC,
              start_addr: ariane_soc::PLICBase,
              end_addr: ariane_soc::PLICBase + ariane_soc::PLICLength
          },
          '{
              idx: ariane_soc::UART,
              start_addr: ariane_soc::UARTBase,
              end_addr: ariane_soc::UARTBase + ariane_soc::UARTLength
          },
          '{
              idx: ariane_soc::Timer,
              start_addr: ariane_soc::TimerBase,
              end_addr: ariane_soc::TimerBase + ariane_soc::TimerLength
          },
          '{
              idx: ariane_soc::SPI,
              start_addr: ariane_soc::SPIBase,
              end_addr: ariane_soc::SPIBase + ariane_soc::SPILength
          },
          '{
              idx: ariane_soc::Ethernet,
              start_addr: ariane_soc::EthernetBase,
              end_addr: ariane_soc::EthernetBase + ariane_soc::EthernetLength
          },
          '{
              idx: ariane_soc::GPIO,
              start_addr: ariane_soc::GPIOBase,
              end_addr: ariane_soc::GPIOBase + ariane_soc::GPIOLength
          },
          '{
              idx: ariane_soc::DRAM,
              start_addr: ariane_soc::DRAMBase,
              end_addr: ariane_soc::DRAMBase + ariane_soc::DRAMLength
          },
          '{
              idx: ariane_soc::Accelerator,
              start_addr: ariane_soc::AcceleratorBase,
              end_addr: ariane_soc::AcceleratorBase + ariane_soc::AcceleratorLength
          }
      };

  localparam axi_pkg::xbar_cfg_t AXI_XBAR_CFG = '{
      NoSlvPorts: ariane_soc::NrSlaves,
      NoMstPorts: ariane_soc::NB_PERIPHERALS,
      MaxMstTrans: 20,  // Probably requires update
      MaxSlvTrans: 20,  // Probably requires update
      FallThrough: 1'b0,
      LatencyMode: axi_pkg::CUT_ALL_PORTS,  //  axi_pkg::NO_LATENCY, // 
      AxiIdWidthSlvPorts: AxiIdWidthMaster,
      AxiIdUsedSlvPorts: AxiIdWidthMaster,
      UniqueIds: 1'b0,
      AxiAddrWidth: AxiAddrWidth,
      AxiDataWidth: AxiDataWidth,
      NoAddrRules: ariane_soc::NB_PERIPHERALS,
      PipelineStages: 1'b1
  };

  axi_xbar_intf #(
      .AXI_USER_WIDTH(AxiUserWidth),
      .Cfg           (AXI_XBAR_CFG),
      .rule_t        (axi_pkg::xbar_rule_64_t)
  ) i_axi_xbar (
      .clk_i                (clk_i),     // clk
      .rst_ni               (rst_ni),    // ndmreset_n 
      .test_i               (1'b0),      // test_en
      .slv_ports            (slave),
      .mst_ports            (master),
      .addr_map_i           (addr_map),
      .en_default_mst_port_i('0),
      .default_mst_port_i   ('0)
  );

  /////////////////// MASTER SLAVE TEST ///////////////////////////

  logic [1:0] int_lines;

  axi_cgra_top #(
      .AXI_ID_WIDTH_MASTER(AxiIdWidthMaster),
      .AXI_ID_WIDTH_SLAVE (AxiIdWidthSlaves),
      .AXI_ADDR_WIDTH     (AxiAddrWidth),
      .AXI_DATA_WIDTH     (AxiDataWidth),
      .AXI_USER_WIDTH     (AxiUserWidth)
  ) i_axi_cgra_top (
      .clk_i          (clk_i),                            // clk
      .rst_ni         (rst_ni),                           // ndmreset_n 
      .axi_slave_port (master[ariane_soc::Accelerator]),
      .axi_master_port(slave[2]),
      .int_lines      (int_lines)
  );

  ////////////// AXI to memory ///////////////

  logic ram_req = '0;
  logic ram_we = '0;
  logic [7:0] ram_be = '0;
  logic [63:0] ram_addr = '0;
  logic [63:0] ram_rdata;
  logic [63:0] ram_wdata = '0;

  axi2mem #(
      .AXI_ID_WIDTH  (AxiIdWidthSlaves),
      .AXI_ADDR_WIDTH(AxiAddrWidth),
      .AXI_DATA_WIDTH(AxiDataWidth),
      .AXI_USER_WIDTH(AxiUserWidth)
  ) i_axi2rom (
      .clk_i (clk_i),
      .rst_ni(rst_ni),
      .slave (master[ariane_soc::DRAM]),
      .req_o (ram_req),
      .we_o  (ram_we),
      .addr_o(ram_addr),
      .be_o  (ram_be),
      .data_o(ram_wdata),
      .data_i(ram_rdata)
  );

  test_ram_64 i_test_ram (
      .clk_i  (clk_i),
      .req_i  (ram_req),
      .we_i   (ram_we),
      .be_i   (ram_be),
      .addr_i (ram_addr),
      .rdata_o(ram_rdata),
      .wdata_i(ram_wdata)
  );

endmodule
