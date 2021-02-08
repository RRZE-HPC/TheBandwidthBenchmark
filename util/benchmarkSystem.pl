#!/usr/bin/env perl
# =======================================================================================
#
#      Author:   Jan Eitzinger (je), jan.eitzinger@fau.de
#      Copyright (c) 2021 RRZE, University Erlangen-Nuremberg
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

use Data::Dumper qw(Dumper);

my ($DIR, $CMD, $PREFIX) = @ARGV;

if (not defined $DIR) {
  die "Usage: $0 <DATA-DIR> <EXE> <PREFIX>\n";
}

my %RES;
my %INFO;
my %RESULT;
my %PLOT;
my %DPLOT;

my @testcases = ('Init', 'Sum', 'Copy', 'Update', 'Triad',  'Daxpy', 'STriad', 'SDaxpy');

my $numDomainsPerSocket;
my $numDomainsPerNode;
my $numCoresPerMemoryDomain;
my $coresPerSocket;
my $SMT;

# Step 0 : Build benchmark
`rm  $DIR/raw/*`;
`rm  $DIR/*`;
`mkdir $DIR/raw`;
`make distclean`;
`make > $DIR/buildoutput.txt`;

# Step 1 : Extract system information
`likwid-topology -g > $DIR/topology.txt`;
my $topo = `likwid-topology -O`;

foreach my $ln (split("\n", $topo)) {
    if ( $ln =~ /^CPU name:/ ) {
        my @fields = split(",", $ln);
        $INFO{processor} = $fields[1];
    }
    if ( $ln =~ /^CPU type/ ) {
        my @fields = split(",", $ln);
        $INFO{family} = $fields[1];
	$INFO{family} =~ s/[\(\)]//g;
    }
    if ( $ln =~ /^Sockets:/ ) {
        my @fields = split(",", $ln);
        $INFO{numSockets} = $fields[1];
    }
    if ( $ln =~ /^Cores per socket:/ ) {
        my @fields = split(",", $ln);
        $INFO{numCoresPerSocket} = $fields[1];
    }
    if ( $ln =~ /^Threads per core:/ ) {
        my @fields = split(",", $ln);
        $SMT = $fields[1];
        $INFO{numThreadsPerCore} = $SMT;
    }
    if ( $ln =~ /^NUMA domains:/ ) {
        my @fields = split(",", $ln);
        $numDomainsPerNode = $fields[1];
    }
}

$INFO{family} =~ s/[ ]//g;

my $cinfo = `make info`;
# my $cinfo = do {
#     local $/ = undef;
#     open my $fh, "<", './toolchain.txt'
#         or die "could not open tile: $!";
#     <$fh>;
# };

my @tmp = split("\n", $cinfo);
$INFO{flags} =  $tmp[0];
my @tools = split(" ", $tmp[1]);
$INFO{toolchain} = $tools[0]. ' ' . $tools[1];
$INFO{version} = $tmp[1];

$numDomainsPerSocket =  $numDomainsPerNode / $INFO{numSockets};
$numDomainsPerNode = 2 * $numDomainsPerSocket;
$numCoresPerMemoryDomain = $INFO{numCoresPerSocket} / $numDomainsPerSocket;
my $TAG = $PREFIX."-S$INFO{numSockets}-M$numDomainsPerSocket-C$INFO{numCoresPerSocket}";
$INFO{numDomainsPerSocket} = $numDomainsPerSocket;

# Step 2 : Execute benchmark

foreach my $numdomains ( 1 ... $numDomainsPerNode ) {
    foreach my $numcores ( 1 ... $numCoresPerMemoryDomain ) {
        my $exp = join('@',map("E:M$_:$numcores:1:$SMT", 0 ... $numdomains-1));
        print "node-M$numdomains-$numcores\n";
        `likwid-pin -q -C $exp $CMD > $DIR/raw/node-M$numdomains-$numcores.txt`;
    }
}

# Step 3 : Generate output

extractResults();
$RESULT{core} = findMaxResult(1,1);
$RESULT{domain} = findMaxResult(1, $numCoresPerMemoryDomain);
$RESULT{socket} = findMaxResult($numDomainsPerSocket, $numCoresPerMemoryDomain);
$RESULT{node} = findMaxResult($numDomainsPerNode, $numCoresPerMemoryDomain);


$RESULT{scaling} = sprintf "#nt";
foreach my $test ( @testcases ) {
$RESULT{scaling} .= sprintf "\t%s", $test;
$PLOT{$test} = '';
}
$RESULT{scaling} .= sprintf "\n";

foreach my $key (sort {$a <=> $b} keys %{$RES{1}}) {
    $RESULT{scaling} .= sprintf "%d", $key;

    foreach my $test ( @testcases ) {
        $RESULT{scaling} .= sprintf "\t%.2f", $RES{1}{$key}{$test};
        $PLOT{$test} .= "$key $RES{1}{$key}{$test}\n";
    }
    $RESULT{scaling} .= sprintf "\n";
}

foreach my $nm ( 1 ... $numDomainsPerNode ) {
    my $tag = "s$nm";
    $DPLOT{meta} .=<<"END";
\@    $tag hidden false
\@    $tag type xy
\@    $tag symbol 1
\@    $tag symbol size 1.000000
\@    $tag symbol color $nm
\@    $tag symbol pattern 1
\@    $tag symbol fill color $nm
\@    $tag symbol fill pattern 1
\@    $tag symbol linewidth 1.0
\@    $tag symbol linestyle 1
\@    $tag symbol char 65
\@    $tag symbol char font 0
\@    $tag symbol skip 0
\@    $tag line type 1
\@    $tag line linestyle 1
\@    $tag line linewidth 4.0
\@    $tag line color $nm
\@    $tag line pattern 1
\@    $tag baseline type 0
\@    $tag baseline off
\@    $tag dropline off
\@    $tag fill type 0
\@    $tag fill rule 0
\@    $tag fill color 1
\@    $tag fill pattern 1
\@    $tag avalue off
\@    $tag avalue type 2
\@    $tag avalue char size 1.000000
\@    $tag avalue font 0
\@    $tag avalue color 1
\@    $tag avalue rot 0
\@    $tag avalue format general
\@    $tag avalue prec 3
\@    $tag avalue prepend ""
\@    $tag avalue append ""
\@    $tag avalue offset 0.000000 , 0.000000
\@    $tag errorbar on
\@    $tag errorbar place both
\@    $tag errorbar color $nm
\@    $tag errorbar pattern 1
\@    $tag errorbar size 1.000000
\@    $tag errorbar linewidth 1.0
\@    $tag errorbar linestyle 1
\@    $tag errorbar riser linewidth 1.0
\@    $tag errorbar riser linestyle 1
\@    $tag errorbar riser clip off
\@    $tag errorbar riser clip length 0.100000
\@    $tag legend  "$nm"
END

}

