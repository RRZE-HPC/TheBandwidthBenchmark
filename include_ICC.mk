CC  = icc
LINKER = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -qopenmp
endif

CFLAGS   = -Ofast -xHost -std=c99 -ffreestanding $(OPENMP)
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
