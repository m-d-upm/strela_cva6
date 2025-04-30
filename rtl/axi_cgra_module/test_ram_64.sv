// A module for simulation of a 64-bit wide RAM with a byte-wise write enable

module test_ram_64 #(
    parameter RAM_SIZE = 65536
)(
   input  logic         clk_i,
   input  logic         req_i,
   input  logic         we_i,
   input  logic [7:0]   be_i,
   input  logic [63:0]  addr_i,
   output logic [63:0]  rdata_o,
   input  logic [63:0]  wdata_i
);

    logic [63:0] ram_memory_contents [RAM_SIZE-1:0] /*verilator public*/;
    // = {
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'haa000000_bb000000,
    //     64'ha0900000_b0900000,
    //     64'ha0800000_b0800000,
    //     64'ha0700000_b0700000,
    //     64'ha0600000_b0600000,
    //     64'ha0500000_b0500000,
    //     64'ha0400000_b0400000,
    //     64'ha0300000_b0300000,
    //     64'ha0200000_b0200000,
    //     64'ha0100000_b0100000,
    //     64'ha0000000_b0000000
    // };

    logic [$clog2(RAM_SIZE)-1:0] addr_q;
    logic [$clog2(RAM_SIZE)-1:0] n_addr_q;

    assign n_addr_q = addr_i[$clog2(RAM_SIZE)-1+3:3];

    always_ff @(posedge clk_i) begin

        if (req_i) begin
            if(!we_i) begin
                addr_q <= n_addr_q;
            end else begin
                integer i;
                for(i=0; i<8; i++)
                    if(be_i[i]) ram_memory_contents[n_addr_q][8*i +:8] <= wdata_i[8*i +:8]; // Index of LSB +: width

            end
        end 
        
    end

    // this prevents spurious Xes from propagating into
    // the speculative fetch stage of the core
    assign rdata_o = (32'(addr_q) < RAM_SIZE) ? ram_memory_contents[addr_q] : '0;
endmodule
