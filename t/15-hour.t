use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

{ # set/get 24 hour clock

    my $o = $mod->new;

    # set 24 hr clock mode

    $o->military_clock(0);

    for (0..23){
        is $o->hour($_), $_, "setting 24-clock hour to '$_' result is ok";
        is $o->hour, $_, "...and reading is also '$_'"
    }

    for (-1, 25){
        is eval {$o->hour($_); 1}, undef, "sending '$_' results in failure ok";
        like $@, qr/out of bounds.*0-23/, "...and for '$_', error msg is sane";
    }
}

{ # set/get 12 hour clock

    my $o = $mod->new;

    # set 12 hr clock mode


    #FIXME
    #TODO: why in hell do we have to set 24 hr clock, then set hours to 0?

    printf("HOUR: %d\n", $o->hour);
    my $reg = $o->_get_register(2);
    printf("%b\n", $reg);
    $o->military_clock(0);
    say $o->military_clock;
##    $o->hour(0);

    is $o->military_clock(1), 1, "set to 12 hr clock ok";
    $reg = $o->_get_register(2);
    printf("%b\n", $reg);

    for (1..12){
        $o->hour($_);
        $reg = $o->_get_register(2);
        printf("%b\n", $reg);

        is $o->hour, $_, "setting hour to '$_' result is ok";
     $reg = $o->_get_register(2);
    printf("%b\n", $reg);
#        is $o->hour, $_, "...and reading is also '$_'"
    }

#    for (0, 13){
#        is eval {$o->hour($_); 1}, undef, "sending '$_' results in failure ok";
#        like $@, qr/out of bounds.*1-12/, "...and for '$_', error msg is sane";
#    }
}

done_testing();
