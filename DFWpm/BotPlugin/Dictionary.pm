package DFWpm::BotPlugin::Dictionary; # this is a dictionary plugin for irc bots

# ------------------------------------------------------------
# SHARED LIBS (WHEELS ALREADY INVENTED -- CODE REUSE IS GOOOD)
# ------------------------------------------------------------

use Moose::Role; # this lets us function as a "plug in" for the main bot

with 'DFWpm::BotPlugin'; # allows us to hook this plugin into the bot

use Try::Tiny; # save the bot if the bot short circuits! (with try {} catch {})

use LWP::Simple qw( get ); # to fetch dictionary definitions from MW

use XML::XML2JSON qw(); # because I hate XML and it is stupid

use JSON::XS qw( decode_json ); # JSON is not stupid

# ------------------------------------------------------------
# SET UP ALIASES FOR THE CORE COMMAND PROVIDED BY THIS PLUGIN
# ------------------------------------------------------------

our $provides = [ 'dict' ];
our $aliases = { dict => [ qw( d dictionary lookup ) ] };

__PACKAGE__->apply_aliases( $aliases );

# ------------------------------------------------------------
# THE CORE IRC BOT COMMAND "dict"
# ------------------------------------------------------------

sub dict
{
   my ( $self, $said_obj, $arg_str ) = @_;

   my $conf = $self->plug_conf;

   my ( $who, $what, $to ) = @{ $said_obj }{ qw( who body address ) };

   # if called with no argument, there's nothing we can do

   return "What would you like me to define, $who?" unless $arg_str;

   # just check one word.  If there's more than one, refuse to check:

   return "I only check one word at a time, $who"
      if $arg_str =~ /[[:space:]]/;

   return "Sorry $who, I accept words with no puctuation only."
      if $arg_str =~ /[^[:alpha:]]/;

   try # in case the web api call or actual dict XML validity fails
   {
      my $url = sprintf '%s/%s?key=%s',
                  $conf->{dict}{api_url},
                  $arg_str,
                  $conf->{dict}{api_key};

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
