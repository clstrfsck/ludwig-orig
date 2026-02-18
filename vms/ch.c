/**********************************************************************/
/*                                                                    */
/*           L      U   U   DDDD   W      W  IIIII   GGGG             */
/*           L      U   U   D   D   W    W     I    G                 */
/*           L      U   U   D   D   W ww W     I    G   GG            */
/*           L      U   U   D   D    W  W      I    G    G            */
/*           LLLLL   UUU    DDDD     W  W    IIIII   GGGG             */
/*                                                                    */
/**********************************************************************/
/*                                                                    */
/*  Copyright (C) 1981, 1987                                          */
/*  Department of Computer Science, University of Adelaide, Australia */
/*  All rights reserved.                                              */
/*  Reproduction of the work or any substantial part thereof in any   */
/*  material form whatsoever is prohibited.                           */
/*                                                                    */
/**********************************************************************/

/*++
! Name:         CH
!
! Description:  These are basic character manipulation routines that are
!               not available in Pascal, and will be much simpler in
!               Bliss-32.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Kelvin B. Nicolle                                    15-Mar-1989
!       Strings passed to ch routines are now passed using conformant
!         arrays, or as type str_object.
!               string[offset],length -> string,offset,length
!       In all calls of ch_length, ch_upcase_str, ch_locase_str, and
!         ch_reverse_str, the offset was 1 and is now omitted.
!       Allow for the extra parameters generated when passing conformant
!         array parameters.
!--*/

#include <ctype.h>
#define NULL  0

#define FALSE 0
#define TRUE  1
#ifdef pyr
#  define STRLEN_RANGE  long
# else
#  define STRLEN_RANGE  short
#endif

#if vax && unix
#define ch_move chmove
#define ch_copy chcopy
#define ch_fill chfill
#define ch_length chlength
#define ch_upcase_str chupcasestr
#define ch_locase_str chlocasestr
#define ch_upcase_chr chupcasechr
#define ch_locase_chr chlocasechr
#define ch_reverse_str chreversestr
#define ch_compare_str chcomparestr
#define ch_search_str chsearchstr
#define ch_move_str_fnm chmovestrfnm
#define ch_copy_str_name chcopystrname
#define ch_copy_str_fnm chcopystrfnm
#define ch_copy_name_str chcopynamestr
#define ch_copy_fnm_str chcopyfnmstr
#define ch_fill_name chfillname
#define ch_length_name chlengthname
#define ch_upcase_key chupcasekey
#define ch_upcase_name chupcasename
#endif


/*--------------------------------------------------------------------*/
/*
{#if ISO1}
procedure ch_move {(
	var     src : packed array [l1..h1:integer] of char;
		st1 : strlen_range;
	var     dst : packed array [l2..h2:integer] of char;
		st2 : strlen_range;
		len : strlen_range)};
{#else}
{##procedure ch_move #<(}
{##        var     src : str_object;}
{##                st1 : strlen_range;}
{##        var     dst : str_object;}
{##                st2 : strlen_range;}
{##                len : strlen_range)#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
void ch_move(src,lo1,hi1,st1,dst,lo2,hi2,st2,len)
#else
void ch_move(src,st1,dst,st2,len)
#endif
char         *src,*dst;
STRLEN_RANGE st1,st2,len;

{
    bcopy(&src[st1-1],&dst[st2-1],len);
}

/*
{#if ISO1}
procedure ch_copy {(
	var     src  : packed array [l1..h1:integer] of char;
		st1  : strlen_range;
		len1 : strlen_range;
	var     dst  : packed array [l2..h2:integer] of char;
		st2  : strlen_range;
		len2 : strlen_range;
		fill : char)};
{#else}
{##procedure ch_copy #<(}
{##        var     src  : str_object;}
{##                st1  : strlen_range;}
{##                len1 : strlen_range;}
{##        var     dst  : str_object;}
{##                st2  : strlen_range;}
{##                len2 : strlen_range;}
{##                fill : char)#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
void ch_copy(src,lo1,hi1, st1, src_len, dst,lo2,hi2, st2, dst_len, filler)
#else
void ch_copy(src, st1, src_len, dst, st2, dst_len, filler)
#endif
STRLEN_RANGE st1, src_len, st2, dst_len;
char         filler, *src, *dst;
{
    int  i, len;
    char *d;

    len = (src_len < dst_len ? src_len : dst_len);
    if (len > 0)
	bcopy(&src[st1-1],&dst[st2-1],len);
    d = dst+st2-1+len;
    len = dst_len - src_len;
    while (len-- > 0)
	*d++ = filler;
}

/*--------------------------------------------------------------------*/

