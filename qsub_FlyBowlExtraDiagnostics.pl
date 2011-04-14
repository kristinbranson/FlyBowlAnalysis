#!/usr/bin/perl

use strict;

my $nargs = $#ARGV + 1;
if($nargs < 1){
    print "Usage: qsub_FlyBowlExtraDiagnostics.pl <expdirlist.txt>\n";
    exit(1);
}

my $SCRIPT = "/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/settings/20110222/run_FlyBowlExtraDiagnostics.sh";

my $PERFRAMEDIR = "perframe";

my $temporary_dir = "/groups/branson/bransonlab/projects/olympiad/FlyBowlAnalysis/temp_compute_stats";
`mkdir -p $temporary_dir`;

my $MCR = "/groups/branson/bransonlab/projects/olympiad/MCR/v714";

my $MCR_CACHE_ROOT = "/tmp/mcr_cache_root";

# read in expdirs
my $expdirfile = $ARGV[0];
open(FILE,$expdirfile) or die("Could not open file $expdirfile for reading");

my $njobs = 0;

# loop through each experiment directory
while(my $expdir = <FILE>){
    chomp $expdir;
    
    if(!$expdir){
	next;
    }
    if($expdir =~ /^\s*#/){
	next;
    }

    if(! -d $expdir){
	print "Directory $expdir does not exist\n";
	next;
    }

    if(! -e "$expdir/hist_perframe.mat"){
	print "Per-frame histograms not yet computed, skipping.\n";
	next;
    }
    if(! -e "$expdir/stats_perframe.mat"){
	print "Per-frame histograms not yet computed, skipping.\n";
	next;
    }

    $expdir =~ /^(.*)\/([^\/]+)$/;
    my $rootdir = $1;
    my $basename = $2;

    print "*** $basename\n";
    
    # make a name for this job
    my $sgeid = "kb_flybowlextradiagnostics_$basename";
    $sgeid =~ s/\//_/g;
    $sgeid =~ s/\./_/g;
    $sgeid =~ s/\;/_/g;

    # names for temporary script and log file
    my $shfilename = "$temporary_dir/$sgeid" . ".sh";
    my $outfilename = "$temporary_dir/$sgeid" . ".log";

    # create temporary script to be submitted
    write_qsub_sh($shfilename,$expdir,$sgeid);

    # submit command
    my $cmd = qq~qsub -N $sgeid -j y -o $outfilename -cwd $shfilename~;
    print "submitting to cluster: $cmd\n";
    system($cmd);
    #system($shfilename);
    $njobs++;

    exit(1);

}

print "$njobs jobs started.";

close(FILE);

sub write_qsub_sh {
	my ($shfilename,$expdir,$jobid) = @_;
	
	open(SHFILE,">$shfilename") || die "Cannot write $shfilename";

	print SHFILE qq~#!/bin/bash
# FlyBowlExtraDiagnostics test script.
# this script will be qsubed
export MCR_CACHE_ROOT=$MCR_CACHE_ROOT.$jobid

$SCRIPT $MCR $expdir analysis_protocol 20110222

~;
	
#	print SHFILE qq~#delete itself
#rm -f \$0
#~;	
	
	close(SHFILE);
	
	chmod(0755, $shfilename);
}
