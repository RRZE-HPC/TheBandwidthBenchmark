
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

int CUDA_DEVICE    = 0;
int type           = WS;
int _SEQ           = 0;
int data_init_type = 0;
size_t N           = 125000000ull;
size_t ITERS       = 10;

void parseCLI(int argc, char **argv)
{
  int co;
  opterr = 0;

  while ((co = getopt(argc, argv, "hm:s:n:i:d:")) != -1)
    switch (co) {
    case 'h': {
      printf(HELPTEXT);
      exit(EXIT_SUCCESS);
      break;
    }

    case 'm': {
      if (strcmp(optarg, "ws") == 0)
        type = WS;
      else if (strcmp(optarg, "tp") == 0) {
        type = TP;
        SEQ  = 0;
      } else if (strcmp(optarg, "seq") == 0) {
        type = SQ;
        SEQ  = 1;
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
      ITERS = strtol(optarg, &end, 10);
      if (*end != '\0' || errno != 0) {
        fprintf(stderr, "Invalid numeric value for -n: %s\n", optarg);
        exit(1);
      }
      break;
    }

    case 'i': {
      if (strcmp(optarg, "constant") == 0)
        data_init_type = 0;
      else if (strcmp(optarg, "random") == 0) {
        data_init_type = 1;
      } else {
        printf("Invalid data initialization type %s\n", optarg);
        exit(1);
      }
      break;
    }

    case 'd': {
      char *end;
      errno          = 0;
      const long val = strtol(optarg, &end, 10);
      if (*end != '\0' || errno != 0 || val < 0 || val > INT_MAX) {
        fprintf(stderr, "Invalid CUDA device ID: %s\n", optarg);
        exit(1);
      }
#ifdef _NVCC
      CUDA_DEVICE = (int)val;
#endif

      break;
    }

    case '?': {
      if (optopt == 'c')
        fprintf(stderr, "Option -%c requires an argument.\n", optopt);
      else if (isprint(optopt))
        fprintf(stderr, "Unknown option `-%c'.\n", optopt);
      else
        fprintf(stderr, "Unknown option character `\\x%x'.\n", optopt);
      exit(1);
    }

    default:
      abort();
    }

  for (int index = optind; index < argc; index++) {
    printf("Non-option argument %s\n", argv[index]);
  }
}
