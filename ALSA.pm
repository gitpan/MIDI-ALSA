# MIDI::ALSA.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package MIDI::ALSA;
no strict;
use bytes;
$VERSION = '1.07';
# 20110430 1.07 reposition free() in xs_status
# 20110428 1.06 fix bug in status() in the time return-value
# 20110322 1.05 controllerevent
# 20110303 1.04 output, input, *2alsa and alsa2* now handle sysex events
# 20110301 1.03 add listclients, listnumports, listconnectedto etc
# 20110213 1.02 add disconnectto and disconnectfrom
# 20110211 1.01 first released version

# gives a -w warning, but I'm afraid $VERSION .= ''; would confuse CPAN
# use DynaLoader 'DYNALOADER';
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = ();
@EXPORT_OK = qw(client connectfrom connectto fd id
 input inputpending output start status stop syncoutput
 noteevent noteonevent noteoffevent pgmchangeevent pitchbendevent
 controllerevent chanpress alsa2scoreevent scoreevent2alsa);
@EXPORT_CONSTS = ();
%EXPORT_TAGS = (ALL => [@EXPORT,@EXPORT_OK], CONSTS => [@EXPORT_CONSTS]);
bootstrap MIDI::ALSA $VERSION;

my $maximum_nports = 4;
my $StartTime = 0;
#------------- public constants from alsa/asoundlib.h  -------------
my %k2v = &xs_constname2value();
while (my ($k,$v) = each %k2v) {
	push @EXPORT_OK, $k;  push @EXPORT_CONSTS, $k;
	# eval "sub $k() { return $v;}";   # subroutines
	# if ($@) { die "can't eval 'sub $k() { return $v;}': $@\n"; }
	# eval "\$$k = $v;";               # simple variables
	# if ($@) { die "can't eval '\$$k = $v;': $@\n"; }
}
# generate this by '!!perl filter':
sub SND_SEQ_EVENT_BOUNCE() { return $k2v{'SND_SEQ_EVENT_BOUNCE'}; }
sub SND_SEQ_EVENT_CHANPRESS() { return $k2v{'SND_SEQ_EVENT_CHANPRESS'}; }
sub SND_SEQ_EVENT_CLIENT_CHANGE() { return $k2v{'SND_SEQ_EVENT_CLIENT_CHANGE'}; }
sub SND_SEQ_EVENT_CLIENT_EXIT() { return $k2v{'SND_SEQ_EVENT_CLIENT_EXIT'}; }
sub SND_SEQ_EVENT_CLIENT_START() { return $k2v{'SND_SEQ_EVENT_CLIENT_START'}; }
sub SND_SEQ_EVENT_CLOCK() { return $k2v{'SND_SEQ_EVENT_CLOCK'}; }
sub SND_SEQ_EVENT_CONTINUE() { return $k2v{'SND_SEQ_EVENT_CONTINUE'}; }
sub SND_SEQ_EVENT_CONTROL14() { return $k2v{'SND_SEQ_EVENT_CONTROL14'}; }
sub SND_SEQ_EVENT_CONTROLLER() { return $k2v{'SND_SEQ_EVENT_CONTROLLER'}; }
sub SND_SEQ_EVENT_ECHO() { return $k2v{'SND_SEQ_EVENT_ECHO'}; }
sub SND_SEQ_EVENT_KEYPRESS() { return $k2v{'SND_SEQ_EVENT_KEYPRESS'}; }
sub SND_SEQ_EVENT_KEYSIGN() { return $k2v{'SND_SEQ_EVENT_KEYSIGN'}; }
sub SND_SEQ_EVENT_NONE() { return $k2v{'SND_SEQ_EVENT_NONE'}; }
sub SND_SEQ_EVENT_NONREGPARAM() { return $k2v{'SND_SEQ_EVENT_NONREGPARAM'}; }
sub SND_SEQ_EVENT_NOTE() { return $k2v{'SND_SEQ_EVENT_NOTE'}; }
sub SND_SEQ_EVENT_NOTEOFF() { return $k2v{'SND_SEQ_EVENT_NOTEOFF'}; }
sub SND_SEQ_EVENT_NOTEON() { return $k2v{'SND_SEQ_EVENT_NOTEON'}; }
sub SND_SEQ_EVENT_OSS() { return $k2v{'SND_SEQ_EVENT_OSS'}; }
sub SND_SEQ_EVENT_PGMCHANGE() { return $k2v{'SND_SEQ_EVENT_PGMCHANGE'}; }
sub SND_SEQ_EVENT_PITCHBEND() { return $k2v{'SND_SEQ_EVENT_PITCHBEND'}; }
sub SND_SEQ_EVENT_PORT_CHANGE() { return $k2v{'SND_SEQ_EVENT_PORT_CHANGE'}; }
sub SND_SEQ_EVENT_PORT_EXIT() { return $k2v{'SND_SEQ_EVENT_PORT_EXIT'}; }
sub SND_SEQ_EVENT_PORT_START() { return $k2v{'SND_SEQ_EVENT_PORT_START'}; }
sub SND_SEQ_EVENT_PORT_SUBSCRIBED() { return $k2v{'SND_SEQ_EVENT_PORT_SUBSCRIBED'}; }
sub SND_SEQ_EVENT_PORT_UNSUBSCRIBED() { return $k2v{'SND_SEQ_EVENT_PORT_UNSUBSCRIBED'}; }
sub SND_SEQ_EVENT_QFRAME() { return $k2v{'SND_SEQ_EVENT_QFRAME'}; }
sub SND_SEQ_EVENT_QUEUE_SKEW() { return $k2v{'SND_SEQ_EVENT_QUEUE_SKEW'}; }
sub SND_SEQ_EVENT_REGPARAM() { return $k2v{'SND_SEQ_EVENT_REGPARAM'}; }
sub SND_SEQ_EVENT_RESET() { return $k2v{'SND_SEQ_EVENT_RESET'}; }
sub SND_SEQ_EVENT_RESULT() { return $k2v{'SND_SEQ_EVENT_RESULT'}; }
sub SND_SEQ_EVENT_SENSING() { return $k2v{'SND_SEQ_EVENT_SENSING'}; }
sub SND_SEQ_EVENT_SETPOS_TICK() { return $k2v{'SND_SEQ_EVENT_SETPOS_TICK'}; }
sub SND_SEQ_EVENT_SETPOS_TIME() { return $k2v{'SND_SEQ_EVENT_SETPOS_TIME'}; }
sub SND_SEQ_EVENT_SONGPOS() { return $k2v{'SND_SEQ_EVENT_SONGPOS'}; }
sub SND_SEQ_EVENT_SONGSEL() { return $k2v{'SND_SEQ_EVENT_SONGSEL'}; }
sub SND_SEQ_EVENT_START() { return $k2v{'SND_SEQ_EVENT_START'}; }
sub SND_SEQ_EVENT_STOP() { return $k2v{'SND_SEQ_EVENT_STOP'}; }
sub SND_SEQ_EVENT_SYNC_POS() { return $k2v{'SND_SEQ_EVENT_SYNC_POS'}; }
sub SND_SEQ_EVENT_SYSEX() { return $k2v{'SND_SEQ_EVENT_SYSEX'}; }
sub SND_SEQ_EVENT_SYSTEM() { return $k2v{'SND_SEQ_EVENT_SYSTEM'}; }
sub SND_SEQ_EVENT_TEMPO() { return $k2v{'SND_SEQ_EVENT_TEMPO'}; }
sub SND_SEQ_EVENT_TICK() { return $k2v{'SND_SEQ_EVENT_TICK'}; }
sub SND_SEQ_EVENT_TIMESIGN() { return $k2v{'SND_SEQ_EVENT_TIMESIGN'}; }
sub SND_SEQ_EVENT_TUNE_REQUEST() { return $k2v{'SND_SEQ_EVENT_TUNE_REQUEST'}; }
sub SND_SEQ_EVENT_USR0() { return $k2v{'SND_SEQ_EVENT_USR0'}; }
sub SND_SEQ_EVENT_USR1() { return $k2v{'SND_SEQ_EVENT_USR1'}; }
sub SND_SEQ_EVENT_USR2() { return $k2v{'SND_SEQ_EVENT_USR2'}; }
sub SND_SEQ_EVENT_USR3() { return $k2v{'SND_SEQ_EVENT_USR3'}; }
sub SND_SEQ_EVENT_USR4() { return $k2v{'SND_SEQ_EVENT_USR4'}; }
sub SND_SEQ_EVENT_USR5() { return $k2v{'SND_SEQ_EVENT_USR5'}; }
sub SND_SEQ_EVENT_USR6() { return $k2v{'SND_SEQ_EVENT_USR6'}; }
sub SND_SEQ_EVENT_USR7() { return $k2v{'SND_SEQ_EVENT_USR7'}; }
sub SND_SEQ_EVENT_USR8() { return $k2v{'SND_SEQ_EVENT_USR8'}; }
sub SND_SEQ_EVENT_USR9() { return $k2v{'SND_SEQ_EVENT_USR9'}; }
sub SND_SEQ_EVENT_USR_VAR0() { return $k2v{'SND_SEQ_EVENT_USR_VAR0'}; }
sub SND_SEQ_EVENT_USR_VAR1() { return $k2v{'SND_SEQ_EVENT_USR_VAR1'}; }
sub SND_SEQ_EVENT_USR_VAR2() { return $k2v{'SND_SEQ_EVENT_USR_VAR2'}; }
sub SND_SEQ_EVENT_USR_VAR3() { return $k2v{'SND_SEQ_EVENT_USR_VAR3'}; }
sub SND_SEQ_EVENT_USR_VAR4() { return $k2v{'SND_SEQ_EVENT_USR_VAR4'}; }
sub SND_SEQ_QUEUE_DIRECT() { return $k2v{'SND_SEQ_QUEUE_DIRECT'}; }
sub SND_SEQ_TIME_STAMP_REAL() { return $k2v{'SND_SEQ_TIME_STAMP_REAL'}; }