/*
{#if ISO1}
procedure ch_fill {(
	var     dst  : packed array [l1..h1:integer] of char;
		st1  : strlen_range;
		len  : strlen_range;
		fill : char)};
{#else}
{##procedure ch_fill #<(}
{##        var     dst  : str_object;}
{##                st1  : strlen_range;}
{##                len  : strlen_range;}
{##                fill : char)#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
void ch_fill(str,lo1,hi1, st1, len, filler)
#else
void ch_fill(str, st1, len, filler)
#endif
char         filler, *str;
STRLEN_RANGE st1, len;
{
    char *s = &str[st1-1];

    while (len-- > 0)
	*s++ = filler;
}

/*--------------------------------------------------------------------*/

/*
{#if ISO1}
function ch_length {(
	var     str : packed array [l1..h1:integer] of char;
		len : strlen_range)
	: strlen_range};
{#else}
{##function ch_length #<(}
{##        var     str : str_object;}
{##                len : strlen_range)}
{##        : strlen_range#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
long ch_length(src,lo1,hi1, len)
#else
long ch_length(src, len)
#endif
char         *src;
STRLEN_RANGE len;

{
    char *s = src+len;

    while (len-- > 0)
	if (*--s != ' ')
	    return(s - src + 1);
    return 0;
}

/*--------------------------------------------------------------------*/

/*
{#if ISO1}
procedure ch_upcase_str {(
	var     str : packed array [l1..h1:integer] of char;
		len : strlen_range)};
{#else}
{##procedure ch_upcase_str #<(}
{##        var     str : str_object;}
{##                len : strlen_range)#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
void ch_upcase_str(str,lo1,hi1, len)
#else
void ch_upcase_str(str, len)
#endif
char         *str;
STRLEN_RANGE len;

{
    char *s;

    for (s = str;len-- > 0;s++)
	if (islower(*s))
	    *s = toupper(*s);
}

/*--------------------------------------------------------------------*/

/*
{#if ISO1}
procedure ch_locase_str {(
	var     str : packed array [l1..h1:integer] of char;
		len : strlen_range)};
{#else}
{##procedure ch_locase_str #<(}
{##        var     str : str_object;}
{##                len : strlen_range)#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
void ch_locase_str(str,lo1,hi1, len)
#else
void ch_locase_str(str, len)
#endif
char         *str;
STRLEN_RANGE len;

{
    char *s;

    for (s = str;len-- > 0;s++)
	if (isupper(*s))
	    *s = tolower(*s);
}

/*----------------------------------------------------------------------------*/

/*
function ch_upcase_chr {(
		ch      : char)
	: char};
  {umax:nonpascal}
  {mach:nonpascal}

*/
char ch_upcase_chr(ch)
char ch;
{
    if (islower(ch))
	return toupper(ch);
    else
	return ch;
}

/*----------------------------------------------------------------------------*/

/*
function ch_locase_chr {(
		ch      : char)
	: char};
  {umax:nonpascal}
  {mach:nonpascal}

*/
char ch_locase_chr(ch)
char ch;
{
    if (isupper(ch))
	return tolower(ch);
    else
	return ch;
}

/*----------------------------------------------------------------------------*/

