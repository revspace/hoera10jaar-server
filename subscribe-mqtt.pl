#!/usr/bin/perl
use strict;
use autodie;
use LWP::Simple qw($ua get);
use JSON::XS ();
use Net::MQTT::Simple;

$ENV{MQTT_SIMPLE_ALLOW_INSECURE_LOGIN} = 1;

my $mqtt = Net::MQTT::Simple->new('localhost');
$mqtt->login(@{ do './.mqtt-login.pl' or die "Login-config ontbreekt" });

my $json = JSON::XS->new->relaxed(1)->utf8(1);

sub slurp { local (@ARGV, $/) = shift; scalar <> }
sub spurt { open my $fh, ">", shift; print $fh @_; close $fh; }

my $old = {};

$mqtt->subscribe('revspace/state' => sub {
    my ($topic, $message) = @_;
    my $m = $message eq 'open' ? 'green' : 'red';
    $mqtt->publish("hoera10jaar/realtime/denhaag", $m);
});

while (1) {
    $mqtt->tick(1);
}
