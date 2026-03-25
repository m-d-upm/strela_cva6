// CPP Testbench for the simulation of the sim_top module

// Generates clock and reset signals and dumps waveforms
// Contains functions for reading and writing in the simulated
// RAM memory, as well as accessing CSRs.

#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsim_top.h"
#include "Vsim_top___024root.h"

// To access memory
#include "Vsim_top_sim_top.h"
#include "Vsim_top_test_ram_64.h"

// To access registers
#include "Vsim_top_axi_cgra_top__pi2.h"

#include "Vsim_top_dma_config_csr__Tz19_TBz20.h"

// Register addresses
#include "register_addresses.h"
#include "kernels.h"

vluint64_t sim_time = 0;

////////////// Functions to read and write config registers and RAM from this testbench ///////////

// To be called before rising edge of the clock
void write_reg(Vsim_top *dut, uint32_t reg_addr, uint32_t reg_data)
{
    dut->sim_top->i_axi_cgra_top->i_dma_config_csr->reg_addr = reg_addr;
    dut->sim_top->i_axi_cgra_top->i_dma_config_csr->reg_write_data = reg_data;
    dut->sim_top->i_axi_cgra_top->i_dma_config_csr->reg_we = 1;
}

void write_reg_eval(Vsim_top *dut, VerilatedVcdC *m_trace, uint32_t reg_addr, uint32_t reg_data)
{
    dut->clk_i = 0;  dut->eval();  m_trace->dump(sim_time++);
    dut->sim_top->i_axi_cgra_top->i_dma_config_csr->reg_addr = reg_addr;
    dut->sim_top->i_axi_cgra_top->i_dma_config_csr->reg_write_data = reg_data;
    dut->sim_top->i_axi_cgra_top->i_dma_config_csr->reg_we = 1;
    dut->clk_i = 1;  dut->eval();  m_trace->dump(sim_time++);
}

uint32_t read_reg(Vsim_top *dut, uint32_t reg_addr)
{
    dut->sim_top->i_axi_cgra_top->i_dma_config_csr->reg_addr = reg_addr;
    dut->eval();
    return dut->sim_top->i_axi_cgra_top->i_dma_config_csr->reg_read_data;
}

#define RAM_CONTENTS dut->sim_top->i_test_ram->ram_memory_contents

uint64_t read_ram(Vsim_top *dut, uint32_t ram_addr)
{
    return dut->sim_top->i_test_ram->ram_memory_contents[(ram_addr & 0xffff)/8];
}

void write_ram(Vsim_top *dut, uint32_t ram_addr, uint64_t ram_data)
{
    dut->sim_top->i_test_ram->ram_memory_contents[(ram_addr & 0xffff)/8] = ram_data;
}

void examine_mem(Vsim_top *dut, uint32_t ram_addr1, uint32_t ram_addr2)
{
    for(int i=ram_addr1; i<ram_addr2; i+=8)
    {
 
        uint32_t high = read_ram(dut, i) >> 32;
        uint32_t low  = read_ram(dut, i) & 0x00000000ffffffff;

        printf("%08x: %08x %08x\n", i, low, high);
        if((i/8+1)%4 == 0)
            printf("\n");
    }
}

