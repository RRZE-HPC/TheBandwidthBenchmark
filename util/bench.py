#!/usr/bin/env python3

# =======================================================================================
#
#      Author:   Thomas Gruber (tg), thomas.gruber@googlemail.com
#      Copyright (c) 2019 RRZE, University Erlangen-Nuremberg
#
#      Permission is hereby granted, free of charge, to any person obtaining a copy
#      of this software and associated documentation files (the "Software"), to deal
#      in the Software without restriction, including without limitation the rights
#      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#      copies of the Software, and to permit persons to whom the Software is
#      furnished to do so, subject to the following conditions:
#
#      The above copyright notice and this permission notice shall be included in all
#      copies or substantial portions of the Software.
#
#      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#      SOFTWARE.
#
# =======================================================================================

import sys, subprocess, re

default_regex = "^(\w+):\s+([\d\.]+)"
default_smt = 2

if len(sys.argv) < 4 or len(sys.argv) > 5:
    print("{} <command> <minthreads>-<maxthreads> <repeats> (<smt>)".format(sys.argv[0]))
    print("Default <smt> value is {}".format(default_smt))
    sys.exit(1)

cmd = str(sys.argv[1])
minthreads = maxthreads = 0
try:
    minthreads, maxthreads = sys.argv[2].split("-")
    minthreads = int(minthreads)
    maxthreads = int(maxthreads)
    if (minthreads == 0 or minthreads > maxthreads):
        print("Cannot use threads range values: {} {}".format(minthreads, maxthreads))
        sys.exit(1)
except:
    print("<minthreads>-<maxthreads> option not readable: {}".format(sys.argv[2]))
    sys.exit(1)
repeats = int(sys.argv[3])
smt = int(sys.argv[4]) if len(sys.argv) == 5 else default_smt

maximum = bestthreads = 0
bestkernel = "None"
for numthreads in range(int(minthreads), int(maxthreads)+1):
    runcmd = "likwid-pin -c E:S0:{}:1:{} {}".format(numthreads, smt, cmd)
    for rep in range(repeats):
        p = subprocess.Popen(runcmd, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT,
                                     shell=True)
        p.wait()
        if p.returncode == 0:
            lines = [ l for l in p.stdout.read().decode('utf-8').split("\n") ]
            for l in lines:
                m = re.search(default_regex, l)
                if m and maximum < float(m.group(2)):
                    maximum = float(m.group(2))
                    bestthreads = numthreads
                    bestkernel = m.group(1)
        else:
            print("Execution failed: {}".format(runcmd))

print("{} was best using {} threads: {}".format(bestkernel, bestthreads, maximum))
