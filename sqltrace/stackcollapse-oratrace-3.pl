#!/usr/bin/env perl
#

use warnings;
use strict;
use Data::Dumper;

my $debug=0;
my %data=();

while (<STDIN>) {
	my $input=$_;
	chomp $input;
	$input =~ s/^\s+//;
	next if $input =~ /^[[:digit:]]+$/;  # do not know where this line is coming from
	next if $input =~ /^\s*$/;
	print "input: |$input|\n" if $debug;
	my ($lineNumber,$sqlid, $cursorID, $event,$time) = split(/,/,$input);


	if ( $debug ) {
		print "sqlid $sqlid\n";
		print "line: $lineNumber\n";
		print "event: $event\n";
		print "time: $time\n\n";
	}

	$data{$sqlid}->{$cursorID}{$event} += $time;

}

foreach my $sqlid ( keys %data ) {
	my %sqldata = %{$data{$sqlid}};
	print "$sqlid: " . Dumper(\%sqldata) if $debug;

	foreach my $cursor ( keys %sqldata ) {

		my %cursorData = %{$sqldata{$cursor}};

		foreach my $event ( keys %cursorData ) {
			print "$sqlid;$cursor;$event $cursorData{$event}\n";
		}
	}
}




