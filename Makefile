# Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
# All rights reserved. This file is part of TheBandwidthBenchmark.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

#CONFIGURE BUILD SYSTEM
TARGET	   = bwbench-$(TOOLCHAIN)
BUILD_DIR  = ./build/$(TOOLCHAIN)
DATA_DIR   = ./dat
PLOTS_DIR  = ./plots
SRC_DIR    = ./src
CPU_DIR    = $(SRC_DIR)/cpu
GPU_DIR    = $(SRC_DIR)/gpu
MAKE_DIR   = ./mk
Q         ?= @

#DO NOT EDIT BELOW
include config.mk
include $(MAKE_DIR)/include_$(TOOLCHAIN).mk
include $(MAKE_DIR)/include_LIKWID.mk
INCLUDES  += -I$(SRC_DIR)/includes -I$(BUILD_DIR) -I$(CPU_DIR) -I$(GPU_DIR)

MAIN_SRC := $(SRC_DIR)/main.c
CPU_SRC  := $(wildcard $(CPU_DIR)/*.c)
GPU_SRC  := $(wildcard $(GPU_DIR)/*.cu $(GPU_DIR)/*.c)

SRC :=
ifeq ($(TOOLCHAIN),NVCC)
    SRC := $(MAIN_SRC) $(GPU_SRC)
else
    SRC := $(MAIN_SRC) $(CPU_SRC)
endif

VPATH := $(SRC_DIR) $(CPU_DIR) $(GPU_DIR)
OBJ := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(SRC:%.c=%.o))
OBJ := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(OBJ:%.cu=%.o))

CPPFLAGS := $(CPPFLAGS) $(DEFINES) $(OPTIONS) $(INCLUDES)

c := ,
clist = $(subst $(eval) ,$c,$(strip $1))

define CLANGD_TEMPLATE
CompileFlags:
  Add: [$(call clist,$(CPPFLAGS)), $(call clist,$(CFLAGS)), -xc]
  Compiler: clang
endef

${TARGET}: $(BUILD_DIR) .clangd $(OBJ) $(DATA_DIR)
	$(info ===>  LINKING  $(TARGET))
	$(Q)${LD} ${LFLAGS} -o $(TARGET) $(OBJ) $(LIBS)

$(BUILD_DIR)/%.o:  %.c $(MAKE_DIR)/include_$(TOOLCHAIN).mk config.mk
	@mkdir -p $(dir $@)
	$(info ===>  COMPILE  $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
	$(Q)$(CC) $(CPPFLAGS) -MT $(@:.d=.o) -MM  $< > $(BUILD_DIR)/$*.d
	
# CUDA files
ifeq ($(TOOLCHAIN),NVCC)
$(BUILD_DIR)/%.o: %.cu 
	@mkdir -p $(dir $@)
	$(info ===>  COMPILE CUDA  $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
endif

$(BUILD_DIR)/%.s:  %.c
	$(info ===>  GENERATE ASM  $@)
	$(CC) -S $(CPPFLAGS) $(CFLAGS) $< -o $@

.PHONY: clean distclean info asm format data plots

clean:
	$(info ===>  CLEAN)
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DATA_DIR)
	@rm -rf $(PLOTS_DIR)

distclean:
	$(info ===>  DIST CLEAN)
	@rm -rf build
	@rm -f $(TARGET)
	@rm -f .clangd

info:
	$(info $(CFLAGS))
	$(Q)$(CC) $(VERSION)

asm:  $(BUILD_DIR) $(ASM)

$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

$(PLOTS_DIR):
	@mkdir -p $(PLOTS_DIR)

plot: $(PLOTS_DIR)
	@./gnuplot_scripts/array_size_vs_bandwidth_plot.sh

plot_dataset: $(PLOTS_DIR)
	@./gnuplot_scripts/dataset_size_vs_bandwidth_plot.sh

format:
	@for src in $(SRC) ; do \
		echo "Formatting $$src" ; \
		clang-format -i $$src ; \
	done
	@echo "Done"

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

.clangd:
	$(file > .clangd,$(CLANGD_TEMPLATE))

-include $(OBJ:.o=.d)
