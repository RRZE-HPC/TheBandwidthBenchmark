CC  = icc
LINKER = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -qopenmp
endif

CFLAGS   = -qopt-report -Ofast -xHost -std=c99 -ffreestanding -pthread $(OPENMP)
LFLAGS   = -pthread $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
