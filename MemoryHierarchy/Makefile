#CONFIGURE TOOL CHAIN
CC  = gcc
OPENMP   =# -fopenmp
#CFLAGS   = -O3 -xHost -qopt-zmm-usage=high -std=c99 $(OPENMP)
CFLAGS   = -O3 -std=c99 $(OPENMP)
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
#DEFINES += -DVERBOSE
#DEFINES += -DLIKWID_PERFMON
DEFINES += -DNTIMES=5
DEFINES += -DARRAY_ALIGNMENT=64

#CONFIGURE BUILD SYSTEM
TARGET	   = striad
BUILD_DIR  = ./build
SRC_DIR    = ./src
INCLUDES  += -I./src/

#DO NOT EDIT BELOW
VPATH     = $(SRC_DIR)
ASM       = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.s,$(wildcard $(SRC_DIR)/*.c))
OBJ       = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o,$(wildcard $(SRC_DIR)/*.c))
CPPFLAGS := $(CPPFLAGS) $(DEFINES) $(INCLUDES)

${TARGET}: $(BUILD_DIR) $(OBJ)
	${CC} ${LFLAGS} -o $(TARGET) $(OBJ) $(LIBS)

asm:  $(BUILD_DIR) $(ASM)

$(BUILD_DIR)/%.o:  %.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(BUILD_DIR)/%.s:  %.c
	$(CC) -S $(CPPFLAGS) $(CFLAGS) $< -o $@

$(BUILD_DIR):
	@mkdir $(BUILD_DIR)

.PHONY: clean

clean:
	@echo "===>  CLEAN"
	@rm -rf $(BUILD_DIR)
	@rm -f $(TARGET)

