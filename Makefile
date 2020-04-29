#=======================================================================================
#
#     Author:   Jan Eitzinger (je), jan.eitzinger@fau.de
#     Copyright (c) 2019 RRZE, University Erlangen-Nuremberg
#
#     Permission is hereby granted, free of charge, to any person obtaining a copy
#     of this software and associated documentation files (the "Software"), to deal
#     in the Software without restriction, including without limitation the rights
#     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#     copies of the Software, and to permit persons to whom the Software is
#     furnished to do so, subject to the following conditions:
#
#     The above copyright notice and this permission notice shall be included in all
#     copies or substantial portions of the Software.
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#     SOFTWARE.
#
#=======================================================================================

#CONFIGURE BUILD SYSTEM
TARGET	   = bwbench-$(TAG)
BUILD_DIR  = ./$(TAG)
SRC_DIR    = ./src
MAKE_DIR   = ./
Q         ?= @

#DO NOT EDIT BELOW
include $(MAKE_DIR)/config.mk
include $(MAKE_DIR)/include_$(TAG).mk
include $(MAKE_DIR)/include_LIKWID.mk
INCLUDES  += -I./src/includes

VPATH     = $(SRC_DIR)
ASM       = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.s,$(wildcard $(SRC_DIR)/*.c))
ASM      += $(patsubst $(SRC_DIR)/%.f90, $(BUILD_DIR)/%.s,$(wildcard $(SRC_DIR)/*.f90))
OBJ       = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR)/*.c))
OBJ      += $(patsubst $(SRC_DIR)/%.cc, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR)/*.cc))
OBJ      += $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR)/*.cpp))
OBJ      += $(patsubst $(SRC_DIR)/%.f90, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR)/*.f90))
OBJ      += $(patsubst $(SRC_DIR)/%.F90, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR)/*.F90))
CPPFLAGS := $(CPPFLAGS) $(DEFINES) $(OPTIONS) $(INCLUDES)


${TARGET}: $(BUILD_DIR) $(OBJ)
	@echo "===>  LINKING  $(TARGET)"
	$(Q)${LINKER} ${LFLAGS} -o $(TARGET) $(OBJ) $(LIBS)

asm:  $(BUILD_DIR) $(ASM)

$(BUILD_DIR)/%.o:  %.c
	@echo "===>  COMPILE  $@"
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@
	$(Q)$(GCC) $(CPPFLAGS) -MT $(@:.d=.o) -MM  $< > $(BUILD_DIR)/$*.d

$(BUILD_DIR)/%.s:  %.c
	@echo "===>  GENERATE ASM  $@"
	$(CC) -S $(CPPFLAGS) $(CFLAGS) $< -o $@

$(BUILD_DIR)/%.s:  %.f90
	@echo "===>  COMPILE  $@"
	$(Q)$(FC) -S  $(FCFLAGS) $< -o $@

$(BUILD_DIR)/%.o:  %.cc
	@echo "===>  COMPILE  $@"
	$(Q)$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@
	$(Q)$(CXX) $(CPPFLAGS) -MT $(@:.d=.o) -MM  $< > $(BUILD_DIR)/$*.d

$(BUILD_DIR)/%.o:  %.cpp
	@echo "===>  COMPILE  $@"
	$(Q)$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@
	$(Q)$(CXX) $(CPPFLAGS) -MT $(@:.d=.o) -MM  $< > $(BUILD_DIR)/$*.d

$(BUILD_DIR)/%.o:  %.f90
	@echo "===>  COMPILE  $@"
	$(Q)$(FC) -c  $(FCFLAGS) $< -o $@

$(BUILD_DIR)/%.o:  %.F90
	@echo "===>  COMPILE  $@"
	$(Q)$(FC) -c  $(CPPFLAGS)  $(FCFLAGS) $< -o $@

tags:
	@echo "===>  GENERATE  TAGS"
	$(Q)ctags -R

$(BUILD_DIR):
	@mkdir $(BUILD_DIR)

ifeq ($(findstring $(MAKECMDGOALS),clean),)
-include $(OBJ:.o=.d)
endif

.PHONY: clean distclean

clean:
	@echo "===>  CLEAN"
	@rm -rf $(BUILD_DIR)
	@rm -f tags

distclean: clean
	@echo "===>  DIST CLEAN"
	@rm -f $(TARGET)
	@rm -f tags

