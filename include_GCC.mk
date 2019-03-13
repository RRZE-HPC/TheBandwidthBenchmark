CC  = gcc
LINKER = $(CC)

OPENMP   = # -fopenmp
CFLAGS   = -Ofast -std=c11 -pthread $(OPENMP)
LFLAGS   = -pthread $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