$RESULT{node} =~ /([0-9.]+)/;
my $ymax = $1 * 1.2;
$DPLOT{world} = "1, 0, $numCoresPerMemoryDomain,  $ymax";

foreach my $test ( @testcases ) {
    my %dplottmp;
    $RESULT{'domain'.$test} = sprintf "#nm";
    foreach my $nm ( 1 ... $numDomainsPerNode ) {
        $RESULT{'domain'.$test} .= sprintf "\t%d", $nm;
        $dplottmp{$nm} = '';
    }
    $RESULT{'domain'.$test} .= sprintf "\n";
    foreach my $nt ( 1 ... $numCoresPerMemoryDomain ) {
        $RESULT{'domain'.$test} .= sprintf "%d", $nt;
        foreach my $nm ( 1 ... $numDomainsPerNode ) {
            $RESULT{'domain'.$test} .= sprintf "\t%.2f", $RES{$nm}{$nt}{$test};
            $dplottmp{$nm} .=  "$nt $RES{$nm}{$nt}{$test}\n";
        }
        $RESULT{'domain'.$test} .= sprintf "\n";
    }

    $DPLOT{series} = '';
    foreach my $nm ( 1 ... $numDomainsPerNode ) {
        $DPLOT{series} .= "\@target G0.S$nm\n\@type xy\n";
        $DPLOT{series} .= $dplottmp{$nm};
        $DPLOT{series} .= "&\n";
    }
    generateDomainScalingPlot("$DIR/$TAG-domains$test.agr");
}

$RESULT{domain} =~ /([0-9]+\.)/;
$ymax = $1 * 1.2;

$RESULT{scalingPlot} = "figures/$TAG-scaling.png";
$RESULT{domainInitPlot} = "figures/$TAG-domainsInit.png";
$RESULT{domainSumPlot} = "figures/$TAG-domainsSum.png";
$RESULT{domainCopyPlot} = "figures/$TAG-domainsCopy.png";
$RESULT{domainTriadPlot} = "figures/$TAG-domainsTriad.png";
$PLOT{world} = "1, 0, $numCoresPerMemoryDomain,  $ymax";

generateMarkdown("$DIR/$TAG.md");
generateScalingPlot("$DIR/$TAG-scaling.agr");

open(my $fh, '>', "$DIR/max.dat") or die "Could not open file $!";
$RESULT{core} =~ /([0-9.]+)/;
print $fh "CORE $1\n";
$RESULT{socket} =~ /([0-9.]+)/;
print $fh "SOCKET $1\n";
$RESULT{node} =~ /([0-9.]+)/;
print $fh "NODE $1\n";
close $fh;

`tar -czf $TAG.tgz $DIR`;

# Helper routines
sub findMaxResult {
my $maxDomains = shift;
my $maxCores = shift;
my %param;
my $max = 0;

foreach my $numDomains ( 1 ... $maxDomains ) {
    foreach my $numCoresPerDomain ( 1 ... $maxCores ) {
        foreach my $testcase (keys %{$RES{$numDomains}{$numCoresPerDomain}}) {
            if ( $RES{$numDomains}{$numCoresPerDomain}{$testcase} > $max ){
                $max = sprintf "\t%.2f",$RES{$numDomains}{$numCoresPerDomain}{$testcase};
                $param{testcase} = $testcase;
                $param{cores} =  $numCoresPerDomain;
            }
        }
    }
}

if ($maxCores == 1) {
return "$max ($param{testcase})";
} else {
return "$max ($param{testcase} with $param{cores} cores)";
}
}

sub extractResults {

while( defined( my $file = glob($DIR . '/raw/*' ) ) ) {

    print "Process $file\n";
    my $nt = 1;
    my $nm = 1;

    open(my $fh, "<","$file");
    if ($file =~ /.*-M([0-9]+)-([0-9]+)\.txt/) {
        $nm = $1;
        $nt = $2;
    }
    # $RES{$nm}{$nt} = {};

    while ( <$fh> ) {
        my $cnt = split(/[ ]+/, $_);

        if ( $cnt == 6 ) {
            my @fields = split(/[ ]+/, $_);

            if ( $fields[1] =~ /[0-9]+/ ) {
                $fields[0] =~ s/://;
                $RES{$nm}{$nt}{$fields[0]} = $fields[1] * 0.001;
            }
        }

    }

    close $fh or die "can't close file $!";
}

}

