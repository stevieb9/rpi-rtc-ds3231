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

say "meridien: " . $rtc->am_pm;
say "meridien: " . $rtc->am_pm(1);

#say $rtc->hour(11);

# not done

# my $wday = $rtc->wday;
# my $mday = $rtc->mday;
# my $mon  = $rtc->month; # reg 05, bits 0-4
# my $year = $rtc->year;


#say $rtc->as_string(1);
#say $rtc->as_string(22);

$rtc->_close;
