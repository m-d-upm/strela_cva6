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
  logic int_shared;


   // APB bus signals
   logic         apb_penable;
   logic         apb_pwrite;
   logic [31:0]  apb_paddr;
   logic         apb_psel;
   logic [31:0]  apb_pwdata;
   logic [31:0]  apb_prdata;
   logic         apb_pready;
   logic         apb_pslverr;

   axi2apb_64_32 #(
       .AXI4_ADDRESS_WIDTH ( AxiAddrWidth ),
       .AXI4_RDATA_WIDTH   ( AxiDataWidth ),
       .AXI4_WDATA_WIDTH   ( AxiDataWidth ),
       .AXI4_ID_WIDTH      ( AxiIdWidthSlaves   ),
       .AXI4_USER_WIDTH    ( AxiUserWidth ),
       .BUFF_DEPTH_SLAVE   ( 2              ),
       .APB_ADDR_WIDTH     ( 32             )
   ) i_axi2apb_64_32_accelerator (
       .ACLK      ( clk_i          ),
       .ARESETn   ( rst_ni         ),
       .test_en_i ( 1'b0           ),
       .AWID_i    ( master[ariane_soc::Accelerator].aw_id     ),
       .AWADDR_i  ( master[ariane_soc::Accelerator].aw_addr   ),
       .AWLEN_i   ( master[ariane_soc::Accelerator].aw_len    ),
       .AWSIZE_i  ( master[ariane_soc::Accelerator].aw_size   ),
       .AWBURST_i ( master[ariane_soc::Accelerator].aw_burst  ),
       .AWLOCK_i  ( master[ariane_soc::Accelerator].aw_lock   ),
       .AWCACHE_i ( master[ariane_soc::Accelerator].aw_cache  ),
       .AWPROT_i  ( master[ariane_soc::Accelerator].aw_prot   ),
       .AWREGION_i( master[ariane_soc::Accelerator].aw_region ),
       .AWUSER_i  ( master[ariane_soc::Accelerator].aw_user   ),
       .AWQOS_i   ( master[ariane_soc::Accelerator].aw_qos    ),
       .AWVALID_i ( master[ariane_soc::Accelerator].aw_valid  ),
       .AWREADY_o ( master[ariane_soc::Accelerator].aw_ready  ),
       .WDATA_i   ( master[ariane_soc::Accelerator].w_data    ),
       .WSTRB_i   ( master[ariane_soc::Accelerator].w_strb    ),
       .WLAST_i   ( master[ariane_soc::Accelerator].w_last    ),
       .WUSER_i   ( master[ariane_soc::Accelerator].w_user    ),
       .WVALID_i  ( master[ariane_soc::Accelerator].w_valid   ),
       .WREADY_o  ( master[ariane_soc::Accelerator].w_ready   ),
       .BID_o     ( master[ariane_soc::Accelerator].b_id      ),
       .BRESP_o   ( master[ariane_soc::Accelerator].b_resp    ),
       .BVALID_o  ( master[ariane_soc::Accelerator].b_valid   ),
       .BUSER_o   ( master[ariane_soc::Accelerator].b_user    ),
       .BREADY_i  ( master[ariane_soc::Accelerator].b_ready   ),
       .ARID_i    ( master[ariane_soc::Accelerator].ar_id     ),
       .ARADDR_i  ( master[ariane_soc::Accelerator].ar_addr   ),
       .ARLEN_i   ( master[ariane_soc::Accelerator].ar_len    ),
       .ARSIZE_i  ( master[ariane_soc::Accelerator].ar_size   ),
       .ARBURST_i ( master[ariane_soc::Accelerator].ar_burst  ),
       .ARLOCK_i  ( master[ariane_soc::Accelerator].ar_lock   ),
       .ARCACHE_i ( master[ariane_soc::Accelerator].ar_cache  ),
       .ARPROT_i  ( master[ariane_soc::Accelerator].ar_prot   ),
       .ARREGION_i( master[ariane_soc::Accelerator].ar_region ),
       .ARUSER_i  ( master[ariane_soc::Accelerator].ar_user   ),
       .ARQOS_i   ( master[ariane_soc::Accelerator].ar_qos    ),
       .ARVALID_i ( master[ariane_soc::Accelerator].ar_valid  ),
       .ARREADY_o ( master[ariane_soc::Accelerator].ar_ready  ),
       .RID_o     ( master[ariane_soc::Accelerator].r_id      ),
       .RDATA_o   ( master[ariane_soc::Accelerator].r_data    ),
       .RRESP_o   ( master[ariane_soc::Accelerator].r_resp    ),
       .RLAST_o   ( master[ariane_soc::Accelerator].r_last    ),
       .RUSER_o   ( master[ariane_soc::Accelerator].r_user    ),
       .RVALID_o  ( master[ariane_soc::Accelerator].r_valid   ),
       .RREADY_i  ( master[ariane_soc::Accelerator].r_ready   ),
       .PENABLE   ( apb_penable   ),
       .PWRITE    ( apb_pwrite    ),
       .PADDR     ( apb_paddr     ),
       .PSEL      ( apb_psel      ),
       .PWDATA    ( apb_pwdata    ),
       .PRDATA    ( apb_prdata    ),
       .PREADY    ( apb_pready    ),
       .PSLVERR   ( apb_pslverr   )
   );

  axi_cgra_top #(
      .AXI_ID_WIDTH_MASTER(AxiIdWidthMaster),
      //.AXI_ID_WIDTH_SLAVE (AxiIdWidthSlaves),
      .AXI_ADDR_WIDTH     (AxiAddrWidth),
      .AXI_DATA_WIDTH     (AxiDataWidth),
      .AXI_USER_WIDTH     (AxiUserWidth)
  ) i_axi_cgra_top (
      .clk_i          (clk_i),                            // clk
      .rst_ni         (rst_ni),                           // ndmreset_n 
      .axi_awvalid(slave[2].aw_valid),
      .axi_awready(slave[2].aw_ready),
      .axi_awid(slave[2].aw_id),
      .axi_awlen(slave[2].aw_len),
      .axi_awaddr(slave[2].aw_addr),
      .axi_wvalid(slave[2].w_valid),
      .axi_wready(slave[2].w_ready),
      .axi_wdata(slave[2].w_data),
      .axi_wstrb(slave[2].w_strb),
      .axi_wlast(slave[2].w_last),
      .axi_arvalid(slave[2].ar_valid),
      .axi_arready(slave[2].ar_ready),
      .axi_arid(slave[2].ar_id),
      .axi_arlen(slave[2].ar_len),
      .axi_araddr(slave[2].ar_addr),
      .axi_bresp(slave[2].b_resp),
      .axi_bvalid(slave[2].b_valid),
      .axi_bready(slave[2].b_ready),
      .axi_bid(slave[2].b_id),
      .axi_rvalid(slave[2].r_valid),
      .axi_rready(slave[2].r_ready),
      .axi_rid(slave[2].r_id),
      .axi_rlast(slave[2].r_last),
      .axi_rdata(slave[2].r_data),
      .axi_rresp(slave[2].r_resp),
      .axi_awsize(slave[2].aw_size),
      .axi_arsize(slave[2].ar_size),
      .axi_awburst(slave[2].aw_burst),
      .axi_arburst(slave[2].ar_burst),
      .axi_awlock(slave[2].aw_lock),
      .axi_arlock(slave[2].ar_lock),
      .axi_awcache(slave[2].aw_cache),
      .axi_arcache(slave[2].ar_cache),
      .axi_awprot(slave[2].aw_prot),
      .axi_arprot(slave[2].ar_prot),
      .axi_awqos(slave[2].aw_qos),
      .axi_awatop(slave[2].aw_atop),
      .axi_awregion(slave[2].aw_region),
      .axi_arqos(slave[2].ar_qos),
      .axi_arregion(slave[2].ar_region),
      .axi_awuser(slave[2].aw_user),
      .axi_wuser(slave[2].w_user),
      .axi_aruser(slave[2].ar_user),
      .axi_buser(slave[2].b_user),
      .axi_ruser(slave[2].r_user),
      .apb_reg_bus_penable(apb_penable),
      .apb_reg_bus_pwrite(apb_pwrite),
      .apb_reg_bus_paddr(apb_paddr),
      .apb_reg_bus_psel(apb_psel),
      .apb_reg_bus_pwdata(apb_pwdata),
      .apb_reg_bus_prdata(apb_prdata),
      .apb_reg_bus_pready(apb_pready),
      .apb_reg_bus_pslverr(apb_pslverr),
      .int_lines(int_lines),
      .int_line_shared(int_shared)
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