sub generateScalingPlot {
my $filename = shift;
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

print $fh <<"END";
# Grace project file
#
\@version 50122
\@page size 792, 612
\@page scroll 5%
\@page inout 5%
\@link page off
\@map font 0 to "Times-Roman", "Times-Roman"
\@map font 1 to "Times-Italic", "Times-Italic"
\@map font 2 to "Times-Bold", "Times-Bold"
\@map font 3 to "Times-BoldItalic", "Times-BoldItalic"
\@map font 4 to "Helvetica", "Helvetica"
\@map font 5 to "Helvetica-Oblique", "Helvetica-Oblique"
\@map font 6 to "Helvetica-Bold", "Helvetica-Bold"
\@map font 7 to "Helvetica-BoldOblique", "Helvetica-BoldOblique"
\@map font 8 to "Courier", "Courier"
\@map font 9 to "Courier-Oblique", "Courier-Oblique"
\@map font 10 to "Courier-Bold", "Courier-Bold"
\@map font 11 to "Courier-BoldOblique", "Courier-BoldOblique"
\@map font 12 to "Symbol", "Symbol"
\@map font 13 to "ZapfDingbats", "ZapfDingbats"
\@map color 0 to (255, 255, 255), "white"
\@map color 1 to (0, 0, 0), "black"
\@map color 2 to (255, 0, 0), "red"
\@map color 3 to (0, 255, 0), "green"
\@map color 4 to (0, 0, 255), "blue"
\@map color 5 to (255, 255, 0), "yellow"
\@map color 6 to (188, 143, 143), "brown"
\@map color 7 to (220, 220, 220), "grey"
\@map color 8 to (148, 0, 211), "violet"
\@map color 9 to (0, 255, 255), "cyan"
\@map color 10 to (255, 0, 255), "magenta"
\@map color 11 to (255, 165, 0), "orange"
\@map color 12 to (114, 33, 188), "indigo"
\@map color 13 to (103, 7, 72), "maroon"
\@map color 14 to (64, 224, 208), "turquoise"
\@map color 15 to (0, 139, 0), "green4"
\@reference date 0
\@date wrap off
\@date wrap year 1950
\@default linewidth 1.0
\@default linestyle 1
\@default color 1
\@default pattern 1
\@default font 0
\@default char size 1.000000
\@default symbol size 1.000000
\@default sformat "%.8g"
\@background color 0
\@page background fill on
\@timestamp off
\@timestamp 0.03, 0.03
\@timestamp color 1
\@timestamp rot 0
\@timestamp font 0
\@timestamp char size 1.000000
\@timestamp def "Tue Dec 15 13:24:48 2020"
\@r0 off
\@link r0 to g0
\@r0 type above
\@r0 linestyle 1
\@r0 linewidth 1.0
\@r0 color 1
\@r0 line 0, 0, 0, 0
\@r1 off
\@link r1 to g0
\@r1 type above
\@r1 linestyle 1
\@r1 linewidth 1.0
\@r1 color 1
\@r1 line 0, 0, 0, 0
\@r2 off
\@link r2 to g0
\@r2 type above
\@r2 linestyle 1
\@r2 linewidth 1.0
\@r2 color 1
\@r2 line 0, 0, 0, 0
\@r3 off
\@link r3 to g0
\@r3 type above
\@r3 linestyle 1
\@r3 linewidth 1.0
\@r3 color 1
\@r3 line 0, 0, 0, 0
\@r4 off
\@link r4 to g0
\@r4 type above
\@r4 linestyle 1
\@r4 linewidth 1.0
\@r4 color 1
\@r4 line 0, 0, 0, 0
\@g0 on
\@g0 hidden false
\@g0 type XY
\@g0 stacked false
\@g0 bar hgap 0.000000
\@g0 fixedpoint off
\@g0 fixedpoint type 0
\@g0 fixedpoint xy 0.000000, 0.000000
\@g0 fixedpoint format general general
\@g0 fixedpoint prec 6, 6
\@with g0
\@    world $PLOT{world}
\@    stack world 0, 1, 0, 1
\@    znorm 1
\@    view 0.150000, 0.150000, 1.150000, 0.850000
\@    title ""
\@    title font 0
\@    title size 1.500000
\@    title color 1
\@    subtitle ""
\@    subtitle font 0
\@    subtitle size 1.000000
\@    subtitle color 1
\@    xaxes scale Normal
\@    yaxes scale Normal
\@    xaxes invert off
\@    yaxes invert off
\@    xaxis  on
\@    xaxis  type zero false
\@    xaxis  offset 0.000000 , 0.000000
\@    xaxis  bar on
\@    xaxis  bar color 1
\@    xaxis  bar linestyle 1
\@    xaxis  bar linewidth 1.0
\@    xaxis  label "number of cores"
\@    xaxis  label layout para
\@    xaxis  label place auto
\@    xaxis  label char size 1.500000
\@    xaxis  label font 0
\@    xaxis  label color 1
\@    xaxis  label place normal
\@    xaxis  tick on
\@    xaxis  tick major 1
\@    xaxis  tick minor ticks 0
\@    xaxis  tick default 6
\@    xaxis  tick place rounded true
\@    xaxis  tick in
\@    xaxis  tick major size 1.000000
\@    xaxis  tick major color 1
\@    xaxis  tick major linewidth 1.0
\@    xaxis  tick major linestyle 1
\@    xaxis  tick major grid off
\@    xaxis  tick minor color 1
\@    xaxis  tick minor linewidth 1.0
\@    xaxis  tick minor linestyle 1
\@    xaxis  tick minor grid off
\@    xaxis  tick minor size 0.500000
\@    xaxis  ticklabel on
\@    xaxis  ticklabel format general
\@    xaxis  ticklabel prec 5
\@    xaxis  ticklabel formula ""
\@    xaxis  ticklabel append ""
\@    xaxis  ticklabel prepend ""
\@    xaxis  ticklabel angle 0
\@    xaxis  ticklabel skip 0
\@    xaxis  ticklabel stagger 0
\@    xaxis  ticklabel place normal
\@    xaxis  ticklabel offset auto
\@    xaxis  ticklabel offset 0.000000 , 0.010000
\@    xaxis  ticklabel start type auto
\@    xaxis  ticklabel start 0.000000
\@    xaxis  ticklabel stop type auto
\@    xaxis  ticklabel stop 0.000000
\@    xaxis  ticklabel char size 1.250000
\@    xaxis  ticklabel font 0
\@    xaxis  ticklabel color 1
\@    xaxis  tick place normal
\@    xaxis  tick spec type none
\@    yaxis  on
\@    yaxis  type zero false
\@    yaxis  offset 0.000000 , 0.000000
\@    yaxis  bar on
\@    yaxis  bar color 1
\@    yaxis  bar linestyle 1
\@    yaxis  bar linewidth 1.0
\@    yaxis  label "Memory bandwidth [GB/s]"
\@    yaxis  label layout para
\@    yaxis  label place auto
\@    yaxis  label char size 1.500000
\@    yaxis  label font 0
\@    yaxis  label color 1
\@    yaxis  label place normal
\@    yaxis  tick on
\@    yaxis  tick major 10
\@    yaxis  tick minor ticks 1
\@    yaxis  tick default 6
\@    yaxis  tick place rounded true
\@    yaxis  tick in
\@    yaxis  tick major size 1.000000
\@    yaxis  tick major color 1
\@    yaxis  tick major linewidth 1.0
\@    yaxis  tick major linestyle 1
\@    yaxis  tick major grid on
\@    yaxis  tick minor color 7
\@    yaxis  tick minor linewidth 1.0
\@    yaxis  tick minor linestyle 1
\@    yaxis  tick minor grid on
\@    yaxis  tick minor size 0.500000
\@    yaxis  ticklabel on
\@    yaxis  ticklabel format general
\@    yaxis  ticklabel prec 5
\@    yaxis  ticklabel formula ""
\@    yaxis  ticklabel append ""
\@    yaxis  ticklabel prepend ""
\@    yaxis  ticklabel angle 0
\@    yaxis  ticklabel skip 0
\@    yaxis  ticklabel stagger 0
\@    yaxis  ticklabel place normal
\@    yaxis  ticklabel offset auto
\@    yaxis  ticklabel offset 0.000000 , 0.010000
\@    yaxis  ticklabel start type auto
\@    yaxis  ticklabel start 0.000000
\@    yaxis  ticklabel stop type auto
\@    yaxis  ticklabel stop 0.000000
\@    yaxis  ticklabel char size 1.250000
\@    yaxis  ticklabel font 0
\@    yaxis  ticklabel color 1
\@    yaxis  tick place both
\@    yaxis  tick spec type none
\@    altxaxis  off
\@    altyaxis  off
\@    legend on
\@    legend loctype view
\@    legend 0.93, 0.45
\@    legend box color 1
\@    legend box pattern 1
\@    legend box linewidth 1.0
\@    legend box linestyle 1
\@    legend box fill color 0
\@    legend box fill pattern 1
\@    legend font 0
\@    legend char size 1.000000
\@    legend color 1
\@    legend length 4
\@    legend vgap 1
\@    legend hgap 1
\@    legend invert false
\@    frame type 0
\@    frame linestyle 1
\@    frame linewidth 1.0
\@    frame color 1
\@    frame pattern 1
\@    frame background color 0
\@    frame background pattern 0
\@    s0 hidden false
\@    s0 type xy
\@    s0 symbol 1
\@    s0 symbol size 1.000000
\@    s0 symbol color 1
\@    s0 symbol pattern 1
\@    s0 symbol fill color 1
\@    s0 symbol fill pattern 1
\@    s0 symbol linewidth 1.0
\@    s0 symbol linestyle 1
\@    s0 symbol char 65
\@    s0 symbol char font 0
\@    s0 symbol skip 0
\@    s0 line type 1
\@    s0 line linestyle 1
\@    s0 line linewidth 4.0
\@    s0 line color 1
\@    s0 line pattern 1
\@    s0 baseline type 0
\@    s0 baseline off
\@    s0 dropline off
\@    s0 fill type 0
\@    s0 fill rule 0
\@    s0 fill color 1
\@    s0 fill pattern 1
\@    s0 avalue off
\@    s0 avalue type 2
\@    s0 avalue char size 1.000000
\@    s0 avalue font 0
\@    s0 avalue color 1
\@    s0 avalue rot 0
\@    s0 avalue format general
\@    s0 avalue prec 3
\@    s0 avalue prepend ""
\@    s0 avalue append ""
\@    s0 avalue offset 0.000000 , 0.000000
\@    s0 errorbar on
\@    s0 errorbar place both
\@    s0 errorbar color 1
\@    s0 errorbar pattern 1
\@    s0 errorbar size 1.000000
\@    s0 errorbar linewidth 1.0
\@    s0 errorbar linestyle 1
\@    s0 errorbar riser linewidth 1.0
\@    s0 errorbar riser linestyle 1
\@    s0 errorbar riser clip off
\@    s0 errorbar riser clip length 0.100000
\@    s0 legend  "Init"
\@    s1 hidden false
\@    s1 type xy
\@    s1 symbol 1
\@    s1 symbol size 1.000000
\@    s1 symbol color 2
\@    s1 symbol pattern 1
\@    s1 symbol fill color 2
\@    s1 symbol fill pattern 1
\@    s1 symbol linewidth 1.0
\@    s1 symbol linestyle 1
\@    s1 symbol char 65
\@    s1 symbol char font 0
\@    s1 symbol skip 0
\@    s1 line type 1
\@    s1 line linestyle 1
\@    s1 line linewidth 4.0
\@    s1 line color 2
\@    s1 line pattern 1
\@    s1 baseline type 0
\@    s1 baseline off
\@    s1 dropline off
\@    s1 fill type 0
\@    s1 fill rule 0
\@    s1 fill color 1
\@    s1 fill pattern 1
\@    s1 avalue off
\@    s1 avalue type 2
\@    s1 avalue char size 1.000000
\@    s1 avalue font 0
\@    s1 avalue color 1
\@    s1 avalue rot 0
\@    s1 avalue format general
\@    s1 avalue prec 3
\@    s1 avalue prepend ""
\@    s1 avalue append ""
\@    s1 avalue offset 0.000000 , 0.000000
\@    s1 errorbar on
\@    s1 errorbar place both
\@    s1 errorbar color 2
\@    s1 errorbar pattern 1
\@    s1 errorbar size 1.000000
\@    s1 errorbar linewidth 1.0
\@    s1 errorbar linestyle 1
\@    s1 errorbar riser linewidth 1.0
\@    s1 errorbar riser linestyle 1
\@    s1 errorbar riser clip off
\@    s1 errorbar riser clip length 0.100000
\@    s1 legend  "Sum"
\@    s2 hidden false
\@    s2 type xy
\@    s2 symbol 1
\@    s2 symbol size 1.000000
\@    s2 symbol color 3
\@    s2 symbol pattern 1
\@    s2 symbol fill color 3
\@    s2 symbol fill pattern 1
\@    s2 symbol linewidth 1.0
\@    s2 symbol linestyle 1
\@    s2 symbol char 65
\@    s2 symbol char font 0
\@    s2 symbol skip 0
\@    s2 line type 1
\@    s2 line linestyle 1
\@    s2 line linewidth 4.0
\@    s2 line color 3
\@    s2 line pattern 1
\@    s2 baseline type 0
\@    s2 baseline off
\@    s2 dropline off
\@    s2 fill type 0
\@    s2 fill rule 0
\@    s2 fill color 1
\@    s2 fill pattern 1
\@    s2 avalue off
\@    s2 avalue type 2
\@    s2 avalue char size 1.000000
\@    s2 avalue font 0
\@    s2 avalue color 1
\@    s2 avalue rot 0
\@    s2 avalue format general
\@    s2 avalue prec 3
\@    s2 avalue prepend ""
\@    s2 avalue append ""
\@    s2 avalue offset 0.000000 , 0.000000
\@    s2 errorbar on
\@    s2 errorbar place both
\@    s2 errorbar color 3
\@    s2 errorbar pattern 1
\@    s2 errorbar size 1.000000
\@    s2 errorbar linewidth 1.0
\@    s2 errorbar linestyle 1
\@    s2 errorbar riser linewidth 1.0
\@    s2 errorbar riser linestyle 1
\@    s2 errorbar riser clip off
\@    s2 errorbar riser clip length 0.100000
\@    s2 legend  "Copy"
\@    s3 hidden false
\@    s3 type xy
\@    s3 symbol 1
\@    s3 symbol size 1.000000
\@    s3 symbol color 4
\@    s3 symbol pattern 1
\@    s3 symbol fill color 4
\@    s3 symbol fill pattern 1
\@    s3 symbol linewidth 1.0
\@    s3 symbol linestyle 1
\@    s3 symbol char 65
\@    s3 symbol char font 0
\@    s3 symbol skip 0
\@    s3 line type 1
\@    s3 line linestyle 1
\@    s3 line linewidth 4.0
\@    s3 line color 4
\@    s3 line pattern 1
\@    s3 baseline type 0
\@    s3 baseline off
\@    s3 dropline off
\@    s3 fill type 0
\@    s3 fill rule 0
\@    s3 fill color 1
\@    s3 fill pattern 1
\@    s3 avalue off
\@    s3 avalue type 2
\@    s3 avalue char size 1.000000
\@    s3 avalue font 0
\@    s3 avalue color 1
\@    s3 avalue rot 0
\@    s3 avalue format general
\@    s3 avalue prec 3
\@    s3 avalue prepend ""
\@    s3 avalue append ""
\@    s3 avalue offset 0.000000 , 0.000000
\@    s3 errorbar on
\@    s3 errorbar place both
\@    s3 errorbar color 4
\@    s3 errorbar pattern 1
\@    s3 errorbar size 1.000000
\@    s3 errorbar linewidth 1.0
\@    s3 errorbar linestyle 1
\@    s3 errorbar riser linewidth 1.0
\@    s3 errorbar riser linestyle 1
\@    s3 errorbar riser clip off
\@    s3 errorbar riser clip length 0.100000
\@    s3 legend  "Update"
\@    s4 hidden false
\@    s4 type xy
\@    s4 symbol 1
\@    s4 symbol size 1.000000
\@    s4 symbol color 5
\@    s4 symbol pattern 1
\@    s4 symbol fill color 5
\@    s4 symbol fill pattern 1
\@    s4 symbol linewidth 1.0
\@    s4 symbol linestyle 1
\@    s4 symbol char 65
\@    s4 symbol char font 0
\@    s4 symbol skip 0
\@    s4 line type 1
\@    s4 line linestyle 1
\@    s4 line linewidth 4.0
\@    s4 line color 5
\@    s4 line pattern 1
\@    s4 baseline type 0
\@    s4 baseline off
\@    s4 dropline off
\@    s4 fill type 0
\@    s4 fill rule 0
\@    s4 fill color 1
\@    s4 fill pattern 1
\@    s4 avalue off
\@    s4 avalue type 2
\@    s4 avalue char size 1.000000
\@    s4 avalue font 0
\@    s4 avalue color 1
\@    s4 avalue rot 0
\@    s4 avalue format general
\@    s4 avalue prec 3
\@    s4 avalue prepend ""
\@    s4 avalue append ""
\@    s4 avalue offset 0.000000 , 0.000000
\@    s4 errorbar on
\@    s4 errorbar place both
\@    s4 errorbar color 5
\@    s4 errorbar pattern 1
\@    s4 errorbar size 1.000000
\@    s4 errorbar linewidth 1.0
\@    s4 errorbar linestyle 1
\@    s4 errorbar riser linewidth 1.0
\@    s4 errorbar riser linestyle 1
\@    s4 errorbar riser clip off
\@    s4 errorbar riser clip length 0.100000
\@    s4 legend  "Triad"
\@    s5 hidden false
\@    s5 type xy
\@    s5 symbol 1
\@    s5 symbol size 1.000000
\@    s5 symbol color 6
\@    s5 symbol pattern 1
\@    s5 symbol fill color 6
\@    s5 symbol fill pattern 1
\@    s5 symbol linewidth 1.0
\@    s5 symbol linestyle 1
\@    s5 symbol char 65
\@    s5 symbol char font 0
\@    s5 symbol skip 0
\@    s5 line type 1
\@    s5 line linestyle 1
\@    s5 line linewidth 4.0
\@    s5 line color 6
\@    s5 line pattern 1
\@    s5 baseline type 0
\@    s5 baseline off
\@    s5 dropline off
\@    s5 fill type 0
\@    s5 fill rule 0
\@    s5 fill color 1
\@    s5 fill pattern 1
\@    s5 avalue off
\@    s5 avalue type 2
\@    s5 avalue char size 1.000000
\@    s5 avalue font 0
\@    s5 avalue color 1
\@    s5 avalue rot 0
\@    s5 avalue format general
\@    s5 avalue prec 3
\@    s5 avalue prepend ""
\@    s5 avalue append ""
\@    s5 avalue offset 0.000000 , 0.000000
\@    s5 errorbar on
\@    s5 errorbar place both
\@    s5 errorbar color 6
\@    s5 errorbar pattern 1
\@    s5 errorbar size 1.000000
\@    s5 errorbar linewidth 1.0
\@    s5 errorbar linestyle 1
\@    s5 errorbar riser linewidth 1.0
\@    s5 errorbar riser linestyle 1
\@    s5 errorbar riser clip off
\@    s5 errorbar riser clip length 0.100000
\@    s5 legend  "Daxpy"
\@    s6 hidden false
\@    s6 type xy
\@    s6 symbol 1
\@    s6 symbol size 1.000000
\@    s6 symbol color 7
\@    s6 symbol pattern 1
\@    s6 symbol fill color 7
\@    s6 symbol fill pattern 1
\@    s6 symbol linewidth 1.0
\@    s6 symbol linestyle 1
\@    s6 symbol char 65
\@    s6 symbol char font 0
\@    s6 symbol skip 0
\@    s6 line type 1
\@    s6 line linestyle 1
\@    s6 line linewidth 4.0
\@    s6 line color 7
\@    s6 line pattern 1
\@    s6 baseline type 0
\@    s6 baseline off
\@    s6 dropline off
\@    s6 fill type 0
\@    s6 fill rule 0
\@    s6 fill color 1
\@    s6 fill pattern 1
\@    s6 avalue off
\@    s6 avalue type 2
\@    s6 avalue char size 1.000000
\@    s6 avalue font 0
\@    s6 avalue color 1
\@    s6 avalue rot 0
\@    s6 avalue format general
\@    s6 avalue prec 3
\@    s6 avalue prepend ""
\@    s6 avalue append ""
\@    s6 avalue offset 0.000000 , 0.000000
\@    s6 errorbar on
\@    s6 errorbar place both
\@    s6 errorbar color 7
\@    s6 errorbar pattern 1
\@    s6 errorbar size 1.000000
\@    s6 errorbar linewidth 1.0
\@    s6 errorbar linestyle 1
\@    s6 errorbar riser linewidth 1.0
\@    s6 errorbar riser linestyle 1
\@    s6 errorbar riser clip off
\@    s6 errorbar riser clip length 0.100000
\@    s6 legend  "STriad"
\@    s7 hidden false
\@    s7 type xy
\@    s7 symbol 1
\@    s7 symbol size 1.000000
\@    s7 symbol color 8
\@    s7 symbol pattern 1
\@    s7 symbol fill color 8
\@    s7 symbol fill pattern 1
\@    s7 symbol linewidth 1.0
\@    s7 symbol linestyle 1
\@    s7 symbol char 65
\@    s7 symbol char font 0
\@    s7 symbol skip 0
\@    s7 line type 1
\@    s7 line linestyle 1
\@    s7 line linewidth 4.0
\@    s7 line color 8
\@    s7 line pattern 1
\@    s7 baseline type 0
\@    s7 baseline off
\@    s7 dropline off
\@    s7 fill type 0
\@    s7 fill rule 0
\@    s7 fill color 1
\@    s7 fill pattern 1
\@    s7 avalue off
\@    s7 avalue type 2
\@    s7 avalue char size 1.000000
\@    s7 avalue font 0
\@    s7 avalue color 1
\@    s7 avalue rot 0
\@    s7 avalue format general
\@    s7 avalue prec 3
\@    s7 avalue prepend ""
\@    s7 avalue append ""
\@    s7 avalue offset 0.000000 , 0.000000
\@    s7 errorbar on
\@    s7 errorbar place both
\@    s7 errorbar color 8
\@    s7 errorbar pattern 1
\@    s7 errorbar size 1.000000
\@    s7 errorbar linewidth 1.0
\@    s7 errorbar linestyle 1
\@    s7 errorbar riser linewidth 1.0
\@    s7 errorbar riser linestyle 1
\@    s7 errorbar riser clip off
\@    s7 errorbar riser clip length 0.100000
\@    s7 legend  "SDaxpy"
#QTGRACE_ADDITIONAL_PARAMETER: PLOT_ALPHA 255 255
#QTGRACE_ADDITIONAL_PARAMETER: GRAPH_ALPHA G 0 {255;255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AXIS_ALPHA G 0 A 0 {255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AXIS_ALPHA G 0 A 1 {255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AXIS_ALPHA G 0 A 2 {255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AXIS_ALPHA G 0 A 3 {255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AUTOATTACH G 0 0 0
#QTGRACE_ADDITIONAL_PARAMETER: TITLE_SHIFT G 0 0 0
#QTGRACE_ADDITIONAL_PARAMETER: SUBTITLE_SHIFT G 0 0 0
#QTGRACE_ADDITIONAL_PARAMETER: VIEWPORT_NAME 0 0 "Default"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT_RESET 1
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Times New Roman,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Times New Roman,10,-1,5,50,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Times New Roman,10,-1,5,75,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Times New Roman,10,-1,5,75,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Helvetica,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Helvetica,10,-1,5,50,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Helvetica,10,-1,5,75,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Helvetica,10,-1,5,75,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Courier,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Courier,10,-1,5,50,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Courier,10,-1,5,75,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Courier,10,-1,5,75,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Symbol,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Zapf Dingbats,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: ENCODING "UTF-8"
#QTGRACE_ADDITIONAL_PARAMETER: UNIVERSAL_FONT_SIZE_FACTOR 1.0000
#QTGRACE_ADDITIONAL_PARAMETER: TIMESTAMP_PATH 0
#QTGRACE_ADDITIONAL_PARAMETER: LINESTYLES 9 {2;2;2;2;2;4;4;6;6} {{0;1},{1;0},{1;3},{5;3},{7;3},{1;3;5;3},{1;3;7;3},{1;3;5;3;1;3},{5;3;1;3;5;3}}
\@target G0.S0
\@type xy
$PLOT{Init}
&
\@target G0.S1
\@type xy
$PLOT{Sum}
&
\@target G0.S2
\@type xy
$PLOT{Copy}
&
\@target G0.S3
\@type xy
$PLOT{Update}
&
\@target G0.S4
\@type xy
$PLOT{Triad}
&
\@target G0.S5
\@type xy
$PLOT{Daxpy}
&
\@target G0.S6
\@type xy
$PLOT{STriad}
&
\@target G0.S7
\@type xy
$PLOT{SDaxpy}
&
END
close $fh;
}

