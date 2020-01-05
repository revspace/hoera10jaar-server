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

my $urls = $json->decode(slurp "urls.json");
my %open;

for my $k (keys %$urls) {
    $open{$k} = undef;
    eval {
        if ($k eq 'utrecht') {  # speciaaltje
            # Van https://randomdata.nl/assets/js/spacestate.js
            $open{$k} = $json->decode(get(
                "http://api.thingspeak.com/channels/886012/feed/last.json?api_key=A0VXRM8FPPKUT031"
            ))->{field1} ? Types::Serialiser::true : Types::Serialiser::false;
            next;
        }

        my $url = $urls->{$k} or next;
	my $hash = $json->decode(get $url);

        # if old api and new api disagree in one state file, state is unknown
        my $open = $hash->{open} // $hash->{state}->{open};
        $open = undef if defined $hash->{open} and defined $hash->{state}->{open}
                         and     $hash->{open}  !=         $hash->{state}->{open};

        $open{$k} = $open;

        $mqtt->publish("hoera10jaar/spaceapi/$k",
            defined $open
            ? ($open ? 'green' : 'red')
            : 'yellow'
        );
    };
    warn "$k: $@" if $@;
}

spurt "open.json", $json->encode(\%open);
