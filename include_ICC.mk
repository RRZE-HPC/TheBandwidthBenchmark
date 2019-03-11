CC  = icc
LINKER = $(CC)

OPENMP   = -qopenmp
CFLAGS   = -Ofast -xhost -std=c11 $(OPENMP)
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
