CC   = nvcc
LD = $(CC)

ifeq ($(ENABLE_OPENMP),true)
OPENMP   = -fopenmp
endif

VERSION   = --version
NVCCFLAGS = -gencode arch=compute_80,code=sm_80
NVCCFLAGS += -gencode arch=compute_86,code=sm_86
NVCCFLAGS += -gencode arch=compute_90a,code=sm_90a 
NVCCFLAGS += -Xcompiler -rdynamic --generate-line-info -Wno-deprecated-gpu-targets
CPUFLAGS  = --compiler-options="-O3 -pipe -ffreestanding $(OPENMP)"
CFLAGS    = -O3 $(NVCCFLAGS) $(CPUFLAGS) 
LFLAGS    = -lcuda -lnvidia-ml -lgomp
DEFINES   = -D_GNU_SOURCE
DEFINES   += -D_NVCC
INCLUDES  =
LIBS      =
