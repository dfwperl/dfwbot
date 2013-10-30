package DFWpm::BotPlugin::Spelling; # this is a spellcheck plugin for irc bots

# ------------------------------------------------------------
# SHARED LIBS (WHEELS ALREADY INVENTED -- CODE REUSE IS GOOOD)
# ------------------------------------------------------------

use Moose::Role; # this lets us function as a "plug in" for the main bot

with 'DFWpm::BotPlugin'; # allows us to hook this plugin into the bot

use Try::Tiny; # save the bot if the bot short circuits! (with try {} catch {})

use Lingua::Ispell qw( ); # you need aspell on your system first

Lingua::Ispell::allow_compounds( 0 ); # << kinda broken in modern aspell anyway

# ------------------------------------------------------------
# SET UP ALIASES FOR THE CORE COMMAND PROVIDED BY THIS PLUGIN
# ------------------------------------------------------------

our $provides = [ 'spell' ];
our $aliases = { spell => [ qw( s spellcheck check ) ] };

__PACKAGE__->apply_aliases( $aliases );

# ------------------------------------------------------------
# THE CORE IRC BOT COMMAND "spell"
# ------------------------------------------------------------

sub spell
{
   my ( $self, $said_obj, $arg_str ) = @_;

   my $conf = $self->plug_conf;

   my ( $who, $what, $to ) = @{ $said_obj }{ qw( who body address ) };

   # if called with no argument, there's nothing we can do

   return "What would you like me to spellcheck, $who?" unless $arg_str;

   # just check one word.  If there's more than one, refuse to check:

   return "I only check one word at a time, $who"
      if $arg_str =~ /[[:space:]]/;

   try # Lingua::Ispell can produce strange errors sometimes...
   {
      my ( $check ) = Lingua::Ispell::spellcheck( $arg_str );
      #  ^        ^ # apparently depends on list context.  That's weird.

      # see perldoc Lingua::Ispell for info on the way these lines
      # work below

      return "'$arg_str' looks perfectly cromulent to me.  Nice spelling, $who"
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
