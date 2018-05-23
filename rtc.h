#ifndef _RTC_H_
#define _RTC_H_
#endif

void  _establishI2C (int fd);
int getMeridien (int fd);
int setMeridien (int fd, int value);
int getMilitary (int fd);
int setMilitary (int fd, int value);
int getHour (int fd);
int setHour (int fd, int value);
int getMinutes (int fd);
int setMinutes (int fd, int value);
int getFh ();
void disableRegisterBit (int fd, int reg, int bit);
void enableRegisterBit (int fd, int reg, int bit);
int getRegister (int fd, int reg);
int getRegisterBit (int fd, int reg, int bit);
int getRegisterBits (int fd, int reg, int msb, int lsb);
int setRegister(int fd, int reg, int value, char* name);
int setRegisterBits(int fd, int reg, int lsb, int nbits, int value, char* name);
int bcd2dec(int num);
int dec2bcd(int num);
