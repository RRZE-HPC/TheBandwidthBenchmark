CC  = clang
LINKER = $(CC)

OPENMP   = #-fopenmp
CFLAGS   = -Ofast -std=c99 -pthread $(OPENMP)
LFLAGS   = -pthread $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
