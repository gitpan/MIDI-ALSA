#!/usr/bin/perl -w
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

use MIDI::ALSA qw(:ALL);
# use Class::MakeMethods::Utility::Ref qw( ref_clone ref_compare );
use Data::Dumper;
use Test::Simple tests => 42;

my @virmidi = virmidi_clients_and_files();
if (@virmidi < 4) {
	print("# To run all tests, four virmidi clients are needed...\n");
}

$rc = MIDI::ALSA::inputpending();
ok(! defined $rc, "inputpending() with no client returned undef");

$rc = MIDI::ALSA::client('test.pl',2,2,1);
ok($rc, "client('test.pl',2,2,1)");

if (@virmidi >= 2 ) {
	$rc = MIDI::ALSA::connectfrom(1,$virmidi[0],0);
	ok($rc, "connectfrom(1,$virmidi[0],0)");
} else {
	ok(1, "can't see a virmidi client, so skipping connectfrom()");
}

$rc = MIDI::ALSA::connectfrom(1,133,0);
ok(! $rc, 'connectfrom(1,133,0) correctly returned 0');

if (@virmidi >= 4 ) {
	$rc = MIDI::ALSA::connectto(2,$virmidi[2],0);
	ok($rc, "connectto(2,$virmidi[2],0)");
} else {
	ok(1, "can't see two virmidi clients, so skipping connectto()");
}

$rc = MIDI::ALSA::connectto(1,133,0);
ok(! $rc, 'connectto(1,133,0) correctly returned 0');

$rc = MIDI::ALSA::start();
ok($rc, 'start()');

$fd = MIDI::ALSA::fd();
ok($fd > 0, 'fd()');

$id = MIDI::ALSA::id();
ok($id > 0, "id() returns $id");

my %num2name = MIDI::ALSA::listclients();
ok($num2name{$id} eq 'test.pl', "listclients()");

my %num2nports = MIDI::ALSA::listnumports();
ok($num2nports{$id} == 4, "listnumports()");

