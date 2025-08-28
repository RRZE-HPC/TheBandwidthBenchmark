/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifdef __cplusplus
extern "C" {
#endif


void initArrays(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], const size_t N);

double init_wrapper(double *__restrict__ b[], int scalar, size_t N);
double copy_wrapper(double *__restrict__ c[], double *__restrict__ a[], size_t N);
double sum_wrapper(double *__restrict__ a[], size_t N);
double update_wrapper(double *__restrict__ a[], int scalar, size_t N);
double triad_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], int scalar, size_t N);
double daxpy_wrapper(double *__restrict__ a[], double *__restrict__ b[], int scalar, size_t N);
double striad_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N);
double sdaxpy_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], size_t N);

double init_seq_wrapper(double *__restrict__ b[], int scalar, size_t N, int iter);
double copy_seq_wrapper(double *__restrict__ c[], double *__restrict__ a[], size_t N, int iter);
double sum_seq_wrapper(double *__restrict__ a[], size_t N, int iter);
double update_seq_wrapper(double *__restrict__ a[], int scalar, size_t N, int iter);
double triad_seq_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], int scalar, size_t N, int iter);
double daxpy_seq_wrapper(double *__restrict__ a[], double *__restrict__ b[], int scalar, size_t N, int iter);
double striad_seq_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N, int iter);
double sdaxpy_seq_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], size_t N, int iter);

double init_tp_wrapper(double *__restrict__ b[], int scalar, size_t N, int iter);
double copy_tp_wrapper(double *__restrict__ c[], double *__restrict__ a[], size_t N, int iter);
double sum_tp_wrapper(double *__restrict__ a[], size_t N, int iter);
double update_tp_wrapper(double *__restrict__ a[], int scalar, size_t N, int iter);
double triad_tp_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], int scalar, size_t N, int iter);
double daxpy_tp_wrapper(double *__restrict__ a[], double *__restrict__ b[], int scalar, size_t N, int iter);
double striad_tp_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], double *__restrict__ d[], size_t N, int iter);
double sdaxpy_tp_wrapper(double *__restrict__ a[], double *__restrict__ b[], double *__restrict__ c[], size_t N, int iter);

void setBlockSize();
int getSharedMemSize(int thread_block_size, int thread_blocks_per_sm, const void* func);

#ifdef __cplusplus
}
#endif