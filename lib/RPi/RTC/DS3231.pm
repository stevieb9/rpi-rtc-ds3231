package RPi::RTC::DS3231;

use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('RPi::RTC::DS3231', $VERSION);

use Carp qw(croak);

use constant DS3231_ADDR => 0x68;

sub new {
    my ($class, $rtc_addr) = @_;

    $rtc_addr = DS3231_ADDR if ! defined $rtc_addr;

    my $self = bless {}, $class;
    $self->_fd($rtc_addr);
    return $self;
}

# misc methods

sub temp {
    my ($self, $output) = @_;
    my $celsius =  getTemp($self->_fd);
    my $temp = defined $output && $output eq 'f' ? $celsius * 9/5 + 32 : $celsius;

    # Normalize to two decimal places so the return value is consistent
    # regardless of scale (Fahrenheit conversion can yield a single decimal).
    return sprintf "%.2f", $temp;
}

# time/date methods

sub year {
    my ($self, $year) = @_;
    if (defined $year){
        setYear($self->_fd, $year);
    }
    return getYear($self->_fd);
}
sub month {
    my ($self, $month) = @_;
    if (defined $month){
        setMonth($self->_fd, $month);
    }
    return getMonth($self->_fd);
}
sub mday {
    my ($self, $mday) = @_;
    if (defined $mday){
        setDayOfMonth($self->_fd, $mday);
    }
    return getDayOfMonth($self->_fd);
}
sub day {
    my ($self, $wday) = @_;
    if (defined $wday){
        setDayOfWeek($self->_fd, $wday);
    }
    return getDayOfWeek($self->_fd);
}
sub hour {
    my ($self, $hour) = @_;
    if (defined $hour){
        setHour($self->_fd, $hour);
    }

    return getHour($self->_fd);
}
sub min {
    my ($self, $min) = @_;
    if (defined $min){
        setMinutes($self->_fd, $min);
    }
    return getMinutes($self->_fd);
}
sub sec {
    my ($self, $sec) = @_;
    if (defined $sec){
        setSeconds($self->_fd, $sec);
    }
    return getSeconds($self->_fd);
}

# auxiliary time/date methods

sub am_pm {
    my ($self, $meridien) = @_;

    if (defined $meridien) {
        if ($meridien ne 'AM' && $meridien ne 'PM'){
            croak("am_pm() requires either 'AM' or 'PM' as a param\n");
        }
        if ($meridien eq 'AM') {
            $meridien = 0;
        }
        else {
            $meridien = 1;
        }
        setMeridien($self->_fd, $meridien);
    }
    return getMeridien($self->_fd) ? 'PM' : 'AM';
}
sub clock_hours {
    my ($self, $value) = @_;
    if (defined $value){
        if ($value !~ /\d+/ || ($value != 12 && $value != 24)){
            croak "clock_hours() requires either 12 or 24 as a parameter\n";
        }
        $value = $value == 12 ? 1 : 0;
        setMilitary($self->_fd, $value);
    }
    return getMilitary($self->_fd) ? 12 : 24;
}
sub hms {
    my ($self) = @_;

    my $h = _stringify(getHour($self->_fd));
    my $m = _stringify(getMinutes($self->_fd));
    my $s = _stringify(getSeconds($self->_fd));

    my $hms = "$h:$m:$s";

    $hms = "$hms " . $self->am_pm if $self->clock_hours == 12;

    return $hms;
}
sub date_time {
    my ($self, $datetime) = @_;

    if (defined $datetime){
        my @dt;

        if (@dt =
            $datetime =~ /(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})/)
        {
            my $ch = $self->clock_hours;

            $self->clock_hours(24) if $ch == 12;

            $self->year($dt[0]);
            $self->month($dt[1]);
            $self->mday($dt[2]);

            $self->hour($dt[3]);
            $self->min($dt[4]);
            $self->sec($dt[5]);

            $self->clock_hours(12) if $ch == 12;
        }
        else {
            croak(
                "datetime parameter must be in the format " .
                "'yyyy-mm-dd hh:mm:ss'. You supplied '$datetime'\n"
            );
        }
    }
    my $y = getYear($self->_fd);
    my $mon = _stringify(getMonth($self->_fd));
    my $day = _stringify(getDayOfMonth($self->_fd));

    my $h;

    if ($self->clock_hours == 12){
        $self->clock_hours(24);
        $h = _stringify(getHour($self->_fd));
        $self->clock_hours(12);
    }
    else {
        $h = _stringify(getHour($self->_fd));
    }

    my $m = _stringify(getMinutes($self->_fd));
    my $s = _stringify(getSeconds($self->_fd));

    return "$y-$mon-$day $h:$m:$s";
}
sub dt_hash {
    my ($self) = @_;

    my %dt;

    $dt{year} = getYear($self->_fd);
    $dt{month} = _stringify(getMonth($self->_fd));
    $dt{day} = _stringify(getDayOfMonth($self->_fd));

    if ($self->clock_hours == 12){
        $self->clock_hours(24);
        $dt{hour} = _stringify(getHour($self->_fd));
        $self->clock_hours(12);
    }
    else {
        $dt{hour} = _stringify(getHour($self->_fd));
    }

    $dt{minute} = _stringify(getMinutes($self->_fd));
    $dt{second} = _stringify(getSeconds($self->_fd));

    return %dt;
}

