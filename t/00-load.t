#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'RPi::RTC::DS3231' ) || print "Bail out!\n";
}

diag( "Testing RPi::RTC::DS3231 $RPi::RTC::DS3231::VERSION, Perl $], $^X" );
