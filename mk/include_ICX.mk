CC   = icx
LD = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -qopenmp
endif

ifeq ($(ENABLE_LTO),true)
FAST_WORKAROUND = -ipo -O3 -static -fp-model=fast
else
FAST_WORKAROUND = -O3 -static -fp-model=fast
endif

VERSION  = --version
CFLAGS   = $(FAST_WORKAROUND) -xHost -qopt-streaming-stores=always -std=c99 -ffreestanding $(OPENMP)
LFLAGS   = $(OPENMP)
DEFINES  = -D_GNU_SOURCE
INCLUDES =
LIBS     =