# operation methods

sub close {
    my ($self) = @_;
    _close($self->_fd);
}

# internal methods

sub _get_register {
    # retrieve the contents of an entire 8-bit register
    my ($self, $reg) = @_;
    return getRegister($self->_fd, $reg);
}
sub _fd {
    # initializes the I2C communications
    my ($self, $rtc_addr) = @_;

    if (! exists $self->{fd}){
        $self->{fd} = getFh($rtc_addr);
    }
    return $self->{fd};
}
sub _stringify {
    # left-pads with a zero any integer with only a single digit
    my ($int) = @_;

    if (! defined $int || $int !~ /\d+/){
        croak "as_string() requires an integer to check/convert to str\n";
    }

    return length($int) < 2 ? "0$int" : $int;
}

sub __vim {};

1;
__END__

=head1 NAME

RPi::RTC::DS3231 - Interface to the DS3231 Real-Time Clock IC over I2C

=head1 SYNOPSIS

    use RPi::RTC::DS3231;

    my $rtc = RPi::RTC::DS3231->new;

    # set individual

    $rtc->month(12);
    $rtc->hour(3);
    $rtc->sec(33);
    # ...etc

    # set date/time in one swoop

    $rtc->date_time('2018-05-28 23:15:17');

    # get individual

    my $h = $rtc->hour;
    my $d = $rtc->mday;
    # ...etc

    # get date/time as a string in one swoop

    my $datetime = $rtc->date_time; # "yyyy-mm-dd hh:mm:ss"

    # get/set 24 or 12 hour clock

    my $ch = $rtc->clock_hours;
    $rtc->clock_hours(24); # or 12

    # get/set AM/PM

    my $meridien = $rtc->am_pm;

    $rtc->am_pm('AM'); # or 'PM' # only available in 12 hr clock mode

    # get temperature

    my $c = $rtc->temp;
    my $f = $rtc->temp('f');

    # get a hash ready for use in DateTime->new()
    # must have DateTime installed!

    my $dt = DateTime->new($rtc->dt_hash);

=head1 DESCRIPTION

XS-based interface to the DS3231 Real-Time Clock Integrated Circuit over I2C.
Although packaged under the C<RPi::> umbrella, the distribution will work on
any Linux system with I2C installed and operable.

This distribution *should* work with the DS1307 modules as well, but I do not
have one to test with.

=head1 Operational Methods

=head2 new([$i2c_addr])

Instantiates and returns a new L<RPi::RTC::DS3231> object.

Parameters:

    $i2c_addr

Optional, Integer: The I2C address of the RTC module. Defaults to C<0x68> for
a DS3231 RTC unit.

Return: An L<RPi::RTC::DS3231> object.

=head2 close

Closes the active I2C (C<ioctl>) file descriptor. Should be called at the end
of your script.

