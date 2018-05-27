use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

{ # set/get

    my $o = $mod->new;

    for (1..12){
        is $o->month($_), $_, "setting month to $_ ok";
    }
}

{   # out of bounds/illegal chars

    my $o = $mod->new;

    for (qw(0 13)){
        is eval { $o->month($_); 1; }, undef, "setting month to '$_' fails ok";
    }
}

done_testing();