if (@virmidi < 2) {
	ok(1, "skipping inputpending() returns $rc");
	ok(1, 'skipping input() test');
	ok(1, 'skipping alsa2scoreevent() test');
	ok(1, 'skipping input() test');
	ok(1, 'skipping alsa2scoreevent() test');
	ok(1, 'skipping input() test');
	ok(1, 'skipping alsa2opusevent() test');
	ok(1, 'skipping input() test');
	ok(1, 'skipping alsa2opusevent() test');
	ok(1, 'skipping listconnectedto() test');
	ok(1, 'skipping listconnectedfrom() test');
} else {
	open(my $inp, '>', $virmidi[1])
	 || die "can't open $virmidi[1]: $!\n";  # client 24
	select($inp); $|=1; select(STDOUT);

	print("# feeding ourselves a patch_change event...\n");
	print $inp "\xC0\x63"; # string.char(12*16, 99)); # {'patch_change',0,0,99}
	$rc =  MIDI::ALSA::inputpending();
	ok($rc > 0, "inputpending() returns $rc");
	@alsaevent  = MIDI::ALSA::input();
	@correct = (11, 1, 0, 1, 300, [24,0], [$id,1], [0, 0, 0, 0, 0, 99] );
	$alsaevent[4] = 300;
	#warn("alsaevent=".Dumper(@alsaevent)."\n");
	# warn("correct  =".Dumper(@correct)."\n");
	ok(Dumper(@alsaevent, \@correct),
	 'input() returns (11,1,0,1,300,[24,0],[id,1],[0,0,0,0,0,99])');
	@e = MIDI::ALSA::alsa2scoreevent(@alsaevent);
	#warn("e=".Dumper(\@e)."\n");
	@correct = ('patch_change',300000,0,99);
	ok(Dumper(@e) eq Dumper(@correct),
	 'alsa2scoreevent() returns ("patch_change",300000,0,99)');

	print("# feeding ourselves a control_change event...\n");
	print $inp "\xB2\x0A\x67"; # 11*16+2,10,103 {'control_change',3,2,10,103}
	$rc =  MIDI::ALSA::inputpending();
	@alsaevent  = MIDI::ALSA::input();
	@correct = (10, 1, 0, 1, 300, [24,0], [$id,1], [2, 0, 0, 0,10,103] );
	$alsaevent[4] = 300;
	ok(Dumper(@alsaevent) eq Dumper(@correct),
	 'input() returns (10,1,0,1,300,[24,0],[id,1],[2,0,0,0,10,103])');
	@e = MIDI::ALSA::alsa2scoreevent(@alsaevent);
	#warn("e=".Dumper(@e)."\n");
	@correct = ('control_change',300000,2,10,103);
	#warn("correct=".Dumper(@correct)."\n");
	ok(Dumper(@e) eq Dumper(@correct),
	 'alsa2scoreevent() returns ("control_change",300000,2,10,103)');

	print("# feeding ourselves a note_on event...\n");
	print $inp "\x90\x3C\x65"; # (9*16, 60,101));  {'note_on',0,60,101}
	$rc =  MIDI::ALSA::inputpending();
	@alsaevent  = MIDI::ALSA::input();
	$save_time = $alsaevent[4];
	@correct = ( 6, 1, 0, 1, 300, [ 24, 0 ], [ 129, 1 ], [ 0, 60, 101, 0, 0 ] );
	$alsaevent[4] = 300;
	${$alsaevent[7]}[3] = 0;
	${$alsaevent[7]}[4] = 0;
	# print "alsaevent=".Dumper(@alsaevent);
	# print "correct  =".Dumper(@correct);
	ok(Dumper(@alsaevent) eq Dumper(@correct),
	 'input() returns (6,1,0,1,300,[24,0],[id,1],[0,60,101,0,0])');
	@opusevent = MIDI::ALSA::alsa2opusevent(@alsaevent);
	$opusevent[1] = 300000;
	@correct = ('note_on',300000,0,60,101);
	ok(Dumper(@opusevent) eq Dumper(@correct),
	 'alsa2opusevent() returns ("note_on",300000,0,60,101)');

	print("# feeding ourselves a note_off event...\n");
	print $inp "\x80\x3C\x65"; # (8*16, 60,101); # {'note_off',0,60,101}
	$rc =  MIDI::ALSA::inputpending();
	@alsaevent  = MIDI::ALSA::input();
	$save_time = $alsaevent[4];
	@correct = ( 7, 1, 0, 1, 300, [ 24, 0 ], [ 129, 1 ], [ 0, 60, 101, 0, 0 ] );
	$alsaevent[4] = 300;
	${$alsaevent[7]}[4] = 0;
	ok(Dumper(@alsaevent) eq Dumper(@correct),
	 'input() returns (7,1,0,1,300,[24,0],[id,1],[0,60,101,0,0])');
	#print('alsaevent='..DataDumper($alsaevent));
	@opusevent = MIDI::ALSA::alsa2opusevent(@alsaevent);
	#print('opusevent='..DataDumper(opusevent));
	$opusevent[1] = 300000;
	@correct = ('note_off',300000,0,60,101);
	ok(Dumper(@opusevent) eq Dumper(@correct),
	 'alsa2opusevent() returns ("note_off",300000,0,60,101)');

	my @to = MIDI::ALSA::listconnectedto();
	@correct = ([2,0+$virmidi[2],0],);
	#print "to=",Dumper(@to),"correct=",Dumper(@correct);
	ok(Dumper(@to) eq Dumper(@correct),
	 "listconnectedto() returns ([2,$virmidi[2],0])");
	my @from = MIDI::ALSA::listconnectedfrom();
	@correct = ([1,0+$virmidi[0],0],);
	#print "from=",Dumper(@from),"correct=",Dumper(@correct);
	ok(Dumper(@from) eq Dumper(@correct),
	 "listconnectedfrom() returns ([1,$virmidi[0],0])");
}

