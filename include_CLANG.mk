CC   = clang
GCC  = gcc
LINKER = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -fopenmp
endif

VERSION  = --version
CFLAGS   = -Ofast -std=c99 $(OPENMP)
#CFLAGS   = -Ofast -fnt-store=aggressive  -std=c99 $(OPENMP) #AMD CLANG
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
