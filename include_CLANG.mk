CC  = clang
LINKER = $(CC)

OPENMP   = #-fopenmp
CFLAGS   = -Ofast -std=c99 $(OPENMP)
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
