# TESTDOC: DS3231 setter validation + temp conversion (HW-free)
use strict;
use warnings;

use RPi::RTC::DS3231;
use Test::More;

my $mod = 'RPi::RTC::DS3231';

# HW-free: _write_time() validates every field BEFORE it touches the fd (the
# burst read/write come after the range checks), so out-of-range values croak
# on a bare-blessed object with no chip. am_pm()/clock_hours() likewise croak on
# a bad argument before their XS setters run.

# ---------------------------------------------------------------------------
# date_time() -> _write_time() field-range croaks (validation precedes the fd)
# ---------------------------------------------------------------------------
{
    my $o = bless {}, $mod;

    # The captures are the (zero-padded) matched strings, so _write_time()
    # interpolates them verbatim - "Month (00)", not "Month (0)".
    my %bad = (
        'year below 2000'  => ['1999-01-01 00:00:00', qr/Year \(1999\) out of range/],
        'year above 2099'  => ['2100-01-01 00:00:00', qr/Year \(2100\) out of range/],
        'month 00'         => ['2025-00-01 00:00:00', qr/Month \(00\) out of range/],
        'month 13'         => ['2025-13-01 00:00:00', qr/Month \(13\) out of range/],
        'mday 00'          => ['2025-01-00 00:00:00', qr/Month day \(00\) out of range/],
        'mday 32'          => ['2025-01-32 00:00:00', qr/Month day \(32\) out of range/],
        'hour 24'          => ['2025-01-01 24:00:00', qr/Hour \(24\) out of range/],
        'min 60'           => ['2025-01-01 00:60:00', qr/Minutes \(60\) out of range/],
        'sec 60'           => ['2025-01-01 00:00:60', qr/Seconds \(60\) out of range/],
    );

    for my $case (sort keys %bad){
        my ($dt, $re) = @{ $bad{$case} };
        eval { $o->date_time($dt) };
        like $@, $re, "date_time($case): croaks before touching the fd";
    }
}

# ---------------------------------------------------------------------------
# date_time() format croak (ungated, unlike the RPI_RTC-gated t/70)
# ---------------------------------------------------------------------------
{
    my $o = bless {}, $mod;

    eval { $o->date_time('blah') };
    like $@, qr/parameter must be in the format/, "date_time(bad format): croaks";

    eval { $o->date_time('2025-1-1 0:0:0') };
    like $@, qr/parameter must be in the format/, "date_time(loose digits): croaks";
}

# ---------------------------------------------------------------------------
# am_pm() / clock_hours() bad-argument croaks (both precede their XS setters)
# ---------------------------------------------------------------------------
{
    my $o = bless {}, $mod;

    eval { $o->am_pm('X') };
    like $@, qr/either 'AM' or 'PM'/, "am_pm(bad meridien): croaks";

    eval { $o->clock_hours(13) };
    like $@, qr/either 12 or 24/, "clock_hours(13): croaks";

    eval { $o->clock_hours('x') };
    like $@, qr/either 12 or 24/, "clock_hours(non-numeric): croaks";
}

# ---------------------------------------------------------------------------
# temp(): sign preservation + 2-decimal format + F-conversion, incl. the
# negative path. The XS getTemp() (the register/sign decode) is stubbed so the
# Perl conversion logic runs HW-free against known Celsius values. The old sign
# bug turned -25C into +231; the sign and scale below prove it stays correct.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';

    my $c;
    local *RPi::RTC::DS3231::getTemp = sub { $c };
    my $o = bless { fd => -1 }, $mod;   # preset fd so _fd() never calls getFh

    # Celsius -> expected Celsius string, expected Fahrenheit string.
    my @cases = (
        [ -25,    '-25.00', '-13.00' ],   # negative: -25*9/5+32 = -13
        [ -40,    '-40.00', '-40.00' ],   # the scales cross at -40
        [ -0.25,  '-0.25',  '31.55'  ],   # small sub-zero fraction
        [ 0,      '0.00',   '32.00'  ],
        [ 22.5,   '22.50',  '72.50'  ],
        [ 85,     '85.00',  '185.00' ],   # DS3231 spec ceiling
    );

    for my $case (@cases){
        my ($celsius, $c_str, $f_str) = @$case;
        $c = $celsius;
        is $o->temp,     $c_str, "temp() formats ${celsius}C as $c_str";
        is $o->temp('f'), $f_str, "temp('f') converts ${celsius}C to $f_str";
    }
}

done_testing();
