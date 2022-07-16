#!/usr/bin/env perl

use warnings;
use strict;

my @versions = qw(14.0.0 13.0.0 12.0.0 11.0.0 10.0.0 9.0.0 8.0.0 7.0.0 6.0.0 5.0.0 4.0.0);

foreach my $version (@versions) {
    my ($v) = $version =~ m/^(\d+)\./;

    print "We found major version: $v\n";
}

exit 0;
