// Used to provide level triggered interrupts
// to signal when the data execution and config loading
// are done

module interrupt_controller (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        done_config_i,
    input  logic        done_exec_i,
    input  logic [1:0]  clear_int_lines_i,
    output logic [1:0]  int_lines_o
); 
   
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
           

        end else begin

           
        end
    end

    always_comb begin

      
    end

endmodule