sub generateDomainScalingPlot {
my $filename = shift;
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

print $fh <<"END";
# Grace project file
#
\@version 50122
\@page size 792, 612
\@page scroll 5%
\@page inout 5%
\@link page off
\@map font 0 to "Times-Roman", "Times-Roman"
\@map font 1 to "Times-Italic", "Times-Italic"
\@map font 2 to "Times-Bold", "Times-Bold"
\@map font 3 to "Times-BoldItalic", "Times-BoldItalic"
\@map font 4 to "Helvetica", "Helvetica"
\@map font 5 to "Helvetica-Oblique", "Helvetica-Oblique"
\@map font 6 to "Helvetica-Bold", "Helvetica-Bold"
\@map font 7 to "Helvetica-BoldOblique", "Helvetica-BoldOblique"
\@map font 8 to "Courier", "Courier"
\@map font 9 to "Courier-Oblique", "Courier-Oblique"
\@map font 10 to "Courier-Bold", "Courier-Bold"
\@map font 11 to "Courier-BoldOblique", "Courier-BoldOblique"
\@map font 12 to "Symbol", "Symbol"
\@map font 13 to "ZapfDingbats", "ZapfDingbats"
\@map color 0 to (255, 255, 255), "white"
\@map color 1 to (0, 0, 0), "black"
\@map color 2 to (255, 0, 0), "red"
\@map color 3 to (0, 255, 0), "green"
\@map color 4 to (0, 0, 255), "blue"
\@map color 5 to (255, 255, 0), "yellow"
\@map color 6 to (188, 143, 143), "brown"
\@map color 7 to (220, 220, 220), "grey"
\@map color 8 to (148, 0, 211), "violet"
\@map color 9 to (0, 255, 255), "cyan"
\@map color 10 to (255, 0, 255), "magenta"
\@map color 11 to (255, 165, 0), "orange"
\@map color 12 to (114, 33, 188), "indigo"
\@map color 13 to (103, 7, 72), "maroon"
\@map color 14 to (64, 224, 208), "turquoise"
\@map color 15 to (0, 139, 0), "green4"
\@reference date 0
\@date wrap off
\@date wrap year 1950
\@default linewidth 1.0
\@default linestyle 1
\@default color 1
\@default pattern 1
\@default font 0
\@default char size 1.000000
\@default symbol size 1.000000
\@default sformat "%.8g"
\@background color 0
\@page background fill on
\@timestamp off
\@timestamp 0.03, 0.03
\@timestamp color 1
\@timestamp rot 0
\@timestamp font 0
\@timestamp char size 1.000000
\@timestamp def "Wed Jan 13 13:31:39 2021"
\@r0 off
\@link r0 to g0
\@r0 type above
\@r0 linestyle 1
\@r0 linewidth 1.0
\@r0 color 1
\@r0 line 0, 0, 0, 0
\@r1 off
\@link r1 to g0
\@r1 type above
\@r1 linestyle 1
\@r1 linewidth 1.0
\@r1 color 1
\@r1 line 0, 0, 0, 0
\@r2 off
\@link r2 to g0
\@r2 type above
\@r2 linestyle 1
\@r2 linewidth 1.0
\@r2 color 1
\@r2 line 0, 0, 0, 0
\@r3 off
\@link r3 to g0
\@r3 type above
\@r3 linestyle 1
\@r3 linewidth 1.0
\@r3 color 1
\@r3 line 0, 0, 0, 0
\@r4 off
\@link r4 to g0
\@r4 type above
\@r4 linestyle 1
\@r4 linewidth 1.0
\@r4 color 1
\@r4 line 0, 0, 0, 0
\@g0 on
\@g0 hidden false
\@g0 type XY
\@g0 stacked false
\@g0 bar hgap 0.000000
\@g0 fixedpoint off
\@g0 fixedpoint type 0
\@g0 fixedpoint xy 0.000000, 0.000000
\@g0 fixedpoint format general general
\@g0 fixedpoint prec 6, 6
\@with g0
\@    world $DPLOT{world}
\@    stack world 0, 1, 0, 1
\@    znorm 1
\@    view 0.150000, 0.150000, 1.150000, 0.850000
\@    title ""
\@    title font 0
\@    title size 1.500000
\@    title color 1
\@    subtitle ""
\@    subtitle font 0
\@    subtitle size 1.000000
\@    subtitle color 1
\@    xaxes scale Normal
\@    yaxes scale Normal
\@    xaxes invert off
\@    yaxes invert off
\@    xaxis  on
\@    xaxis  type zero false
\@    xaxis  offset 0.000000 , 0.000000
\@    xaxis  bar on
\@    xaxis  bar color 1
\@    xaxis  bar linestyle 1
\@    xaxis  bar linewidth 1.0
\@    xaxis  label "number of cores per memory domain"
\@    xaxis  label layout para
\@    xaxis  label place auto
\@    xaxis  label char size 1.500000
\@    xaxis  label font 0
\@    xaxis  label color 1
\@    xaxis  label place normal
\@    xaxis  tick on
\@    xaxis  tick major 1
\@    xaxis  tick minor ticks 0
\@    xaxis  tick default 6
\@    xaxis  tick place rounded true
\@    xaxis  tick in
\@    xaxis  tick major size 1.000000
\@    xaxis  tick major color 1
\@    xaxis  tick major linewidth 1.0
\@    xaxis  tick major linestyle 1
\@    xaxis  tick major grid off
\@    xaxis  tick minor color 1
\@    xaxis  tick minor linewidth 1.0
\@    xaxis  tick minor linestyle 1
\@    xaxis  tick minor grid off
\@    xaxis  tick minor size 0.500000
\@    xaxis  ticklabel on
\@    xaxis  ticklabel format general
\@    xaxis  ticklabel prec 5
\@    xaxis  ticklabel formula ""
\@    xaxis  ticklabel append ""
\@    xaxis  ticklabel prepend ""
\@    xaxis  ticklabel angle 0
\@    xaxis  ticklabel skip 0
\@    xaxis  ticklabel stagger 0
\@    xaxis  ticklabel place normal
\@    xaxis  ticklabel offset auto
\@    xaxis  ticklabel offset 0.000000 , 0.010000
\@    xaxis  ticklabel start type auto
\@    xaxis  ticklabel start 0.000000
\@    xaxis  ticklabel stop type auto
\@    xaxis  ticklabel stop 0.000000
\@    xaxis  ticklabel char size 1.250000
\@    xaxis  ticklabel font 0
\@    xaxis  ticklabel color 1
\@    xaxis  tick place normal
\@    xaxis  tick spec type none
\@    yaxis  on
\@    yaxis  type zero false
\@    yaxis  offset 0.000000 , 0.000000
\@    yaxis  bar on
\@    yaxis  bar color 1
\@    yaxis  bar linestyle 1
\@    yaxis  bar linewidth 1.0
\@    yaxis  label "Memory bandwidth [GB/s]"
\@    yaxis  label layout para
\@    yaxis  label place auto
\@    yaxis  label char size 1.500000
\@    yaxis  label font 0
\@    yaxis  label color 1
\@    yaxis  label place normal
\@    yaxis  tick on
\@    yaxis  tick major 50
\@    yaxis  tick minor ticks 1
\@    yaxis  tick default 6
\@    yaxis  tick place rounded true
\@    yaxis  tick in
\@    yaxis  tick major size 1.000000
\@    yaxis  tick major color 1
\@    yaxis  tick major linewidth 1.0
\@    yaxis  tick major linestyle 1
\@    yaxis  tick major grid on
\@    yaxis  tick minor color 7
\@    yaxis  tick minor linewidth 1.0
\@    yaxis  tick minor linestyle 1
\@    yaxis  tick minor grid on
\@    yaxis  tick minor size 0.500000
\@    yaxis  ticklabel on
\@    yaxis  ticklabel format general
\@    yaxis  ticklabel prec 5
\@    yaxis  ticklabel formula ""
\@    yaxis  ticklabel append ""
\@    yaxis  ticklabel prepend ""
\@    yaxis  ticklabel angle 0
\@    yaxis  ticklabel skip 0
\@    yaxis  ticklabel stagger 0
\@    yaxis  ticklabel place normal
\@    yaxis  ticklabel offset auto
\@    yaxis  ticklabel offset 0.000000 , 0.010000
\@    yaxis  ticklabel start type auto
\@    yaxis  ticklabel start 0.000000
\@    yaxis  ticklabel stop type auto
\@    yaxis  ticklabel stop 0.000000
\@    yaxis  ticklabel char size 1.250000
\@    yaxis  ticklabel font 0
\@    yaxis  ticklabel color 1
\@    yaxis  tick place both
\@    yaxis  tick spec type none
\@    altxaxis  off
\@    altyaxis  off
\@    legend on
\@    legend loctype view
\@    legend 0.9, 0.4
\@    legend box color 1
\@    legend box pattern 1
\@    legend box linewidth 1.0
\@    legend box linestyle 1
\@    legend box fill color 0
\@    legend box fill pattern 1
\@    legend font 0
\@    legend char size 1.000000
\@    legend color 1
\@    legend length 4
\@    legend vgap 1
\@    legend hgap 1
\@    legend invert false
\@    frame type 0
\@    frame linestyle 1
\@    frame linewidth 1.0
\@    frame color 1
\@    frame pattern 1
\@    frame background color 0
\@    frame background pattern 0
$DPLOT{meta}
#QTGRACE_ADDITIONAL_PARAMETER: PLOT_ALPHA 255 255
#QTGRACE_ADDITIONAL_PARAMETER: GRAPH_ALPHA G 0 {255;255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AXIS_ALPHA G 0 A 0 {255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AXIS_ALPHA G 0 A 1 {255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AXIS_ALPHA G 0 A 2 {255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AXIS_ALPHA G 0 A 3 {255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 0 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 1 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 2 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 3 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 4 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 5 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 6 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 POLYGONEBASESET -1
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 SHOWERRORBARINLEGEND 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 CONNECTERRORBARS 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 IGNOREINAUTOSCALE 0
#QTGRACE_ADDITIONAL_PARAMETER: G 0 S 7 ALPHA_CHANNELS {255;255;255;255;255;255}
#QTGRACE_ADDITIONAL_PARAMETER: AUTOATTACH G 0 0 0
#QTGRACE_ADDITIONAL_PARAMETER: TITLE_SHIFT G 0 0 0
#QTGRACE_ADDITIONAL_PARAMETER: SUBTITLE_SHIFT G 0 0 0
#QTGRACE_ADDITIONAL_PARAMETER: VIEWPORT_NAME 0 0 "Default"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT_RESET 1
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Times New Roman,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Times New Roman,10,-1,5,50,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Times New Roman,10,-1,5,75,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Times New Roman,10,-1,5,75,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Helvetica,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Helvetica,10,-1,5,50,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Helvetica,10,-1,5,75,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Helvetica,10,-1,5,75,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Courier,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Courier,10,-1,5,50,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Courier,10,-1,5,75,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Courier,10,-1,5,75,1,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Symbol,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: QTFONT "Zapf Dingbats,10,-1,5,50,0,0,0,0,0"
#QTGRACE_ADDITIONAL_PARAMETER: ENCODING "UTF-8"
#QTGRACE_ADDITIONAL_PARAMETER: UNIVERSAL_FONT_SIZE_FACTOR 1.0000
#QTGRACE_ADDITIONAL_PARAMETER: TIMESTAMP_PATH 0
#QTGRACE_ADDITIONAL_PARAMETER: LINESTYLES 9 {2;2;2;2;2;4;4;6;6} {{0;1},{1;0},{1;3},{5;3},{7;3},{1;3;5;3},{1;3;7;3},{1;3;5;3;1;3},{5;3;1;3;5;3}}
$DPLOT{series}
END
close $fh;
}

