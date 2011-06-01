#!/usr/bin/perl
package DCOLLINS::ANN::SimWorld;
BEGIN {
  $DCOLLINS::ANN::SimWorld::VERSION = '0.002';
}
use strict;
use warnings;
# ABSTRACT: a simulated world for robots to play in

use Moose;

use Storable qw(dclone);
use List::Util qw(max min);


has 'map' => (is => 'rw', isa => 'ArrayRef[ArrayRef[Str]]');
has 'batt_while_moving' => (is => 'rw', isa => 'Num', default => 0.2);
has 'batt_while_not_moving' => (is => 'rw', isa => 'Num', default => 0.1);
has 'pain_decrease' => (is => 'rw', isa => 'Num', default => 0.3);
has 'pain_overcharge' => (is => 'rw', isa => 'Num', default => 2);
has 'batt_charge' => (is => 'rw', isa => 'Num', default => 5);
has 'pain_stationary_not_charging' => (is => 'rw', isa => 'Num', default => 2);
has 'pain_collision' => (is => 'rw', isa => 'Num', default => 6);
has 'fitness_function' => (is => 'rw', isa => 'CodeRef', default => 
	sub { sub { $_[0]->{'age'} + # 0 to 1
				-10*(min($_[0]->{'total_pain'}/$_[0]->{'age'}, 0.03))*$_[0] + # 0 to -0.3
				min($_[0]->{'total_battery'}/$_[0]->{'age'}, 0.3)*$_[0] # 0 to 0.3
	}});

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my %input = @_;
	for (my $i = 0; $i <= 9; $i++) {
		for (my $j = 0; $j <= 9; $j++) {
			$input{'map'}->[$i]->[$j] = '0';
		}
	}
	$input{'map'}->[0]->[0] = 'C';
	return $class->$orig(%input);
};


