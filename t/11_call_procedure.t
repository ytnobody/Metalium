use strict;
use warnings;
use Test::More;
use t::Util;

my ( $s, $c ) = test_server(
    double => sub { $_ * 2 },
);

$c->set('a', 123);
$c->set('call:double', 'a');
is $c->get('a'), 246;

done_testing;

