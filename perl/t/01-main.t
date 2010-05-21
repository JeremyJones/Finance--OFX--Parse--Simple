#!perl -T

use Test::More 'no_plan';
use Finance::OFX::Parse::Simple;

my $parser = Finance::OFX::Parse::Simple->new;

ok( (not defined $parser->parse_file),
    "File parser returns undef with no filename");

ok( (not defined $parser->parse_file("/this/file/does/not/exist")),
    "File parser returns undef for a non-existant filename");

#ok( (not defined $parser->parse_file("/var/log/maillog")),
#    "File parser returns undef for a non-readable filename");

ok( (not defined $parser->parse_scalar),
    "Scalar parser returns undef with no scalar");

ok( (ref($parser->parse_scalar("foo")) eq 'ARRAY'),
    "Scalar parser returns a list reference");

