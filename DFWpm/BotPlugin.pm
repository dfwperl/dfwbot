package DFWpm::BotPlugin;

use Moose::Role;

# EXPECTED FORMAT: $provides = [ 'something' ];
# EXPECTED FORMAT: $aliases  = { something => [ qw( some other aliases ) ] };

sub apply_aliases
{
   my ( $class, $aliases ) = @_;

   my $meta = $class->meta;

   for my $aliased_cmd ( keys %$aliases )
   {
      my $alias_list = $aliases->{ $aliased_cmd };

      warn 'Encountered alformed bot command alias list'
         and next unless ref $alias_list eq 'ARRAY';

      for my $alias ( @$alias_list )
      {
         $meta->add_method( $alias => sub { shift->$aliased_cmd( @_ ) } );
      }
   }
}

sub plugin_provides
{
   my $class = shift;

   my ( $provides, $aliases );

   {
      no strict 'refs';

      $provides = ${ $class . '::provides' };
      $aliases  = ${ $class . '::aliases'  };
   }

   my @super_powers = @$provides; # superclass, get it?

   for my $aliased_cmd ( keys %$aliases )
   {
      my $alias_list = $aliases->{ $aliased_cmd };

      warn 'Encountered malformed bot command alias list'
         and next unless ref $alias_list eq 'ARRAY';

      push @super_powers, @$alias_list;
   }

   return @super_powers;
}

1;
