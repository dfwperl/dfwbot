package DFWpm::BotPlugin::Greeter; # this is a greeter plugin for DFWpm irc bots

# ------------------------------------------------------------
# SHARED LIBS (WHEELS ALREADY INVENTED -- CODE REUSE IS GOOOD)
# ------------------------------------------------------------

use Moose::Role; # this lets us function as a "plug in" for the main bot

with 'DFWpm::BotPlugin'; # allows us to hook this plugin into the bot

# ------------------------------------------------------------
# SET UP ALIASES FOR THE CORE COMMAND PROVIDED BY THIS PLUGIN
# ------------------------------------------------------------

our $provides = [ 'greet' ];

our $aliases  = { greet => [ qw( hello hi howdy greetings salutations hola ) ] };

__PACKAGE__->apply_aliases( $aliases );

# ------------------------------------------------------------
# THE CORE IRC BOT COMMAND "greet"
# ------------------------------------------------------------

sub greet
{
   my ( $self, $said_obj, $arg_str ) = @_;

   my ( $who, $what, $to ) = @{ $said_obj }{ qw( who body address ) };

   return "What's up $who!  So nice to see you online today.";
}

1;
