CC  = clang
LINKER = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -fopenmp
endif

CFLAGS   = -Ofast -ffreestanding -std=c99 -pthread $(OPENMP)
LFLAGS   = -pthread $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
