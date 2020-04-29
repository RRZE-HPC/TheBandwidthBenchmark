#!/usr/bin/env perl

# =======================================================================================
#
#      Author:   Jan Eitzinger (je), jan.eitzinger@fau.de
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

use strict;
use warnings;
use utf8;

my $CMD = $ARGV[0];
my @N =  split /-/, $ARGV[1];
my $R = $ARGV[2];
my $MAX = 0; my $CORES = 0; my $BENCH = '';
my $SMT = $ARGV[3] ? $ARGV[3] : 2;

foreach my $numcores ( $N[0] ... $N[1] ) {
    foreach ( 1 ... $R ) {
        foreach my $ln ( split /\n/, `likwid-pin -c E:S0:$numcores:1:$SMT $CMD` ){
            if ( $ln =~ /^([A-Za-z]+):[ ]+([0-9.]+) /) {
                if ( $MAX < $2 ){
                    $MAX = $2; $CORES = $numcores; $BENCH = $1;
                }
            }
        }
    }
}
print "$BENCH was best using $CORES threads: $MAX\n";
