#!/usr/bin/env perl

use Modern::Perl; # turn on strict, warnings, and goodies

package DFWpm::MongerBot;

use Moo;

extends 'Bot::BasicBot';

my @nicks = qw( mongerbot monger_bot dfw_mongerbot dfw_monger_bot );

sub said
{
   my ( $self, $said ) = @_;

   my ( $who, $what, $to ) = @{ $said }{ qw( who body address ) };

   return unless $to && $to eq $self->nick;

   return "Hi, $who.  That's all I do."
}

DFWpm::MongerBot->new(
   server    => 'irc.perl.org',
   channels  => [ '#bot-test' ],
   nick      => shift @nicks,
   alt_nicks => \@nicks,
   username  => undef, # no auth at irc.perl.org
   name      => 'DFW Perl Monger Bot'
)->run();

exit;
