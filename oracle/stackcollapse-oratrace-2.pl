#!/usr/bin/env perl
#

use warnings;
use strict;
use Data::Dumper;

=head1 example output data from perf

 ./stackcollapse-perf.pl oracle-p1-12c.perf

 oracle_29716_js;__libc_start_main;main;ssthrdmain;opimai_real;sou2o;opidrv;opiodr;opiino;opitsk;opikndf2;kslwtectx 1
 oracle_29716_js;__libc_start_main;main;ssthrdmain;opimai_real;sou2o;opidrv;opiodr;opiino;opitsk;opikndf2;nioqrc;nsbsend;nsbasic_bsd;nttfpwr;__write_nocancel;system_call_fastpath;sys_write;vfs_write;do_sync_write;do_aio_write;sock_aio_write;inet_sendmsg;__copy_user_nocache 1
 oracle_29716_js;__libc_start_main;main;ssthrdmain;opimai_real;sou2o;opidrv;opiodr;opiino;opitsk;opikndf2;nioqrc;nsbsend;nsbasic_bsd;nttfpwr;__write_nocancel;system_call_fastpath;sys_write;vfs_write;do_sync_write;do_aio_write;sock_aio_write;inet_sendmsg;tcp_sendmsg;sk_stream_alloc_skb;__alloc_skb;__kmalloc_reserve;__kmalloc_node_track_caller;ret_from_intr;do_IRQ;irq_exit;do_softirq;call_softirq;__do_softirq 1
 oracle_29716_js;__libc_start_main;main;ssthrdmain;opimai_real;sou2o;opidrv;opiodr;opiino;opitsk;opikndf2;nioqrc;nsbsend;nsbasic_bsd;nttfpwr;__write_nocancel;system_call_fastpath;sys_write;vfs_write;do_sync_write;do_aio_write;sock_aio_write;inet_sendmsg;tcp_sendmsg;tcp_push;__tcp_push_pending_frames;tcp_write_xmit;tcp_transmit_skb 1
 oracle_29716_js;__libc_start_main;main;ssthrdmain;opimai_real;sou2o;opidrv;opiodr;opiino;opitsk;opikndf2;nioqrc;nsbsend;nsbasic_bsd;nttfpwr;__write_nocancel;system_call_fastpath;sys_write;vfs_write;do_sync_write;do_aio_write;sock_aio_write;inet_sendmsg;tcp_sendmsg;tcp_push;__tcp_push_pending_frames;tcp_write_xmit;tcp_transmit_skb;ip_queue_xmit;ip_local_out;ip_output;ip_finish_output;dev_queue_xmit;sch_direct_xmit;dev_hard_start_xmit;e1000_xmit_frame 754

=cut

=head1 example output data from mrskew

 to be transformed to something similar to perf

 $  mrskew --rc=cull-snmfc.rc --rc=calls-totaled-test.rc --where='$sqlid eq q{35yzusqaa1szk}'   oracle-trace/flamegraph-test.trc  | head
 468,35yzusqaa1szk,SQL*Net_message_to_client,2
 475,35yzusqaa1szk,SQL*Net_message_from_client,1235
 18285,35yzusqaa1szk,PGA_memory_operation,14
 18286,35yzusqaa1szk,PGA_memory_operation,9
 18287,35yzusqaa1szk,PGA_memory_operation,11
 18288,35yzusqaa1szk,PGA_memory_operation,11
 18289,35yzusqaa1szk,PGA_memory_operation,11
 18290,35yzusqaa1szk,PGA_memory_operation,10
 18291,35yzusqaa1szk,PGA_memory_operation,13
 18292,35yzusqaa1szk,PGA_memory_operation,12

=cut

use warnings;
use strict;

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

	$data{$sqlid}->{$cursorID}{$event}++;

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




