package RPi::RTC::DS3231;

use strict;
use warnings;

our $VERSION = '0.01';

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
    my $celcius =  getTemp($self->_fd);
    return defined $output && $output eq 'f' ? $celcius * 9/5 + 32 : $celcius;
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

# auxillary time/date methods

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
    my ($self, $reg) = @_;
    return getRegister($self->_fd, $reg);
}
sub _fd {
    my ($self, $rtc_addr) = @_;

    if (! exists $self->{fd}){
        $self->{fd} = getFh($rtc_addr);
    }
    return $self->{fd};
}
sub _stringify {
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
    $rt->sec(33);
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

    $rtc->am_pm('AM'); # or 'PM' # only available in 24 hr clock mode

    # get temperature

    my $c = $rtc->temp;
    my $f = $rtc->temp('f');

    # get a hash ready for use in DateTime->new()

    DateTime->new($rtc->dt_hash); # must have DateTime installed!

=head1 DESCRIPTION


=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
