CC   = nvcc
LD = $(CC)

# ifeq ($(ENABLE_OPENMP),true)
# OPENMP   = -fopenmp
# endif

VERSION   = --version
NVCCFLAGS = -gencode arch=compute_80,code=sm_80
NVCCFLAGS += -gencode arch=compute_86,code=sm_86
NVCCFLAGS += -gencode arch=compute_90a,code=sm_90a 
NVCCFLAGS += -Xcompiler -rdynamic --generate-line-info -Wno-deprecated-gpu-targets
CPUFLAGS  = -O3 -pipe  $(OPENMP)
CFLAGS    = -O3 $(NVCCFLAGS) --compiler-options="$(CPUFLAGS)"
LFLAGS    = -lcuda
DEFINES   = -D_GNU_SOURCE
DEFINES   += -D_NVCC
INCLUDES  =
LIBS      =