if (@virmidi < 4) {
	ok(1, 'skipping patch_change event output');
	ok(1, 'skipping control_change event output');
	ok(1, 'skipping note_on event output');
	ok(1, 'skipping note_off event output');
} else {
	open(my $oup, '<', $virmidi[3])
	 || die "can't open $virmidi[3]: $!\n";  # client 25

	print("# outputting a patch_change event...\n");
	@correct = (11, 1, 0, 1, 0.5, [24,0], [$id,1], [0, 0, 0, 0, 0, 99] );
	$rc =  MIDI::ALSA::output(@correct);
	read $oup, $bytes, 2;
	ok($bytes eq "\xC0\x63", 'patch_change event detected');

	print("# outputting a control_change event...\n");
	@correct = (10, 1, 0, 1, 1.5, [24,0], [$id,1], [2, 0, 0, 0,10,103] );
	$rc =  MIDI::ALSA::output(@correct);
	read $oup, $bytes, 3;
	ok($bytes eq "\xB2\x0A\x67", 'control_change event detected');

	print("# outputting a note_on event...\n");
	@correct = ( 6, 1, 0, 1, 2.0, [ 24, 0 ], [ $id, 1 ], [ 0, 60, 101, 0, 0 ] );
	$rc =  MIDI::ALSA::output(@correct);
	read $oup, $bytes, 3;
	#printf "bytes=%vx\n", $bytes;
	ok($bytes eq "\x90\x3C\x65", 'note_on event detected');

	print("# outputting a note_off event...\n");
	@correct = ( 7, 1, 0, 1, 2.5, [ 24, 0 ], [ $id, 1 ], [ 0, 60, 101, 0, 0 ] );
	$rc =  MIDI::ALSA::output(@correct);
	read $oup, $bytes, 3;
	#printf "bytes=%vx\n", $bytes;
	ok($bytes eq "\x80\x3C\x65", 'note_off event detected');
}

if (@virmidi <2) {
	ok(1, "skipping disconnectfrom()");
	ok(1, 'skipping SND_SEQ_EVENT_PORT_UNSUBSCRIBED event');
} else {
	print("# running  aconnect -d $virmidi[0] $id:1 ...\n");
	system("aconnect -d $virmidi[0] $id:1");
	$rc =  MIDI::ALSA::inputpending();
	@alsaevent  = MIDI::ALSA::input();
	ok($alsaevent[0] == MIDI::ALSA::SND_SEQ_EVENT_PORT_UNSUBSCRIBED,
	 'SND_SEQ_EVENT_PORT_UNSUBSCRIBED event received');
}

$rc = MIDI::ALSA::disconnectto(2,$virmidi[2],0);
ok($rc, "disconnectto(2,$virmidi[2],0)");

$rc = MIDI::ALSA::connectto(2,$id,1);
ok($rc, "connectto(2,$id,1) connected to myself");
@correct = (11, 1, 0, 1, 2.5, [$id,2], [$id,1], [0, 0, 0, 0, 0, 99] );
$rc =  MIDI::ALSA::output(@correct);
@alsaevent  = MIDI::ALSA::input();
$latency = int(0.5 + 1000 * ($alsaevent[4]-$correct[4]));
$alsaevent[4] = $correct[4];
ok(Dumper(@alsaevent) eq Dumper(@correct), "received an event from myself");
ok($latency < 20, "latency was $latency ms");

$rc = MIDI::ALSA::disconnectfrom(1,$id,2);
ok($rc, "disconnectfrom(1,$id,2)");

$rc = MIDI::ALSA::stop();
ok($rc,'stop() returns success');

@alsaevent = MIDI::ALSA::noteonevent(15, 72, 100, 2.7);
@opusevent = MIDI::ALSA::alsa2opusevent(@alsaevent);
@correct = ('note_on',0,15,72,100);
ok(Dumper(@opusevent) eq Dumper(@correct), 'noteonevent()');

