use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

{ # set/get

    my $o = $mod->new;

    my $temp = $o->temp;

    like $temp, qr/\d+(?:\.\d{2})?/, "temp() return is ok";

}

done_testing();
