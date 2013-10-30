#!/usr/bin/env perl

# ------------------------------------------------------------
# THE SETTINGS (adjust as desired inside dictbot.yml)
# ------------------------------------------------------------

use YAML::XS qw(); # the easiest way to use config files

our $conf = YAML::XS::LoadFile( 'borgbot.yml' );

# ------------------------------------------------------------
# THE SETUP
# ------------------------------------------------------------

package DFWpm::BorgBot; # this is a dictionary lookup IRC bot

use Moose;

extends 'Bot::BasicBot'; # the proper way to subclass

use Try::Tiny; # save the bot if the bot short circuits! (with try {} catch {})

# ------------------------------------------------------------
# IMPORT THE PLUGINS OR DIE TRYING (list them in borgbot.yml)
# ------------------------------------------------------------

has plug_conf => ( is => 'rw', isa => 'HashRef' );

our @supported_cmds;

for my $plugin ( @{ $conf->{plugins} } )
{
   with $plugin; # consumes the plugin as a Moose role

   push @supported_cmds, $plugin->plugin_provides;

   print "Loaded plugin $plugin which provides\n   - ",
      join ( "\n   - ", $plugin->plugin_provides ), "\n\n"
         if $conf->{debug};
}

# ------------------------------------------------------------
# THE BOT
# ------------------------------------------------------------

# run the bot, connect to the irc server, use the nicks above in the order
# they appear, join channels, listen for commands.  See perldoc Bot::BasicBot

map { $_ = qq(#$_) } @{ $conf->{channels} }; # make IRC channels into #channels

our $bot = DFWpm::BorgBot->new(
   plug_conf => $conf,
   server    => $conf->{server},
   channels  => $conf->{channels},
   nick      => $conf->{nick},
   alt_nicks => $conf->{alt_nicks},
   username  => $conf->{user},
   name      => $conf->{name},
   port      => $conf->{port},
);

$bot->run();

exit;

# ------------------------------------------------------------
# THE GEARS - this makes the bot go, sending calls to plugins
# ------------------------------------------------------------

sub said
{
   my ( $self, $said_obj ) = @_;

   my ( $who, $what, $to, $channel ) =
      @{ $said_obj }{ qw( who body address channel ) };

   # don't speak unless spoken to:

   return unless $to && $to eq $self->nick;

   my ( $cmd, $arg_str ) = split /[[:space:]]+/, $what, 2;

   # give help if the user gave no command
   return $self->help unless defined $cmd && length $cmd;

   return "Sorry, I'm not that kind of bot.  I don't do '$cmd'"
      unless $self->can( $cmd );

   try
   {
      return $self->forkit(
         run     => sub { print $self->$cmd( $said_obj, $arg_str ), "\n" },
         address => 1,
         who     => $who,
         channel => $channel,
      )
   }
   catch { return "A plugin has failed: $_" }
}

sub help
{
   my $self = shift;
   my $me   = $self->nick;

   return "Usage: $me command [ arg1 arg2 ...]\nCommands: @supported_cmds";
}

1;
