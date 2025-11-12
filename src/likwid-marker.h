/* Copyright (C) NHR@FAU, University Erlangen-Nuremberg.
 * All rights reserved. This file is part of TheBandwidthBenchmark.
 * Use of this source code is governed by a MIT style
 * license that can be found in the LICENSE file. */
#ifndef LIKWID_MARKERS_H
#define LIKWID_MARKERS_H

#ifdef LIKWID_PERFMON
#include <likwid.h>
#define LIKWID_MARKER_INIT likwid_markerInit()
#define LIKWID_MARKER_THREADINIT likwid_markerThreadInit()
#define LIKWID_MARKER_SWITCH likwid_markerNextGroup()
#define LIKWID_MARKER_REGISTER(regionTag) likwid_markerRegisterRegion(regionTag)
#define LIKWID_MARKER_START(regionTag) likwid_markerStartRegion(regionTag)
#define LIKWID_MARKER_STOP(regionTag) likwid_markerStopRegion(regionTag)
#define LIKWID_MARKER_CLOSE likwid_markerClose()
#define LIKWID_MARKER_RESET(regionTag) likwid_markerResetRegion(regionTag)
#define LIKWID_MARKER_GET(regionTag, nevents, events, time, count)                       \
  likwid_markerGetRegion(regionTag, nevents, events, time, count)
#else /* LIKWID_PERFMON */
#define LIKWID_MARKER_INIT
#define LIKWID_MARKER_THREADINIT
#define LIKWID_MARKER_SWITCH
#define LIKWID_MARKER_REGISTER(regionTag)
#define LIKWID_MARKER_START(regionTag)
#define LIKWID_MARKER_STOP(regionTag)
#define LIKWID_MARKER_CLOSE
#define LIKWID_MARKER_GET(regionTag, nevents, events, time, count)
#define LIKWID_MARKER_RESET(regionTag)
#endif /* LIKWID_PERFMON */

#endif /*LIKWID_MARKERS_H*/
