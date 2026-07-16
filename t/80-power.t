# TESTDOC: DS3231 en_32khz / osc_on_battery power bits (HW-free)
use strict;
use warnings;

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

# HW-free: en_32khz()/osc_on_battery() are pure Perl over the enable/disable/
# getRegisterBit XS helpers, so stubbing _fd (no bus opened) and those three
# helpers lets us assert exactly which register + bit each method drives - and,
# for osc_on_battery(), that the active-low EOSC bit is inverted correctly.

my @calls;      # each set() records [op, reg, bit]
my %bit;        # "reg:bit" => current value getRegisterBit returns

no warnings qw(redefine once);
local *RPi::RTC::DS3231::_fd = sub { 42 };   # Any truthy fd; no chip is touched
local *RPi::RTC::DS3231::enableRegisterBit = sub {
    my ($fd, $reg, $b) = @_;
    push @calls, ['enable', $reg, $b];
    $bit{"$reg:$b"} = 1;
};
local *RPi::RTC::DS3231::disableRegisterBit = sub {
    my ($fd, $reg, $b) = @_;
    push @calls, ['disable', $reg, $b];
    $bit{"$reg:$b"} = 0;
};
local *RPi::RTC::DS3231::getRegisterBit = sub {
    my ($fd, $reg, $b) = @_;
    return $bit{"$reg:$b"} // 0;
};

my $rtc = bless {}, $mod;

# --- en_32khz(): Status register 0x0F bit 3, direct sense ---
{
    @calls = ();
    $rtc->en_32khz(1);
    is_deeply \@calls, [['enable', 0x0F, 3]], "en_32khz(1) enables Status(0x0F) bit 3";
    is $rtc->en_32khz, 1, "en_32khz() reads back enabled";

    @calls = ();
    $rtc->en_32khz(0);
    is_deeply \@calls, [['disable', 0x0F, 3]], "en_32khz(0) disables Status(0x0F) bit 3";
    is $rtc->en_32khz, 0, "en_32khz() reads back disabled";
}

# --- osc_on_battery(): Control register 0x0E bit 7 (EOSC, active-low) ---
# Positive sense: true = keep running on battery = EOSC cleared; false = stop = EOSC set.
{
    @calls = ();
    $rtc->osc_on_battery(1);
    is_deeply \@calls, [['disable', 0x0E, 7]],
        "osc_on_battery(1) CLEARS EOSC (Control 0x0E bit 7) - keeps the clock on battery";
    is $rtc->osc_on_battery, 1, "osc_on_battery() reads back true (runs on battery)";

    @calls = ();
    $rtc->osc_on_battery(0);
    is_deeply \@calls, [['enable', 0x0E, 7]],
        "osc_on_battery(0) SETS EOSC - stops the oscillator on battery";
    is $rtc->osc_on_battery, 0, "osc_on_battery() reads back false (stops on battery)";
}

done_testing();
