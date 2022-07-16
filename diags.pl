#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Mojo::UserAgent;
use feature qw(say);

# REF: https://docs.mojolicious.org/Mojo/DOM
# REF: https://docs.mojolicious.org/Mojo/UserAgent

my %urls = (
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

foreach my $key (keys %urls) {
    
    my $url = $urls{$key};
    #print STDERR "We are parsing >$url< for key >$key<\n";
    my $res = $ua->get($url)->result;

    if    ($res->is_success)  { _parse_result($res, $key, $url, $data, $headings) }
    elsif ($res->is_error)    { say STDERR $res->message; exit $res->code }
    elsif ($res->code == 301) { say STDERR $res->headers->location }
    else                      { say STDERR 'Unable to handle, stopping - '.$res->message; exit $res->code }  
}

#print STDERR Dumper $headings;
#print STDERR Dumper $data;

my @versions = sort { ($a =~ m/^(\d+)\./)[0] <=> ($b =~ m/^(\d+)\./)[0] } (keys %urls);
my @h = sort (keys %{$headings});

my $titles = '| |';
my $seperator = '|-|';

print '# Clang command line flags';
print "\n\n";

foreach my $version (@versions) {
    my $url = $urls{$version};
    $titles .= " [$version]($url) |";
    $seperator .= "-|";
}

print "$titles\n";
print "$seperator\n";

foreach my $flag (@h) {
    if ($flag =~ /^\-/) {
        print "| `$flag` |";
        foreach my $version (@versions) {
            if (exists $data->{$version}->{$flag}) {
                print ' [✅]('.$data->{$version}->{$flag}.') |';
            } else {
                print ' ❌ |';
            }
        }
        print "\n";
    }
}
print "\n";

exit 0;

sub _parse_result {
    my ($result, $key, $url, $data, $headings) = @_;

    my ($major_version) = $key =~ m/^(\d+)\./;

    my $match = '';

    if ($major_version < 11) {
        $match = 'li > a';
    } else {
        $match = 'li > p > a';
    }

    for my $e ($result->dom->find($match)->each) {        
        $headings->{$e->text}++;
        #print STDERR "We got: ".$e->text."\n";
        my ($anchor) = $e->text =~ m/^-(.*)/;
        my $link = $url .'#'. lc $anchor;
        $data->{$key}->{$e->text} = $link;
    }
}
