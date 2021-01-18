CC   = icc
GCC  = gcc
LINKER = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -qopenmp
endif

VERSION  = --version
CFLAGS   =  -fast -xHost -qopt-streaming-stores=always -std=c99 -ffreestanding $(OPENMP)
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
