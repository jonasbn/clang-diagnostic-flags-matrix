#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Mojo::UserAgent;
use feature qw(say);

# REF: https://docs.mojolicious.org/Mojo/DOM
# REF: https://docs.mojolicious.org/Mojo/UserAgent

my %urls = (
    '16.0.0' => 'https://releases.llvm.org/16.0.0/tools/clang/docs/DiagnosticsReference.html',
    '15.0.0' => 'https://releases.llvm.org/15.0.0/tools/clang/docs/DiagnosticsReference.html',
    '14.0.0' => 'https://releases.llvm.org/14.0.0/tools/clang/docs/DiagnosticsReference.html',
    '13.0.0' => 'https://releases.llvm.org/13.0.0/tools/clang/docs/DiagnosticsReference.html',
    '12.0.0' => 'https://releases.llvm.org/12.0.0/tools/clang/docs/DiagnosticsReference.html',
    '11.0.0' => 'https://releases.llvm.org/11.0.0/tools/clang/docs/DiagnosticsReference.html',
    '10.0.0' => 'https://releases.llvm.org/10.0.0/tools/clang/docs/DiagnosticsReference.html',
    '9.0.0' => 'https://releases.llvm.org/10.0.0/tools/clang/docs/DiagnosticsReference.html',
    '8.0.0' => 'https://releases.llvm.org/8.0.0/tools/clang/docs/DiagnosticsReference.html',
    '7.0.0' => 'https://releases.llvm.org/7.0.0/tools/clang/docs/DiagnosticsReference.html',
    '6.0.0' => 'https://releases.llvm.org/6.0.0/tools/clang/docs/DiagnosticsReference.html',
    '5.0.0' => 'https://releases.llvm.org/5.0.0/tools/clang/docs/DiagnosticsReference.html',
    '4.0.0' => 'https://releases.llvm.org/4.0.0/tools/clang/docs/DiagnosticsReference.html',
);

my $ua  = Mojo::UserAgent->new;
my $data = {};
my $headings = {};
my $use_emoji = 0;
my $use_short_url = 1;

foreach my $key (keys %urls) {
    
    my $url = $urls{$key};
    my $res = $ua->get($url)->result;

    if    ($res->is_success)  { _parse_result($res, $key, $url, $data, $headings) }
    elsif ($res->is_error)    { say STDERR $res->message; exit $res->code }
    elsif ($res->code == 301) { say STDERR $res->headers->location }
    else                      { say STDERR 'Unable to handle, stopping - '.$res->message; exit $res->code }  
}

# We sort the 3-part (semver) version number by the major number
my @versions = sort { ($a =~ m/^(\d+)\./)[0] <=> ($b =~ m/^(\d+)\./)[0] } (keys %urls);
my @h = sort (keys %{$headings});

my $titles = '| |';
my $seperator = '|-|';

# Output Markdown title
print '# Clang command line flags';
print "\n\n";

# Generate table headings with versions, linked to the documentation pages
# See the URL as the beginning of the program
# In addition we generate the separator, since rows and heading are using same
# notation in markdown
foreach my $version (@versions) {
    my $url = $urls{$version};
    $titles .= "[$version]($url)|";
    $seperator .= "-|";
}

# Output table headings and separator
print "$titles\n";
print "$seperator\n";

# Output rows
foreach my $flag (@h) {
    # We skip/ignore heading not resembling command line flags
    if (is_cli_flag($flag)) {
        print "|`$flag`|";
        foreach my $version (@versions) {
            if (exists $data->{$version}->{$flag}) {
                my $short_url = $data->{$version}->{$flag};
                if ($use_short_url) {
                    $short_url = _shorten_url($data->{$version}->{$flag});
                }

                if ($use_emoji) {
                    print "[✅]($short_url)|";
                } else {
                    print "[X]($short_url)|";
                }

            } else {
                if ($use_emoji) {
                    print "❌|";
                } else {
                    print "-|";
                }
            }
        }
        print "\n";
    }
}
print "\n";

exit 0;

# https://releases.llvm.org/5.0.0/tools/clang/docs/DiagnosticsReference.html#rsanitize-address
# https://pxy.fi/5/rsanitize-address

sub _shorten_url {
    my ($url) = shift;

    my $short_url = $url =~ s/https:\/\/releases.llvm.org\/(\d+)\.\d+\.\d+\/tools\/clang\/docs\/DiagnosticsReference.html#(.*)/https:\/\/pxy.fi\/p\/r\/$1\/$2/r;

    return $short_url;
}

sub _parse_result {
    my ($result, $version, $url, $data, $headings) = @_;

    my ($major_version) = $version =~ m/^(\d+)\./;

    my $match = '';

    if ($major_version < 11) {
        $match = 'li > a';
    } else {
        $match = 'li > p > a';
    }

    for my $e ($result->dom->find($match)->each) {        
        # We skip/ignore heading not resembling command line flags
        if (is_cli_flag($e->text)) {
            $headings->{$e->text}++;
            my ($link) = $e->text =~ m/^-(.*)/;
            # HACK: We generate the URL for the anchor, this might fail if the naming is not consistent
            my $anchor = $url .'#'. lc $link;
            $data->{$version}->{$e->text} = $anchor;
        }
    }
}

sub is_cli_flag {
    my $str = shift;

    if ($str =~ m/^\-/) {
        return 1;
    }

    return 0;
}