sub generateMarkdown {
my $filename = shift;
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

print $fh <<"END";
# System

* **Processor:** $INFO{processor}
* **Base frequency:** ??
* **Number of sockets:** $INFO{numSockets}
* **Number of memory domains per socket:** $INFO{numDomainsPerSocket}
* **Number of cores per socket:** $INFO{numCoresPerSocket}
* **Number of HWThreads per core:** $INFO{numThreadsPerCore}
* **[MachineState](https://github.com/RRZE-HPC/MachineState) output:**  NA

# Tool chain

```
+----------+-----------+
| Compiler | $INFO{toolchain} |
|----------|-----------|
| Version  |  $INFO{version}  |
+----------+-----------+
```

Optimizing flags: ```$INFO{flags}```

# Results

All results are in ```GB/s```.

Summary results:
```
+---------------------------------+
| Single core   |  $RESULT{core}   |
| Memory domain |  $RESULT{domain} |
| Socket        |  $RESULT{socket} |
| Node          |  $RESULT{node}   |
+---------------------------------+
```

Results for scaling within a memory domain:
```
$RESULT{scaling}
```

Results for scaling across  memory domains. Shown are the results for the number of memory domains used (nm) with columns number of cores used per memory domain.

Init:
```
$RESULT{domainInit}
```

Sum:
```
$RESULT{domainSum}
```

Copy
```
$RESULT{domainCopy}
```

Update
```
$RESULT{domainUpdate}
```

Triad
```
$RESULT{domainTriad}
```

# Scaling

Memory bandwidth scaling within one memory domain:
![Main memory bandwidth scaling plot]($RESULT{scalingPlot})

The following plots illustrate the the performance scaling over multiple memory domains using different number of cores per memory domain.

Memory bandwidth scaling across memory domains for init:
![Memory domain scaling plot]($RESULT{domainInitPlot})

Memory bandwidth scaling across memory domains for sum
![Memory domain scaling plot]($RESULT{domainSumPlot})

Memory bandwidth scaling across memory domains for copy
![Memory domain scaling plot]($RESULT{domainCopyPlot})

Memory bandwidth scaling across memory domains for Triad
![Memory domain scaling plot]($RESULT{domainTriadPlot})
END

close $fh;
}
