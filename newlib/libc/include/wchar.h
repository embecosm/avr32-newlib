#ifndef _WCHAR_H_
#define _WCHAR_H_

#include <_ansi.h>

#define __need_size_t
#define __need_wchar_t
#define __need_wint_t
#include <stddef.h>

/* For _mbstate_t definition. */
#include <sys/_types.h>

#ifndef NULL
#define NULL	0
#endif

#ifndef WEOF
# define WEOF ((wint_t)-1)
#endif

#ifndef MBSTATE_T
#define MBSTATE_T
typedef _mbstate_t mbstate_t;
#endif /* MBSTATE_T */

wint_t	_EXFUN(btowc, (int));
int	_EXFUN(wctob, (wint_t));
size_t	_EXFUN(mbrlen, (const char * , size_t, mbstate_t *));
size_t	_EXFUN(mbrtowc, (wchar_t * , const char * , size_t, mbstate_t *));
int	_EXFUN(mbsinit, (const mbstate_t *));
size_t	_EXFUN(mbsrtowcs, (wchar_t * , const char ** , size_t, mbstate_t *));
size_t	_EXFUN(wcrtomb, (char * , wchar_t, mbstate_t *));
size_t	_EXFUN(wcsrtombs, (char * , const wchar_t ** , size_t, mbstate_t *));
wchar_t	*_EXFUN(wcscat, (wchar_t * , const wchar_t *));
wchar_t	*_EXFUN(wcschr, (const wchar_t *, wchar_t));
int	_EXFUN(wcscmp, (const wchar_t *, const wchar_t *));
wchar_t	*_EXFUN(wcscpy, (wchar_t * , const wchar_t *));
size_t	_EXFUN(wcscspn, (const wchar_t *, const wchar_t *));
size_t	_EXFUN(wcslcat, (wchar_t *, const wchar_t *, size_t));
size_t	_EXFUN(wcslcpy, (wchar_t *, const wchar_t *, size_t));
size_t	_EXFUN(wcslen, (const wchar_t *));
wchar_t	*_EXFUN(wcsncat, (wchar_t * , const wchar_t * , size_t));
int	_EXFUN(wcsncmp, (const wchar_t *, const wchar_t *, size_t));
wchar_t	*_EXFUN(wcsncpy, (wchar_t *  , const wchar_t * , size_t));
wchar_t	*_EXFUN(wcspbrk, (const wchar_t *, const wchar_t *));
wchar_t	*_EXFUN(wcsrchr, (const wchar_t *, wchar_t));
size_t	_EXFUN(wcsspn, (const wchar_t *, const wchar_t *));
wchar_t	*_EXFUN(wcsstr, (const wchar_t *, const wchar_t *));
wchar_t	*_EXFUN(wmemchr, (const wchar_t *, wchar_t, size_t));
int	_EXFUN(wmemcmp, (const wchar_t *, const wchar_t *, size_t));
wchar_t	*_EXFUN(wmemcpy, (wchar_t * , const wchar_t * , size_t));
wchar_t	*_EXFUN(wmemmove, (wchar_t *, const wchar_t *, size_t));
wchar_t	*_EXFUN(wmemset, (wchar_t *, wchar_t, size_t));

#endif /* _WCHAR_H_ */