#!/usr/bin/perl
use strict;
use autodie;
use LWP::Simple qw($ua get);
use JSON::XS ();
use Net::MQTT::Simple;
use Time::HiRes qw(time);

$ENV{MQTT_SIMPLE_ALLOW_INSECURE_LOGIN} = 1;

my $debounce_seconds = 60;

my $mqtt = Net::MQTT::Simple->new('localhost');
$mqtt->login(@{ do './.mqtt-login.pl' or die "Login-config ontbreekt" });

my $json = JSON::XS->new->relaxed(1)->utf8(1);

sub slurp { local (@ARGV, $/) = shift; scalar <> }
sub spurt { open my $fh, ">", shift; print $fh @_; close $fh; }

my $old = {};
my %ignore_until;

$mqtt->subscribe(
    "hoera10jaar/realtime/+", sub {
        my ($topic, $message) = @_;
        my ($stad) = (split m[/], $topic)[-1];

        # in case of race condition, prioritize mqtt over file
        $ignore_until{$stad} = time() + $debounce_seconds;

        $old->{$stad} = $message;
        $mqtt->retain("hoera10jaar/$stad", $message);
    },
    "hoera10jaar/spaceapi/+", sub {
        my ($topic, $message) = @_;
        my ($stad) = (split m[/], $topic)[-1];

        next if defined $old->{$stad} and $old->{$stad} eq $message;
        next if exists $ignore_until{$stad} and time() < $ignore_until{$stad};

        $old->{$stad} = $message;
        $mqtt->retain("hoera10jaar/$stad", $message);
    },
);

while (1) {
    $mqtt->tick(5);
}
