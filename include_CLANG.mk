CC   = clang
GCC  = gcc
LINKER = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -Xpreprocessor -fopenmp
LIBS     = -lomp
endif

CFLAGS   = -Ofast -ffreestanding -std=c99 $(OPENMP)
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
