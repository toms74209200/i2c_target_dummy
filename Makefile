# Project
PROJECT = I2C_TARGET_IF
# Directory
QUARTUS_DIR = /mnt/d/intelFPGA_lite/17.1
QUARTUS_BIN_DIR = $(QUARTUS_DIR)/quartus/bin64
MODELSIM_BIN_DIR = $(QUARTUS_DIR)/modelsim_ase/win32aloem
PLD_DIR = ./pld
PRG_DIR = ./output_files
TB_DIR = ./testbench

PRG = $(PRG_DIR)/$(PROJECT).sof
TB_SRC = $(TB_DIR)/TB_$(PROJECT).sv

MODELSIM_LIB_FLAGS = -work work
MODELSIM_SIM_FLAGS = -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"
MODELSIM_DO_FLAGS = -do "add wave -unsigned *; \
					view structure; \
					view signals; \
					run -all"

lib_exist := $(shell find -maxdepth 1 -name rtl_work -type d)

all: clean $(PRG) check

clean:
	rm -rf ./output_files
	rm -rf ./rtl_work

$(PRG) : $(PLD_DIR)/*.vhd
	$(QUARTUS_BIN_DIR)/quartus_sh.exe --flow compile $(PROJECT)

check: ./rtl_work/
	$(MODELSIM_BIN_DIR)/vmap.exe work rtl_work
#	$(MODELSIM_BIN_DIR)/vcom.exe -93 $(MODELSIM_LIB_FLAGS) $(PLD_DIR)/PAC_*.vhd
	$(MODELSIM_BIN_DIR)/vcom.exe -93 $(MODELSIM_LIB_FLAGS) $(PLD_DIR)/*.vhd
	$(MODELSIM_BIN_DIR)/vlog.exe -sv $(MODELSIM_LIB_FLAGS) +incdir+$(TB_DIR) $(TB_SRC)
	$(MODELSIM_BIN_DIR)/vsim.exe $(MODELSIM_SIM_FLAGS) -msgmode both -displaymsgmode both TB_$(PROJECT) $(MODELSIM_DO_FLAGS)

./rtl_work/: $(TB_SRC)
	$(if $(lib_exist),$(MODELSIM_BIN_DIR)/vdel.exe -lib rtl_work -all)
	$(MODELSIM_BIN_DIR)/vlib.exe rtl_work

.PHONY: all check