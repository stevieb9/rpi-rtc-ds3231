package RPi::RTC::DS3231;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('RPi::RTC::DS3231', $VERSION);

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self->_fd;
    return $self;
}
sub close {
    my ($self) = @_;
    _close($self->_fd);
}
sub hour {
    my ($self, $hour) = @_;

    # check for 12/24 hour mode and barf if user
    # is trying to set a 24 hr clock in 12 hr mode

    #FIXME: add set hour routine here

    return getHour($self->_fd);
}
sub min {
    my ($self, $min) = @_;

    #FIXME: set minutes if set

    return getMinutes($self->_fd);
}
sub sec {
    my ($self, $sec) = @_;

    #FIXME: set seconds if set

    return getSeconds($self->_fd);
}
sub _fd {
    my ($self) = @_;

    if (! exists $self->{fd}){
        $self->{fd} = getFh();
    }
    return $self->{fd};
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
