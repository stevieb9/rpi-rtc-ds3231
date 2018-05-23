/*
 * This file was generated automatically by ExtUtils::ParseXS version 3.34 from the
 * contents of DS3231.xs. Do not edit this file, edit DS3231.xs instead.
 *
 *    ANY CHANGES MADE HERE WILL BE LOST!
 *
 */

#line 1 "DS3231.xs"
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

int getMinutes (int fd){
    return bcd2dec(getRegister(fd, RTC_MIN));
}

int getHour (int fd){
   
    int hour;

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) == 0){
        // 24 hr clock
        hour = getRegister(fd, RTC_HOUR);
    }
    else {
        // 12 hr clock
        hour = getRegisterBits(fd, RTC_HOUR, 4, 0);
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

    if (write(fd, buf, 1) != 1){
        close(fd);
		croak(
		    "Couldn't set the register address %d: %s\n",
		    reg,
		    strerror(errno)
        );
    }

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

    int buf[2] = {reg, data};

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

#line 243 "DS3231.c"
#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#ifndef dVAR
#  define dVAR		dNOOP
#endif


/* This stuff is not part of the API! You have been warned. */
#ifndef PERL_VERSION_DECIMAL
#  define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#endif
#ifndef PERL_DECIMAL_VERSION
#  define PERL_DECIMAL_VERSION \
	  PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#endif
#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
	  (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))
#endif
#ifndef PERL_VERSION_LE
#  define PERL_VERSION_LE(r,v,s) \
	  (PERL_DECIMAL_VERSION <= PERL_VERSION_DECIMAL(r,v,s))
#endif

/* XS_INTERNAL is the explicit static-linkage variant of the default
 * XS macro.
 *
 * XS_EXTERNAL is the same as XS_INTERNAL except it does not include
 * "STATIC", ie. it exports XSUB symbols. You probably don't want that
 * for anything but the BOOT XSUB.
 *
 * See XSUB.h in core!
 */


/* TODO: This might be compatible further back than 5.10.0. */
#if PERL_VERSION_GE(5, 10, 0) && PERL_VERSION_LE(5, 15, 1)
#  undef XS_EXTERNAL
#  undef XS_INTERNAL
#  if defined(__CYGWIN__) && defined(USE_DYNAMIC_LOADING)
#    define XS_EXTERNAL(name) __declspec(dllexport) XSPROTO(name)
#    define XS_INTERNAL(name) STATIC XSPROTO(name)
#  endif
#  if defined(__SYMBIAN32__)
#    define XS_EXTERNAL(name) EXPORT_C XSPROTO(name)
#    define XS_INTERNAL(name) EXPORT_C STATIC XSPROTO(name)
#  endif
#  ifndef XS_EXTERNAL
#    if defined(HASATTRIBUTE_UNUSED) && !defined(__cplusplus)
#      define XS_EXTERNAL(name) void name(pTHX_ CV* cv __attribute__unused__)
#      define XS_INTERNAL(name) STATIC void name(pTHX_ CV* cv __attribute__unused__)
#    else
#      ifdef __cplusplus
#        define XS_EXTERNAL(name) extern "C" XSPROTO(name)
#        define XS_INTERNAL(name) static XSPROTO(name)
#      else
#        define XS_EXTERNAL(name) XSPROTO(name)
#        define XS_INTERNAL(name) STATIC XSPROTO(name)
#      endif
#    endif
#  endif
#endif

/* perl >= 5.10.0 && perl <= 5.15.1 */


/* The XS_EXTERNAL macro is used for functions that must not be static
 * like the boot XSUB of a module. If perl didn't have an XS_EXTERNAL
 * macro defined, the best we can do is assume XS is the same.
 * Dito for XS_INTERNAL.
 */
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) XS(name)
#endif

/* Now, finally, after all this mess, we want an ExtUtils::ParseXS
 * internal macro that we're free to redefine for varying linkage due
 * to the EXPORT_XSUB_SYMBOLS XS keyword. This is internal, use
 * XS_EXTERNAL(name) or XS_INTERNAL(name) in your code if you need to!
 */

