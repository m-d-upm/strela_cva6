// Used to provide level triggered interrupts
// to signal when the data execution and config loading
// are done

module interrupt_controller (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic event_started_i,
    input  logic event_done_i,
    output logic int_line_o
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

      if (started_event_d) begin
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
    int_occured_d   = event_done_i && !event_done_prev_q && started_event_q;
  end

endmodule
