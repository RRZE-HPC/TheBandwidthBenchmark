#!/usr/bin/env perl
# =======================================================================================
#
#      Author:   Jan Eitzinger (je), jan.eitzinger@fau.de
#      Copyright (c) 2020 RRZE, University Erlangen-Nuremberg
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

my $DIR = $ARGV[0];
my %RES;

my @testcases = ('Init', 'Sum', 'Copy', 'Update', 'Triad',  'Daxpy', 'STriad', 'SDaxpy');

while( defined( my $file = glob($DIR . '/*' ) ) ) {

    my $nt = 1;
    open(my $fh, "<","$file");
    if ($file =~ /.*-([0-9]+)\.txt/) {
        $nt = $1;
    }
    $RES{$nt} = {};

    while ( <$fh> ) {
        my $cnt = split(/[ ]+/, $_);

        if ( $cnt == 6 ) {
            my @fields = split(/[ ]+/, $_);

            if ( $fields[1] =~ /[0-9]+/ ) {
                $fields[0] =~ s/://;
                $RES{$nt}->{$fields[0]} = $fields[1];
            }
        }

    }

    close $fh or die "can't close file $!";
}

printf "#nt";
foreach my $test ( @testcases ) {
    printf "\t%s", $test;
}
printf "\n";

foreach my $key (sort {$a <=> $b} keys %RES) {
    printf "%d", $key;

    foreach my $test ( @testcases ) {
        printf "\t%.0f", $RES{$key}->{$test};
    }
    printf "\n";
}
