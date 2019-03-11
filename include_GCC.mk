CC  = gcc
LINKER = $(CC)

OPENMP   = # -fopenmp
CFLAGS   = -Ofast -std=c11 $(OPENMP)
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
