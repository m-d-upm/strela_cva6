// Used to provide level triggered interrupts
// to signal when the data execution and config loading
// are done

module interrupt_controller (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        event_started_i,
    input  logic        event_done_i,
    output logic        int_line_o
); 

    logic int_occured_d;
    logic started_event_d;
    logic started_event_q;

    logic event_started_prev_q;
    logic event_done_prev_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            event_started_prev_q <= 1'b0;
            event_done_prev_q <= 1'b0;
            started_event_q <= 1'b0;
            int_line_o <= 1'b0;
        end else begin
            event_started_prev_q <= event_started_i;
            event_done_prev_q <= event_done_i;

            if(started_event_d) begin
                started_event_q <= 1'b1;
            end

            if (int_occured_d) begin
                int_line_o <= 1'b1;
            end
        end
    end

    always_comb begin
        // detect rising edge 0->1
       started_event_d = event_started_i && !event_started_prev_q;
       int_occured_d = event_done_i && !event_done_prev_q && started_event_q;
    end

/*
    cgra_intr_fsm intr_ctrl_config
    (
        .clk_i                      ( clk_i ),
        .rst_ni                     ( rst_ni ), 
        .event_started_flag_i       ( start_config_csr_i ),
        .event_completed_flag_i     ( done_config_i ),
        .clear_intr_line            ( clear_int_lines_i[0] ),
        .int_line_o                 ( int_lines_o[0] )
    );

    cgra_intr_fsm intr_ctrl_exec
    (
        .clk_i                      ( clk_i ),
        .rst_ni                     ( rst_ni ), 
        .event_started_flag_i       ( start_exec_csr_i ),
        .event_completed_flag_i     ( done_exec_i ),
        .clear_intr_line            ( clear_int_lines_i[1] ),
        .int_line_o                 ( int_lines_o[1] )
    );
*/

endmodule

module cgra_intr_fsm (
    input  logic clk_i,          
    input  logic rst_ni,       
    input  logic event_started_flag_i,
    input  logic event_completed_flag_i,        
    input  logic clear_intr_line,        
    output logic int_line_o
);
    // State encoding
    typedef enum logic [1:0] {
        WAIT_FOR_EVENT_START    = 2'b00,
        WAIT_FOR_EVENT_END      = 2'b01,
        WAIT_FOR_INT_ACK        = 2'b10
    } state_t;

    state_t current_state, next_state;
    logic intr;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            current_state <= WAIT_FOR_EVENT_START;
            int_line_o <= 1'b0;
        end else begin
            current_state <= next_state;
            int_line_o <= intr;
        end
    end

    always_comb begin
        next_state = current_state;
        intr = 1'b0; 

        case (current_state)
            WAIT_FOR_EVENT_START: begin
                if (event_started_flag_i) begin
                    next_state = WAIT_FOR_EVENT_END; 
                end
            end

            WAIT_FOR_EVENT_END: begin
                if (event_completed_flag_i) begin
                    next_state = WAIT_FOR_INT_ACK;
                    intr = 1'b1; 
                end
            end

            WAIT_FOR_INT_ACK: begin
                if (clear_intr_line) begin // intr acknowledged when being cleared, writing '1' to a proper position in CSR
                    next_state = WAIT_FOR_EVENT_START;
                    intr = 1'b0; 
                end
            end

            default: begin
                next_state = WAIT_FOR_EVENT_START;
            end
        endcase
    end

endmodule
