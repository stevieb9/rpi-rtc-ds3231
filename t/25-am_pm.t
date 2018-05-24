use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

{ # 24-hr clock fail

    my $o = $mod->new;

    is $o->clock_hours(24), 0, "24 hr clock enabled ok";
    is eval { $o->am_pm; 1 }, undef, "reading AM/PM fails in 24-hr clk mode";
    like $@, qr/not available when in 24/, "...and error is sane";
    is eval { $o->am_pm(1); 1 }, undef, "writing AM/PM fails in 24-hr clk mode";
    like $@, qr/can not be set when in 24/, "...and error is sane";
}

{ # set/get

     my $o = $mod->new;


    is $o->min(13), 13, "set 24-hr clock to 13th min ok";
    is $o->sec(13), 13, "set 24-hr clock to 13th sec ok";

    # AM hours

    for (0..12){
        is $o->clock_hours(24), 0, "24 hr clock enabled ok";
        is $o->hour($_), $_, "set 24-hr clock to hour '$_' ok";
        is $o->clock_hours(12), 1, "12 hr clock enabled ok";
        is $o->am_pm, 0, "hr $_ in 24 clock mode is AM ok";
    }

    # PM hours

    for (13..23){
        is $o->clock_hours(24), 0, "24 hr clock enabled ok";
        is $o->hour($_), $_, "set 24-hr clock to hour '$_' ok";
        is $o->clock_hours(12), 1, "12 hr clock enabled ok";
        is $o->am_pm, 1, "hr $_ in 24 clock mode is PM ok";
    }

    is $o->clock_hours(24), 0, "set back to 24 hr clock ok";
}

done_testing();
