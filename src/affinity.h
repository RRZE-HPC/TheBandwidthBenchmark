/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef AFFINITY_H
#define AFFINITY_H

#ifdef _OPENMP

extern int affinity_getProcessorId();
extern void affinity_pinProcess(int);
extern void affinity_pinThread(int);
extern void affinity_getmask(void);

#endif /*_OPENMP*/

#endif /*AFFINITY_H*/
