#!/usr/bin/env perl

# ------------------------------------------------------------
# THE SETTINGS (adjust as desired)
# ------------------------------------------------------------

# IRC server to which the bot will connect
our $server   = 'irc.perl.org';

# Channels on the server which the bot will join
our @channels = qw( #bot-test );

# IRC server username
our $user = undef, # no auth at irc.perl.org

# desired IRC nicknames, which will be tried in the order they appear
our @nicks = qw( spellcheck spellerbot speller_bot dfw_spellerbot );

# IRC name
our $name = 'DFW Perl Monger Spellchecker Bot';

# ------------------------------------------------------------
# THE SETUP
# ------------------------------------------------------------

use Modern::Perl; # turn on strict, warnings, and goodies

package DFWpm::SpellerBot; # this is a spellchecker IRC bot

use Moo; extends 'Bot::BasicBot'; # the proper way to subclass

use Try::Tiny; # save the bot if the bot short circuits! (with try {} catch {})

use Lingua::Ispell qw( spellcheck ); # you need aspell on your system first

Lingua::Ispell::allow_compounds( 0 ); # << doesn't work in modern aspell anyway

# ------------------------------------------------------------
# THE BOT
# ------------------------------------------------------------

# run the bot, connect to the irc server, use the nicks above in the order
# they appear, join channels, listen for commands.  See perldoc Bot::BasicBot

DFWpm::SpellerBot->new(
   server    => $server,
   channels  => \@channels,
   nick      => shift @nicks,
   alt_nicks => \@nicks,
   username  => $user,
   name      => $name,
)->run();

exit;

# ------------------------------------------------------------
# THE GEARS
# ------------------------------------------------------------

sub said
{
   my ( $self, $said ) = @_;

   my ( $who, $what, $to ) = @{ $said }{ qw( who body address ) };

   # don't speak unless spoken to:

   return unless $to && $to eq $self->nick;

   # just check one word.  If there's more than one, refuse to check:

   return "I only check one word at a time, $who"
      if $what =~ /[[:space:]]/;

   try # Lingua::Ispell can produce strange errors sometimes...
   {
      my ( $check ) = spellcheck( $what );
      #  ^        ^ # apparently depends on list context.  That's weird.

      # see perldoc Lingua::Ispell for info on the way these lines
      # work below

      return "'$what' looks perfectly cromulent to me.  Nice spelling, $who"
         unless $check || ( $check && $check->{type} eq 'ok' );

      my $suggest = join ', ',
                    map { qq("$_") }
                    @{ $check->{misses} },
                    @{ $check->{guesses} };

      return "Did you mean one of these? $suggest"
         if $check->{type} eq 'miss' or $check->{type} eq 'guess';

      return "'$check->{term}' is an embiggened compound word."
         if $check->{type} eq 'compound';

      return "'$check->{term}' can be formed from root '$check->{root}'."
         if $check->{type} eq 'root';

      return "I have no idea what to do with that nonsense, $who"
         if $check->{type} eq 'none';
   }
   catch # ... so we can catch the errors with Try::Tiny
   {
      return "Something wicked happened: '$_'"
   }
}

1;
