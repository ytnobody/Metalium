package t::Util;
use strict;
use warnings;
use Test::TCP;
use Metalium;
use Cache::Memcached::Fast;
use Exporter 'import';
our @EXPORT = qw[ test_server ];

sub test_server {
    my %procs = @_;
    my $sv = Test::TCP->new( code => sub {
        my $port = shift;
        my $sv = Metalium->new( open => [[ 0, $port ]] );
        if ( %procs ) {
            $sv->add_procedure( $_ => $procs{$_} ) for keys %procs;
        }
        $sv->run;
    });
    return wantarray ? 
        ( $sv, Cache::Memcached::Fast->new({servers => [ "127.0.0.1:". $sv->port ]}) ) :
        $sv
    ;
}

1;
