CC  = icc
LINKER = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -qopenmp
endif

CFLAGS   = -Ofast -xhost -std=c99 -pthread $(OPENMP)
LFLAGS   = -pthread $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