/*
{#if ISO1}
procedure ch_reverse_str {(
	var     src : packed array [l1..h1:integer] of char;
	var     dst : packed array [l2..h2:integer] of char;
		len : strlen_range)};
{#else}
{##procedure ch_reverse_str #<(}
{##        var     src : str_object;}
{##        var     dst : str_object;}
{##                len : strlen_range)#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
void ch_reverse_str(src,lo1,hi1, dst,lo2,hi2, len)
#else
void ch_reverse_str(src,dst,len)
#endif
char         *src,*dst;
STRLEN_RANGE len;

{
    char *d;

    d = (dst + len);
    while (len-- > 0)
	*--d = *src++;
}

/*
{#if ISO1}
function ch_compare_str {(
	var     target    : packed array [l1..h1:integer] of char;
		st1       : strlen_range;
		len1      : strlen_range;
	var     text      : packed array [l2..h2:integer] of char;
		st2       : strlen_range;
		len2      : strlen_range;
		exactcase : boolean;
	var     nch_ident : strlen_range)
	: integer};
{#else}
{##function ch_compare_str #<(}
{##        var     target    : str_object;}
{##                st1       : strlen_range;}
{##                len1      : strlen_range;}
{##        var     text      : str_object;}
{##                st2       : strlen_range;}
{##                len2      : strlen_range;}
{##                exactcase : boolean;}
{##        var     nch_ident : strlen_range)}
{##        : integer#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
long ch_compare_str(target,lo1,hi1,st1,len1,
		    text,lo2,hi2,st2,len2,exactcase,nch_ident)
#else
long ch_compare_str(target,st1,len1,text,st2,len2,exactcase,nch_ident)
#endif
char         *target,*text;
STRLEN_RANGE st1,len1,st2,len2,*nch_ident;
long         exactcase;

{
    char  *s;
    short i,diff;

    if (!exactcase) {
	/* convert text to uppercase (assume target already done) */
	s = (char *)malloc(len2);
	for (i = 0;i < len2;i++)
	    s[i] = ch_upcase_chr(text[i+st2-1]);
    } else
	s = &text[st2-1];
    for (i = 0;i < len1 && i < len2;i++)
	if (target[i+st1-1] != s[i]) {
	    diff = target[i+st1-1]-s[i];
	    *nch_ident = i;
	    if (!exactcase) free(s);
	    return diff/abs(diff);
	}
    *nch_ident = i;
    if (i < len1)
	diff = 1;
    else if (i < len2)
	diff = -1;
    else
	diff = 0;
    if (!exactcase) free(s);
    return diff;
}

/*
{#if ISO1}
function ch_search_str {(
	var     target    : packed array [l1..h1:integer] of char;
		st1       : strlen_range;
		len1      : strlen_range;
	var     text      : packed array [l2..h2:integer] of char;
		st2       : strlen_range;
		len2      : strlen_range;
		exactcase : boolean;
		backwards : boolean;
	var     found_loc : strlen_range)
	: boolean};
{#else}
{##function ch_search_str #<(}
{##        var     target    : str_object;}
{##                st1       : strlen_range;}
{##                len1      : strlen_range;}
{##        var     text      : str_object;}
{##                st2       : strlen_range;}
{##                len2      : strlen_range;}
{##                exactcase : boolean;}
{##                backwards : boolean;}
{##        var     found_loc : strlen_range)}
{##        : boolean#>;}
{#endif}
  {umax:nonpascal}
  {mach:nonpascal}

*/
#ifdef ISO1
long ch_search_str(target,lo1,hi1,st1,len1,
		   text,lo2,hi2,st2,len2,exactcase,backwards,found_loc)
#else
long ch_search_str(target,st1,len1,
		   text,st2,len2,exactcase,backwards,found_loc)
#endif
char         *target,*text;
STRLEN_RANGE st1,len1,st2,len2,*found_loc;
long         exactcase,backwards;

{
    char  *s;
    short i;

    if (backwards || !exactcase) {
	s = (char *)malloc(len2);
	if (backwards) {
	    for (i = 0;i < len2;i++)
		s[len2-i-1] = (exactcase)?text[i+st2-1]:ch_upcase_chr(text[i+st2-1]);
	} else {
	    for (i = 0;i < len2;i++)
		s[i] = ch_upcase_chr(text[i+st2-1]);
	}
    } else
	s = &text[st2-1];
    for (i = 0;i <= len2-len1;i++)
	if (bcmp(&target[st1-1],&s[i],len1) == 0) {
	    if (backwards)
		*found_loc = len2-(i+len1);
	    else
		*found_loc = i;
	    if (backwards || !exactcase) free(s);
	    return 1;
	}
    if (backwards || !exactcase) free(s);
    if (backwards)
	*found_loc = len2;
    else
	*found_loc = 0;
    return 0;
}