Takes no parameters, has no return.

=head1 Individual time/date methods

=head2 year([$year])

Sets/gets the RTC year.

Parameters:

    $year

Optional, Integer: A year between C<2000> and C<2099>. If set, we'll update the
RTC.

Return: Integer, the year currently stored in the RTC.

=head2 month([$month])

Sets/gets the RTC month.

Parameters:

    $month

Optional, Integer: A month between C<1> and C<12>. If set, we'll update the RTC.

Return: String/Integer, the month currently stored in the RTC, between C<1> and
C<12>. Single digits will be left-padded with a zero within a string.

=head2 mday([$mday])

Sets/gets the RTC day of the month.

Parameters:

    $mday

Optional, Integer: A day between C<1> and C<31>. If set, we'll update the RTC.

Return: String/Integer, the day currently stored in the RTC, between C<1> and
C<31>. Single digits will be left-padded with a zero within a string.

=head2 day([$day])

Sets/gets the RTC weekday.

Parameters:

    $day

Optional, Integer: A weekday between C<1> and C<7> (correlates to C<Monday> to
C<Sunday> respectively). If set, we'll update the RTC.

Return: String, the weekday currently stored in the RTC, as C<Monday> to
C<Sunday>.

=head2 hour([$hour])

Sets/gets the RTC hour.

Parameters:

    $hour

Optional, Integer: An hour between C<0> and C<23>. If set, we'll update the RTC.

Return: String/Integer, the hour currently stored in the RTC, between C<0> and
C<23>. Single digits will be left-padded with a zero within a string.

NOTE: If you're in 24-hour clock mode
(L<clock_hours|/"clock_hours([$format])">), valid values are C<0>
through C<23>. If in 12-hour clock mode, valid values are C<1> through C<12>.

=head2 min([$min])

Sets/gets the RTC minute.

Parameters:

    $min

Optional, Integer: A minute between C<0> and C<59>. If set, we'll update the
RTC.

Return: String/Integer, the minute currently stored in the RTC, between C<0> and
C<59>. Single digits will be left-padded with a zero within a string.

=head2 sec([$sec])

Sets/gets the RTC second.

Parameters:

    $sec

Optional, Integer: A second between C<0> and C<59>. If set, we'll update the
RTC.

Return: String/Integer, the second currently stored in the RTC, between C<0> and
C<59>. Single digits will be left-padded with a zero within a string.

=head1 Auxiliary date/time methods

=head2 am_pm ([$meridien])

Sets/gets the time meridien (AM/PM) when in 12-hour clock mode. This method will
C<croak()> if called while in 24-hour clock format.

Parameters:

   $meridien

Optional, String: Set by sending in either C<AM> for morning hours, or C<PM> for
latter hours.

Return: String: Returns either C<AM> or C<PM>.

=head2 clock_hours([$format])

Sets/gets the current clock format as either 12-hour or 24-hour format. By
default, the RTC is set to 24-hour clock format.

Parameters:

    $format

Optional, Integer: Send in C<24> for 24-hour (aka. Military) clock format, or
C<12> for 12-hour clock format.

Return: Integer: The current format as either C<24> or C<12>.

=head2 hms

Returns the current hours, minutes and seconds as a string in the following
format:

    'HH:MM:SS'

If in 12-hour clock mode, we will append either C<AM> or C<PM> to the string as
such:

    'HH:MM:SS AM'

=head2 date_time([$datetime])

Sets gets the date/time in one single operation.

Parameters:

    $datetime

Optional, String: The date and time you want to set the RTC to, in the format:

    'YYYY-MM-DD HH:MM:SS'

Note that the hours must reflect 24-hour clock format, so for example, if you
want to set 11 PM, use C<23> for the hours field.

Return: String: The date and time in the format C<YYYY-MM-DD HH:MM:SS>.

=head2 dt_hash

This is a convenience method that returns the date and time in hash format,
ready to be used by L<DateTime>'s C<new()> method.

Return: Hash: The format of the hash is as follows:

      'minute' => 20,
      'hour' => '02',
      'year' => 2000,
      'second' => '07',
      'day' => 18,
      'month' => '05'

