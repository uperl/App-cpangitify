use strict;
use warnings;
use Test::More;

our $format;
diag sprintf $format, 'git', eval {
  require AnyEvent::Git::Wrapper;
  AnyEvent::Git::Wrapper->new(".")->version;
} || '-';

1;
