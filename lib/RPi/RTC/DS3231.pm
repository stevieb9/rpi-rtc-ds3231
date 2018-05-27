package RPi::RTC::DS3231;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('RPi::RTC::DS3231', $VERSION);

use Carp qw(croak);

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self->_fd;
    return $self;
}

# misc methods

sub temp {
    my ($self) = @_;

    return getTemp($self->_fd);
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

    if (defined $meridien){
        setMeridien($self->_fd, $meridien);
    }
    return getMeridien($self->_fd);
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
    return getMilitary($self->_fd);
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
    my ($self) = @_;

    if (! exists $self->{fd}){
        $self->{fd} = getFh();
    }
    return $self->{fd};
}
sub _as_string {
    my ($self, $int) = @_;

    if (! defined $int){
        croak "as_string() requires an integer to check/convert to str\n";
    }

    return length($int) < 2 ? "0$int" : $int;
}

sub __vim {};

1;
__END__

=head1 NAME

RPi::RTC::DS3231 - The great new RPi::RTC::DS3231!

=head1 SYNOPSIS

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
