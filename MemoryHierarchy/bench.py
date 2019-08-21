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

default_regex = "([0-9.]+) ([0-9.]+)"
default_smt = 2
striad_types = {"seq" : 0,
                 "tp" : 1,
                 "ws" : 2
               }
start_N = 100
max_N = 8000000
scale_N = 1.2

if len(sys.argv) < 3 or len(sys.argv) > 4:
    print("Usage: {} <numcores> <seq|tp|ws> (<smt>)".format(sys.argv[0]))
    print("Default <smt> value is {}".format(default_smt))
    sys.exit(1)

numcores = int(sys.argv[1])
striad_type = sys.argv[2]
striad_t = 0
if striad_type in striad_types:
    striad_t = striad_types.get(striad_type)
else:
    print("Invalid type for striad. Available types: {}".format(", ".join(striad_types.keys())))
    sys.exit(1)
smt = int(sys.argv[3]) if len(sys.argv) == 4 else default_smt

print("# striad {} {} {}".format(numcores, smt, striad_type))

N = start_N
while N < max_N:
    performance = 0
    result = None
    runcmd = "likwid-pin -c E:S0:{}:1:{} -q ./striad {} {}".format(numcores, smt,
                                                                   striad_t, N)
    while performance == 0:
        p = subprocess.Popen(runcmd, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT,
                                     shell=True)
        p.wait()
        if p.returncode == 0:
            result = p.stdout.read().decode('utf-8').strip()
            m = re.search(default_regex, result)
            if m:
                performance = float(m.group(2))
        else:
            print("Execution failed: {}".format(runcmd))
            break
    print(result)
    sys.stdout.flush()
    N = int(N * scale_N)
