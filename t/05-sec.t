use strict;
use warnings;

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

{ # set/get

    my $o = $mod->new;

    for (0..59){
        is $o->sec($_), $_, "setting sec to '$_' result is ok";
        is $o->sec, $_, "...and reading is also '$_'"
    }

    for (-1, 60){
        is eval {$o->sec($_); 1}, undef, "sending '$_' results in failure ok";
        like $@, qr/out of bounds.*0-59/, "...and for '$_', error msg is sane";
    }
}

done_testing();
