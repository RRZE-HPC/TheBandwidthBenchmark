CC   = icc
LD = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -qopenmp
endif

VERSION  = --version
CFLAGS   =  -fast -xHost -qopt-streaming-stores=always -std=c99 -ffreestanding $(OPENMP)
LFLAGS   = $(OPENMP) -lpthread
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
