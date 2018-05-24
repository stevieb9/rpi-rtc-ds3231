use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use RPi::RTC::DS3231;

my $rtc = RPi::RTC::DS3231->new;

#military(0);

#$rtc->hour(17);
#$rtc->min(30);
#$rtc->sec(33);

#military(1);

sub hour {$rtc->hour(shift)}
sub military {$rtc->military_clock(shift)}

#my $meridien;

#if ($rtc->military_clock){
#    $meridien = $rtc->am_pm ? 'PM' : 'AM';
#}

my $h = $rtc->hour;
my $m = $rtc->min;
my $s = $rtc->sec;

#if (defined $meridien){
#    say "$h:$m:$s $meridien";
#}
#else {
say "$h:$m:$s";
#}

# not done

# my $wday = $rtc->wday;
# my $mday = $rtc->mday;
# my $mon  = $rtc->month; # reg 05, bits 0-4
# my $year = $rtc->year;


#say $rtc->as_string(1);
#say $rtc->as_string(22);

$rtc->_close;