#----------------- public functions from alsaseq.py  -----------------
sub client {
	my ($name, $ninputports, $noutputports, $createqueue) = @_;
    if ($ninputports > $maximum_nports) {
        warn("MIDI::ALSA::client: only $maximum_nports input ports are allowed.\n");
        return 0;
    } elsif ($noutputports > $maximum_nports) {
        warn("MIDI::ALSA::client: only $maximum_nports output ports are allowed.\n");
        return 0;
    }
    return &xs_client($name, $ninputports, $noutputports, $createqueue);
}

sub connectfrom { my ($myport, $src_client, $src_port) = @_;
	if (!defined $src_port and $src_client =~ /^(\d+):(\d+)$/) { # 1.03 ?
		$src_client = 0+$1; $src_port = 0+$2;
	}
    return &xs_connectfrom($myport, $src_client, $src_port);
}
sub connectto { my ($myport, $dest_client, $dest_port) = @_;
	if (!defined $dest_port and $dest_client =~ /^(\d+):(\d+)$/) { # 1.03 ?
		$dest_client = 0+$1; $dest_port = 0+$2;
	}
    return &xs_connectto($myport, $dest_client, $dest_port);
}
sub disconnectfrom { my ($myport, $src_client, $src_port) = @_;
	if (!defined $src_port and $src_client =~ /^(\d+):(\d+)$/) { # 1.03 ?
		$src_client = 0+$1; $src_port = 0+$2;
	}
    return &xs_disconnectfrom($myport, $src_client, $src_port);
}
sub disconnectto { my ($myport, $dest_client, $dest_port) = @_;
	if (!defined $dest_port and $dest_client =~ /^(\d+):(\d+)$/) { # 1.03 ?
		$dest_client = 0+$1; $dest_port = 0+$2;
	}
    return &xs_disconnectto($myport, $dest_client, $dest_port);
}
sub fd {
    return &xs_fd();
}
sub id {
    return &xs_id();
}
sub input {
    my @ev = &xs_input();
	if (! @ev) { return undef; }   # 1.04 probably received an interrupt
	my @data = @ev[9..$#ev];
	if ($ev[0] == SND_SEQ_EVENT_SYSEX) { # there's only one element in @data;
		# If you receive a sysex remember the data-string starts
		# with a F0 and and ends with a F7.  "\xF0}hello world\xF7"
		# If you're receiving a multiblock sysex, the first block has its
		# F0 at the beginning, and the last block has a F7 at the end.
    	return ( $ev[0], $ev[1], $ev[2], $ev[3], $ev[4],
		  [$ev[5],$ev[6]], [$ev[7],$ev[8]], [$data[0]] );
		# We could test for a top bit set and if so return undef ...
		# but that would mean every caller would have to test for undef :-(
		# We can't just hang waiting for the next event, because the caller
		# may have called inputpending() and probably doesn't want to hang.
	} else {
    	return ( $ev[0], $ev[1], $ev[2], $ev[3], $ev[4],
		  [$ev[5],$ev[6]], [$ev[7],$ev[8]], [@data] );
	}
}
sub inputpending {
    return &xs_inputpending();
}
sub output { my @ev = @_;
	if (! @ev) { return 0; }
	my @src  = @{$ev[5]};
	my @dest = @{$ev[6]};
	my @data = @{$ev[7]};
	if ($ev[0] == SND_SEQ_EVENT_SYSEX) { # $data[0]=length, $data[6]=char*
		my $s = "$data[0]";
		# If you're sending a sysex remember the data-string needs an F0
		# and an F7.  (SND_SEQ_EVENT_SYSEX, ...., ["\xF0}hello world\xF7"])
		# ( If you're sending a multiblock sysex, the first block needs its
		#   F0 at the beginning, and the last block needs a F7 at the end. )
		if ($s =~ /^\xF0.*[\x80-\xF6\xF8-\xFF]/) {
			if (length($s) > 16) { $s = substr($s,0,14).'...'; }
			warn "MIDI::ALSA::output: SYSEX data '$s' has a top bit set\n";
			return undef;
			# some misgivings... this is stricter than aplaymidi, and than alsa
		}
		return &xs_output($ev[0], $ev[1], $ev[2], $ev[3], $ev[4],
		  $src[0],$src[1], $dest[0],$dest[1],
		  length($s),1,2,3,4,5,$s);   #  (encoding?)
	} else {
		return &xs_output($ev[0], $ev[1], $ev[2], $ev[3], $ev[4],
		  $src[0],$src[1], $dest[0],$dest[1],
		  $data[0], $data[1], $data[2],$data[3],$data[4]||0,$data[5]||0,q{});
	}
}
sub start {
	my $rc = &xs_start();
	return $rc;
}
sub status {
	return &xs_status();
}
sub stop {
	return &xs_stop();
}
sub syncoutput {
	return &xs_syncoutput();
}
# ---------------- public functions from alsamidi.py  -----------------

sub noteevent { my ($ch,$key,$vel,$start,$duration ) = @_;
	return ( SND_SEQ_EVENT_NOTE, SND_SEQ_TIME_STAMP_REAL,
		0, 0, $start, [ 0,0 ], [ 0,0 ],
		[$ch,$key,$vel, $vel, int(0.5 + 1000*$duration) ] );
}
sub noteonevent { my ($ch,$key,$vel ) = @_;
	return ( SND_SEQ_EVENT_NOTEON, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], [$ch,$key,$vel, 0, 0 ] );
}
sub noteoffevent { my ($ch,$key,$vel ) = @_;
	return ( SND_SEQ_EVENT_NOTEOFF, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], [$ch,$key,$vel, $vel, 0 ] );
}
sub pgmchangeevent { my ($ch,$value,$start ) = @_;
	# If start is not provided, the event will be sent directly.
	if (! defined $start) {
		return ( SND_SEQ_EVENT_PGMCHANGE, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], [$ch, 0, 0, 0, 0,$value ] );
	} else {
		return ( SND_SEQ_EVENT_PGMCHANGE, SND_SEQ_TIME_STAMP_REAL,
		0, 0, $start,
		[ 0,0 ], [ 0,0 ], [$ch, 0, 0, 0, 0,$value ] );
	}
}
sub pitchbendevent { my ($ch,$value,$start ) = @_;
	# If start is not provided, the event will be sent directly.
	if (! defined $start) {
		return ( SND_SEQ_EVENT_PITCHBEND, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], [$ch, 0,0,0,0, $value ] );
	} else {
		return ( SND_SEQ_EVENT_PITCHBEND, SND_SEQ_TIME_STAMP_REAL,
		0, 0, $start,
		[ 0,0 ], [ 0,0 ], [$ch, 0,0,0,0, $value ] );
	}
}
sub controllerevent { my ($ch,$key,$value,$start ) = @_;  # 1.05
	# If start is not provided, the event will be sent directly.
	if (! defined $start) {
		return ( SND_SEQ_EVENT_CONTROLLER, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], [$ch, 0,0,0, $key, $value ] );
	} else {
		return ( SND_SEQ_EVENT_CONTROLLER, SND_SEQ_TIME_STAMP_REAL,
		0, 0, $start,
		[ 0,0 ], [ 0,0 ], [$ch, 0,0,0, $key, $value ] );
	}
}
sub chanpress { my ($ch,$value,$start ) = @_;
	# If start is not provided, the event will be sent directly.
	if (! defined $start) {
		return ( SND_SEQ_EVENT_CHANPRESS, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], [$ch, 0,0,0,0, $value ] );
	} else {
		return ( SND_SEQ_EVENT_CHANPRESS, SND_SEQ_TIME_STAMP_REAL,
		0, 0, $start,
		[ 0,0 ], [ 0,0 ], [$ch, 0,0,0,0, $value ] );
	}
}
sub sysex { my ($ch,$value,$start ) = @_;
	if ($value =~ /[\x80-\xFF]/) {
		warn "sysex: the string $value has top-bits set :-(\n";
		return undef;
	}
	if (! defined $start) {
		return ( SND_SEQ_EVENT_SYSEX, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], ["\xF0$value\xF7",] );
	} else {
		return ( SND_SEQ_EVENT_SYSEX, SND_SEQ_TIME_STAMP_REAL,
		0, 0, $start,
		[ 0,0 ], [ 0,0 ], ["\xF0$value\xF7",] );
	}
}


