use strict;
use warnings;
use feature 'say';

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

{ # set/get

    my $o = $mod->new;

    for (2000..2099){
        is $o->year($_), $_, "setting year to $_ ok";
    }
}

{   # out of bounds/illegal chars

    my $o = $mod->new;

    for (qw(1999 2100)){
        is eval { $o->year($_); 1; }, undef, "setting year to '$_' fails ok";
    }
}

done_testing();