/*
{#if not ISO1}
{##procedure ch_move_str_fnm #<(}
{##        var     src : str_object;}
{##                st1 : strlen_range;}
{##        var     dst : file_name_str;}
{##                st2 : strlen_range;}
{##                len : strlen_range)#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
void ch_move_str_fnm(src,st1,dst,st2,len)
char         *src,*dst;
STRLEN_RANGE st1,st2,len;

{
    bcopy(&src[st1-1],&dst[st2-1],len);
}

/*
{#if not ISO1}
{##procedure ch_copy_str_name #<(}
{##        var     src  : str_object;}
{##                st1  : strlen_range;}
{##                len1 : strlen_range;}
{##        var     dst  : name_str;}
{##                st2  : strlen_range;}
{##                len2 : strlen_range;}
{##                fill : char)#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
void ch_copy_str_name(src, st1, src_len, dst, st2, dst_len, filler)
STRLEN_RANGE st1, src_len, st2, dst_len;
char         filler, *src, *dst;
{
    int  i, len;
    char *d;

    len = (src_len < dst_len ? src_len : dst_len);
    if (len > 0)
	bcopy(&src[st1-1],&dst[st2-1],len);
    d = dst+st2-1+len;
    len = dst_len - src_len;
    while (len-- > 0)
	*d++ = filler;
}

/*
{#if not ISO1}
{##procedure ch_copy_str_fnm #<(}
{##        var     src  : str_object;}
{##                st1  : strlen_range;}
{##                len1 : strlen_range;}
{##        var     dst  : file_name_str;}
{##                st2  : strlen_range;}
{##                len2 : strlen_range;}
{##                fill : char)#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
void ch_copy_str_fnm(src, st1, src_len, dst, st2, dst_len, filler)
STRLEN_RANGE st1, src_len, st2, dst_len;
char         filler, *src, *dst;
{
    int  i, len;
    char *d;

    len = (src_len < dst_len ? src_len : dst_len);
    if (len > 0)
	bcopy(&src[st1-1],&dst[st2-1],len);
    d = dst+st2-1+len;
    len = dst_len - src_len;
    while (len-- > 0)
	*d++ = filler;
}

/*
{#if not ISO1}
{##procedure ch_copy_name_str #<(}
{##        var     src  : name_str;}
{##                st1  : strlen_range;}
{##                len1 : strlen_range;}
{##        var     dst  : str_object;}
{##                st2  : strlen_range;}
{##                len2 : strlen_range;}
{##                fill : char)#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
void ch_copy_name_str(src, st1, src_len, dst, st2, dst_len, filler)
STRLEN_RANGE st1, src_len, st2, dst_len;
char         filler, *src, *dst;
{
    int  i, len;
    char *d;

    len = (src_len < dst_len ? src_len : dst_len);
    if (len > 0)
	bcopy(&src[st1-1],&dst[st2-1],len);
    d = dst+st2-1+len;
    len = dst_len - src_len;
    while (len-- > 0)
	*d++ = filler;
}

/*
{#if not ISO1}
{##procedure ch_copy_fnm_str #<(}
{##        var     src  : file_name_str;}
{##                st1  : strlen_range;}
{##                len1 : strlen_range;}
{##        var     dst  : str_object;}
{##                st2  : strlen_range;}
{##                len2 : strlen_range;}
{##                fill : char)#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
void ch_copy_fnm_str(src, st1, src_len, dst, st2, dst_len, filler)
STRLEN_RANGE st1, src_len, st2, dst_len;
char         filler, *src, *dst;
{
    int  i, len;
    char *d;

    len = (src_len < dst_len ? src_len : dst_len);
    if (len > 0)
	bcopy(&src[st1-1],&dst[st2-1],len);
    d = dst+st2-1+len;
    len = dst_len - src_len;
    while (len-- > 0)
	*d++ = filler;
}

/*
{#if not ISO1}
{##procedure ch_fill_name #<(}
{##        var     dst  : name_str;}
{##                st1  : strlen_range;}
{##                len  : strlen_range;}
{##                fill : char)#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
void ch_fill_name(str, st1, len, filler)
char         filler, *str;
STRLEN_RANGE st1, len;
{
    char *s = &str[st1-1];

    while (len-- > 0)
	*s++ = filler;
}

/*
{#if not ISO1}
{##function ch_length_name #<(}
{##        var     str : name_str;}
{##                len : strlen_range)}
{##        : strlen_range#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
long ch_length_name(src, len)
char         *src;
STRLEN_RANGE len;

{
    char *s = src+len;

    while (len-- > 0)
	if (*--s != ' ')
	    return(s - src + 1);
    return 0;
}

/*
{#if not ISO1}
{##procedure ch_upcase_key #<(}
{##        var     str : key_str;}
{##                len : strlen_range)#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
void ch_upcase_key(str, len)
char         *str;
STRLEN_RANGE len;

{
    char *s;

    for (s = str;len-- > 0;s++)
	if (islower(*s))
	    *s = toupper(*s);
}

/*
{#if not ISO1}
{##procedure ch_upcase_name #<(}
{##        var     str : name_str;}
{##                len : strlen_range)#>;}
{##  #<umax:nonpascal#>}
{##  #<mach:nonpascal#>}
{##}
{#endif}
*/
void ch_upcase_name(str, len)
char         *str;
STRLEN_RANGE len;

{
    char *s;

    for (s = str;len-- > 0;s++)
	if (islower(*s))
	    *s = toupper(*s);
}
