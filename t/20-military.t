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

    # 0

    is $o->hour(0), 0, "hr 0 in 24-hr mode ok";
    $o->military_clock(1);
    is $o->military_clock, 1, "set clock to 12-hr ok";
    is $o->hour, 12, "hr 0 in 12-hr mode ok";

    for (1..12){
        is $o->military_clock(0), 0, "set clock to 24-hr ok";
        is $o->hour($_), $_, "hr $_ in 24-hr mode ok";
        is $o->military_clock(1), 1, "set clock to 12-hr ok";
        is $o->hour, $_, "hr $_ in 12-hr mode ok";

    }
}

done_testing();
