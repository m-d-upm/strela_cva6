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
    parameter int unsigned AXI_ID_WIDTH_MASTER  = -1,
    parameter int unsigned AXI_ID_WIDTH_SLAVE   = -1,
    parameter int unsigned AXI_ADDR_WIDTH       = -1,
    parameter int unsigned AXI_DATA_WIDTH       = -1,
    parameter int unsigned AXI_USER_WIDTH       = -1
) (
    input   logic       clk_i,
    input   logic       rst_ni,
    AXI_BUS.Slave       axi_slave_port,
    AXI_BUS.Master      axi_master_port,
    output  logic[1:0]  int_lines // two - one to signal exec done index [1], other to signal config loading done index [0]
);

    localparam INPUT_NODES_NUM = 4;
    localparam OUTPUT_NODES_NUM = 4;

    // define types regbus_req_t, regbus_rsp_t
    `REG_BUS_TYPEDEF_ALL(regbus, logic[31:0], logic[31:0], logic[3:0])
    regbus_req_t regbus_req;
    regbus_rsp_t regbus_rsp;

    AXI_LITE #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH        ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH        )
    ) axi_lite_bus();


    axi_slave_to_reg_adapter #(
        .AXI_ID_WIDTH_MASTER    ( AXI_ID_WIDTH_MASTER   ),
        .AXI_ID_WIDTH_SLAVE     ( AXI_ID_WIDTH_SLAVE    ),
        .AXI_ADDR_WIDTH         ( AXI_ADDR_WIDTH        ),
        .AXI_DATA_WIDTH         ( AXI_DATA_WIDTH        ),
        .AXI_USER_WIDTH         ( AXI_USER_WIDTH        ),
        .regbus_req_t           ( regbus_req_t          ),
        .regbus_rsp_t           ( regbus_rsp_t          )
    ) i_axi_slave_to_reg_adapter (
        .clk_i                  ( clk_i             ),
        .rst_ni                 ( rst_ni            ),
        .axi_slave_port         ( axi_slave_port    ),
        .regbus_req_o           ( regbus_req        ),
        .regbus_rsp_i           ( regbus_rsp        )
    );


    axi_lite_to_axi_intf #(
        .AXI_DATA_WIDTH (64)
    ) i_axi_lite_to_axi_adpter (
        .in             ( axi_lite_bus      ),
        .slv_aw_cache_i ( '0                ),
        .slv_ar_cache_i ( '0                ),
        .out            ( axi_master_port   )
    );

    logic [31:0] data_input_addr [INPUT_NODES_NUM-1:0];
    logic [15:0] data_input_size [INPUT_NODES_NUM-1:0];
    logic [15:0] data_input_stride [INPUT_NODES_NUM-1:0];

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

    dma_config_csr #(
        .reg_req_t      ( regbus_req_t      ),
        .reg_rsp_t      ( regbus_rsp_t      )
    ) i_dma_config_csr (
        .clk_i          ( clk_i             ),
        .rst_ni         ( rst_ni            ),
        .reg_req_i      ( regbus_req        ),
        .reg_rsp_o      ( regbus_rsp        ),

        .data_input_addr_o   ( data_input_addr   ),
        .data_input_size_o   ( data_input_size   ),
        .data_input_stride_o ( data_input_stride ),
        .data_config_addr_o  ( data_config_addr  ),
        .data_config_size_o  ( data_config_size  ),
        .data_output_addr_o  ( data_output_addr  ),
        .data_output_size_o  ( data_output_size  ),

        .done_exec_output_i     ( done_exec             ),
        .done_config_i          ( done_config           ),
        .start_execution_o      ( csr_execute_input_output ),
        .load_configuration_o   ( csr_load_config       ),

        // Performance counters
        .cycle_count_load_config_i  ( cycle_count_load_config   ),
        .cycle_count_execute_i      ( cycle_count_execute       ),
        .cycle_count_stall_i        ( cycle_count_stall         ),

        .clear_cgra_config_o          ( clear_cgra_config ),
        .clear_cgra_state_o           ( clear_cgra_state ),

        .reset_state_machines_o ( reset_state_machines  ),
        .output_arbiter_hold_o   ( output_arbiter_hold ),
        .clear_interrupt_lines_o ( clear_interrupt_lines )
    );


    logic control_execute_config, control_execute_input, control_execute_output;
    logic counters_read_stall, counters_write_stall;

    logic [31:0] cycle_count_load_config, cycle_count_execute, cycle_count_stall;

    countrol_unit i_control_unit(
        // Clock and reset
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        // From CSR
        .start_execution_i(csr_execute_input_output),
        .load_configuration_i(csr_load_config),

        // Control signals
        .execute_config_o(control_execute_config),
        .execute_input_o(control_execute_input),
        .execute_output_o(control_execute_output),

        // Input signals
        .data_config_done_i(done_config),
        .data_output_done_i(done_exec),

        .data_read_stall_i(counters_read_stall),
        .data_write_stall_i(counters_write_stall),

        // Performance counters
        .cycle_count_load_config_o  ( cycle_count_load_config   ),
        .cycle_count_execute_o      ( cycle_count_execute       ),
        .cycle_count_stall_o        ( cycle_count_stall         )

    ); 

    logic [32*INPUT_NODES_NUM-1:0] cgra_data_input_data;
    logic [INPUT_NODES_NUM-1:0] cgra_data_input_valid;
    logic [INPUT_NODES_NUM-1:0] cgra_data_input_ready;

    logic [32*OUTPUT_NODES_NUM-1:0] cgra_data_output_data;
    logic [OUTPUT_NODES_NUM-1:0] cgra_data_output_valid;
    logic [OUTPUT_NODES_NUM-1:0] cgra_data_output_ready;

    logic [159:0] configuration_word;

    dma_interface i_dma_interface (
        .clk_i  (clk_i),
        .rst_ni ( !(!rst_ni | reset_state_machines) ),
        .axi_master_port (axi_lite_bus),

        // Execute
        .execute_input_i(control_execute_input),
        .execute_output_i(control_execute_output),
        .execute_config_i(control_execute_config),

        // CGRA input data signals
        .data_input_o        ( cgra_data_input_data ),
        .data_input_valid_o  ( cgra_data_input_valid ),
        .data_input_ready_i  ( cgra_data_input_ready ),
        .data_input_addr_i   ( data_input_addr ),
        .data_input_size_i   ( data_input_size ),
        .data_input_stride_i ( data_input_stride ),

        // CGRA config data signals
        .configuration_word_o( configuration_word ),
        .data_config_addr_i  ( data_config_addr  ),
        .data_config_size_i  ( data_config_size  ),
        .data_config_done_o  ( done_config  ),

        // CGRA output data signals
        .data_output_i       ( cgra_data_output_data ),
        .data_output_valid_i ( cgra_data_output_valid ),
        .data_output_ready_o ( cgra_data_output_ready ),
        .data_output_addr_i  ( data_output_addr ),
        .data_output_size_i  ( data_output_size ),
        .data_output_done_o  ( done_exec ),
        .output_arbiter_hold_i  ( output_arbiter_hold ),

        // For stall cycle calculation
        .input_outst_fifo_full_o(counters_read_stall),
        .output_outst_fifo_full_o(counters_write_stall)
    );

    CGRA cgra_i
    (
        .clk                ( clk_i ),
        .rst_n              ( !(!rst_ni | clear_cgra_state) ), // Reset internal state
        .clk_bs             ( clk_i ),
        .rst_n_bs           ( !(!rst_ni | clear_cgra_config) ), // Reset configuration
        .data_in            ( cgra_data_input_data   ),
        .data_in_valid      ( cgra_data_input_valid  ),
        .data_in_ready      ( cgra_data_input_ready  ),
        .data_out           ( cgra_data_output_data  ),
        .data_out_valid     ( cgra_data_output_valid ),
        .data_out_ready     ( cgra_data_output_ready ),
        .config_bitstream   ( configuration_word ),
        .bitstream_enable_i ( 1'b1 ),
        .execute_i          ( !done_exec )
    );

    /*
    interrupt_controller int_ctrl
    (
        .clk_i              ( clk_i ),
        .rst_ni             ( rst_ni ), 
        .start_config_csr_i ( csr_load_config ),
        .start_exec_csr_i   ( csr_execute_input_output ),
        .done_config_i      ( done_config ),
        .done_exec_i        ( done_exec ),
        .clear_int_lines_i  ( clear_interrupt_lines ),
        .int_lines_o        ( int_lines )
    );
    */

    interrupt_controller int_ctrl_conf
    (
        .clk_i              ( clk_i ),
        .rst_ni             ( !(!rst_ni | clear_interrupt_lines[0]) ), 
        .event_started_i    ( csr_load_config ),
        .event_done_i       ( done_config ),
        .int_line_o         ( int_lines[0] )
    );

    interrupt_controller int_ctrl_exec
    (
        .clk_i              ( clk_i ),
        .rst_ni             ( !(!rst_ni | clear_interrupt_lines[1]) ), 
        .event_started_i    ( csr_execute_input_output ),
        .event_done_i       ( done_exec ),
        .int_line_o         ( int_lines[1] )
    );

endmodule
