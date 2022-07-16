#!/usr/bin/env perl

use warnings;
use strict;

my @versions = qw(9.0.0 13.0.0 6.0.0 5.0.0 10.0.0 14.0.0 8.0.0 7.0.0 12.0.0 11.0.0 4.0.0);

print map("$_\n", sort { ($a =~ m/^(\d+)\./)[0] <=> ($b =~ m/^(\d+)\./)[0] } @versions);

exit 0;
