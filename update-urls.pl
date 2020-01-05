#!/usr/bin/perl
use strict;
use autodie;
use LWP::Simple qw($ua get);
use JSON::XS ();

my $json = JSON::XS->new->relaxed(1)->utf8(1);

sub slurp { local (@ARGV, $/) = shift; scalar <> }
sub spurt { open my $fh, ">", shift; print $fh @_; close $fh; }

my $spaces = $json->decode(slurp "spaces.json");
my $urls = $json->decode(get "https://directory.spaceapi.io/");
for my $v (values %$spaces) {
	$v = $urls->{$v};
}

spurt "urls.json", $json->encode($spaces);
