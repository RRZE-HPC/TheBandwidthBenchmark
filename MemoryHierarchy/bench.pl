#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

if ( $#ARGV < 2 ){
    print "Usage: ./bench.pl <numcores> <seq|tp|ws> <SMT>\n";
    exit;
}

my $numCores = $ARGV[0];
my $type =  0;
my $SMT = $ARGV[2] ? $ARGV[2] : 2;
my $N = 100;


if ( $ARGV[1] eq 'seq' ){
    $type = 0;
} elsif (  $ARGV[1] eq 'tp'  ){
    $type = 1;
} elsif (  $ARGV[1] eq 'ws'  ){
    $type = 2;
}

print("# striad $numCores $SMT $ARGV[1]\n");
while ( $N < 8000000 ) {
    my $result;
    my $performance = '0.00';

    while ( $performance eq '0.00' ){
        $result =  `likwid-pin -c E:S0:$numCores:1:$SMT -q ./striad $type $N`;
        $result =~ /([0-9.]+) ([0-9.]+)/;
        $performance = $2;
    }

    print $result;
    $N = int($N * 1.2);
}