#undef XS_EUPXS
#if defined(PERL_EUPXS_ALWAYS_EXPORT)
#  define XS_EUPXS(name) XS_EXTERNAL(name)
#else
   /* default to internal */
#  define XS_EUPXS(name) XS_INTERNAL(name)
#endif

#ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#define PERL_ARGS_ASSERT_CROAK_XS_USAGE assert(cv); assert(params)

/* prototype to pass -Wmissing-prototypes */
STATIC void
S_croak_xs_usage(const CV *const cv, const char *const params);

STATIC void
S_croak_xs_usage(const CV *const cv, const char *const params)
{
    const GV *const gv = CvGV(cv);

    PERL_ARGS_ASSERT_CROAK_XS_USAGE;

    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;

        if (hvname)
	    Perl_croak_nocontext("Usage: %s::%s(%s)", hvname, gvname, params);
        else
	    Perl_croak_nocontext("Usage: %s(%s)", gvname, params);
    } else {
        /* Pants. I don't think that it should be possible to get here. */
	Perl_croak_nocontext("Usage: CODE(0x%" UVxf ")(%s)", PTR2UV(cv), params);
    }
}
#undef  PERL_ARGS_ASSERT_CROAK_XS_USAGE

#define croak_xs_usage        S_croak_xs_usage

#endif

/* NOTE: the prototype of newXSproto() is different in versions of perls,
 * so we define a portable version of newXSproto()
 */
#ifdef newXS_flags
#define newXSproto_portable(name, c_impl, file, proto) newXS_flags(name, c_impl, file, proto, 0)
#else
#define newXSproto_portable(name, c_impl, file, proto) (PL_Sv=(SV*)newXS(name, c_impl, file), sv_setpv(PL_Sv, proto), (CV*)PL_Sv)
#endif /* !defined(newXS_flags) */

#if PERL_VERSION_LE(5, 21, 5)
#  define newXS_deffile(a,b) Perl_newXS(aTHX_ a,b,file)
#else
#  define newXS_deffile(a,b) Perl_newXS_deffile(aTHX_ a,b)
#endif

#line 387 "DS3231.c"

XS_EUPXS(XS_RPi__RTC__DS3231_getHour); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_getHour)
{
    dVAR; dXSARGS;
    if (items != 1)
       croak_xs_usage(cv,  "fd");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = getHour(fd);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_getSeconds); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_getSeconds)
{
    dVAR; dXSARGS;
    if (items != 1)
       croak_xs_usage(cv,  "fd");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = getSeconds(fd);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_getMinutes); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_getMinutes)
{
    dVAR; dXSARGS;
    if (items != 1)
       croak_xs_usage(cv,  "fd");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = getMinutes(fd);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_setHour); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_setHour)
{
    dVAR; dXSARGS;
    if (items != 2)
       croak_xs_usage(cv,  "fd, value");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	value = (int)SvIV(ST(1))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = setHour(fd, value);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_getFh); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_getFh)
{
    dVAR; dXSARGS;
    if (items != 0)
       croak_xs_usage(cv,  "");
    {
	int	RETVAL;
	dXSTARG;

	RETVAL = getFh();
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_disableRegisterBit); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_disableRegisterBit)
{
    dVAR; dXSARGS;
    if (items != 3)
       croak_xs_usage(cv,  "fd, reg, bit");
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	int	fd = (int)SvIV(ST(0))
;
	int	reg = (int)SvIV(ST(1))
;
	int	bit = (int)SvIV(ST(2))
;
#line 262 "DS3231.xs"
        I32* temp;
#line 501 "DS3231.c"
#line 264 "DS3231.xs"
        temp = PL_markstack_ptr++;
        disableRegisterBit(fd, reg, bit);
        if (PL_markstack_ptr != temp) {
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY;
        }
        return;
#line 510 "DS3231.c"
	PUTBACK;
	return;
    }
}


