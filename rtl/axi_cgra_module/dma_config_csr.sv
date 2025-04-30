// Countrol-Status Registers for DMA Interface configuration

module dma_config_csr #(
    parameter type reg_req_t  = logic,
    parameter type reg_rsp_t  = logic,
    parameter INPUT_NODES_NUM = 4,
    parameter OUTPUT_NODES_NUM = 4
) (
    input  logic clk_i,   // Clock
    input  logic rst_ni,  // Asynchronous reset active low
    
    // Bus Interface
    input  reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o,

    // To memory
    output logic [31:0] data_input_addr_o [INPUT_NODES_NUM-1:0],
    output logic [15:0] data_input_size_o [INPUT_NODES_NUM-1:0],
    output logic [15:0] data_input_stride_o [INPUT_NODES_NUM-1:0],

    output logic [31:0] data_config_addr_o,
    output logic [15:0] data_config_size_o,

    output logic [31:0] data_output_addr_o [OUTPUT_NODES_NUM-1:0],
    output logic [15:0] data_output_size_o [OUTPUT_NODES_NUM-1:0],

    input  logic done_exec_output_i,
    input  logic done_config_i,
    output logic start_execution_o,
    output logic load_configuration_o,

    input  logic [31:0] cycle_count_load_config_i,
    input  logic [31:0] cycle_count_execute_i,
    input  logic [31:0] cycle_count_stall_i,

    output logic clear_cgra_config_o,
    output logic clear_cgra_state_o,
    
    // Test debug:
    output logic reset_state_machines_o,

    output logic output_arbiter_hold_o

);

// Register interface signals

// reg_req_i.addr
// reg_req_i.write
// reg_req_i.wdata
// reg_req_i.wstrb
// reg_req_i.valid

// reg_rsp_o.rdata
// reg_rsp_o.error
// reg_rsp_o.ready

    logic [7:0]     reg_addr /*verilator public*/;
    logic           reg_we /*verilator public*/;
    
    assign reg_rsp_o.ready = 1'b1;
    assign reg_rsp_o.error = 1'b0;

    assign reg_addr = reg_req_i.addr;
    assign reg_we = reg_req_i.valid & reg_req_i.write;

    // For easier monitoring in simulation
    logic [31:0] reg_write_data /*verilator public*/;
    assign reg_write_data = reg_req_i.wdata;

    logic [31:0] reg_read_data /*verilator public*/;
    assign reg_rsp_o.rdata = reg_read_data;

    // Some registers
    logic [31:0] op_a;
    logic [31:0] op_b;



    // Register read
    always_comb begin
        case(reg_addr)
            // Test: Useful for debugging
            8'hF0: reg_read_data = op_a;
            8'hF4: reg_read_data = op_b;
            8'hF8: reg_read_data = op_a + op_b;

            // Control/status
            8'h00: reg_read_data = {done_config_i, done_exec_output_i};

            // Config
            8'h04: reg_read_data = data_config_addr_o;  
            8'h08: reg_read_data = data_config_size_o;

            // Input
            8'h10: reg_read_data = data_input_addr_o[0];
            8'h14: reg_read_data = {data_input_stride_o[0], data_input_size_o[0]};

            8'h18: reg_read_data = data_input_addr_o[1];
            8'h1C: reg_read_data = {data_input_stride_o[1], data_input_size_o[1]};

            8'h20: reg_read_data = data_input_addr_o[2];
            8'h24: reg_read_data = {data_input_stride_o[2], data_input_size_o[2]};

            8'h28: reg_read_data = data_input_addr_o[3];
            8'h2C: reg_read_data = {data_input_stride_o[3], data_input_size_o[3]};

            // Output
            8'h50: reg_read_data = data_output_addr_o[0];
            8'h54: reg_read_data = data_output_size_o[0];

            8'h58: reg_read_data = data_output_addr_o[1];
            8'h5C: reg_read_data = data_output_size_o[1];

            8'h60: reg_read_data = data_output_addr_o[2];
            8'h64: reg_read_data = data_output_size_o[2];

            8'h68: reg_read_data = data_output_addr_o[3];
            8'h6C: reg_read_data = data_output_size_o[3];

            // Performance counters
            8'h90: reg_read_data = cycle_count_load_config_i;
            8'h94: reg_read_data = cycle_count_execute_i;
            8'h98: reg_read_data = cycle_count_stall_i;

            8'hA0: reg_read_data = output_arbiter_hold_o;

            default: reg_read_data = '0;
        endcase
    end

    // Register write
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            op_a <= '0;
            op_b <= '0;

            data_input_addr_o <= '{32'h0,32'h0,32'h0,32'h0};
            data_input_size_o <= '{16'h0, 16'h0, 16'h0, 16'h0};
            data_input_stride_o <= '{16'h0, 16'h0, 16'h0, 16'h0};

            data_output_addr_o <= '{32'h0,32'h0,32'h0,32'h0};
            data_output_size_o <= '{16'h0, 16'h0, 16'h0, 16'h0};

            data_config_addr_o <= 32'h0;
            data_config_size_o <= 16'h0;

            output_arbiter_hold_o <= 1'b0;


        end else begin
            if(reg_we) begin
            case(reg_addr)

                // Test
                8'hF0: op_a <= reg_write_data;
                8'hF4: op_b <= reg_write_data;

                8'hF8: reset_state_machines_o <= reg_write_data;

                // Control/status
                8'h00: {clear_cgra_config_o, load_configuration_o, clear_cgra_state_o, start_execution_o} <= reg_write_data[3:0];


                // Config:
                8'h04: data_config_addr_o <= reg_write_data;  
                8'h08: data_config_size_o <= reg_write_data;

                // Input
                8'h10: data_input_addr_o[0] <= reg_write_data;
                8'h14: {data_input_stride_o[0], data_input_size_o[0]} <= reg_write_data;

                8'h18: data_input_addr_o[1] <= reg_write_data;
                8'h1C: {data_input_stride_o[1], data_input_size_o[1]} <= reg_write_data;

                8'h20: data_input_addr_o[2] <= reg_write_data;
                8'h24: {data_input_stride_o[2], data_input_size_o[2]} <= reg_write_data;

                8'h28: data_input_addr_o[3] <= reg_write_data;
                8'h2C: {data_input_stride_o[3], data_input_size_o[3]} <= reg_write_data;

                // Output
                8'h50: data_output_addr_o[0] <= reg_write_data;
                8'h54: data_output_size_o[0] <= reg_write_data;

                8'h58: data_output_addr_o[1] <= reg_write_data;
                8'h5C: data_output_size_o[1] <= reg_write_data;

                8'h60: data_output_addr_o[2] <= reg_write_data;
                8'h64: data_output_size_o[2] <= reg_write_data;

                8'h68: data_output_addr_o[3] <= reg_write_data;
                8'h6C: data_output_size_o[3] <= reg_write_data;

                // Output arbiter config
                8'hA0: output_arbiter_hold_o <= reg_write_data[0];


            endcase
            end else begin
                start_execution_o <= 0;
                load_configuration_o <= 0;
                clear_cgra_config_o <= 0;
                clear_cgra_state_o <= 0;
                reset_state_machines_o <= 0;
            end
        end
    end

endmodule
