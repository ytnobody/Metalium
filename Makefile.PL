use inc::Module::Install;
name 'Metalium';
all_from 'lib/Metalium.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