XS_EUPXS(XS_RPi__RTC__DS3231_enableRegisterBit); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_enableRegisterBit)
{
    dVAR; dXSARGS;
    if (items != 3)
       croak_xs_usage(cv,  "fd, reg, bit");
    PERL_UNUSED_VAR(ax); /* -Wall */
    SP -= items;
    {
	int	fd = (int)SvIV(ST(0))
;
	int	reg = (int)SvIV(ST(1))
;
	int	bit = (int)SvIV(ST(2))
;
#line 278 "DS3231.xs"
        I32* temp;
#line 534 "DS3231.c"
#line 280 "DS3231.xs"
        temp = PL_markstack_ptr++;
        enableRegisterBit(fd, reg, bit);
        if (PL_markstack_ptr != temp) {
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY;
        }
        return;
#line 543 "DS3231.c"
	PUTBACK;
	return;
    }
}


XS_EUPXS(XS_RPi__RTC__DS3231_getRegister); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_getRegister)
{
    dVAR; dXSARGS;
    if (items != 2)
       croak_xs_usage(cv,  "fd, reg");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	reg = (int)SvIV(ST(1))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = getRegister(fd, reg);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_getRegisterBit); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_getRegisterBit)
{
    dVAR; dXSARGS;
    if (items != 3)
       croak_xs_usage(cv,  "fd, reg, bit");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	reg = (int)SvIV(ST(1))
;
	int	bit = (int)SvIV(ST(2))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = getRegisterBit(fd, reg, bit);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_getRegisterBits); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_getRegisterBits)
{
    dVAR; dXSARGS;
    if (items != 4)
       croak_xs_usage(cv,  "fd, reg, msb, lsb");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	reg = (int)SvIV(ST(1))
;
	int	msb = (int)SvIV(ST(2))
;
	int	lsb = (int)SvIV(ST(3))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = getRegisterBits(fd, reg, msb, lsb);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_setRegister); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_setRegister)
{
    dVAR; dXSARGS;
    if (items != 4)
       croak_xs_usage(cv,  "fd, reg, value, name");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	reg = (int)SvIV(ST(1))
;
	int	value = (int)SvIV(ST(2))
;
	char*	name = (char *)SvPV_nolen(ST(3))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = setRegister(fd, reg, value, name);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_setRegisterBits); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_setRegisterBits)
{
    dVAR; dXSARGS;
    if (items != 6)
       croak_xs_usage(cv,  "fd, reg, lsb, nbits, value, name");
    {
	int	fd = (int)SvIV(ST(0))
;
	int	reg = (int)SvIV(ST(1))
;
	int	lsb = (int)SvIV(ST(2))
;
	int	nbits = (int)SvIV(ST(3))
;
	int	value = (int)SvIV(ST(4))
;
	char*	name = (char *)SvPV_nolen(ST(5))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = setRegisterBits(fd, reg, lsb, nbits, value, name);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_bcd2dec); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_bcd2dec)
{
    dVAR; dXSARGS;
    if (items != 1)
       croak_xs_usage(cv,  "num");
    {
	int	num = (int)SvIV(ST(0))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = bcd2dec(num);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231_dec2bcd); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231_dec2bcd)
{
    dVAR; dXSARGS;
    if (items != 1)
       croak_xs_usage(cv,  "num");
    {
	int	num = (int)SvIV(ST(0))
;
	int	RETVAL;
	dXSTARG;

	RETVAL = dec2bcd(num);
	XSprePUSH; PUSHi((IV)RETVAL);
    }
    XSRETURN(1);
}


XS_EUPXS(XS_RPi__RTC__DS3231__establishI2C); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231__establishI2C)
{
    dVAR; dXSARGS;
    if (items != 1)
       croak_xs_usage(cv,  "fd");
    {
	int	fd = (int)SvIV(ST(0))
;

	_establishI2C(fd);
    }
    XSRETURN_EMPTY;
}


