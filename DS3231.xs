#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include <fcntl.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "rtc.h"
#include "bit.h"

#define RTC_ADDR    0x68

// top-level registers

#define RTC_REG_DT  0x00

// sub-level registers

#define RTC_SEC     0x00
#define RTC_MIN     0x01
#define RTC_HOUR    0x02
#define RTC_WDAY    0x03 // day of week (1-7)
#define RTC_MDAY    0x04 // day of month (1-31)
#define RTC_MONTH   0x05
#define RTC_YEAR    0x06

// sub-level register bits

// sub register RTC_HOUR

#define RTC_AM_PM       0x05
#define RTC_12_24       0x06

int getSeconds (int fd){
    return bcd2dec(getRegister(fd, RTC_SEC));
}

int setSeconds (int fd, int value){
    if (value < 0 || value > 60){
        croak("seconds parameter out of bounds. Must be between 0-60\n");
    }
    setRegister(fd, RTC_SEC, dec2bcd(value), "seconds");
}

int getMinutes (int fd){
    return bcd2dec(getRegister(fd, RTC_MIN));
}

int setMinutes (int fd, int value){
    setRegister(fd, RTC_MIN, dec2bcd(value), "minutes");
}

int getHour (int fd){
   
    int hour;

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) == 0){
        // 24 hr clock
        hour = getRegister(fd, RTC_HOUR);
    }
    else {
        // 12 hr clock
        hour = getRegisterBits(fd, RTC_HOUR, 3, 0);
    }

    return bcd2dec(hour);
}

int setHour (int fd, int value){

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) != 0){
        // 12 hour clock

        if (value > 12 || value < 1){
            croak(
                "hour (%d) is out of bounds when in 12-hour clock mode\n",
                value
            );
        }

        setRegisterBits(fd, RTC_HOUR, 0, 4, value, "hour");
        return 0;
    }
    else {
        // 24 hour clock

        if (value > 23 || value < 0){
            croak(
                "hour (%d) is out of bounds when in 24-hour clock mode\n",
                value
            );
        }

        value = dec2bcd(value);
        setRegister(fd, RTC_HOUR, value, "hour");
        return 0;
    }
}

int getMeridien (int fd){

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) == 0){
        croak(
            "AM/PM functionality not available when in 24-hour clock mode\n"
        );
    }
    return getRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
}

int setMeridien (int fd, int value){

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) == 0){
        croak(
            "AM/PM can not be set when in 24-hour clock mode\n"
        );
    }

    if (value == 1){
        enableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
    }
    else if (value == 0){
        disableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
    }
    else {
        croak(
            "AM/PM value (%d) out of bounds. Send 1 for enable, 0 for disable",
            value
        );
    }

    return 0;
}

int getMilitary (int fd){
    return getRegisterBit(fd, RTC_HOUR, RTC_12_24);
}

int setMilitary (int fd, int value){

    int militaryTime = getMilitary(fd);

    if (militaryTime == value){
        // nothing to do
        return 0;
    }

    if (value == 1){
        // enable 12 hr clock

        if (getHour(fd) <= 12){
            // AM
            setHour(fd, getHour(fd));
            enableRegisterBit(fd, RTC_HOUR, RTC_12_24);
            disableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
        }
        else {
            // PM
            setHour(fd, getHour(fd) - 12);
            enableRegisterBit(fd, RTC_HOUR, RTC_12_24);
            enableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
        }
    }
    else {
        // enable 24 hr clock

        int meridien = getMeridien(fd);

        if (meridien == 0){
            // AM

            int hr = getHour(fd);

            if (hr == 12){
                disableRegisterBit(fd, RTC_HOUR, RTC_12_24);
                setHour(fd, 0);
            }
            else {
                disableRegisterBit(fd, RTC_HOUR, RTC_12_24);
                setHour(fd, hr);
            }
        }
        else {
            // PM

            int hr = getHour(fd);
            if (hr < 12){
                disableRegisterBit(fd, RTC_HOUR, RTC_12_24);
                setHour(fd, hr + 12);
            }
            else {
                disableRegisterBit(fd, RTC_HOUR, RTC_12_24);
                setHour(fd, hr);
            }
        }
    }
}

int getFh (){

    int fd;

    if ((fd = open("/dev/i2c-1", O_RDWR)) < 0) {
        close(fd);
        croak("Couldn't open the device: %s\n", strerror(errno));
	}

	if (ioctl(fd, I2C_SLAVE_FORCE, RTC_ADDR) < 0) {
        close(fd);
        croak(
            "Couldn't find device at addr %d: %s\n",
            RTC_ADDR,
            strerror(errno)
        );
	}

    _establishI2C(fd);

    return fd;
}

