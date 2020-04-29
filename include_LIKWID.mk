LIKWID_INC ?= -I/usr/local/include
LIKWID_DEFINES ?= -DLIKWID_PERFMON
LIKWID_LIB ?= -L/usr/local/lib

ifeq ($(strip $(ENABLE_LIKWID)),true)
INCLUDES += ${LIKWID_INC}
DEFINES +=  ${LIKWID_DEFINES}
LIBS += -llikwid
LFLAGS += ${LIKWID_LIB}
endif
