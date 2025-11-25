# Makefile for stand-alone simulation of the AXI CGRA Module
# Juan Granja, 2024

# Example: Running "make waves" will call Verilator with the SV sources, generate
# an executable model, run it, and launch GTKWave with the logic traces.

VERILATOR = verilator
GTKWAVE = gtkwave

.PHONY: verilate sim
verilate: .stamp.verilate
sim: waveform.vcd

TOP_MODULE = sim_top

vendor_src_dir = rtl/vendor
include_dir = include

############# Include dirs #############
verilator_inc_dirs = $(include_dir)

############# Source packages #############
verilator_src_pkgs = rtl/vendor/axi_pkg.sv \
		     rtl/cva6_files/ariane_soc_pkg.sv \
		     rtl/strela/rtl/include/cgra_pkg.sv \
    		     rtl/vendor/cf_math_pkg.sv


############# My sources ##############
verilator_srcs += rtl/axi_cgra_module/sim_top.sv
verilator_srcs += rtl/axi_cgra_module/test_ram_64.sv
verilator_srcs += rtl/axi_cgra_module/axi_cgra_top.sv
verilator_srcs += rtl/axi_cgra_module/dma_config_csr.sv
verilator_srcs += rtl/axi_cgra_module/dma_interface.sv
verilator_srcs += rtl/axi_cgra_module/deserializer.sv
verilator_srcs += rtl/axi_cgra_module/control_unit.sv
verilator_srcs += rtl/axi_cgra_module/apb_to_reg_adapter.sv
verilator_srcs += rtl/axi_cgra_module/interrupt_controller.sv

############# Strela CGRA sources #############
verilator_srcs += $(wildcard rtl/strela/rtl/cgra/*.sv)

############# Vendor sources ###########
verilator_srcs += $(vendor_src_dir)/rstgen_bypass.sv
verilator_srcs += $(vendor_src_dir)/rstgen.sv
verilator_srcs += $(vendor_src_dir)/addr_decode.sv
verilator_srcs += $(vendor_src_dir)/stream_register.sv
verilator_srcs += $(vendor_src_dir)/cdc_2phase.sv
verilator_srcs += $(vendor_src_dir)/spill_register_flushable.sv
verilator_srcs += $(vendor_src_dir)/spill_register.sv
verilator_srcs += $(vendor_src_dir)/fifo_v1.sv
verilator_srcs += $(vendor_src_dir)/fifo_v2.sv
verilator_srcs += $(vendor_src_dir)/stream_delay.sv
verilator_srcs += $(vendor_src_dir)/lfsr_16bit.sv
verilator_srcs += $(vendor_src_dir)/delta_counter.sv
verilator_srcs += $(vendor_src_dir)/rr_arb_tree.sv
verilator_srcs += $(vendor_src_dir)/lzc.sv
verilator_srcs += $(vendor_src_dir)/fifo_v3.sv
verilator_srcs += $(vendor_src_dir)/counter.sv
verilator_srcs += $(vendor_src_dir)/axi_intf.sv
verilator_srcs += $(vendor_src_dir)/axi_cut.sv
verilator_srcs += $(vendor_src_dir)/axi_join.sv
verilator_srcs += $(vendor_src_dir)/axi_delayer.sv
verilator_srcs += $(vendor_src_dir)/axi_to_axi_lite.sv
verilator_srcs += $(vendor_src_dir)/axi_id_prepend.sv
verilator_srcs += $(vendor_src_dir)/axi_atop_filter.sv
verilator_srcs += $(vendor_src_dir)/axi_err_slv.sv
verilator_srcs += $(vendor_src_dir)/axi_mux.sv
verilator_srcs += $(vendor_src_dir)/axi_demux.sv
verilator_srcs += $(vendor_src_dir)/axi_xbar.sv
verilator_srcs += $(vendor_src_dir)/axi_lite_to_axi.sv
verilator_srcs += $(vendor_src_dir)/reg_intf.sv
verilator_srcs += $(vendor_src_dir)/axi2apb_64_32.sv
verilator_srcs += $(vendor_src_dir)/apb_to_reg.sv
verilator_srcs += $(vendor_src_dir)/axi_ar_buffer.sv
verilator_srcs += $(vendor_src_dir)/axi_aw_buffer.sv
verilator_srcs += $(vendor_src_dir)/axi_b_buffer.sv
verilator_srcs += $(vendor_src_dir)/axi_r_buffer.sv
verilator_srcs += $(vendor_src_dir)/axi_single_slice.sv
verilator_srcs += $(vendor_src_dir)/axi_slice.sv
verilator_srcs += $(vendor_src_dir)/axi_w_buffer.sv
verilator_srcs += $(vendor_src_dir)/axi_to_mem.sv
verilator_srcs += $(vendor_src_dir)/axi_multicut.sv
verilator_srcs += $(vendor_src_dir)/axi_demux_simple.sv
verilator_srcs += $(vendor_src_dir)/axi2mem.sv


# Note: A useful command for managing sources (example):
# $(filter-out %_pkg.sv, $(wildcard rtl/vendor/pulp-platform/common_cells/src/*.sv))

############# Verilate command #############
verilator_cpp_testbench = rtl/axi_cgra_module/verilator_cpp/cpp_testbench.cpp

verilate_command = 	$(VERILATOR) --no-timing --assert
verilate_command +=	-Wall --trace -cc
verilate_command +=	$(verilator_src_pkgs)
verilate_command +=	$(verilator_srcs)
verilate_command +=	--top-module $(TOP_MODULE)
verilate_command += 	$(foreach dir, ${verilator_inc_dirs}, +incdir+$(dir))

verilate_command +=	--exe $(verilator_cpp_testbench)

verilate_command += -Werror-PINMISSING      \
                    -Werror-IMPLICIT        \
                    -Wno-fatal              \
                    -Wno-PINCONNECTEMPTY    \
                    -Wno-ASSIGNDLY          \
                    -Wno-DECLFILENAME       \
                    -Wno-UNUSED             \
                    -Wno-UNOPTFLAT          \
                    -Wno-BLKANDNBLK	    \
		    -Wno-GENUNNAMED	    \
		    -Wno-WIDTHEXPAND	    \
		    -Wno-WIDTHTRUNC	    \
		    -Wno-CASEINCOMPLETE	    \
		    -Wno-WIDTHCONCAT	    \
		    -Wno-ASCRANGE	    \
		    -Wno-SYNCASYNCNET

.stamp.verilate: $(verilator_srcs) $(verilator_cpp_testbench)
	@echo "### VERILATING ###"
	$(verilate_command) -j $(shell nproc)
# Useful for debugging:
# -CFLAGS '-DVL_DEBUG -ggdb'
# -CFLAGS '-DVL_DEBUG -ggdb' --debug --gdbbt
	@echo "### BUILDING ###"
	$(MAKE) -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE) -j $(shell nproc)
	@touch .stamp.verilate

waveform.vcd: .stamp.verilate # Because we verilate and build at once.
	@echo "### RUNNING ###"
	./obj_dir/V$(TOP_MODULE)

.PHONY:waves
waves: waveform.vcd
	$(GTKWAVE) waveform.vcd gtkwave_config/gtkwave_waveform_setup.gtkw --rcvar 'fontname_signals Monospace 10' --rcvar 'fontname_waves Monospace 10'

.PHONY:lint
lint: $(verilator_srcs)
	$(verilate_command) --lint-only

.PHONY:clean
clean:
	rm -rf ./obj_dir
	rm -rf waveform.vcd
	rm -rf .stamp.*







