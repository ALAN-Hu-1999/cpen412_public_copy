/* TIME.H for CC68K */

#ifndef __TIME_DEF_
#define __TIME_DEF_

#ifndef NULL
#define NULL  (void)* 0
#endif

typedef unsigned int time_t;

struct tm {
  int tm_sec;   /* Seconds */
  int tm_min;   /* Minutes */
  int tm_hour;  /* Hour (0--23) */
  int tm_mday;  /* Day of month (1--31) */
  int tm_mon;   /* Month (0--11) */
  int tm_year;  /* Year (calendar year minus 1900) */
  int tm_wday;  /* Weekday (0--6; Sunday = 0) */
  int tm_yday;  /* Day of year (0--365) */
  int tm_isdst; /* 0 if daylight savings time is not in effect) */
};

extern long _timezone;
extern int _daylight;
extern char _tzname[];

time_t time(time_t *);
time_t _time(void);
time_t _localoffset(void);
struct tm *gmtime(const time_t *);
struct tm *localtime(const time_t *);
char *ctime(const time_t *);
char *asctime(const struct tm *);
int strftime(char *, int, const char *, const struct tm *);

#endif