
FlameGraphs from Oracle SQL Trace (10046) Files
===============================================

Files used to generate flamegraphs from 10046 trace files.

Requires [FlameGraph](https://github.com/brendangregg/FlameGraph)

## mrskew rc files

mrskew is part of the [Method-R Workbench](https://method-r.com/software/workbench/)

###  cull-snmfc.rc

```text
# cull-snmfc.rc
# Jared Still 2023
# jkstill@gmail.com
# exlude snmfc (SQL*Net message from client) if >= 1 second

--init='

=encoding utf8

'

--where='($name =~ q{message from client} and $af < 1) or ! ( $name =~ q{message from client})'
```

### call-db-flamegraph.rc

```text
--init='

# $e is multiplied by 1e6
# the purpose of this is to impose some time based data on flamegraph.pl
# 1 microsecond is 1 unit - send the number units, as flamegraphs are count based

=encoding utf8

=cut

sub replaceSpaces ($) {
        my ($s) = @_;
        $s =~ s/\s+/_/g;
        return $s;
}

'
--group='print($line . "," . $sqlid . "," . replaceSpaces($name) . "," . sprintf("%-12d\n",$e * 1e6 ))'
--alldepths --nohistogram --name=:dbcall --top=0 --nohead --nofoot
```

### call-os-flamegraph.rc

```text
--init='

# $ela is multiplied by 1e6
# the purpose of this is to impose some time based data on flamegraph.pl
# 1 microsecond is 1 unit - send the number units, as flamegraphs are count based

=encoding utf8

=cut

sub replaceSpaces ($) {
        my ($s) = @_;
        $s =~ s/\s+/_/g;
        return $s;
}

'
--group='print($line . "," . $sqlid . "," . replaceSpaces($name) . "," . sprintf("%-12d\n",$ela * 1e6 ))'
--alldepths --nohistogram --name=:oscall --top=0 --nohead --nofoot
```

## stackcollapse-oratrace.pl

```perl
#!/usr/bin/env perl

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
   my ($lineNumber,$sqlid, $event,$time) = split(/,/,$input);


   if ( $debug ) {
      print "sqlid $sqlid\n";
      print "line: $lineNumber\n";
      print "event: $event\n";
      print "time: $time\n\n";
   }

   my $count = $time * 1e3;

   $data{$sqlid}{$event}++;

}

foreach my $sqlid ( keys %data ) {
   my %sqldata = %{$data{$sqlid}};
   print "$sqlid: " . Dumper(\%sqldata) if $debug;

   foreach my $event ( keys %sqldata ) {
      print "$sqlid;$event $sqldata{$event}\n";
   }
}

```

## Examples

### DB calls

```text
$  mrskew --rc=cull-snmfc.rc --rc=call-db-flamegraph.rc oracle-trace/flamegraph-test.trc | ./stackcollapse-oratrace.pl  | ./flamegraph.pl > flamegraph-db.svg
```

### OS calls

```text
$  mrskew --rc=cull-snmfc.rc --rc=call-os-flamegraph.rc oracle-trace/flamegraph-test.trc | ./stackcollapse-oratrace.pl  | ./flamegraph.pl > flamegraph-os.svg
```