XS_EUPXS(XS_RPi__RTC__DS3231__close); /* prototype to pass -Wmissing-prototypes */
XS_EUPXS(XS_RPi__RTC__DS3231__close)
{
    dVAR; dXSARGS;
    if (items != 1)
       croak_xs_usage(cv,  "fd");
    {
	int	fd = (int)SvIV(ST(0))
;

	_close(fd);
    }
    XSRETURN_EMPTY;
}

#ifdef __cplusplus
extern "C"
#endif
XS_EXTERNAL(boot_RPi__RTC__DS3231); /* prototype to pass -Wmissing-prototypes */
XS_EXTERNAL(boot_RPi__RTC__DS3231)
{
#if PERL_VERSION_LE(5, 21, 5)
    dVAR; dXSARGS;
#else
    dVAR; dXSBOOTARGSXSAPIVERCHK;
#endif
#if (PERL_REVISION == 5 && PERL_VERSION < 9)
    char* file = __FILE__;
#else
    const char* file = __FILE__;
#endif

    PERL_UNUSED_VAR(file);

    PERL_UNUSED_VAR(cv); /* -W */
    PERL_UNUSED_VAR(items); /* -W */
#if PERL_VERSION_LE(5, 21, 5)
    XS_VERSION_BOOTCHECK;
#  ifdef XS_APIVERSION_BOOTCHECK
    XS_APIVERSION_BOOTCHECK;
#  endif
#endif

        newXS_deffile("RPi::RTC::DS3231::getHour", XS_RPi__RTC__DS3231_getHour);
        newXS_deffile("RPi::RTC::DS3231::getSeconds", XS_RPi__RTC__DS3231_getSeconds);
        newXS_deffile("RPi::RTC::DS3231::getMinutes", XS_RPi__RTC__DS3231_getMinutes);
        newXS_deffile("RPi::RTC::DS3231::setHour", XS_RPi__RTC__DS3231_setHour);
        newXS_deffile("RPi::RTC::DS3231::getFh", XS_RPi__RTC__DS3231_getFh);
        newXS_deffile("RPi::RTC::DS3231::disableRegisterBit", XS_RPi__RTC__DS3231_disableRegisterBit);
        newXS_deffile("RPi::RTC::DS3231::enableRegisterBit", XS_RPi__RTC__DS3231_enableRegisterBit);
        newXS_deffile("RPi::RTC::DS3231::getRegister", XS_RPi__RTC__DS3231_getRegister);
        newXS_deffile("RPi::RTC::DS3231::getRegisterBit", XS_RPi__RTC__DS3231_getRegisterBit);
        newXS_deffile("RPi::RTC::DS3231::getRegisterBits", XS_RPi__RTC__DS3231_getRegisterBits);
        newXS_deffile("RPi::RTC::DS3231::setRegister", XS_RPi__RTC__DS3231_setRegister);
        newXS_deffile("RPi::RTC::DS3231::setRegisterBits", XS_RPi__RTC__DS3231_setRegisterBits);
        newXS_deffile("RPi::RTC::DS3231::bcd2dec", XS_RPi__RTC__DS3231_bcd2dec);
        newXS_deffile("RPi::RTC::DS3231::dec2bcd", XS_RPi__RTC__DS3231_dec2bcd);
        newXS_deffile("RPi::RTC::DS3231::_establishI2C", XS_RPi__RTC__DS3231__establishI2C);
        newXS_deffile("RPi::RTC::DS3231::_close", XS_RPi__RTC__DS3231__close);
#if PERL_VERSION_LE(5, 21, 5)
#  if PERL_VERSION_GE(5, 9, 0)
    if (PL_unitcheckav)
        call_list(PL_scopestack_ix, PL_unitcheckav);
#  endif
    XSRETURN_YES;
#else
    Perl_xs_boot_epilog(aTHX_ ax);
#endif
}

