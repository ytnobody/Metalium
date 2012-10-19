package Metalium;
use strict;
use warnings;
our $VERSION = '0.01';
use parent 'Memcached::Server';
use JSON;
use AE;
use Try::Tiny;

our $DATA = {};
our $PROCEDURE = {};
our $PARSER = JSON->new->utf8(1);

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
    $PROCEDURE->{$name} = $code;
}

sub call_procedure {
    my ( $proc_name, $data ) = @_;
    my $proc = $PROCEDURE->{$proc_name};
    return try {
        ( 1, $proc->( $data ) );
    } catch {
        warn "Error in procedure $proc_name: ". $_;
        ( 0, undef );
    };
}

sub set {
    my ( $cb, $key, $flag, $expire, $data ) = @_;
    if ( my ( $proc_name ) = $DATA->{$key} =~ /^call (.+)$/  ) {
        return call_procedure( $proc_name, $DATA->{$key} );
    }
    else {
        $DATA->{$key} = { 
            data => try { $PARSER->decode( $data ) } catch { $data },
            expire => $expire ? time + $expire : 0,
        };
        return $cb->(1);
    }
}

sub get {
    my ( $cb, $key ) = @_;
    if ( $DATA->{$key} ) {
        delete $DATA->{$key} if $DATA->{$key}{expire} <= time;
    }
    return $cb->( 0 ) unless exists $DATA->{$key};
    my $data = ref $DATA->{$key}{data} =~ /^(ARRAY|HASH)$/ ? 
        $PARSER->encode( $DATA->{$key}{data} ) : 
        $DATA->{$key}{data} 
    ;
    return $cb->( 1, $data );
}

sub delete {
    my ( $cb, $key ) = @_;
    delete $DATA->{$key};
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
