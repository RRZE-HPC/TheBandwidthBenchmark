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
MAKE_DIR   = ./mk
Q         ?= @

#DO NOT EDIT BELOW
include config.mk
include $(MAKE_DIR)/include_$(TOOLCHAIN).mk
include $(MAKE_DIR)/include_LIKWID.mk
INCLUDES  += -I$(SRC_DIR)/includes -I$(BUILD_DIR)

VPATH     = $(SRC_DIR)
ASM       = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.s,$(wildcard $(SRC_DIR)/*.c))
OBJ       = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR)/*.c))
SRC       =  $(wildcard $(SRC_DIR)/*.h $(SRC_DIR)/*.c)
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
	$(info ===>  COMPILE  $@)
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
	$(Q)$(CC) $(CPPFLAGS) -MT $(@:.d=.o) -MM  $< > $(BUILD_DIR)/$*.d

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
	@if test -f "./dat/Init.dat"; then gnuplot ./gnuplot_scripts/Init.gp; fi;
	@if test -f "./dat/Copy.dat"; then gnuplot ./gnuplot_scripts/Copy.gp; fi;
	@if test -f "./dat/Sum.dat"; then gnuplot ./gnuplot_scripts/Sum.gp; fi;
	@if test -f "./dat/Update.dat"; then gnuplot ./gnuplot_scripts/Update.gp; fi;
	@if test -f "./dat/Triad.dat"; then gnuplot ./gnuplot_scripts/Triad.gp; fi;
	@if test -f "./dat/STriad.dat"; then gnuplot ./gnuplot_scripts/STriad.gp; fi;
	@if test -f "./dat/Daxpy.dat"; then gnuplot ./gnuplot_scripts/Daxpy.gp; fi;
	@if test -f "./dat/SDaxpy.dat"; then gnuplot ./gnuplot_scripts/SDaxpy.gp; fi;
	@gnuplot ./gnuplot_scripts/Combined.gp;

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