@alsaevent = MIDI::ALSA::noteoffevent(15, 72, 100, 2.7);
@opusevent = MIDI::ALSA::alsa2opusevent(@alsaevent);
@correct = ('note_off',0,15,72,100);
ok(Dumper(@opusevent) eq Dumper(@correct), 'noteoffevent()');

@alsaevent  = MIDI::ALSA::noteevent(15, 72, 100, 2.7, 3.1);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
@correct = ('note',2700,3100,15,72,100);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'noteevent()');

@alsaevent = MIDI::ALSA::pgmchangeevent(11, 98, 2.7);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
@correct = ('patch_change',2700,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'pgmchangeevent() with time>=0');

@alsaevent = MIDI::ALSA::pgmchangeevent(11, 98);
@opusevent = MIDI::ALSA::alsa2opusevent(@alsaevent);
@correct = ('patch_change',0,11,98);
ok(Dumper(@opusevent) eq Dumper(@correct), 'pgmchangeevent() with time undefined');

@alsaevent = MIDI::ALSA::pitchbendevent(11, 98, 2.7);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
@correct = ('pitch_wheel_change',2700,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'pitchbendevent() with time>=0');

@alsaevent = MIDI::ALSA::pitchbendevent(11, 98);
@opusevent = MIDI::ALSA::alsa2opusevent(@alsaevent);
@correct = ('pitch_wheel_change',0,11,98);
ok(Dumper(@opusevent) eq Dumper(@correct), 'pitchbendevent() with time undefined');

@alsaevent = MIDI::ALSA::chanpress(11, 98, 2.7);
@scoreevent = MIDI::ALSA::alsa2scoreevent(@alsaevent);
# print('alsaevent='.Dumper(@alsaevent)."\n");
# print('scoreevent='.Dumper(@scoreevent)."\n");
@correct = ('channel_after_touch',2700,11,98);
ok(Dumper(@scoreevent) eq Dumper(@correct), 'chanpress() with time>=0');

@alsaevent = MIDI::ALSA::chanpress(11, 98);
@opusevent = MIDI::ALSA::alsa2opusevent(@alsaevent);
# print('alsaevent='.Dumper(@alsaevent)."\n");
# print('opusevent='.Dumper(@opusevent)."\n");
@correct = ('channel_after_touch',0,11,98);
ok(Dumper(@opusevent) eq Dumper(@correct), 'chanpress() with time undefined');

# --------------------------- infrastructure ----------------
sub virmidi_clients_and_files {
	if (!open(P, 'aconnect -oil|')) {
		die "can't run aconnect; you may need to install alsa-utils\n";
	}
	my @virmidi = ();
	while (<P>) {
		if (/^client (\d+):\s*\W*Virtual Raw MIDI (\d+)-(\d+)/) {
			my $f = "/dev/snd/midiC$2D$3";
			if (! -e $f) {
				warn "client $1: can't see associated file $f\n";
				last;
			}
			push @virmidi, 0+$1, $f;
			if (@virmidi >= 4) { last; }
		}
	}
	close P;
	return @virmidi;
}
sub equal { my ($xref, $yref) = @_;
	my @x = @$xref; my @y = @$yref;
	if (scalar @x != scalar @y) { return 0; }
	my $i; for ($i=$[; $i<=$#x; $i++) {
		if (abs($x[$i]-$y[$i]) > 0.0000001) { return 0; }
	}
	return 1;
}

__END__

=pod

=head1 NAME

test.pl - Perl script to test MIDI::ALSA.pm

=head1 SYNOPSIS

 perl test.pl

=head1 DESCRIPTION

This script tests MIDI::ALSA.pm

=head1 AUTHOR

Peter J Billam  http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

MIDI::ALSA.pm , http://www.pjb.com.au/ , perl(1).

=cut

