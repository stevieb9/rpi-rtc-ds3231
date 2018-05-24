use strict;
use warnings;

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

{ # set/get

    my $o = $mod->new;

    $o->min(1);
    $o->sec(1);

    is $o->military_clock(0), 0, "setting clock to 24 hr result ok";
    is $o->military_clock, 0, "...and so is the return with no param";

    for (0..23){
        is $o->hour($_), 0, "hr $_ in 24-hr mode ok";
        $o->military_clock(1);
        is $o->military_clock, 1, "set clock to 12-hr ok";
        is $o->hour, 12, "hr $_ in 12-hr mode ok";
        exit;

    }
}

done_testing();
