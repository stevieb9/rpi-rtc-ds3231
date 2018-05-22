use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use RPi::RTC::DS3231;

my $rtc = RPi::RTC::DS3231->new;

my $h = $rtc->hour;
my $m = $rtc->min;
my $s = $rtc->sec;

say "$h:$m:$s";

$rtc->_close;
