#!/usr/bin/env perl
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
