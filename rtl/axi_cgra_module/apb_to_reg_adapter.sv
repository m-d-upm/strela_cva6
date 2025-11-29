// An adapter between an AXI Slave and Register Interface

`include "register_interface/assign.svh"

module apb_to_reg_adapter #(
    parameter type regbus_req_t = logic,
    parameter type regbus_rsp_t = logic
) (
    input  logic               clk_i,
    input  logic               rst_ni,
    input  logic               apb_penable,
    input  logic               apb_pwrite,
    input  logic        [31:0] apb_paddr,
    input  logic               apb_psel,
    input  logic        [31:0] apb_pwdata,
    output logic        [31:0] apb_prdata,
    output logic               apb_pready,
    output logic               apb_pslverr,
    output regbus_req_t        regbus_req_o,
    input  regbus_rsp_t        regbus_rsp_i
);

  //              ______________          ___________ 
  // APB bus --->|  apb_to_reg  | <----> |  reg_bus  |
  //             |______________|        |___________|

  REG_BUS #(
      .ADDR_WIDTH(32),
      .DATA_WIDTH(32)
  ) reg_bus (
      clk_i
  );

  // APB bus signals

  apb_to_reg i_apb_to_reg (
      .clk_i    (clk_i),
      .rst_ni   (rst_ni),
      .penable_i(apb_penable),
      .pwrite_i (apb_pwrite),
      .paddr_i  (apb_paddr),
      .psel_i   (apb_psel),
      .pwdata_i (apb_pwdata),
      .prdata_o (apb_prdata),
      .pready_o (apb_pready),
      .pslverr_o(apb_pslverr),
      .reg_o    (reg_bus)
  );

  // assign REG_BUS.out to (req_t, rsp_t) pair
  `REG_BUS_ASSIGN_TO_REQ(regbus_req_o, reg_bus)
  `REG_BUS_ASSIGN_FROM_RSP(reg_bus, regbus_rsp_i)

endmodule
