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
$VERSION = '1.01';
# gives a -w warning, but I'm afraid $VERSION .= ''; would confuse CPAN
# use DynaLoader 'DYNALOADER';
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();
@EXPORT_OK = qw(client connectfrom connectto fd id
 input inputpending output start status stop syncoutput
 noteevent noteonevent noteoffevent pgmchangeevent pitchbendevent chanpress 
 alsa2opusevent alsa2scoreevent scoreevent2alsa rawevent2alsa);
%EXPORT_TAGS = (ALL => [@EXPORT,@EXPORT_OK]);
bootstrap MIDI::ALSA $VERSION;

my $maximum_nports = 4;
#------------- public constants from alsa/asoundlib.h  -------------
my %k2v = &xs_constname2value();
while (my ($k,$v) = each %k2v) {
	push @EXPORT_OK, $k;
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
sub input {
    my @ev = &xs_input();
	my @data = @ev[9..$#ev];
    return ( $ev[0], $ev[1], $ev[2], $ev[3], $ev[4],
     [$ev[5],$ev[6]], [$ev[7],$ev[8]], [@data] )

}
sub inputpending {
    return &xs_inputpending();
}
sub connectfrom { my ($myport, $src_lient, $src_port) = @_;
    return &xs_connectfrom($myport, $src_lient, $src_port);
}
sub connectto { my ($myport, $dest_lient, $dest_port) = @_;
    return &xs_connectto($myport, $dest_lient, $dest_port);
}
sub fd {
    return &xs_fd();
}
sub id {
    return &xs_id();
}
sub output { my @ev = @_;
	if (! @ev) { return 0; }
	my @src  = @{$ev[5]};
	my @dest = @{$ev[6]};
	my @data = @{$ev[7]};
	return &xs_output($ev[0], $ev[1], $ev[2], $ev[3], $ev[4],
	 $src[0],$src[1], $dest[0],$dest[1],
	 $data[0],$data[1],$data[2],$data[3],$data[4]||0,$data[5]||0);

}
sub start {
	return &xs_start();
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
		[$ch,$key,$vel, 0, int(0.5 + 1000*$duration) ] );
}
sub noteonevent { my ($ch,$key,$vel ) = @_;
	return ( SND_SEQ_EVENT_NOTEON, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], [$ch,$key,$vel, 0, 0 ] );
}
sub noteoffevent { my ($ch,$key,$vel ) = @_;
	return ( SND_SEQ_EVENT_NOTEOFF, SND_SEQ_TIME_STAMP_REAL,
		0, SND_SEQ_QUEUE_DIRECT, 0,
		[ 0,0 ], [ 0,0 ], [$ch,$key,$vel, 0, 0 ] );
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


#------------ public functions to handle MIDI.lua events  -------------
# for MIDI.lua events see http://www.pjb.com.au/comp/lua/MIDI.html#events
# for data args see http://alsa-project.org/alsa-doc/alsa-lib/seq.html
# http://alsa-project.org/alsa-doc/alsa-lib/group___seq_events.html

my $ticks_so_far = 0;
my %chapitch2note_on_events = ();  # this mechanism courtesy of MIDI.lua
my $want_score = 0;
sub alsa2opusevent { my @alsaevent = @_;
	my $new_ticks = int(0.5 + 1000*$alsaevent[4]);
	my $ticks;
	my $function_name;
	if ($want_score) {
		$function_name = 'MIDI::ALSA::alsa2scoreevent';
		$ticks = $new_ticks;
	} else {
		$function_name = 'MIDI::ALSA::alsa2opusevent';
		$ticks = $new_ticks - $ticks_so_far;
		if ($ticks < 0) { $ticks = 0; }
		$ticks_so_far = $new_ticks;
	}
	my @data = @{$alsaevent[7]};   # deepcopy?
	# snd_seq_ev_note_t: channel, note, velocity, off_velocity, duration
	if ($alsaevent[0] == SND_SEQ_EVENT_NOTE) {
		return ( 'note',$ticks,$data[4],$data[0],$data[1],$data[2] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_NOTEOFF
	 or ($alsaevent[0] == SND_SEQ_EVENT_NOTEON and $data[2] == 0)) {
		if ($want_score) {
			$want_score = 0;  # 1.01
			my $cha = $data[0];
			my $pitch = $data[1];
			my $key = $cha*128 + $pitch;
			my @pending_notes = @{$chapitch2note_on_events{$key}};
			if (@pending_notes and $pending_notes > 0) {
				my $new_e = pop @pending_notes; # pop
				$new_e->[2] = $ticks - $new_e->[1];
				return @{$new_e};
			} elsif ($pitch > 127) {
				warn("$function_name: note_off with no note_on, bad pitch=$pitch");
				return undef;
			} else {
				warn("$function_name: note_off with no note_on cha=$cha pitch=$pitch");
				return undef;
			}
		} else {
			return ( 'note_off',$ticks,$data[0],$data[1],$data[2] )
		}
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_NOTEON) {
		my $cha = $data[0];
		my $pitch = $data[1];
		if ($want_score) {
			my $key = $cha*128 + $pitch;
			my $new_e = ['note',$ticks,0,$cha,$pitch,$data[2]];
			if ($chapitch2note_on_events{$key}) {
				push @{$chapitch2note_on_events[$key]}, $new_e;
			} else {
				$chapitch2note_on_events{$key} = $new_e;
			}
		} else {
			return ( 'note_on',$ticks,$cha,$pitch,$data[2] );
		}
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_CONTROLLER) {
		$want_score = 0;  # 1.01
		return ( 'control_change',$ticks,$data[0],$data[4],$data[5] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_PGMCHANGE) {
		$want_score = 0;  # 1.01
		return ( 'patch_change',$ticks,$data[0],$data[5] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_PITCHBEND) {
		$want_score = 0;  # 1.01
		return ( 'pitch_wheel_change',$ticks,$data[0],$data[5] );
	} elsif ($alsaevent[0] == SND_SEQ_EVENT_CHANPRESS) {
		$want_score = 0;  # 1.01
		return ( 'channel_after_touch',$ticks,$data[0],$data[5] );
	} else {
		$want_score = 0;  # 1.01
		warn("$function_name: unsupported event-type $alsaevent[0]\n");
		return undef;
	}
	$want_score = 0;
	return;
}
sub alsa2scoreevent {
	$want_score = 1;
	return alsa2opusevent(@_);
}
sub scoreevent2alsa { my @event = @_;
}
sub rawevent2alsa {
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
     if ($alsaevent[0] == SND_SEQ_EVENT_PORT_UNSUBSCRIBED) { last; }
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

The event-type constants, beginning with SND_SEQ_,
are available not as scalars, but as module subroutines with empty prototypes.
They must therefore be used without a dollar-sign e.g.:
 if ($event[0] == MIDI::ALSA::SND_SEQ_EVENT_PORT_UNSUBSCRIBED) { ...

=head1 FUNCTIONS

Functions based on those in I<alsaseq.py>:
client(), connectfrom(), connectto(), fd(), id(), input(), inputpending(),
output(), start(), status(), stop(), syncoutput()

Functions based on those in I<alsamidi.py>:
noteevent(), noteonevent(), noteoffevent(), pgmchangeevent(),
pitchbendevent(), chanpress()

Functions to interface with I<MIDI-Perl>:
alsa2opusevent(), alsa2scoreevent(), scoreevent2alsa(), rawevent2alsa()

=over 3

=item I<client>(name, ninputports, noutputports, createqueue)

Create an ALSA sequencer client with zero or more input or output ports,
and optionally a timing queue.  ninputports and noutputports are created
if the quantity requested is between 1 and 4 for each.
If createqueue = true, it creates a queue for stamping the arrival time of
incoming events and scheduling future start times of outgoing events.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

=item I<connectfrom>( inputport, src_client, src_port )

Connect from src_client:src_port to inputport. Each input port can connect
from more than one client. The input() function will receive events
from any intput port and any of the clients connected to each of them.
Events from each client can be distinguised by their source field.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

=item I<connectto>( outputport, dest_client, dest_port )

Connect outputport to dest_client:dest_port. Each outputport can be
Connected to more than one client. Events sent to an output port using
the output()  funtion will be sent to all clients that are connected to
it using this function.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

=item I<fd>()

Return fileno of sequencer.

=item I<id>()

Return the client number, or 0 if the client is not yet created.

=item I<input>()

Wait for an ALSA event in any of the input ports and return it.
ALSA events are returned as an array with 8 elements:

 {type, flags, tag, queue, time, source, destination, data}

Unlike in the I<alsaseq.py> Python module,
the time element is in floating-point seconds.
The last three elements are also arrays:

 source = { src_client,  src_port }
 destination = { dest_client,  dest_port }
 data = { varies depending on type }

The I<source> and I<destination> arrays may be useful within an application
for handling events differently according to their source or destination.
The event-type constants, beginning with SND_SEQ_,
are available as module subroutines with empty prototypes,
not as strings, and must therefore be used without any dollar-sign e.g.:

 if ($event[0] == MIDI::ALSA::SND_SEQ_EVENT_PORT_UNSUBSCRIBED) { ...

Note that if the event is of type SND_SEQ_EVENT_PORT_UNSUBSCRIBED
then the remote client and port do not seem to be correct...

The data array is documented in
http://alsa-project.org/alsa-doc/alsa-lib/seq.html

=item I<inputpending>()

Return the number of bytes available in input buffer.
Use before input()  to wait till an event is ready to be read. 
If a connection terminates, then inputpending() returns,
and the next event will be of type SND_SEQ_EVENT_PORT_UNSUBSCRIBED

=item I<output>( {type, flags, tag, queue, time, source, destination, data} )

Send an ALSA-event-array to an output port.
The format of the event is dicussed in input() above.
The event will be output immediately
either if no queue was created in the client,
or if the I<queue> parameter is set to SND_SEQ_QUEUE_DIRECT
and otherwise it will be queued and scheduled.

If only one port exists, all events are sent to that port. If two or
more output ports exist, the I<dest_port> of the event determines
which to use.
The smallest available port-number ( as created by client() )
will be used if I<dest_port> is less than it,
and the largest available port-number
will be used if I<dest_port> is greater than it.

An event sent to an output port will be sent to all clients
that were subscribed using the connectto() function.

If the queue buffer is full, output() will wait
until space is available to output the event.
Use status() to know how many events are scheduled in the queue.

=item I<start>(queue)

Start the queue. It is ignored if the client does not have a queue. 

=item I<status>(queue)

Return { status, time, events } of the queue.

 Status: 0 if stopped, 1 if running.
 Time: current time in seconds.
 Events: number of output events scheduled in the queue.

If the client does not have a queue the value {0,0,0} is returned.
Unlike in the I<alsaseq.py> Python module,
the I<time> element is in floating-point seconds.

=item I<stop>(queue)

Stop the queue. It is ignored if the client does not have a queue. 

=item I<syncoutput>(queue)

Wait until output events are processed.

=item I<noteevent>( ch, key, vel, start, duration )

Returns an ALSA-event-array, to be scheduled by output().
Unlike in the I<alsaseq.py> Python module,
the I<start> and I<duration> elements are in floating-point seconds.

=item I<noteonevent>( ch, key, vel )

Returns an ALSA-event-array to be sent directly with output().

=item I<noteoffevent>( ch, key, vel )

Returns an ALSA-event-array to be sent directly with output().

=item I<pgmchangeevent>( ch, value, start )

Returns an ALSA-event-array to be sent by output().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item I<pitchbendevent>( ch, value, start )

Returns an ALSA-event-array to be sent by output().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item I<chanpress>( ch, value, start )

Returns an ALSA-event-array to be sent by output().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item I<alsa2opusevent>(alsaevent)

Returns an event in the millisecond-tick score-format
used by the I<MIDI.lua> and I<MIDI.py> modules,
based on the opus-format in Sean Burke's MIDI-Perl CPAN module. See:
 http://www.pjb.com.au/comp/lua/MIDI.html#events

=item I<alsa2scoreevent>(alsaevent)

Returns an event in the millisecond-tick score-format
used by the I<MIDI.lua> and I<MIDI.py> modules,
based on the score-format in Sean Burke's MIDI-Perl CPAN module. See:
 http://www.pjb.com.au/comp/lua/MIDI.html#events

Since it combines a I<note_on> and a I<note_off> event into one note event,
it will return I<nil> when called with the I<note_on> event;
the calling loop must therefore detect I<nil>
and not, for example, try to index it.

=item I<scoreevent2alsa>(event)

Returns an ALSA-event-array to be scheduled in a queue by output().
The input is an event in the millisecond-tick score-format
used by the I<MIDI.lua> and I<MIDI.py> modules,
based on the score-format in Sean Burke's MIDI-Perl CPAN module. See:
 http://www.pjb.com.au/comp/lua/MIDI.html#events

For example:
 ALSA.output(ALSA.scoreevent2alsa{'note',4000,1000,0,62,110})

=item I<rawevent2alsa>()

Unimplemented

=back

=head1 DOWNLOAD

This Perl version is available from CPAN at
http://search.cpan.org/perldoc?MIDI::ALSA

The Lua module is available as a LuaRock in
http://luarocks.org/repositories/rocks/index.html#midi
so you should be able to install it with the command:
 # luarocks install midialsa

=head1 TO DO

Certainly there should be a way of checking the current status
of a connection,
like is_still_connectedto() and is_still_connectedfrom()
or something, so that if a connection has vanished the application
can handle it gracefully.

Probably there should be disconnectto() and disconnectfrom()

Perhaps there should be a general connect_between() mechanism,
allowing the interconnection of two other clients,
a bit like I<aconnect 32 20>

There should be a way of getting the textual information
about the various clients, like "TiMidity" or
"Roland XV-2020" or "Virtual Raw MIDI 2-0" and so on.

If an event is of type SND_SEQ_EVENT_PORT_UNSUBSCRIBED
then the remote client and port seem to be zeroed-out,
which makes it hard to know which client has disconnected.

output() and input() seem to filter out all non-sounding events,
like text_events and sysex; this ought to be adjustable.

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
 snd_seq_client_info_event_filter_clear
 snd_seq_get_any_client_info
 snd_seq_get_client_info
 snd_seq_client_info_t

=cut

