#!/usr/bin/perl
#
# Use al-axtends=4
#
use strict;
use Fcntl;
use Fcntl ":seek";

sub do_test($)
{
    my ($devname)=@_;
    my ($buffer,$i,$rv);
    #my @pattern = ( 0,1,2,3,4 );
    # Evict from 1st place in empty next chain. The new extent replaces
    # the previous extent (goes into same slot). PASSED

    #my @pattern = ( 0,1,2,3,5 );
    # Evict from 1st place in empty next chain. 
    # chained to the slot via hash next. PASSED

    #my @pattern = ( 0,4,1,2,0,3 ); 
    # Tests evict from 2nd place in next chain. The new extent replaces
    # the previous extent (goes into same slot). PASSED

    #my @pattern = ( 0,4,1,2,0,6 ); 
    # Tests evict from 2nd place in next chain. The new extent must be
    # chained to the slot via hash next. PASSED

    #my @pattern = ( 0,4,1,2,6 ); 
    # Evict from 1st place in two element next chain. The new extent must be
    # chained to the slot via hash next. PASSED

    my @pattern = ( 0,4,3,2,5,4 ); 
    # This tests the 
    # "move the next in hash table (p) to first position (extent) !"
    # codepath. PASSED
    # T000 S000=E000000
    # T001 S003=E000004
    # T002 S002=E000004
    # T002 S003=E000003
    # T003 S001=E000004
    # T003 S002=E000002
    # T004 S000=E000004
    # T004 S001=E000005


    $buffer="foo";
    
    sysopen(DEVICE,$devname, O_RDWR|O_SYNC ) or die "open failed";

    for($i=0;$i<=$#pattern;$i++) {
	$rv=sysseek(DEVICE, $pattern[$i] * 4 * 1024*1024, SEEK_SET);
	print "$i $pattern[$i] $rv\n";
	syswrite(DEVICE, $buffer, 4);
    }
}


do_test($ARGV[0]);