Example L<DateTime> usage:

    my $dt = DateTime->new($rtc->dt_hash);

=head1 Miscellaneous methods

=head2 temp([$degrees])

The DS3231 has a built-in thermometer which you can leverage to get the current
temperature. By default, we return the temperature in Celsius. Send in C<'f'>
to get the temperature in Fahrenheit instead.

=head1 TECHNICAL INFORMATION

=head2 DEVICE SPECIFICS

The DS3231 is a real-time clock IC with its 32.768kHz crystal and the
temperature-compensation circuitry for it (TCXO) integrated on-chip,
which is what buys its headline accuracy:

    - Counts seconds, minutes, hours, weekday, date, month and year,
      with leap-year compensation valid up to 2100
    - Accurate to +/-2ppm from 0C to +40C (about one minute per year),
      and +/-3.5ppm from -40C to +85C
    - Keeps time in 24-hour or 12-hour (AM/PM) format
    - On-chip temperature sensor, +/-3C accuracy at 0.25C resolution;
      a conversion runs at power-up and every 64 seconds thereafter
    - VCC supply range 2.3-5.5V (3.3V typical); a separate battery
      input (VBAT, 2.3-5.5V) keeps the clock alive with main power off
    - I2C slave address 0x68 (7-bit), standard (100kHz) and fast
      (400kHz) modes
    - Two time-of-day alarms, plus programmable square-wave (INT/SQW)
      and 32kHz outputs - none of which this module currently drives

Wiring to the Pi (the module hardcodes I2C bus 1, C</dev/i2c-1>):

    DS3231 pin    Pi physical pin
    ----------    ---------------
    VCC           1 (3.3V)
    GND           6 (ground)
    SDA           3 (SDA1 / GPIO 2)
    SCL           5 (SCL1 / GPIO 3)

Breakout modules carry the backup coin cell and bus pull-up resistors,
and the Pi has its own on-board pull-ups on bus 1. If the kernel's RTC
driver has claimed address 0x68 (a C<dtoverlay=i2c-rtc,ds3231> boot
config), this module will still reach the chip - the XS opens it with
C<I2C_SLAVE_FORCE> - but running both at once invites interleaved
transactions, so use one or the other.

=head2 REGISTER MAP

Time and date live in seven BCD registers: 0x47 in the minutes register
means 47 minutes, not 71. The XS layer converts on every access, so the
Perl API speaks plain decimal throughout. The chip's address pointer
increments after every byte transferred, wrapping from 0x12 back to
0x00.

    Addr       Register         Contents
    ----       --------         --------
    0x00       Seconds          00-59 (bit 7 always reads 0)
    0x01       Minutes          00-59 (bit 7 always reads 0)
    0x02       Hours            1-12 plus AM/PM, or 00-23 (see below)
    0x03       Day              Weekday 1-7 (this module: 1 = Monday)
    0x04       Date             01-31
    0x05       Month/Century    Month 01-12; bit 7 is the century flag
    0x06       Year             00-99 (module presents 2000-2099)
    0x07-0x0A  Alarm 1          Seconds/minutes/hours/day-date
    0x0B-0x0D  Alarm 2          Minutes/hours/day-date
    0x0E       Control          EOSC BBSQW CONV RS2 RS1 INTCN A2IE A1IE
    0x0F       Control/status   OSF EN32kHz BSY A2F A1F
    0x10       Aging offset     Signed crystal trim
    0x11       Temperature MSB  Signed integer Celsius (read-only)
    0x12       Temperature LSB  Bits 7-6 = 0.25C fraction (read-only)

This module touches only the seven time/date registers and reads the
two temperature registers; the alarm, control/status and aging
registers are mapped here for completeness.

The hours register (0x02) packs the clock format in with the hour:

    bit 7     Always 0
    bit 6     Clock format select; high = 12-hour, low = 24-hour
    bit 5     In 12-hour mode, the AM/PM flag (high = PM); in 24-hour
              mode, the BCD 20-hour tens bit
    bits 4-0  The remaining BCD hour digits

