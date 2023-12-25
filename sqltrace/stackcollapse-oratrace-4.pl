#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;

my $debug=0;
my %data=();

# output data for the top N most time consumingg SQL Statements
my $maxTopSqlCount=100;

# use %sqlTimeTracker to output data for only the top N SQL_IDs
my %sqlTimeTracker;

# input is expected as comma delimited, no quotes
# $lineNumber, elapsed Time, sqlid, data . Data can have as many elements as needed

while (<STDIN>) {
	my $input=$_;
	chomp $input;
	$input =~ s/^\s+//;

	warn "bad data: $input\n"  if $input =~ /^[[:digit:]]+$/;  # do not know where this line is coming from

	next if $input =~ /^\s*$/;
	print "input: |$input|\n" if $debug;
	my ($lineNumber,$time,@lineData) = split(/,/,$input);
	my $sqlID = $lineData[0];

	$sqlTimeTracker{$sqlID} += $time;
	
	if ( $debug ) {
		print  join (';',@lineData) .  " $time\n";
	}
	
	$data{join(';',@lineData)} += $time;

}

my %sqlSortedByTime = ();
my $currentCount=0;
my $maxCount=$maxTopSqlCount;

foreach my $sqlID ( sort { $sqlTimeTracker{$b} <=> $sqlTimeTracker{$a} } keys %sqlTimeTracker) {
	my  $time=$sqlTimeTracker{$sqlID};	
	last if $currentCount++ >= $maxCount;
	$sqlSortedByTime{$sqlID} = $time;
}

foreach my $key ( keys %data ) {

	my $time = $data{$key};
	$time =~ s/\s+//g;
	my ($sqlID) = split(/;/, $key);

	if (exists $sqlSortedByTime{$sqlID}) {
		# do not output operations with 0 time - XCTEND, COMMIT for exampl
		print "$key $data{$key}\n" if $time > 0;
	}
}