sub run_robot {
	my $self = shift;
	my $robot = shift;
	my $pain = 0;
	my $battery = 100;
	my $x = 0;
	my $y = 0;
	my $xmax = $#{$self->{'map'}};
	my $ymax = $#{$self->{'map'}->[0]};
	my $disscale = max($xmax, $ymax)*1.4;
	my $dir = "N";
	my $diffpain = 0;
	my $diffbatt = 0;
	my $moved = 0;
	my $return = { age => 0, total_pain => 0, total_battery => 0,
		battery_used => 0, pain_given => 0 };
	my %diroffs = ( "N" => 0, 
				 "NE" => 1,
				 "E" => 2,
				 "SE" => 3,
				 "S" => 4,
				 "SW" => 5,
				 "W" => 6,
				 "NW" => 7);
	my %dirs = reverse %diroffs;
	my @dis;
	my $inputs = [];
	my $outputs = [];
	while ($pain < 100 && ($battery > 0 || ($x == 0 && $y == 0))) {
		$inputs->[0] = $battery/100;
		$inputs->[1] = $pain/100;
		$inputs->[2] = $diffbatt;
		$inputs->[3] = $diffpain;
		$dis[0] = 1.4*min($x, $y); # NorthWest
		$dis[1] = $y;
		$dis[2] = 1.4*min($xmax-$x, $y);
		$dis[3] = $xmax-$x;
		$dis[4] = 1.4*min($xmax-$x, $ymax-$y);
		$dis[5] = $ymax-$y;
		$dis[6] = 1.4*min($x, $ymax-$y);
		$dis[7] = $x;
		@dis[8..13] = @dis[0..5];
		@dis = map { min($_, 3) / 3 } @dis;
		@{$inputs}[4..6] = @dis[($diroffs{$dir})..($diroffs{$dir}+2)];
		$inputs->[7] = $x;
		$inputs->[8] = $y;
		$inputs->[9] = ($dir =~ /N/ ? 1 : 0);
		$inputs->[10] = ($dir =~ /S/ ? 1 : 0);
		$inputs->[11] = ($dir =~ /E/ ? 1 : 0);
		$inputs->[12] = ($dir =~ /W/ ? 1 : 0);
		$outputs = $robot->execute($inputs);
		$diffbatt = $diffpain = $moved = 0;
#print STDERR join("|", @$inputs) . "\n";
#print STDERR join("|", @$outputs) . "\n";
#my ($a, $b, $c) = $robot->get_state();
#print STDERR join("|", @$a) . "\n";
#print STDERR join("|", @$b) . "\n";die;
#print STDERR join("|", @$c) . "\n";

		my $maxout = max(@$outputs);
		if ($maxout >= 1) {
			if ($outputs->[0] == $maxout) {
				my $newdir = $diroffs{$dir}-1;
				$newdir = 7 if $newdir == -1;
				$dir = $dirs{$newdir};
				$diffbatt = -1 if rand() < $self->{'batt_while_moving'};
				$moved = 1;
			} elsif ($outputs->[1] == $maxout) {
				my $newdir = $diroffs{$dir}+1;
				$newdir = 0 if $newdir == 8;
				$dir = $dirs{$newdir};
				$diffbatt = -1 if rand() < $self->{'batt_while_moving'};
				$moved = 1;
			} elsif ($outputs->[2] == $maxout) {
				if ($dis[$diroffs{$dir}+1] == 0) {
					$diffpain = $self->{'pain_collision'};
				} else { 
					$x++ if $dir =~ /E/;
					$x-- if $dir =~ /W/;
					$y++ if $dir =~ /S/;
					$y-- if $dir =~ /N/;
				}
				$diffbatt = -1 if rand() < $self->{'batt_while_moving'};
				$moved = 1;
			} elsif ($outputs->[3] == $maxout) {
				if ($dis[$diroffs{$dir}+5] == 0) {
					$diffpain = $self->{'pain_collision'};
				} else { 
					$x-- if $dir =~ /E/;
					$x++ if $dir =~ /W/;
					$y-- if $dir =~ /S/;
					$y++ if $dir =~ /N/;
				}
				$diffbatt = -1 if rand() < $self->{'batt_while_moving'};
				$moved = 1;
			}
		}
		if ($moved == 0) {
			$diffbatt = -1 if rand() < $self->{'batt_while_not_moving'};
		}
		if ($x == 0 && $y == 0) {
			$diffbatt += $self->{'batt_charge'};
			if ($battery + $diffbatt > 100) {
				$diffpain += $self->{'pain_overcharge'};
				$diffbatt = 100 - $battery;
			}
		}
		if ($moved == 0 && ($x != 0 || $y != 0)) {
			$diffpain += $self->{'pain_stationary_not_charging'};
		}
		if ($diffpain == 0 && $pain > 0) {
			$diffpain = -1 if rand() < $self->{'pain_decrease'};
		}
		if ($pain + $diffpain < 0) {
			$diffpain = 0 - $pain;
		}
		$pain += $diffpain;
		$battery += $diffbatt;
		$return->{'age'}++;
		$return->{'total_battery'} += $battery;
		$return->{'total_pain'} += $pain;
		$return->{'battery_used'} -= $diffbatt if $diffbatt < 0;
		$return->{'pain_given'} += $diffpain if $diffpain > 0;
	}
	$return->{'fitness'} = &{$self->{'fitness_function'}}($return);
	return $return;
}

1;

__END__
=pod

=head1 NAME

DCOLLINS::ANN::SimWorld - a simulated world for robots to play in

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 METHODS

=head2 new

DCOLLINS::ANN::SimWorld::new( )

Creates a DCOLLINS::ANN::SimWorld object ready to test robots.

Has many parameters. Important may be fitness_function, a coderef to 
a function that takes age, total_pain, total_battery, battery_used, pain_given
For standardization, these are the parameters that SimWorld will pass to the 
	network:
Current battery power (0-1)
Current pain value (0-1)
Differential battery power ((-1)-1)
Differential pain value ((-1)-1)
Proximity readings, -45, 0, 45 degrees (0-1)
Current X location (0-1)
Current Y location (0-1)
Currently facing: N, S, E, W (0-1)

These are the parameters that SimWorld will expect as outputs from the network: 
Rotate L
Rotate R
Forwards
Reverse
Stop
The largest value will be accepted. If no output is greater than 1, SimWorld 
	will interpret as a stop.

=head2 run_robot

$environment->run_robot($robot);

Returns a hashref with the following information:
	fitness => Num
	age => Num
	total_pain => Num
	total_battery => Num
	battery_used => Num
	pain_given => Num

=head1 AUTHOR

Dan Collins <dcollin1@stevens.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dan Collins.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