#------------ public functions to handle MIDI.lua events  -------------
# for MIDI.lua events see http://www.pjb.com.au/comp/lua/MIDI.html#events
# for data args see http://alsa-project.org/alsa-doc/alsa-lib/seq.html
# http://alsa-project.org/alsa-doc/alsa-lib/group___seq_events.html

my %chapitch2note_on_events = ();  # this mechanism courtesy of MIDI.lua
sub alsa2scoreevent { my @alsaevent = @_;
	if (@alsaevent<8) { warn "alsa2scoreevent: event too short\n"; return (); }
	my $ticks = int(0.5 + 1000*$alsaevent[4]);
	my $func  = 'MIDI::ALSA::alsa2scoreevent';
	my @data  = @{$alsaevent[7]};   # deepcopy needed?
	# snd_seq_ev_note_t: channel, note, velocity, off_velocity, duration
	if ($alsaevent[0] == SND_SEQ_EVENT_NOTE) {
		return ( 'note',$ticks,$data[4],$data[0],$data[1],$data[2] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_NOTEOFF
	 or ($alsaevent[0] == SND_SEQ_EVENT_NOTEON and !$data[2])) {
		my $cha = $data[0];
		my $pitch = $data[1];
		my $key = $cha*128 + $pitch;
		my @pending_notes = @{$chapitch2note_on_events{$key}};
		if (@pending_notes and @pending_notes > 0) {  # 1.04
			my $new_e = pop @pending_notes; # pop
			$new_e->[2] = $ticks - $new_e->[1];
			return @{$new_e};
		} elsif ($pitch > 127) {
			warn("$func: note_off with no note_on, bad pitch=$pitch");
			return undef;
		} else {
			warn("$func: note_off with no note_on cha=$cha pitch=$pitch");
			return undef;
		}
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_NOTEON) {
		my $cha = $data[0];
		my $pitch = $data[1];
		my $key = $cha*128 + $pitch;
		my $new_e = ['note',$ticks,0,$cha,$pitch,$data[2]];
		if ($chapitch2note_on_events{$key}) {
			push @{$chapitch2note_on_events[$key]}, $new_e;
		} else {
			$chapitch2note_on_events{$key} = [ $new_e ];  # 1.04
		}
		return undef;
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_CONTROLLER) {
		return ( 'control_change',$ticks,$data[0],$data[4],$data[5] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_PGMCHANGE) {
		return ( 'patch_change',$ticks,$data[0],$data[5] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_PITCHBEND) {
		return ( 'pitch_wheel_change',$ticks,$data[0],$data[5] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_CHANPRESS) {
		return ( 'channel_after_touch',$ticks,$data[0],$data[5] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_SYSEX) {  # 1.04
		my $s = $data[0];
		if ($s =~ s/^\xF0//) { return ( 'sysex_f0',$ticks,$s );
		}      else          { return ( 'sysex_f7',$ticks,$s );
		}
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_PORT_SUBSCRIBED
	      or $alsaevent[0] == SND_SEQ_EVENT_PORT_UNSUBSCRIBED) {
		return undef; # only have meaning to an ALSA client
	} else {
		warn("$func: unsupported event-type $alsaevent[0]\n");
		return undef;
	}
}
sub scoreevent2alsa { my @event = @_;
	# what's this? 1.03 already and completely missing !
    my $time_in_secs = 0.001*$event[1];  # ms ticks -> secs
    if ($event[0] eq 'note') {
        # note on and off with duration; event data type = snd_seq_ev_note_t
        return ( SND_SEQ_EVENT_NOTE, SND_SEQ_TIME_STAMP_REAL,
         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ],
         [ $event[3], $event[4], $event[5], 0, $event[2] ] );
    } elsif ($event[0] eq 'control_change') {
        # controller; snd_seq_ev_ctrl_t; channel, unused[3], param, value
        return ( SND_SEQ_EVENT_CONTROLLER, SND_SEQ_TIME_STAMP_REAL,
         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ],
         [ $event[2], 0,0,0, $event[3], $event[4] ] );
    } elsif ($event[0] eq 'patch_change') {
        # program change; data type=snd_seq_ev_ctrl_t, param is ignored
        return ( SND_SEQ_EVENT_PGMCHANGE, SND_SEQ_TIME_STAMP_REAL,
         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ],
         [ $event[2], 0,0,0, 0, $event[3] ] );
    } elsif ($event[0] eq 'pitch_wheel_change') {
        # pitchwheel; snd_seq_ev_ctrl_t; data is from -8192 to 8191
        return ( SND_SEQ_EVENT_PITCHBEND, SND_SEQ_TIME_STAMP_REAL,
         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ],
         [ $event[2], 0,0,0, 0, $event[3] ] );
    } elsif ($event[0] eq 'channel_after_touch') {
        # channel_after_touch; snd_seq_ev_ctrl_t; data is from -8192 to 8191
        return ( SND_SEQ_EVENT_CHANPRESS, SND_SEQ_TIME_STAMP_REAL,
         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ],
         [ $event[2], 0,0,0, 0, $event[3] ] );
#    } elsif ($event[0] eq 'key_signature') {
#        # key_signature; snd_seq_ev_ctrl_t; data is from -8192 to 8191
#        return ( SND_SEQ_EVENT_KEYSIGN, SND_SEQ_TIME_STAMP_REAL,
#         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ],
#         [ $event[2], 0,0,0, $event[3], $event[4] ] );
#    } elsif ($event[0] eq 'set_tempo') {
#        # set_tempo; snd_seq_ev_queue_control
#        return ( SND_SEQ_EVENT_TEMPO, SND_SEQ_TIME_STAMP_REAL,
#         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ],
#         [ $event[2], 0,0,0, 0, 0 ] );
    } elsif ($event[0] eq 'sysex_f0') {
		# If you're sending a sysex remember the data-string needs an
		# an F7 at the end.  ('sysex_f0', $ticks, "}hello world\xF7")
		# If you're sending a multiblock sysex, the first block should
		# be a sysex_f0, all subsequent blocks should be sysex_f7's,
		# of which the last block needs a F7 at the end.
		my $s = $event[2];
		$s =~ s/^([^\xF0])/\xF0$1/;
        return ( SND_SEQ_EVENT_SYSEX, SND_SEQ_TIME_STAMP_REAL,
         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ], [ $s, ] );
    } elsif ($event[0] eq 'sysex_f7') {
		# If you're sending a multiblock sysex, the first block should
		# be a sysex_f0, all subsequent blocks should be sysex_f7's,
		# of which the last block needs a F7 at the end.
		# You can also use a sysex_f7 to sneak in a MIDI command that
		# cannot be otherwise specified in .mid files, such as System
		# Common messages except SysEx, or System Realtime messages.
		# E.g., you can output a MIDI Tune-Request message (F6) by
		# ('sysex_f7', <delta>, "\xF6") which will put the event
		# "<delta> F7 01 F6" into the .mid file, and hence the
		# byte F6 onto the wire.
        return ( SND_SEQ_EVENT_SYSEX, SND_SEQ_TIME_STAMP_REAL,
         0, 0, $time_in_secs, [ 0,0 ], [ 0,0 ], [ $event[2], ] );
    } else {
        # Meta-event, or unsupported event
        return undef;
    }
}

