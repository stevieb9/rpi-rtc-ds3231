use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use DateTime;
use RPi::RTC::DS3231;

my $rtc = RPi::RTC::DS3231->new;

say $rtc->temp('f');

$rtc->clock_hours(12);
$rtc->year(2000);

my $dt = DateTime->new($rtc->dt_hash);

say $dt;
