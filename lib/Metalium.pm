package Metalium;
use strict;
use warnings;
our $VERSION = '0.01';
use parent 'Memcached::Server';
use JSON;
use AE;
use Try::Tiny;

my $data = {};
my $procedure = {};
my $parser = JSON->new->utf8(1);

sub new {
    my ( $class, %opts ) = @_;
    my $self = $class->SUPER::new( 
        cmd => { map { ( $_ => \&{ $_ } ) } qw[ get set delete flush_all ] }, 
        no_extra => 1, 
        %opts 
    );
    return $self;
}

sub run {
    AE::cv->recv;
}

sub add_procedure {
    my ( $self, $name, $code ) = @_;
    $procedure->{$name} = $code;
}

use Data::Dumper;
sub call_procedure {
    my ( $proc_name, $key ) = @_;
    my $proc = $procedure->{$proc_name};
    return try {
        local $_ = $data->{$key}{data};
        $data->{$key}{data} = $proc->();
        ( 1, $data->{$key} );
    } catch {
        warn "Error in procedure $proc_name: ". $_;
        ( 0, undef );
    };
}

sub set {
    my ( $cb, $key, $flag, $expire, $param ) = @_;
    $expire ||= 30;
    if ( my ( $proc_name ) = $key =~ /^call:(.+)$/  ) {
        return call_procedure( $proc_name, $param );
    }
    else {
        $data->{$key} = { 
            limit  => time() + $expire,
            data   => try { $parser->decode( $param ) } catch { $param },
        };
        return $cb->(1);
    }
}

sub get {
    my ( $cb, $key ) = @_;
    if ( $data->{$key} ) {
        delete $data->{$key} if $data->{$key}{limit} <= time;
    }
    return $cb->( 0 ) unless exists $data->{$key};
    my $data = ref $data->{$key}{data} =~ /^(ARRAY|HASH)$/ ? 
        $parser->encode( $data->{$key}{data} ) : 
        $data->{$key}{data} 
    ;
    return $cb->( 1, $data );
}

sub delete {
    my ( $cb, $key ) = @_;
    delete $data->{$key};
    $cb->( 1 );
}

sub flush_all {
    my ( $cb ) = @_;
    $data = {};
    $cb->( 1 );
}

1;
__END__

=head1 NAME

Metalium -

=head1 SYNOPSIS

  use Metalium;

=head1 DESCRIPTION

Metalium is

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
