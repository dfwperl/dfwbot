#!/usr/bin/env perl

# ------------------------------------------------------------
# THE SETTINGS (adjust as desired inside dictbot.yml)
# ------------------------------------------------------------

use YAML::XS qw(); # the easiest way to use config files

our $conf = YAML::XS::LoadFile( 'dictbot.yml' );

# ------------------------------------------------------------
# THE SETUP
# ------------------------------------------------------------

use Modern::Perl; # turn on strict, warnings, and goodies

package DFWpm::DictionaryBot; # this is a dictionary lookup IRC bot

use Moo; extends 'Bot::BasicBot'; # the proper way to subclass

use Try::Tiny; # save the bot if the bot short circuits! (with try {} catch {})

use LWP::Simple qw( get ); # to fetch dictionary definitions from MW

use XML::XML2JSON qw(); # because I hate XML and it is stupid

use JSON::XS qw( decode_json ); # Let's me go from XML -> JSON -> Perl struct

# ------------------------------------------------------------
# THE BOT
# ------------------------------------------------------------

# run the bot, connect to the irc server, use the nicks above in the order
# they appear, join channels, listen for commands.  See perldoc Bot::BasicBot

map { $_ = qq(#$_) } @{ $conf->{channels} }; # make IRC channels into #channels

DFWpm::DictionaryBot->new(
   server    => $conf->{server},
   channels  => $conf->{channels},
   nick      => shift @$conf{nicks},
   alt_nicks => $conf->{nicks},
   username  => $conf->{user},
   name      => $conf->{name},
   port      => $conf->{port},
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

   # if called with no argument, there's nothing we can do

   return "What would you like me to define, $who?" unless $what;

   # just check one word.  If there's more than one, refuse to check:

   return "I only check one word at a time, $who"
      if $what =~ /[[:space:]]/;

   return "Sorry $who, I accept words with no puctuation only."
      if $what =~ /[^[:alpha:]]/;

   try # in case the web api call or actual dict XML validity fails
   {
      my $url = sprintf '%s/%s?key=%s',
                  $conf->{api_url},
                  $what,
                  $conf->{api_key};

      my $content = get $url;

      return "Couldn't reach dictionary.com API" unless $content;

      my $json = XML::XML2JSON->new->convert( $content );

         $json = decode_json( $json );

      use Data::Dumper;

      warn Dumper $json if $conf->{debug};

      # this gets ugly and there's nothing I can do about it.  The XML is
      # absolutely horrific.  Almost nothing sensible comes after this line.

      my ( $def, $defs, $entries );

      $entries = $json->{entry_list}{entry};

      $defs = ref $entries eq 'HASH'
         ? $entries
         : $entries->[0];

      # ok we have our definitions object, we just took the first one.
      # now we narrow it down to the first definition in the first "entry"

      $defs = $defs->{def}{dt};

      # you can tell the code continues to grow more and more definsive
      # due to the ridiculously complex XML schema

      return "Sorry, I've got no actual results for that, $who."
         unless ref $defs eq 'ARRAY' || ref $defs eq 'HASH';

      # there is no reason why the key is named "$t".  Don't ask

      $def = ref $defs eq 'ARRAY'
               ? $defs->[0]->{ '$t' }
               : $defs->{ '$t' };

      return "Something went wrong during the lookup.  Sorry, $who."
         unless $def;

      # sometimes the first definition is empty.  *facepalm*  Try the next one

      $def = $defs->[1]->{ '$t' }
         if length $def =~ /:\s/ && ref $defs eq 'ARRAY';

      $def = substr $def, 1; # they always add a leading ":".  why clown, why?

      # if we still have no valid definition, then we are done trying

      $def = "$who, I couldn't find a valid definition while searching the API."
         unless $def;

      return $def;
   }
   catch # ... so we can catch the errors with Try::Tiny
   {
      return "Something wicked happened.  Here's a look under the hood: '$_'"
   }
}

1;
