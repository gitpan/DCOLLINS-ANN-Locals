#!/usr/bin/perl
package DCOLLINS::ANN::Robot;
BEGIN {
  $DCOLLINS::ANN::Robot::VERSION = '0.001';
}
use strict;
use warnings;
# ABSTRACT: a wrapper for AI::ANN

use base qw(AI::ANN);
use Storable qw(dclone);


sub new {
	my $class = shift;
	my $self = {};
	my %data = ();
	$data{'inputs'} = 13;
	$data{'minvalue'} = -2;
	$data{'maxvalue'} = 2;
	my $arg2 = [];
	for (my $i = 0; $i < 13; $i++) {
		push $arg2, { 'iamanoutput' => 0, # Requires Perl 5.14 !!!
					  'inputs' => { $i => rand() },
					  'neurons' => { } };
		push $arg2, { 'iamanoutput' => 0,
					  'inputs' => { $i => 3 * rand() - 2 },
					  'neurons' => { } };
	} # Made neurons 0-25
	for (my $i = 0; $i < 13; $i++) {
		my $working = {};
		for (my $j = 0; $j < 26; $j ++) {
			$working->{$j}=rand();
		}
		push $arg2, { 'iamanoutput' => 0,
					  'inputs' => {},
					  'neurons' => $working };
	} # Made neurons 26-38
	for (my $i = 0; $i < 13; $i++) {
		my $working = {};
		for (my $j = 13; $j < 39; $j ++) {
			$working->{$j}=rand();
		}
		push $arg2, { 'iamanoutput' => 0,
					  'inputs' => {},
					  'neurons' => $working };
	} # Made neurons 39-51
	for (my $i = 0; $i < 5; $i++) {
		my $working = {};
		for (my $j = 26; $j < 52; $j ++) {
			$working->{$j}=rand();
		}
		push $arg2, { 'iamanoutput' => 1,
					  'inputs' => {},
					  'neurons' => $working };
	} # Made neurons 52-56
	$data{'data'} = $arg2;
	$self = $class->SUPER::new(%data);
	return $self;
}

1;

__END__
=pod

=head1 NAME

DCOLLINS::ANN::Robot - a wrapper for AI::ANN

=head1 VERSION

version 0.001

=head1 SYNOPSIS

use DCOLLINS::ANN::Robot;
my $robot = new DCOLLINS::ANN::Robot ( );

=head1 METHODS

=head2 new

DCOLLINS::ANN::ROBOT::new( )

Creates a DCOLLINS::ANN::Robot object and a neural net to go with it.

This object has methods of its own, as well as the methods available in AI::ANN. We do, however, override the execute method.

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

=head1 AUTHOR

Dan Collins <dcollin1@stevens.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dan Collins.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

