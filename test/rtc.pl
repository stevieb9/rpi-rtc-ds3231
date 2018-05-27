use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use RPi::RTC::DS3231;

my $rtc = RPi::RTC::DS3231->new;

#say $rtc->temp();

$rtc->clock_hours(12);
$rtc->year(2000);
say $rtc->datetime;
