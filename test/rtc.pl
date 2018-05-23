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

#say $rtc->as_string(1);
#say $rtc->as_string(22);

$rtc->_close;
