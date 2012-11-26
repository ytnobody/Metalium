use strict;
use warnings;
use Test::More;
use t::Util;

my ( $s, $c ) = test_server();

is $c->get('a'), undef;
$c->set('a', 123);
is $c->get('a'), 123;

$c->delete('a');
is $c->get('a'), undef;

done_testing;

