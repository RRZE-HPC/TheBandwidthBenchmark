CC  = icc
LINKER = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -qopenmp
endif

CFLAGS   = -DLIKWID -DLIKWID_PERFMON -Ofast -xHost -std=c99 -ffreestanding $(OPENMP) $(LIKWID_INC)
LFLAGS   = $(OPENMP) $(LIKWID_LIB) -llikwid
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
