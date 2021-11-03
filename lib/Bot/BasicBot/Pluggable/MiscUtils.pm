package Bot::BasicBot::Pluggable::MiscUtils;
use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(util_dehi util_strip_codes massblocker);
use List::Util qw(min max);

sub util_dehi {
    my $r = shift;
    $r =~ s/^(.)(.*)$/$1\cB\cB$2/g;
    $r
}

sub util_strip_codes {
  my $msg = shift;
  $msg =~ s/\c_|\cB|\cC(?:\d{1,2}(?:,\d{1,2})?)?//g;
  $msg
}

my $mass_stop_user_default = 30;
my $mass_stop_other_default = 10;
sub massblocker {
    bless +{
	stop_user => $mass_stop_user_default,
	stop_other => $mass_stop_other_default,
	blocker => +{},
	@_
       }, 'Bot::BasicBot::Pluggable::MiscUtils::_mass_blocker';
}

1;

package Bot::BasicBot::Pluggable::MiscUtils::_mass_blocker;
use strict;
use warnings;
local *util_strip_codes = \&Bot::BasicBot::Pluggable::MiscUtils::util_strip_codes;
use List::Util qw(min max);

sub check {
    my $self = shift;
    my ($who, $channel, $msg) = @_;

    my $hr = $self->{blocker}{ $channel } ||= +{};

    my $mr = $hr->{ $msg } ||= +{};

    my $now = time;

    my $user_time = $mr->{$who} || 0;
    my $other_time = $mr->{'@'} || 0;

    $mr->{'@'} = $mr->{$who} = $now;

    my $block = $user_time > $now - $self->{stop_user} || $other_time > $now - $self->{stop_other};
    warn "blocking " . substr(util_strip_codes($msg),0,14) . ".." . max($now-$user_time,$now-$other_time) if $block;
    !$block
}

sub expire {
    my $self = shift;
    my $now = time;
    for my $ch (keys %{ $self->{blocker} }) {
	for my $msg (keys %{ $self->{blocker}{$ch} }) {
	    if ($self->{blocker}{ $ch }{ $msg }{'@'} < $now - $self->{stop_user}) {
		delete $self->{blocker}{$ch}{$msg};
	    }
	}
    }
}

1;