# 1.03
sub listclients {
	return &xs_listclients(0);
}
sub listnumports { # returns (14->2,20->1,128->4)
	return &xs_listclients(1);
}
sub listconnectedto { # returns ([0,14,1], [1,20,0])
	my @flat = &xs_listconnections(0);
	my @lol  = (); my $ifl = $[; my $ilol = $[;
	while ($ifl < $#flat) {
		push @{$lol[$ilol]}, 0+$flat[$ifl];  $ifl += 1;
		push @{$lol[$ilol]}, 0+$flat[$ifl];  $ifl += 1;
		push @{$lol[$ilol]}, 0+$flat[$ifl];  $ifl += 1;
		$ilol += 1;
	}
	return @lol;
}
sub listconnectedfrom { # returns ([1,32,0], [0,36,0])
	my @flat = &xs_listconnections(1);
	my @lol  = (); my $ifl = $[; my $ilol = $[;
	while ($ifl < $#flat) {
		push @{$lol[$ilol]}, 0+$flat[$ifl];  $ifl += 1;
		push @{$lol[$ilol]}, 0+$flat[$ifl];  $ifl += 1;
		push @{$lol[$ilol]}, 0+$flat[$ifl];  $ifl += 1;
		$ilol += 1;
	}
	return @lol;
}

1;

__END__

=pod

=head1 NAME

MIDI::ALSA - the ALSA library, plus some interface functions

=head1 SYNOPSIS

 use MIDI::ALSA(SND_SEQ_EVENT_PORT_UNSUBSCRIBED);
 MIDI::ALSA::client( 'Perl MIDI::ALSA client', 1, 1, 0 );
 MIDI::ALSA::connectfrom( 0, 14, 0 );  # input port is lower (0)
 MIDI::ALSA::connectto( 1, 20, 0 );   # output port is higher (1)
 while (1) {
     my @alsaevent = MIDI::ALSA::input();
     if ($alsaevent[0] == SND_SEQ_EVENT_PORT_UNSUBSCRIBED()) { last; }
     MIDI::ALSA::output( @alsaevent );
 }

=head1 DESCRIPTION

This module offers a Perl interface to the I<ALSA> library.
It is a call-compatible translation into Perl of the Lua module
I<midialsa> http://www.pjb.com.au/comp/lua/midialsa.html
which is in turn based on the Python modules
I<alsaseq.py> and I<alsamidi.py> by Patricio Paez.

It also offers some functions to translate events from and to
the event format used in Sean Burke's MIDI-Perl module.

Nothing is exported by default,
but all the functions and constants can be exported, e.g.:
 use MIDI::ALSA(client, connectfrom, connectto, id, input, output);
 use MIDI::ALSA(':CONSTS');

The event-type constants, beginning with SND_SEQ_,
are available not as scalars, but as module subroutines with empty prototypes.
They must therefore be used without a dollar-sign e.g.:
 if ($event[0] == MIDI::ALSA::SND_SEQ_EVENT_PORT_UNSUBSCRIBED) { ...

=head1 FUNCTIONS

Functions based on those in I<alsaseq.py>:
client(), connectfrom(), connectto(), disconnectfrom(), disconnectto(), fd(),
id(), input(), inputpending(), output(), start(), status(), stop(), syncoutput()

Functions based on those in I<alsamidi.py>:
noteevent(), noteonevent(), noteoffevent(), pgmchangeevent(),
pitchbendevent(), controllerevent(), chanpress(), sysex()

Functions to interface with I<MIDI-Perl>:
alsa2scoreevent(), scoreevent2alsa()

Functions to get the current ALSA status:
listclients(), listnumports(), listconnectedto(), listconnectedfrom()

=over 3

=item client($name, $ninputports, $noutputports, $createqueue)

Create an ALSA sequencer client with zero or more input or output ports,
and optionally a timing queue.  ninputports and noutputports are created
if the quantity requested is between 1 and 4 for each.
If I<createqueue> = true, it creates a queue for stamping the arrival time
of incoming events and scheduling future start times of outgoing events.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

=item connectfrom( $inputport, $src_client, $src_port )

Connect from I<src_client:src_port> to I<inputport>. Each input port can
connect from more than one client. The I<input()> function will receive events
from any intput port and any of the clients connected to each of them.
Events from each client can be distinguised by their source field.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

=item connectto( $outputport, $dest_client, $dest_port )

Connect outputport to I<dest_client:dest_port>. Each output port can be
Connected to more than one client. Events sent to an output port using
the I<output>()  funtion will be sent to all clients that are connected to
it using this function.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

=item disconnectfrom( $inputport, $src_client, $src_port )

Disconnect the connection
from the remote I<src_client:src_port> to my I<inputport>.
Returns success or failure.

=item disconnectto( $outputport, $dest_client, $dest_port )

Disconnect the connection
from my I<outputport> to the remote I<dest_client:dest_port>.
Returns success or failure.

=item fd()

Return fileno of sequencer.

=item id()

Return the client number, or 0 if the client is not yet created.

=item input()

Wait for an ALSA event in any of the input ports and return it.
ALSA events are returned as an array with 8 elements:

 ($type, $flags, $tag, $queue, $time, \@source, \@destination, \@data)

Unlike in the I<alsaseq.py> Python module,
the time element is in floating-point seconds.
The last three elements are also arrays:

 @source = ( $src_client,  $src_port )
 @destination = ( $dest_client,  $dest_port )
 @data = ( varies depending on type )

The I<source> and I<destination> arrays may be useful within an application
for handling events differently according to their source or destination.
The event-type constants, beginning with SND_SEQ_,
are available as module subroutines with empty prototypes,
not as strings, and must therefore be used without any dollar-sign e.g.:

 if ($event[0] == MIDI::ALSA::SND_SEQ_EVENT_PORT_UNSUBSCRIBED) { ...

Note that if the event is of type SND_SEQ_EVENT_PORT_UNSUBSCRIBED
then the remote client and port do not get set;
you need to use listconnected() to see what's happened.

The data array is mostly as documented in
http://alsa-project.org/alsa-doc/alsa-lib/seq.html.
For NOTE events,  the elements are
( $channel, $pitch, $velocity, unused, $duration );
For SYSEX events, the data array contains just one element:
the byte-string, including any F0 and F7 bytes.
For most other events,  the elements are
($channel, unused,unused,unused, $param, $value)

=item inputpending()

Return the number of bytes available in input buffer.
Use before input()  to wait till an event is ready to be read. 
If a connection terminates, then inputpending() returns,
and the next event will be of type SND_SEQ_EVENT_PORT_UNSUBSCRIBED

=item output($type,$flags,$tag,$queue,$time,\@source,\@destination,\@data)

Send an ALSA-event-array to an output port.
The format of the event is discussed in input() above.
The event will be output immediately
either if no queue was created in the client,
or if the I<queue> parameter is set to SND_SEQ_QUEUE_DIRECT
and otherwise it will be queued and scheduled.

If only one port exists, all events are sent to that port. If two or
more output ports exist, the I<dest_port> of the event determines
which to use.
The smallest available port-number ( as created by I<client>() )
will be used if I<dest_port> is less than it,
and the largest available port-number
will be used if I<dest_port> is greater than it.

An event sent to an output port will be sent to all clients
that were subscribed using the I<connectto>() function.

If the queue buffer is full, I<output>() will wait
until space is available to output the event.
Use I<status>() to know how many events are scheduled in the queue.

=item start()

Start the queue. It is ignored if the client does not have a queue. 

=item status()

Return ($status,$time,$events ) of the queue.

 Status: 0 if stopped, 1 if running.
 Time: current time in seconds.
 Events: number of output events scheduled in the queue.

If the client does not have a queue then (0,0,0) is returned.
Unlike in the I<alsaseq.py> Python module,
the I<time> element is in floating-point seconds.

=item stop()

Stop the queue. It is ignored if the client does not have a queue. 

=item syncoutput()

Wait until output events are processed.

=item noteevent( $ch, $key, $vel, $start, $duration )

Returns an ALSA-event-array, to be scheduled by I<output>().
Unlike in the I<alsaseq.py> Python module,
the I<start> and I<duration> elements are in floating-point seconds.

=item noteonevent( $ch, $key, $vel )

Returns an ALSA-event-array to be sent directly with I<output>().

=item noteoffevent( $ch, $key, $vel )

Returns an ALSA-event-array to be sent directly with I<output>().

=item pgmchangeevent( $ch, $value, $start )

Returns an ALSA-event-array to be sent by I<output>().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item pitchbendevent( $ch, $value, $start )

Returns an ALSA-event-array to be sent by I<output>().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item controllerevent( $ch, $controllernum, $value, $start )

Returns an ALSA-event-array to be sent by I<output>().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.


=item chanpress( $ch, $value, $start )

Returns an ALSA-event-array to be sent by I<output>().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item sysex( $ch, $string, $start )

Returns an ALSA-event-array to be sent by I<output>().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
The string should start with your Manufacturer ID,
but should not contain any of the F0 or F7 bytes,
they will be added automatically;
indeed the string must not contain any bytes with the top-bit set.

=item alsa2scoreevent( @alsaevent )

Returns an event in the millisecond-tick score-format
used by the I<MIDI.lua> and I<MIDI.py> modules,
based on the score-format in Sean Burke's MIDI-Perl CPAN module. See:
 http://www.pjb.com.au/comp/lua/MIDI.html#events

Since it combines a I<note_on> and a I<note_off> event into one note event,
it will return I<nil> when called with the I<note_on> event;
the calling loop must therefore detect I<nil>
and not, for example, try to index it.

=item scoreevent2alsa( @event )

Returns an ALSA-event-array to be scheduled in a queue by I<output>().
The input is an event in the millisecond-tick score-format
used by the I<MIDI.lua> and I<MIDI.py> modules,
based on the score-format in Sean Burke's MIDI-Perl CPAN module. See:
 http://www.pjb.com.au/comp/lua/MIDI.html#events

For example:
 output(scoreevent2alsa('note',4000,1000,0,62,110))

Some events in a .mid file have no equivalent
real-time-midi event (which is the sort that ALSA deals in);
these events will cause scoreevent2alsa() to return undef.
Therefore if you are going through the events in a midi score
converting them with scoreevent2alsa(),
you should check that the result is not undef before doing anything further.

=item listclients()

Returns a hash of the numbers and descriptive strings of all ALSA clients:

 my %clientnumber2clientname = MIDI::ALSA::listclients();
 my %clientname2clientnumber = reverse %clientnumber2clientname;

=item listnumports()

Returns a hash of the client-numbers and how many ports they are running,
so if a client is running 4 ports they will be numbered 0..3

 my %clientnumber2howmanyports = MIDI::ALSA::listnumports();

=item listconnectedto()

Returns a list of arrayrefs, each to a three-element array
( $outputport, $dest_client, $dest_port )
exactly as might have been passed to connectto(),
or which could be passed to disconnectto().

=item listconnectedfrom()

Returns a list of arrayrefs, each to a three-element array
( $inputport, $src_client, $src_port )
exactly as might have been passed to connectfrom(),
or which could be passed to disconnectfrom().

=back

=head1 DOWNLOAD

This Perl version is available from CPAN at
http://search.cpan.org/perldoc?MIDI::ALSA

The Lua module is available as a LuaRock in
http://luarocks.org/repositories/rocks/index.html#midi
so you should be able to install it with the command:
 # luarocks install midialsa

=head1 TO DO

Perhaps there should be a general connect_between() mechanism,
allowing the interconnection of two other clients,
a bit like I<aconnect 32 20>

If an event is of type SND_SEQ_EVENT_PORT_UNSUBSCRIBED
then the remote client and port seem to be zeroed-out,
which makes it hard to know which client has just disconnected.
You have to consult listconnectedto() and listconnectedfrom()

ALSA does not transmit Meta-Events like I<text_event>,
and there's not much can be done about that.

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 aconnect -oil
 http://pp.com.mx/python/alsaseq
 http://search.cpan.org/perldoc?MIDI::ALSA
 http://www.pjb.com.au/comp/lua/midialsa.html
 http://luarocks.org/repositories/rocks/index.html#midialsa
 http://www.pjb.com.au/comp/lua/MIDI.html
 http://www.pjb.com.au/comp/lua/MIDI.html#events
 http://alsa-project.org/alsa-doc/alsa-lib/seq.html
 http://alsa-project.org/alsa-doc/alsa-lib/structsnd__seq__ev__note.html
 http://alsa-project.org/alsa-doc/alsa-lib/structsnd__seq__ev__ctrl.html
 http://alsa-project.org/alsa-doc/alsa-lib/structsnd__seq__ev__queue__control.html
 http://alsa-project.org/alsa-doc/alsa-lib/group___seq_client.html
 http://alsa-utils.sourcearchive.com/documentation/1.0.20/aconnect_8c-source.html 
 http://alsa-utils.sourcearchive.com/documentation/1.0.8/aplaymidi_8c-source.html
 snd_seq_client_info_event_filter_clear
 snd_seq_get_any_client_info
 snd_seq_get_client_info
 snd_seq_client_info_t

=cut