L<clock_hours|/"clock_hours([$format])"> flips bit 6 (rewriting the
hour so the reading survives the format change),
L<am_pm|/"am_pm ([$meridien])"> flips bit 5, and hour writes preserve
both flag bits.

The century flag (bit 7 of 0x05) toggles when the year register rolls
from 99 to 00. The module preserves it when writing the month and masks
it off month reads; years are pinned to 2000-2099.

Weekday numbering is user-defined on the chip - it only requires the
values to advance sequentially, incrementing at midnight. This module
assigns 1 through 7 to Monday through Sunday.

=head2 ON THE WIRE

The XS layer talks straight C<read()>/C<write()> to C</dev/i2c-1> - no
SMBus protocol calls. The 7-bit address 0x68 becomes C<0xD0> on the
wire for a write and C<0xD1> for a read; bits travel MSB first, and
time/date payloads are BCD.

    S = START    P = STOP
    A = ACK (receiver pulls SDA low)    N = NACK (master, "done")

Opening the device (L<new|/"new([$i2c_addr])">) probes the chip with a
bare pointer write - no data byte, just proof that something ACKs at
0x68:

    +---+------+---+------+---+---+
    | S | 0xD0 | A | 0x00 | A | P |
    +---+------+---+------+---+---+
         addr+W     pointer

Every get is two transactions: point, then read a byte.
C<< $rtc->min >> at 47 minutes past the hour:

    +---+------+---+------+---+---+
    | S | 0xD0 | A | 0x01 | A | P |    Point at the minutes register
    +---+------+---+------+---+---+

    +---+------+---+------+---+---+
    | S | 0xD1 | A | 0x47 | N | P |    Chip drives 0x47: BCD, 47 min
    +---+------+---+------+---+---+
         addr+R

The datasheet's read diagram joins those two with a repeated START, but
it also states that a read simply starts wherever the pointer was last
left - so the STOP-divided pair above works fine.

Every set is one two-byte write: pointer, then data.
C<< $rtc->sec(33) >> (33 encodes to BCD 0x33):

    +---+------+---+------+---+------+---+---+
    | S | 0xD0 | A | 0x00 | A | 0x33 | A | P |
    +---+------+---+------+---+------+---+---+
         addr+W     pointer    data

A seconds write also resets the chip's countdown chain: the next tick
lands a full second after that ACK.

Flag flips are read-modify-write - three transactions. C<am_pm('PM')>
with the hours register holding 0x49 (12-hour mode, 9 o'clock, AM):

    +---+------+---+------+---+---+
    | S | 0xD0 | A | 0x02 | A | P |    Point at the hours register
    +---+------+---+------+---+---+

    +---+------+---+------+---+---+
    | S | 0xD1 | A | 0x49 | N | P |    12-hour mode, 9 AM
    +---+------+---+------+---+---+

    +---+------+---+------+---+------+---+---+
    | S | 0xD0 | A | 0x02 | A | 0x69 | A | P |    Same byte with bit 5
    +---+------+---+------+---+------+---+---+    (AM/PM) raised: 9 PM

L<temp|/"temp([$degrees])"> is two of the get pairs back to back, 0x11
then 0x12:

    0x11 -> 0x16    Signed MSB: 22C
    0x12 -> 0x80    0x80 >> 6 = 2 quarter-degrees: 0.50C

    22 + 0.50 = 22.50C

One caveat: on every START the chip latches a coherent snapshot of the
time registers into secondary buffers, which makes a multi-byte burst
read atomic - but this module reads one register per transaction, so
composed results (C<hms()>, C<date_time()>, C<dt_hash()>) are stitched
together from several snapshots. A tick landing between two of those
transactions can skew a boundary read (minutes read at :59, seconds
read after the rollover, say).

=head2 DATASHEET

The Maxim Integrated (now Analog Devices) DS3231 datasheet (19-5170
Rev 10) is distributed with this software as F<docs/datasheet/DS3231.pdf>.
It covers the register map, the I2C protocol and the electrical
characteristics this module's XS layer implements.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
