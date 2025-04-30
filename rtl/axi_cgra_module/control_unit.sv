// Control Unit and Performance Counters
// Directs signals from CSRs to command
// DMA interface and CGRA operation

module countrol_unit (
    // Clock and reset
    input  logic    clk_i,
    input  logic    rst_ni,

    // From CSR
    input  logic    start_execution_i,
    input  logic    load_configuration_i,

    // Control signals
    output logic    execute_config_o,
    output logic    execute_input_o,
    output logic    execute_output_o,

    // Input signals
    input   logic   data_config_done_i,
    input   logic   data_output_done_i,

    input   logic   data_read_stall_i,
    input   logic   data_write_stall_i,

    // Performance counters
    output logic [31:0] cycle_count_load_config_o,
    output logic [31:0] cycle_count_execute_o,
    output logic [31:0] cycle_count_stall_o

); 
    // Execute
    logic start_execution_q;
    logic load_configuration_q;

    // Performance counters
    logic [31:0] cycle_count_load_config_d, cycle_count_load_config_q;
    logic [31:0] cycle_count_execute_d, cycle_count_execute_q;
    logic [31:0] cycle_count_stall_d, cycle_count_stall_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            cycle_count_load_config_q <= '0;
            cycle_count_execute_q <= '0;
            cycle_count_stall_q <= '0;

        end else begin

            // Execute
            start_execution_q <= start_execution_i;
            load_configuration_q <= load_configuration_i;

            // Performace counters
            cycle_count_load_config_q <= cycle_count_load_config_d;
            cycle_count_execute_q <= cycle_count_execute_d;
            cycle_count_stall_q <= cycle_count_stall_d;

        end
    end

    always_comb begin

        // Execute: Output pulse on rising edge
        execute_config_o = load_configuration_i && !load_configuration_q;
        execute_input_o  = start_execution_i && !start_execution_q;
        execute_output_o = execute_input_o;

        // Performance counters
        cycle_count_load_config_d = cycle_count_load_config_q;
        cycle_count_execute_d = cycle_count_execute_q;
        cycle_count_stall_d = cycle_count_stall_q;

        if(execute_config_o)
            cycle_count_load_config_d = '0;
        else if (!data_config_done_i)
            cycle_count_load_config_d = cycle_count_load_config_q + 1;

        if(execute_output_o)
            cycle_count_execute_d = '0;
        else if (!data_output_done_i)
            cycle_count_execute_d = cycle_count_execute_q + 1;

        if(execute_output_o)
            cycle_count_stall_d = '0;
        else if (data_read_stall_i || data_write_stall_i)
            cycle_count_stall_d = cycle_count_stall_q + 1;


        cycle_count_load_config_o = cycle_count_load_config_q;
        cycle_count_execute_o     = cycle_count_execute_q;    
        cycle_count_stall_o       = cycle_count_stall_q;   

    end

endmodule