void disableRegisterBit (int fd, int reg, int bit){
    int data = bitOff(getRegister(fd, reg), bit);
    setRegister(fd, reg, data, "disabling bit");
}

void enableRegisterBit (int fd, int reg, int bit){
    int data = bitOn(getRegister(fd, reg), bit);
    setRegister(fd, reg, data, "enabling bit");
}

int getRegister (int fd, int reg){

    char buf[1];
    buf[0] = reg;

    if ((write(fd, buf, 1)) != 1){
        close(fd);
        croak(
            "Could not write register pointer %d: %s\n", 
            reg, 
            strerror(errno)
        );
    }

    if ((read(fd, buf, 1)) != 1){
        close(fd);
        croak("Could not read register %d: %s\n", reg, strerror(errno));
    }

    return buf[0];
}

int getRegisterBit (int fd, int reg, int bit){
    int regData = getRegister(fd, reg);
    return bitGet(regData, bit, bit);
}

int getRegisterBits (int fd, int reg, int msb, int lsb){
    return bitGet(getRegister(fd, reg), msb, lsb);
}

int setRegister(int fd, int reg, int value, char* name){
    /*
        always call dec2bcd(value) before sending
        in the value to this function
    */

    char buf[2] = {reg, value};

    if ((write(fd, buf, sizeof(buf))) != 2){
        close(fd);
        croak(
            "Could not write to the %s register: %s\n",
            name,
            strerror(errno)
        );
    }

    return 0;
}

int setRegisterBits(int fd, int reg, int lsb, int nbits, int value, char* name){
    /*
        never call dec2bcd(value) before sending
        in the value to this function
    */

    int data = getRegister(fd, reg);

    data = bitSet(data, lsb, nbits, value);

    char buf[2] = {reg, data};

    if ((write(fd, buf, sizeof(buf))) != 2){
        croak(
            "Could not write to the %s register: %s\n",
            name,
            strerror(errno)
        );
    }

    return 0;
}

int bcd2dec (int num){
  return (((num & 0xF0) >> 4) * 10) + (num & 0x0F);
}

int dec2bcd(int num){
   return((num/10) * 16 + (num%10));
}

void _establishI2C (int fd){

    int buf[1] = { 0x00 };

    if (write(fd, buf, 1) != 1){
        close(fd);
		croak("Error: Received no ACK-Bit, couldn't established connection!");
    }
}

void _close (int fd){
    close(fd);
}

MODULE = RPi::RTC::DS3231  PACKAGE = RPi::RTC::DS3231

PROTOTYPES: DISABLE

int setSeconds (fd, value)
    int fd
    int value

int setMinutes (fd, value)
    int fd
    int value

int setMilitary (fd, value)
    int fd
    int value

int getMilitary (fd)
    int fd

int
setMeridien (fd, value)
    int fd
    int value

int
getMeridien (fd)
    int fd

int
getHour (fd)
	int	fd

int
getSeconds (fd)
    int fd

int
getMinutes (fd)
    int fd

int setHour (fd, value)
    int fd
    int value

int
getFh ()

void
disableRegisterBit (fd, reg, bit)
	int	fd
	int	reg
	int	bit
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        disableRegisterBit(fd, reg, bit);
        if (PL_markstack_ptr != temp) {
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY;
        }
        return;

void
enableRegisterBit (fd, reg, bit)
	int	fd
	int	reg
	int	bit
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        enableRegisterBit(fd, reg, bit);
        if (PL_markstack_ptr != temp) {
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY;
        }
        return;

int
getRegister (fd, reg)
	int	fd
	int	reg

int
getRegisterBit (fd, reg, bit)
	int	fd
	int	reg
	int	bit

int
getRegisterBits (fd, reg, msb, lsb)
	int	fd
	int	reg
	int	msb
	int	lsb

int
setRegister (fd, reg, value, name)
	int	fd
	int	reg
	int	value
	char*	name

int
setRegisterBits(fd, reg, lsb, nbits, value, name)
    int fd
    int reg
    int lsb
    int nbits
    int value
    char* name

int
bcd2dec (num)
	int	num

int
dec2bcd (num)
	int	num

void
_establishI2C (fd)
	int	fd

void
_close (fd)
    int fd
