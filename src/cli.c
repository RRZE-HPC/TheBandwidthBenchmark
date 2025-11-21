
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "cli.h"

int Type            = WS;
int Seq             = 0;
int DataInitVariant = 0;
size_t N            = 125000000ULL;
size_t Iter         = 10;

#ifdef _NVCC
int CUDA_DEVICE             = 0;
int THREAD_BLOCK_PER_SM     = 1024;
int THREAD_BLOCK_SIZE       = 2;
int THREAD_BLOCK_SIZE_SET   = 0;
int THREAD_BLOCK_PER_SM_SET = 0;
#endif

void parseArguments(int argc, char **argv)
{
  int co;
  opterr = 0;

  while ((co = getopt(argc, argv, "hm:s:n:i:d:p:t:b:")) != -1) {
    switch (co) {
    case 'h': {
      printf(HELPTEXT);
      exit(EXIT_SUCCESS);
      break;
    }

    case 'm': {
      if (strcmp(optarg, "ws") == 0) {
        Type = WS;
      } else if (strcmp(optarg, "tp") == 0) {
        Type = TP;
        Seq  = 0;
      } else if (strcmp(optarg, "seq") == 0) {
        Type = SQ;
        Seq  = 1;
      } else {
        printf("Unknown bench type %s\n", optarg);
        exit(1);
      }
      break;
    }

    case 's': {
      char *end;
      errno = 0;
      N     = strtol(optarg, &end, 10);
      if (*end != '\0' || errno != 0) {
        fprintf(stderr, "Invalid numeric value for -s: %s\n", optarg);
        exit(1);
      }
      break;
    }

    case 'n': {
      char *end;
      errno = 0;
      Iter  = strtol(optarg, &end, 10);
      if (*end != '\0' || errno != 0) {
        fprintf(stderr, "Invalid numeric value for -n: %s\n", optarg);
        exit(1);
      }
      break;
    }

    case 'i': {
      if (strcmp(optarg, "constant") == 0) {
        DataInitVariant = 0;
      } else if (strcmp(optarg, "random") == 0) {
        DataInitVariant = 1;
      } else {
        printf("Invalid data initialization type %s\n", optarg);
        exit(1);
      }
      break;
    }

#ifdef _NVCC
    case 'd': {
      char *end;
      errno          = 0;
      const long val = strtol(optarg, &end, 10);
      if (*end != '\0' || errno != 0 || val < 0 || val > INT_MAX) {
        fprintf(stderr, "Invalid CUDA device ID: %s\n", optarg);
        exit(1);
      }
      CUDA_DEVICE = (int)val;

      break;
    }

    case 't': {
      char *end;
      errno          = 0;
      const long val = strtol(optarg, &end, 10);
      if (*end != '\0' || errno != 0 || val < 0 || val > INT_MAX) {
        fprintf(stderr, "Invalid Thread Block Size: %s\n", optarg);
        exit(1);
      }
      THREAD_BLOCK_SIZE     = (int)val;
      THREAD_BLOCK_SIZE_SET = 1;
      break;
    }

    case 'b': {
      char *end;
      errno          = 0;
      const long val = strtol(optarg, &end, 10);
      if (*end != '\0' || errno != 0 || val < 0 || val > INT_MAX) {
        fprintf(stderr, "Invalid Thread Blocks per SM: %s\n", optarg);
        exit(1);
      }
      THREAD_BLOCK_PER_SM     = (int)val;
      THREAD_BLOCK_PER_SM_SET = 1;
      break;
    }
#endif

    case '?': {
      if (optopt == 'c') {
        fprintf(stderr, "Option -%c requires an argument.\n", optopt);
      } else if (isprint(optopt)) {
        fprintf(stderr, "Unknown option `-%c'.\n", optopt);
      } else
        fprintf(stderr, "Unknown option character `\\x%x'.\n", optopt);
      exit(1);
    }

    default:
      abort();
    }
  }

  for (int index = optind; index < argc; index++) {
    printf("Non-option argument %s\n", argv[index]);
  }
}
