#!/usr/bin/env perl

use warnings;
use strict;

my $url = 'https://releases.llvm.org/5.0.0/tools/clang/docs/DiagnosticsReference.html#rsanitize-address';

print _shorten_url($url);

exit 0;

sub _shorten_url {
    my ($url) = shift;

    my $short_url = $url =~ s/https:\/\/releases.llvm.org\/(\d+)\.\d+\.\d+\/tools\/clang\/docs\/DiagnosticsReference.html#(.*)/https:\/\/pxy.fi\/$1\/$2/r;

    return $short_url;
}