int main(int argc, char** argv, char** env) {

    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    Vsim_top *dut = new Vsim_top;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 99);
    m_trace->open("waveform.vcd");

    ////////////// MEMORY SETUP ///////////////////

    #define CONFIG_ADDR     0x80000000
    #define DATA_IN_ADDR    0x80001000
    #define DATA_OUT_ADDR   0x80002000

    // Copy bitstream to RAM

    uint32_t *cgra_kernel = bypass_kernel;
    uint32_t cgra_kernel_size = BYPASS_SIZE;

    for(int i=0; i<cgra_kernel_size; i+=2)
    {
        write_ram(dut, CONFIG_ADDR + i*4, \
                    ((uint64_t)cgra_kernel[i+1] << 32) | cgra_kernel[i]);
    }

    // Setup Input data
    for(int i = 0; i<16; i++)
    {
        write_ram(dut, DATA_IN_ADDR + i*4, i);
    }
    // write_ram(dut, DATA_IN_ADDR + 0x00, 1L << 32 | 2 );
    // write_ram(dut, DATA_IN_ADDR + 0x08, (uint64_t)(-2) << 32 | 4 );

    /////////////// SIMULATION LOOP ////////////////
    dut->rst_ni = 0;
    while (!contextp->gotFinish()) {
        dut->clk_i = 0;  dut->eval();  m_trace->dump(sim_time++);
        dut->clk_i = 1;  dut->eval();  m_trace->dump(sim_time++);

        if(sim_time > 2)
            dut->rst_ni = 1;

        if(sim_time == 10)
        {
            write_reg_eval(dut, m_trace, CGRA_CTRL_A, STRELA_CTRL_BIT_CLEAR_STATE);
            write_reg_eval(dut, m_trace, CGRA_CTRL_A, STRELA_CTRL_BIT_CLEAR_CONFIG);
        }

        if(sim_time == 20)
        {
            write_reg_eval(dut, m_trace, CGRA_RESET_DMA_A, 1);
        }

        if(sim_time == 30)
        {
            // Load configuration
            write_reg_eval(dut, m_trace, CGRA_CONF_ADDR_A, CONFIG_ADDR);
            write_reg_eval(dut, m_trace, CGRA_CONF_SIZE_A, cgra_kernel_size*4);
            write_reg_eval(dut, m_trace, CGRA_CTRL_A, CGRA_CTRL_BIT_LOAD_CONFIG);
        }

        if(sim_time == 400)
        {
            write_reg_eval(dut, m_trace, CGRA_CTRL_A, STRELA_CTRL_BIT_CLEAR_INT_CONFIG);
        }

        // Start exec
        if(sim_time == 500)
        {

            write_reg_eval(dut, m_trace, CGRA_IN0_SIZE_A, 0);
            write_reg_eval(dut, m_trace, CGRA_IN1_SIZE_A, 0);
            write_reg_eval(dut, m_trace, CGRA_IN2_SIZE_A, 0);
            write_reg_eval(dut, m_trace, CGRA_IN3_SIZE_A, 0);

            write_reg_eval(dut, m_trace, CGRA_OUT0_SIZE_A, 0);
            write_reg_eval(dut, m_trace, CGRA_OUT1_SIZE_A, 0);
            write_reg_eval(dut, m_trace, CGRA_OUT2_SIZE_A, 0);
            write_reg_eval(dut, m_trace, CGRA_OUT3_SIZE_A, 0);


            // Bypass
            write_reg_eval(dut, m_trace, CGRA_IN0_ADDR_A, DATA_IN_ADDR);
            write_reg_eval(dut, m_trace, CGRA_IN0_SIZE_A, 0x4 << 16 | 0x4*16);

            write_reg_eval(dut, m_trace, CGRA_IN1_ADDR_A, DATA_IN_ADDR);
            write_reg_eval(dut, m_trace, CGRA_IN1_SIZE_A, 0x4 << 16 | 0x4*16);

            write_reg_eval(dut, m_trace, CGRA_IN2_ADDR_A, DATA_IN_ADDR);
            write_reg_eval(dut, m_trace, CGRA_IN2_SIZE_A, 0x4 << 16 | 0x4*16);

            write_reg_eval(dut, m_trace, CGRA_IN3_ADDR_A, DATA_IN_ADDR);
            write_reg_eval(dut, m_trace, CGRA_IN3_SIZE_A, 0x4 << 16 | 0x4*16);


            write_reg_eval(dut, m_trace, CGRA_OUT0_ADDR_A, DATA_OUT_ADDR);
            write_reg_eval(dut, m_trace, CGRA_OUT0_SIZE_A, 0x4*16);

            write_reg_eval(dut, m_trace, CGRA_OUT1_ADDR_A, DATA_OUT_ADDR+0x20);
            write_reg_eval(dut, m_trace, CGRA_OUT1_SIZE_A, 0x4*16);
            
            write_reg_eval(dut, m_trace, CGRA_OUT2_ADDR_A, DATA_OUT_ADDR+0x40);
            write_reg_eval(dut, m_trace, CGRA_OUT2_SIZE_A, 0x4*16);
            
            write_reg_eval(dut, m_trace, CGRA_OUT3_ADDR_A, DATA_OUT_ADDR+0x60);
            write_reg_eval(dut, m_trace, CGRA_OUT3_SIZE_A, 0x4*16);

            write_reg_eval(dut, m_trace, CGRA_CTRL_A, CGRA_CTRL_BIT_START_EXEC);
        } 

        // // Start exec
        // if(sim_time == 1100)
        // {

        //     //write_reg_eval(dut, m_trace, CGRA_CTRL_A, CGRA_CTRL_BIT_CLEAR);
        //     write_reg_eval(dut, m_trace, CGRA_CTRL_A, CGRA_CTRL_BIT_START_EXEC);
        // }

        if(sim_time == 1500)
        {
            write_reg_eval(dut, m_trace, CGRA_CTRL_A, STRELA_CTRL_BIT_CLEAR_INT_EXEC);
        }
    }


    printf("\nMemory dump\n");

    printf("\nCONFIG MEM\n");
    examine_mem(dut, CONFIG_ADDR, CONFIG_ADDR + 0x50);

    printf("\nINPUT MEM\n");
    examine_mem(dut, DATA_IN_ADDR, DATA_IN_ADDR + 0x50);

    printf("\nOUTPUT MEM\n");
    examine_mem(dut, DATA_OUT_ADDR, DATA_OUT_ADDR + 0x50);


    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
