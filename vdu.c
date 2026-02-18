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
! Name:         VDU
!
! Description:  This module does all the complex control of the VDU type
!               screens that Ludwig demands.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002
! 4-003 John Warburton                                        6-Apr-1989
!       Added vdu_putcurs(old_x,old_y) to vdu_redrawscr so that the
!       cursor is returned to it's old position after a suspend.
! 4-004 Jeff Blows                                           19-Jun-1989
!       Rearrange calls in vdu_redraw so return from suspend looks better.
! 4-005 Jeff Blows                                           20-Jun-1989
!       Modify tt_setupterm so that ioctl's are used to determine the window
!       size when running on a sun.
! 4-006 Jeff Blows                                           23-Jun-1989
!       Add code to support te and ti termcap fields.
!--*/

/* Notes:
 * . I have not finished changing the order of parameters to a consistent
 *   str,str_len order.
 * . Interrupt (CTRL/C) handling has yet to be added.
 * . The capabilities vector needs to be set in vdu_init.
 */

#include <sys/file.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/uio.h>
#include <sys/time.h>

#if sun
#include <sys/termios.h>
#endif

#include <sgtty.h>
#include <stdio.h>
#include <signal.h>
#include <ctype.h>

#include "const.h"
#include "type.h"
#include "termdesc.h"

#if vax && unix
#define screen_unix_message     screenunixmessage
#define unix_suspend            unixsuspend
#endif

#define NUL             (short)0000
#define SOH             (short)0001
#define BEL             (short)0007
#define BS              (short)0010
#define LF              (short)0012
#define CR              (short)0015
#define EM              (short)0031
#define SUB             (short)0032
#define ESC             (short)0033
#define FS              (short)0034
#define GS              (short)0035
#define DEL             (short)0177

#define max_out_buf_len 900
#define out_m_cleareol  1
#define out_m_anycurs   2

#define TRMFLAGS_V_CLSC 0
#define TRMFLAGS_V_CLES 1
#define TRMFLAGS_V_CLEL 2
#define TRMFLAGS_V_INLN 3
#define TRMFLAGS_V_INCH 4
#define TRMFLAGS_V_DLLN 5
#define TRMFLAGS_V_DLCH 6
#define TRMFLAGS_V_SCDN 7
#define TRMFLAGS_V_INMD 8
#define TRMFLAGS_V_WRAP 9
#define TRMFLAGS_V_HARD 10

static char           ascii_bell = BEL;
static char           *getenv(),temp_str[MAX_STRLEN];
static BOOLEAN        *ctrl_c_ptr;
static int            takeback_flag = 0;
static KEY_CODE_RANGE takeback_buffer;
static char           output_buffer[max_out_buf_len];
static long           out_buf_len,out_buf_ndx;
static short          imag_x,imag_y,real_x,real_y;
static unsigned char  control_chars[32] = {
	0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
static unsigned char  terminators[32];
static char           hw_insert_mode,sw_insert_mode;
static char           termcap[1024],termcap_buffer[1024];
static struct         sgttyb sgb, sgb_save;
static struct         tchars tchar, tchar_save;
static char           *imag_row,**row_ptrs,*tmp_row,**tmp_ptrs,*spaces,
		      *backspaces,*linefeeds;

#if vax && unix
#define tt_clsc                 ttclsc
#define vdu_initterm            vduinitterm
#define vdu_movecurs            vdumovecurs
#define vdu_flush               vduflush
#define vdu_beep                vdubeep
#define vdu_cleareol            vducleareol
#define vdu_displaystr          vdudisplaystr
#define vdu_displaych           vdudisplaych
#define vdu_clearscr            vduclearscr
#define vdu_cleareos            vducleareos
#define vdu_redrawscr           vduredrawscr
#define vdu_scrollup            vduscrollup
#define vdu_deletelines         vdudeletelines
#define vdu_insertlines         vduinsertlines
#define vdu_insertchars         vduinsertchars
#define vdu_deletechars         vdudeletechars
#define vdu_displaycrlf         vdudisplaycrlf
#define vdu_take_back_key       vdutakebackkey
#define vdu_new_introducer      vdunewintroducer
#define vdu_resetterm           vduresetterm
#define vdu_get_key             vdugetkey
#define vdu_get_input           vdugetinput
#define vdu_get_text            vdugettext
#define vdu_insert_mode         vduinsertmode
#define vdu_keyboard_init       vdukeyboardinit
#define vdu_init                vduinit
#define vdu_free                vdufree
#endif

extern void  vdu_take_back_key(),vdu_flushbuf(),vdu_putstr();
extern char  *tgoto(),*tgetstr(),PC,*BC,*UP;
extern short ospeed;

/*******************************************************************************

			   TRMHND emulation routines

*******************************************************************************/

static char *bc,*change_scroll_region,*clear_display,*clear_line,*clear_screen;
static char *cursor_address,*delete_char,*delete_line,*down,*enter_insert_mode;
static char *enter_keypad_mode,*exit_insert_mode,*exit_keypad_mode,*home_cursor;
static char *initialize_terminal,*insert_char,*insert_line,*reverse_scroll,*up;
static char *initialize_termcap,*end_termcap;
static long tt_termheight,tt_termwidth,bs;
static unsigned char tt_capabilities[4];

tt_putchar(ch)
char ch;

{
    vdu_putstr(1,&ch);
}

int tt_setupterm(capabilities,width,height)
unsigned char *capabilities;
SCR_COL_RANGE *width;
SCR_ROW_RANGE *height;

{
    int  i;
    char *ptr;

#ifdef sun
    struct      winsize window_size;
#endif


    /* Assume it is a hardcopy device */
    setbit(capabilities,TRMFLAGS_V_HARD);
    setbit(tt_capabilities,TRMFLAGS_V_HARD);
    *width = tt_termwidth = 80;
    *height = tt_termheight = 4;
    if (isatty(0) == 0)
	return 0;
    ptr = termcap_buffer;
    if (tgetent(termcap,getenv("TERM")) != 1)
	return 1; /* don't know about this terminal, assume it's hardcopy */
    if (!tgetflag("hc")) clrbit(tt_capabilities,TRMFLAGS_V_HARD);

#ifdef sun
    ioctl(0, TIOCGWINSZ, &window_size);
    if (window_size.ws_row == 0) {
	if ((i = tgetnum("co")) != -1)
	    tt_termwidth = i;
	if ((i = tgetnum("li")) != -1)
	    tt_termheight = i;
    }
    else {
	tt_termwidth = window_size.ws_col;
	tt_termheight = window_size.ws_row;
    }
	ioctl(0,TIOCSETP, &sgb_save);
#else
    if ((i = tgetnum("co")) != -1)
	tt_termwidth = i;
    if ((i = tgetnum("li")) != -1)
	tt_termheight = i;
#endif
    if ((insert_line = tgetstr("al",&ptr)) != NULL) {
	setbit(tt_capabilities,TRMFLAGS_V_INLN);
	setbit(tt_capabilities,TRMFLAGS_V_SCDN);
    }
    if (tgetflag("am") && !tgetflag("xn"))
	setbit(tt_capabilities,TRMFLAGS_V_WRAP);
    if (!(bs = tgetflag("bs")))
	bc = tgetstr("bc",&ptr);
    if ((clear_display = tgetstr("cd",&ptr)) != NULL)
	setbit(tt_capabilities,TRMFLAGS_V_CLES);
    if ((clear_line = tgetstr("ce",&ptr)) != NULL)
	setbit(tt_capabilities,TRMFLAGS_V_CLEL);
    if ((clear_screen = tgetstr("cl",&ptr)) != NULL)
	setbit(tt_capabilities,TRMFLAGS_V_CLSC);
    if ((cursor_address = tgetstr("cm",&ptr)) == NULL)
	setbit(tt_capabilities,TRMFLAGS_V_HARD);
    if ((change_scroll_region = tgetstr("cs",&ptr)) != NULL) {
	setbit(tt_capabilities,TRMFLAGS_V_INLN);
	setbit(tt_capabilities,TRMFLAGS_V_DLLN);
	setbit(tt_capabilities,TRMFLAGS_V_SCDN);
    }
    if ((delete_char = tgetstr("dc",&ptr)) != NULL)
	setbit(tt_capabilities,TRMFLAGS_V_DLCH);
    if ((delete_line = tgetstr("dl",&ptr)) != NULL)
	setbit(tt_capabilities,TRMFLAGS_V_DLLN);
    down = tgetstr("do",&ptr);
    exit_insert_mode = tgetstr("ei",&ptr);
    home_cursor = tgetstr("ho",&ptr);
    if ((insert_char = tgetstr("ic",&ptr)) != NULL)
	setbit(tt_capabilities,TRMFLAGS_V_INCH);
    if ((enter_insert_mode = tgetstr("im",&ptr)) != NULL && *enter_insert_mode != NULL)
	setbit(tt_capabilities,TRMFLAGS_V_INMD);
    initialize_terminal = tgetstr("is",&ptr);
    initialize_termcap = tgetstr("ti",&ptr);
    end_termcap = tgetstr("te",&ptr);
    exit_keypad_mode = tgetstr("ke",&ptr);
    enter_keypad_mode = tgetstr("ks",&ptr);
    reverse_scroll = tgetstr("sr",&ptr);
    up = tgetstr("up",&ptr);
    for (i = 0;i < 4;i++)
	capabilities[i] = tt_capabilities[i];
    *width = tt_termwidth;
    *height = tt_termheight;
    return 1;
}

tt_putcursor(x,y)
int x,y;

{
    char *ptr;

    real_x = x;
    real_y = y;
    if (cursor_address != NULL)
	tputs(tgoto(cursor_address,x,y),1,tt_putchar);
    else { /* NO cursor addressing!!! */

    }
}

tt_upcursor(dist)
int dist;

{
    char *ptr;

    real_y -= dist;
    if (up != NULL)
	while (dist--)
	    tputs(up,1,tt_putchar);
    else
	tputs(tgoto(cursor_address,real_x,real_y),1,tt_putchar);
}

tt_clsc()

{
    real_x = real_y = 0;
    if (home_cursor != NULL)
	tputs(home_cursor,1,tt_putchar);
    tputs(clear_screen,1,tt_putchar);
}

tt_cles()

{
    tputs(clear_display,1,tt_putchar);
}

tt_clel()

{
    tputs(clear_line,1,tt_putchar);
}

tt_scrolldn()

{
    tt_inln(1);
}

tt_inln(n)
int n;

{
    real_x = 0;
    if (insert_line != NULL)
	while (n--)
	    tputs(insert_line,1,tt_putchar);
    else {
	if (real_y != 0) {
	    tputs(tgoto(change_scroll_region,tt_termheight-1,real_y),1,tt_putchar);
	    tputs(tgoto(cursor_address,real_x,real_y),1,tt_putchar);
	}
	while (n--)
	    tputs(reverse_scroll,1,tt_putchar);
	if (real_y != 0) {
	    tputs(tgoto(change_scroll_region,tt_termheight-1,0),1,tt_putchar);
	    real_x = real_y = 0;
	}
    }
}

tt_dlln(n)
int n;

{
    real_x = 0;
    if (delete_line != NULL)
	while (n--)
	    tputs(delete_line,1,tt_putchar);
    else {
	if (real_y != 0) {
	    tputs(tgoto(change_scroll_region,tt_termheight-1,real_y),1,tt_putchar);
	    tputs(tgoto(cursor_address,real_x,tt_termheight-1),1,tt_putchar);
	}
	while (n--)
	    tputs(down,1,tt_putchar);
	if (real_y != 0) {
	    tputs(tgoto(change_scroll_region,tt_termheight-1,0),1,tt_putchar);
	    real_x = real_y = 0;
	}
    }
}

tt_setinsmod(mode)
int mode;

{
    if (mode)
	tputs(enter_insert_mode,1,tt_putchar);
    else
	tputs(exit_insert_mode,1,tt_putchar);
}

tt_inch(n)
int n;

{
    while (n--)
	tputs(insert_char,1,tt_putchar);
}

tt_dlch(n)
int n;

{
    while (n--)
	tputs(delete_char,1,tt_putchar);
}

/******************************************************************************/

void vdu_drop_buf()

{
    out_buf_ndx = 0;
}

void vdu_flushbuf(wait)
int wait;

{
    if (out_buf_ndx) {
	fwrite(output_buffer,1,out_buf_ndx,stdout);
	fflush(stdout);
    }
    out_buf_ndx = 0;
}

void vdu_putstr(len,str)
int  len;
char *str;

{
    int i;

    if (out_buf_ndx+len > out_buf_len)
	vdu_flushbuf(1);
    if (out_buf_ndx+len > out_buf_len) {
	fwrite(str,1,len,stdout);
	fflush(stdout);
    } else {
	for (i = 0;i < len;i++)
	    output_buffer[out_buf_ndx+i] = *str++;
	out_buf_ndx += len;
    }
}

void vdu_trmfail(status)

{
    exit(status);
}

void vdu_putcurs(x,y)
int x,y;

{
    char *ptr;

    imag_x = x;
    imag_y = y;
    imag_row = row_ptrs[y];
    tt_putcursor(imag_x,imag_y);
}

void vdu_fixcurs()

{
    int dx,dy,upflag,bkflag;

    upflag = bkflag = 0;
    /* compute the vertical and horizontal differences */
    if ((dy = imag_y-real_y) < 0) {
	dy *= -2;
	upflag = 1;
    }
    if ((dx = imag_x-real_x) < 0) {
	dx *= -1;
	bkflag = 1;
    }
    if (dx+dy >= 4) /* if cheaper to cursor address then */
	tt_putcursor(imag_x,imag_y);
    else {          /* else move it cleverly! */
	if (dy)
	    if (upflag)
		tt_upcursor(dy/2);
	    else {
		vdu_putstr(dy,linefeeds);
		real_y = imag_y;
	    }
	if (dx) {
	    if (bkflag)
		vdu_putstr(dx,backspaces);
	    else
		vdu_putstr(dx,&imag_row[real_x]);
	    real_x = imag_x;
	}
    }
}

/*
procedure vdu_initterm{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_initterm()

{
    if (initialize_termcap) tputs(initialize_termcap,1,tt_putchar);
    if (initialize_terminal) tputs(initialize_terminal,1,tt_putchar);
    if (enter_keypad_mode) tputs(enter_keypad_mode,1,tt_putchar);
    if (exit_insert_mode) tputs(exit_insert_mode,1,tt_putchar);
    ioctl(0, TIOCGETP, &sgb_save);
    ioctl(0, TIOCGETP, &sgb);
    if (isclr(tt_capabilities,TRMFLAGS_V_HARD))
	sgb.sg_flags = ANYP|CBREAK|TANDEM;
    ioctl(0, TIOCSETN, &sgb);
    vdu_flushbuf(1);
}

/*
procedure vdu_resetterm{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_resetterm()

{
    if (end_termcap) tputs(end_termcap,1,tt_putchar);
    if (exit_keypad_mode) tputs(exit_keypad_mode,1,tt_putchar);
    if (exit_insert_mode) tputs(exit_insert_mode,1,tt_putchar);
    ioctl(0, TIOCSETN, &sgb_save);
    ioctl(0, TIOCSETC, &tchar_save);
    vdu_flushbuf(1);
}

/*
procedure vdu_movecurs {(
		x,
		y : scr_col_range)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_movecurs(x, y)
SCR_COL_RANGE x, y;
{
    imag_x = x-1;
    imag_y = y-1;
    imag_row = row_ptrs[imag_y];
}


/*
procedure vdu_flush {(
		wait : boolean)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_flush(wait)
int wait;
{
    vdu_fixcurs();
    vdu_flushbuf(wait);
}


/*
procedure vdu_beep{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_beep()

{
    vdu_putstr(1,&ascii_bell);
}

vdu_cntrlcatch()

{
    if (ctrl_c_ptr != NULL) *ctrl_c_ptr = 1;
    if (isclr(tt_capabilities,TRMFLAGS_V_HARD)) {
	vdu_drop_buf();
	vdu_beep();
	vdu_flushbuf(0);
    }
}

/*
procedure vdu_cleareol{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_cleareol()
{
    int  i_x;
    char *i_row;

    i_x = imag_x;
    i_row = imag_row;
    if (strspn(&i_row[i_x]," ") == strlen(&i_row[i_x]))
	return; /* nothing to erase */
    if (isset(tt_capabilities,TRMFLAGS_V_CLEL)) {
	bcopy(spaces,&i_row[i_x],tt_termwidth-i_x);
	i_row[tt_termwidth] = '\0';
	vdu_fixcurs();
	tt_clel();
    } else {
	vdu_stringdraw(tt_termwidth-i_x,spaces);
	imag_x = i_x;
    }
}

vdu_stringdraw(str_len,str)
int  str_len;
char *str;

{
    int  len,width,i_x;
    char *ptr,*i_row;

    i_x = imag_x;
    i_row = imag_row;
    width = tt_termwidth;
    len = str_len;
    if (i_x+len > width) len = width-i_x;
    ptr = str;
    while (len) {
	int  size,start_x;
	char *start_p;

	/* skip over any identical characters */
	while (i_row[i_x] == *ptr++) {
	    i_x++;
	    len--;
	    if (len == 0) {
		if (i_x == width) i_x--;
		imag_x = i_x;
		return;
	    }
	}
	start_p = ptr-1;
	start_x = i_x;
	i_x++;
	len--;
	/* scan the differing characters */
	while (len) {
	    if (i_row[i_x] == *ptr++) {
		ptr--;
		break;
	    }
	    i_x++;
	    len--;
	}
	/* update the erroneous area of the screen */
	imag_x = start_x;
	vdu_fixcurs();
	size = i_x-start_x;
	bcopy(start_p,&i_row[start_x],size);
	i_row[tt_termwidth] = '\0';
	imag_x = i_x;
	real_x = i_x;
	if (i_x == width) {
	    len = 0;
	    i_x--;
	    imag_x = i_x;
	    real_x = i_x;
	    if (isset(tt_capabilities,TRMFLAGS_V_WRAP)) /* bad news not over yet */
		if (imag_y == tt_termheight-1)
		    size--;
		else {
		    real_x = 0;
		    real_y++;
		}
	}
	vdu_putstr(size,start_p);
    }
}

/*
procedure vdu_displaystr {(
		strlen : scr_col_range;
	 var    str    : char;
		opts   : integer)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_displaystr(str_len, str, opts)
SCR_COL_RANGE str_len;
char          *str;
long          opts;
{
    int  i,hitmargin,leng;
    char *pnew,*pscr;

    if (imag_x+str_len >= tt_termwidth) {
	leng = tt_termwidth-imag_x;
	hitmargin = 1;
    } else {
	leng = str_len;
	hitmargin = 0;
    }
    pscr = &imag_row[imag_x];
    /* take a shortcut if rest of line all blanks */
    if (strspn(pscr," ") == strlen(pscr)) {
	vdu_stringdraw(leng,str);
	return;
    }
    pnew = str;
    /* skip stuff that doesn't need fixing at the front */
    while (leng)
	if (*pnew++ != *pscr++) {
	   --pnew;
	   break;
	} else
	   leng--;
    /* if nothing left to do then stop */
    if (leng <= 0 && !(out_m_cleareol & opts)) {
	imag_x = imag_x+str_len;
	if (imag_x >= tt_termwidth) imag_x = tt_termwidth-1;
	return;
    }
    imag_x += pnew-str;
    vdu_stringdraw(leng,pnew);
    if ((out_m_cleareol & opts) && !hitmargin)
	vdu_cleareol();
}

/*
procedure vdu_displaych {(
		ch : char)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_displaych(ch)
char ch;
{
    vdu_displaystr(1,&ch,0);
}

/*
procedure vdu_clearscr{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_clearscr()
{
    int i;

    vdu_drop_buf();
    if (isclr(tt_capabilities,TRMFLAGS_V_HARD)) {
	for (i = 0;i < tt_termheight;i++) {
	    bcopy(spaces,row_ptrs[i],tt_termwidth);
	    row_ptrs[i][tt_termwidth] = '\0';
	}
	if (isset(tt_capabilities,TRMFLAGS_V_CLSC))
	    tt_clsc();
	else {
	    vdu_putstr(2*tt_termheight,linefeeds); /* Whatawaytogo! */
	    vdu_putcurs(0,0);
	}
	imag_x = imag_y = 0;
	imag_row = row_ptrs[0];
    }
}


/*
procedure vdu_cleareos{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_cleareos()
{
    int i,i_x,i_y;

    i_x = imag_x;
    i_y = imag_y;
    if (isset(tt_capabilities,TRMFLAGS_V_CLES)) {
	vdu_fixcurs();
	tt_cles();
	bcopy(spaces,&row_ptrs[i_y][i_x],tt_termwidth-i_x);
	row_ptrs[i_y][tt_termwidth] = '\0';
	for (i = i_y+1;i < tt_termheight;i++) {
	    bcopy(spaces,row_ptrs[i],tt_termwidth);
	    row_ptrs[i][tt_termwidth] = '\0';
	}
    } else {
	vdu_cleareol();
	for (i = i_y+1;i < tt_termheight;i++) {
	    imag_x = 0;
	    imag_y = i;
	    imag_row = row_ptrs[i];
	    vdu_cleareol();
	}
	imag_x = i_x;
	imag_y = i_y;
	imag_row = row_ptrs[i_y];
    }
}

/*
procedure vdu_redrawscr{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_redrawscr()
{
    char *ptr,*save;
    int  i,old_x,old_y;

    vdu_drop_buf();
    old_x = imag_x;
    old_y = imag_y;
    save = (char *)malloc(tt_termheight*tt_termwidth);
    ptr = save;
    for (i = 0;i < tt_termheight;i++) {
	bcopy(row_ptrs[i],ptr,tt_termwidth);
	row_ptrs[i][0] = '\0';
	ptr += tt_termwidth;
    }
    vdu_clearscr();
    ptr = save;
    for (i = 0;i < tt_termheight;i++) {
	imag_x = 0;
	imag_y = i;
	imag_row = row_ptrs[i];
	vdu_displaystr(tt_termwidth,ptr,0);
	ptr += tt_termwidth;
    }
    free(save);
    vdu_putcurs(old_x, old_y);
    vdu_flush(1);
}

/*
procedure vdu_scrollup {(
		n : integer)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_scrollup(n)
int n;
{
    int i;

    if (n >= tt_termheight) {
	vdu_clearscr();
	return;
    }
    imag_y = tt_termheight-1;
    imag_row = row_ptrs[tt_termheight-1];
    vdu_fixcurs();
    vdu_putstr(n,linefeeds);
    for (i = 0;i < n;i++)
	tmp_ptrs[i] = row_ptrs[i];
    for (i = 0;i < tt_termheight-n;i++)
	row_ptrs[i] = row_ptrs[n+i];
    for (i = 0;i < n;i++)
	row_ptrs[tt_termheight-n+i] = tmp_ptrs[i];
    imag_row = row_ptrs[tt_termheight-1];
    for (i = n-1;i >= 0;i--) {
	bcopy(spaces,tmp_ptrs[i],tt_termwidth);
	tmp_ptrs[i][tt_termwidth] = '\0';
    }
    if (isset(tt_capabilities,TRMFLAGS_V_WRAP)) {
	int sx,sy;

	sx = imag_x;
	sy = imag_y;
	for (i = tt_termheight-1-n;i <= tt_termheight-2;i++)
	    if (row_ptrs[i][tt_termwidth-1] != ' ') {
		imag_x = tt_termwidth-1;
		imag_y = i;
		imag_row = row_ptrs[i];
		vdu_fixcurs();
		vdu_putstr(1,&row_ptrs[i][tt_termwidth-1]);
		real_x = 0;
		real_y++;
	    }
	imag_x = sx;
	imag_y = sy;
	imag_row = row_ptrs[sy];
    }
}

/*
procedure vdu_deletelines {(
		n         : integer;
		clear_eos : boolean)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_deletelines(n, clear_eos)
int n, clear_eos;
{
    int i,i_y;

    i_y = imag_y;
    imag_x = 0;
    if (n >= tt_termheight-imag_y) {
	vdu_cleareos();
	return;
    }
    if (imag_y == 0) {
	vdu_scrollup(n);
	return;
    }
    if (isclr(tt_capabilities,TRMFLAGS_V_DLLN) && imag_y <= tt_termheight/3) {
	for (i = imag_y-1;i >= 0;i--) {
	    imag_x = 0;
	    imag_y = i+n;
	    imag_row = row_ptrs[i+n];
	    vdu_displaystr(tt_termwidth,row_ptrs[i],0);
	}
	vdu_scrollup(n);
	imag_y = i_y;
	imag_row = row_ptrs[imag_y];
	return;
    }
    if (isset(tt_capabilities,TRMFLAGS_V_DLLN)) { /* use hardware to delete area */
	vdu_fixcurs();
	tt_dlln(n);
	for (i = 0;i < n;i++)
	    tmp_ptrs[i] = row_ptrs[i+i_y];
	for (i = 0;i < tt_termheight-i_y-n;i++)
	    row_ptrs[i+i_y] = row_ptrs[i+i_y+n];
	for (i = 0;i < n;i++)
	    row_ptrs[i+tt_termheight-n] = tmp_ptrs[i];
	for (i = n-1;i >= 0;i--) {
	    bcopy(spaces,tmp_ptrs[i],tt_termwidth);
	    tmp_ptrs[i][tt_termwidth] = '\0';
	}
	imag_row = row_ptrs[i_y];
    } else { /* have to delete by hand */
	for (i = i_y; i <= tt_termheight-1-n;i++) {
	    imag_x = 0;
	    imag_y = i;
	    imag_row = row_ptrs[i];
	    vdu_displaystr(tt_termwidth,row_ptrs[i+n],0);
	}
	if (clear_eos) {
	    imag_x = 0;
	    imag_y = tt_termheight-n;
	    imag_row = row_ptrs[tt_termheight-n];
	    vdu_cleareos();
	}
	imag_x = 0;
	imag_y = i_y;
	imag_row = row_ptrs[i_y];
    }
}

/*
procedure vdu_insertlines {(
		n     : integer)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_insertlines(n)
int n;
{
    int i,i_y;

    i_y = imag_y;
    imag_x = 0;
    if (n >= tt_termheight-i_y) {
	vdu_cleareos();
	return;
    }
    if (isset(tt_capabilities,TRMFLAGS_V_INLN)) {
	vdu_fixcurs();
	for (i = 0;i < n;i++)
	    tmp_ptrs[i] = row_ptrs[i+tt_termheight-n];
	for (i = tt_termheight-i_y-n-1;i >= 0;i--)
	    row_ptrs[i+i_y+n] = row_ptrs[i+i_y];
	for (i = 0;i < n;i++)
	    row_ptrs[i+i_y] = tmp_ptrs[i];
	imag_row = row_ptrs[i_y];
	tt_inln(n);
	for (i = 0;i < n;i++) {
	    bcopy(spaces,tmp_ptrs[i],tt_termwidth);
	    tmp_ptrs[i][tt_termwidth] = '\0';
	}
	return;
    } else if (   (isset(tt_capabilities,TRMFLAGS_V_SCDN))
	       && i_y < tt_termheight/3 && i_y+n < tt_termheight) {
	imag_y = 0;
	imag_row = row_ptrs[0];
	vdu_fixcurs();
	tt_scrolldn(n);
	for (i = 0;i < n;i++)
	    tmp_ptrs[i] = row_ptrs[i+tt_termheight-n];
	for (i = 0;i < tt_termheight-i_y-n;i++)
	    row_ptrs[i+i_y+n] = row_ptrs[i+i_y];
	for (i = 0;i < n;i++)
	    row_ptrs[i+i_y] = tmp_ptrs[i];
	imag_row = row_ptrs[i_y];
	for (i = 0;i < n;i++) {
	    bcopy(spaces,tmp_ptrs[i],tt_termwidth);
	    tmp_ptrs[i][tt_termwidth] = '\0';
	}
	for (i = 0;i < i_y;i++) {
	    imag_x = 0;
	    imag_y = i;
	    imag_row = row_ptrs[i];
	    vdu_displaystr(tt_termwidth,row_ptrs[i+n],1);
	}
    } else {
	for (i = tt_termheight-1;i <= i_y+n;i++) {
	    imag_x = 0;
	    imag_y = i;
	    imag_row = row_ptrs[i];
	    vdu_displaystr(tt_termwidth,row_ptrs[i-n],1);
	}
    }
    for (i = i_y+n-1;i <= i_y;i++) {
	imag_x = 0;
	imag_y = i;
	imag_row = row_ptrs[i];
	vdu_cleareol();
    }
    imag_x = 0;
    imag_y = i_y;
    imag_row = row_ptrs[i_y];
}

/*
procedure vdu_insertchars {(
		n : scr_col_range)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_insertchars(n)
SCR_COL_RANGE n;
{
    int  count,i,j,k,old_x;
    char *ptr;

    k = tt_termwidth-1;
    if (n > tt_termwidth-imag_x) n = tt_termwidth-imag_x;
    if (n <= 0) return;
    if (isset(tt_capabilities,TRMFLAGS_V_INCH)) {
	count = 0;
	ptr = &imag_row[imag_x];
	for (i = k-imag_x-n-1;i >= 0;i--)
	    if (*ptr++ != ' ') count++;
	if (2*count > n*strlen(insert_char)) {
	    vdu_fixcurs();
	    tt_inch(n);
	    for (i = tt_termwidth-n-1;i >= imag_x;i--)
		imag_row[i+n] = imag_row[i];
	    bcopy(spaces,&imag_row[imag_x],n);
	    return;
	}
    }
    old_x = imag_x;
    bcopy(spaces,tmp_row,n);
    bcopy(&imag_row[imag_x],&tmp_row[n],tt_termwidth-imag_x-n);
    vdu_displaystr(tt_termwidth-imag_x,tmp_row,0);
    imag_x = old_x;
}

/*
procedure vdu_deletechars {(
		n : scr_col_range)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_deletechars(n)
SCR_COL_RANGE n;
{
    int  i,j,k,count,old_x;
    char *ptr;

    for (k = tt_termwidth-1;k >= imag_x;k--)
	if (imag_row[k] != ' ') break;
    if (n > k+1-imag_x) n = k+1-imag_x;
    if (n <= 0) return;
    if (isset(tt_capabilities,TRMFLAGS_V_DLCH)) {
	count = 0;
	ptr = &imag_row[imag_x+n];
	for (i = k-(imag_x+n);i >= 0;i--)
	    if (*ptr++ != ' ') count++;
	if (2*count > n*strlen(delete_char)) {
	    vdu_fixcurs();
	    tt_dlch(n);
	    for (i = imag_x;i < tt_termwidth-n;i++)
		imag_row[i] = imag_row[i+n];
	    bcopy(spaces,&imag_row[tt_termwidth-n],n);
	    return;
	}
    }
    old_x = imag_x;
    bcopy(&imag_row[imag_x+n],tmp_row,tt_termwidth-(imag_x+n));
    vdu_displaystr(tt_termwidth-(imag_x+n),tmp_row,out_m_cleareol);
    imag_x = old_x;
}

/*
procedure vdu_displaycrlf{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_displaycrlf()
{
    if (imag_y == tt_termheight-1)
	vdu_scrollup(1);
    else {
	imag_y++;
	imag_row = row_ptrs[imag_y];
    }
    imag_x = 0;
}

/*
procedure vdu_take_back_key {(
		key : key_code_range)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_take_back_key(key)
KEY_CODE_RANGE key;
{
    takeback_flag = 1;
    takeback_buffer = key;
}

/*
procedure vdu_new_introducer {(
		key : key_code_range)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_new_introducer(key)
KEY_CODE_RANGE key;
{
    int i;

    for (i = 0; i < sizeof(control_chars); i++)
	terminators[i] = control_chars[i];
    if (key > 0) setbit(terminators, key);
    cmd_introducer = key;
}

/*
function vdu_get_key {
	: key_code_range};
  {umax:nonpascal}
  {mach:nonpascal}

*/
KEY_CODE_RANGE vdu_get_key()
{
    char  ch;
    long  ptr;
    KEY_CODE_RANGE key;

    if (takeback_flag) {
	key = takeback_buffer;
	takeback_flag = 0;
    } else {
	vdu_flush(1);
	if (ctrl_c_ptr && *ctrl_c_ptr) return tchar_save.t_intrc;
	/*
	 * Dont let interrupts get through during reads as if we are
	 * interrupted we certainly dont want to continue to read!
	 * We do this by disable the users way of signalling them!
	 */
	ioctl(0, TIOCSETC, &tchar);
	fread(&ch,1,1,stdin);
	ioctl(0, TIOCSETC, &tchar_save);
	if (ch == tchar_save.t_intrc) {
	    if (ctrl_c_ptr) *ctrl_c_ptr = 1;
	    return 0;
	}
	if (isset(introducers,ch)) {
	    ptr = 0;
	    do {
		parse_table[parse_table[ptr].index].ch = ch;
		while (parse_table[++ptr].ch != ch);
		key = parse_table[ptr].key_code;
		ptr = parse_table[ptr].index;
		if (ptr) {
		    ioctl(0, TIOCSETC, &tchar);
		    fread(&ch,1,1,stdin);
		    ioctl(0, TIOCSETC, &tchar_save);
		    if (ch == tchar_save.t_intrc) {
			if (ctrl_c_ptr) *ctrl_c_ptr = 1;
			return 0;
		    }
		}
	    } while (ptr != 0);
	} else
	    key = ch;
    }
    return key;
}


/*
procedure vdu_get_input {(
	var     prompt     : str_object;
		prompt_len : strlen_range;
	var     get        : str_object;
		get_len    : strlen_range;
	var     outlen     : strlen_range)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_get_input(prompt, prompt_len, get, get_len, outlen)
char         *prompt, *get;
STRLEN_RANGE prompt_len, get_len, *outlen;
{
    char  ch;
    KEY_CODE_RANGE key;

    vdu_displaystr(prompt_len, prompt, out_m_cleareol);
    *outlen = 0;
    if (tt_termwidth-imag_x < get_len)
	get_len = tt_termwidth-imag_x;
    vdu_flush(1);
    while (get_len--) {
	key = vdu_get_key();
	if (ctrl_c_ptr && *ctrl_c_ptr) return;
	if (key == CR || key == LF)
	    return;
	if (*outlen > 0 && key == DEL) {
	    ++get_len;
	    --*outlen;
	    imag_x--;
	    vdu_displaystr(1,spaces,0);
	    imag_x--;
	    continue;
	} else if (key < 0 || isset(control_chars, key)) {
	    vdu_beep();
	    ++get_len;
	    continue;
	}
	vdu_displaych((char)key);
	get[(*outlen)++] = (char)key;
    }
}

/*
procedure vdu_insert_mode {(
		turn_on : boolean)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_insert_mode(turn_on)
int turn_on;
{
    if (isset(tt_capabilities,TRMFLAGS_V_INMD))
	hw_insert_mode = turn_on;
    else
	sw_insert_mode = turn_on;
}

/* VDU_GET_TEXT provides the echoed reading of text, in either overtype or
 * insert mode. The caller provides a buffer which is filled, and a variable to
 * receive the number of characters read into his buffer.
 */

/*
procedure vdu_get_text {(
		str_len : integer;
	var     str     : str_object;
	var     outlen  : strlen_range)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_get_text(str_len, str, outlen)
char         *str;
int          str_len;
STRLEN_RANGE *outlen;
{
    int y, x;
    KEY_CODE_RANGE key;

    *outlen = 0;
    if (tt_termwidth - imag_x < str_len)
	str_len = tt_termwidth - imag_x;
    while (str_len--) {
	key = vdu_get_key();
	if (ctrl_c_ptr && *ctrl_c_ptr) return;
	if (key < 0 || isset(terminators, key)) {
	    vdu_take_back_key(key);
	    return;
	}
	if (hw_insert_mode || sw_insert_mode)
	    vdu_insertchars(1);
	vdu_displaych((char)key);
	str[(*outlen)++] = (char)key;
    }
}

/*
procedure vdu_keyboard_init {(
	var     nr_key_names      : key_names_range;
	var     key_name_list_ptr : key_name_array_ptr;
	var     key_introducers   : accept_set_type;
	var     terminal_info     : terminal_info_type)};
  {umax:nonpascal}
  {mach:nonpascal}

*/

void vdu_keyboard_init(nr_key_names,key_name_list_ptr,key_introducers,
		       terminal_info)
KEY_NAMES_RANGE    *nr_key_names;
KEY_NAME_RECORD    **key_name_list_ptr;
CHAR               *key_introducers;
TERMINAL_INFO_TYPE *terminal_info;

{
#   define define_key(i,name,code) \
	bcopy(name,key_name_list[i].key_name,KEY_NAME_LEN); \
	key_name_list[i].key_code = code

    long  i;
    int   termdesc;
    char  *termdesc_fname,*term,file_name[1024];
    unsigned short length,number;
    struct stat stat_buffer;

    *nr_key_names = 0;
    *key_name_list_ptr = NULL;
    parse_table = NULL;
    for (i = 0;i < (ORD_MAXCHAR+1)/8;i++) {
	key_introducers[i] = 0;
	introducers[i] = 0;
    }
    if ((key_name_list = (KEY_NAME_RECORD*)calloc(33,sizeof(KEY_NAME_RECORD))) == NULL) {
	screen_unix_message("Dynamic Memory Exceeded");
	return;
    }
    *key_name_list_ptr = key_name_list;
    *nr_key_names = 32;
    define_key( 1,"CONTROL-@                               ", 0);
    define_key( 2,"CONTROL-A                               ", 1);
    define_key( 3,"CONTROL-B                               ", 2);
    define_key( 4,"CONTROL-C                               ", 3);
    define_key( 5,"CONTROL-D                               ", 4);
    define_key( 6,"CONTROL-E                               ", 5);
    define_key( 7,"CONTROL-F                               ", 6);
    define_key( 8,"CONTROL-G                               ", 7);
    define_key( 9,"CONTROL-H                               ", 8);
    define_key(10,"CONTROL-I                               ", 9);
    define_key(11,"CONTROL-J                               ",10);
    define_key(12,"CONTROL-K                               ",11);
    define_key(13,"CONTROL-L                               ",12);
    define_key(14,"CONTROL-M                               ",13);
    define_key(15,"CONTROL-N                               ",14);
    define_key(16,"CONTROL-O                               ",15);
    define_key(17,"CONTROL-P                               ",16);
    define_key(18,"CONTROL-Q                               ",17);
    define_key(19,"CONTROL-R                               ",18);
    define_key(20,"CONTROL-S                               ",19);
    define_key(21,"CONTROL-T                               ",20);
    define_key(22,"CONTROL-U                               ",21);
    define_key(23,"CONTROL-V                               ",22);
    define_key(24,"CONTROL-W                               ",23);
    define_key(25,"CONTROL-X                               ",24);
    define_key(26,"CONTROL-Y                               ",25);
    define_key(27,"CONTROL-Z                               ",26);
    define_key(28,"CONTROL-[                               ",27);
    define_key(29,"CONTROL-\\                               ",28);
    define_key(30,"CONTROL-]                               ",29);
    define_key(31,"CONTROL-^                               ",30);
    define_key(32,"CONTROL-_                               ",31);
    *nr_key_names = 32;
    if ((termdesc_fname = getenv("TERMDESC")) != NULL) {
	if (stat(termdesc_fname,&stat_buffer) != 0) {
	    screen_unix_message("Error in value of TERMDESC");
	    return;
	}
	if ((stat_buffer.st_mode & S_IFMT) == S_IFDIR)
	    sprintf(file_name,"%s/%s",termdesc_fname,getenv("TERM"));
	else
	    strcpy(file_name,termdesc_fname);
    } else
	sprintf(file_name,"/usr/local/lib/termdesc/%s",getenv("TERM"));
    if ((termdesc = open(file_name,O_RDONLY)) < 0) {
	screen_unix_message("Cannot open keys file");
	return;
    }
    if (read(termdesc,&length,sizeof(short)) <= 0
     || length != sizeof(KEY_NAME_RECORD)) {
	screen_unix_message("Invalid Key Definition File");
	close(termdesc);
	return;
    }
    if (read(termdesc,&number,sizeof(short)) <= 0) {
	screen_unix_message("Invalid Key Definition File");
	close(termdesc);
	return;
    }
    *nr_key_names += number;
    if ((key_name_list = (KEY_NAME_RECORD*)realloc(key_name_list,(*nr_key_names+1)*length)) == NULL) {
	screen_unix_message("Dynamic Memory Exceeded");
	close(termdesc);
	return;
    }
    *key_name_list_ptr = key_name_list;
    if (read(termdesc,&key_name_list[33],number*length) <= 0
     || read(termdesc,&length,sizeof(short)) <= 0
     || length != sizeof(PARSE_TABLE_RECORD)) {
	screen_unix_message("Invalid Key Definition File");
	close(termdesc);
	return;
    }
    if (read(termdesc,&number,sizeof(short)) <= 0) {
	screen_unix_message("Invalid Key Definition File");
	close(termdesc);
	return;
    }
    if ((parse_table = (PARSE_TABLE_RECORD*)calloc(number,length)) == NULL) {
	screen_unix_message("Dynamic Memory Exceeded");
	close(termdesc);
	return;
    }
    if (read(termdesc,parse_table,number*length) <= 0
     || read(termdesc,&length,sizeof(short)) <= 0
     || read(termdesc,introducers,length) <= 0) {
	screen_unix_message("Invalid Key Definition File");
	close(termdesc);
	return;
    }
    for (i = 0;i < (ORD_MAXCHAR+1)/8;i++)
	key_introducers[i] = introducers[i];
    if (read(termdesc,&length,sizeof(short)) <= 0) {
	screen_unix_message("Invalid Key Definition File");
	close(termdesc);
	return;
    }
    if ((terminal_info->name = (char *)calloc(1,length)) == NULL) {
	screen_unix_message("Dynamic Memory Exceeded");
	close(termdesc);
	return;
    }
    if (read(termdesc,terminal_info->name,length) <= 0) {
	screen_unix_message("Invalid Key Definition File");
	close(termdesc);
	return;
    }
    terminal_info->namelen = length;
    close(termdesc);
}


/*
function vdu_init {(
		outbuflen     : integer;
	var     capabilities  : terminal_capabilities;
	var     terminal_info : terminal_info_type;
	var     ctrl_c_flag   : boolean)
	: boolean};
  {umax:nonpascal}
  {mach:nonpascal}

*/
int vdu_init(outbuflen, capabilities, terminal_info, ctrl_c_flag)
unsigned long      outbuflen;
unsigned char      *capabilities;
TERMINAL_INFO_TYPE *terminal_info;
BOOLEAN            *ctrl_c_flag;
{
    SCR_COL_RANGE w, *width = &w;
    SCR_ROW_RANGE h, *height = &h;
    int  i;
    void unix_suspend();

    out_buf_len = max_out_buf_len;
    ioctl(0, TIOCGETP, &sgb_save);
    ioctl(0, TIOCGETC, &tchar_save);
    ioctl(0, TIOCGETP, &sgb);
    ioctl(0, TIOCGETC, &tchar);
    if (!tt_setupterm(capabilities,width,height))
	return 0;
    terminal_info->width = *width;
    terminal_info->height = *height;
    vdu_initterm();
    /* alter tchar so we can protect reads from interrupts */
    tchar.t_intrc = -1;
    signal(SIGINT, vdu_cntrlcatch);
    signal(SIGTSTP, unix_suspend);
    ospeed = sgb.sg_ospeed;
    terminal_info->speed = ospeed;
    *ctrl_c_flag = 0;
    sw_insert_mode = 0;
    hw_insert_mode = 0;
    cmd_introducer = 0;
    row_ptrs = NULL;
    tmp_ptrs = NULL;
    imag_row = NULL;
    tmp_row = NULL;
    real_x = real_y = -10;
    imag_x = imag_y = 0;
    ctrl_c_ptr = NULL;
    spaces = (char *)malloc(tt_termwidth);
    backspaces = (char *)malloc(tt_termwidth);
    linefeeds = (char *)malloc(tt_termwidth);
    for (i = 0;i < tt_termwidth;i++) {
	spaces[i] = ' ';
	backspaces[i] = BS;
	linefeeds[i] = LF;
    }
    if (isclr(tt_capabilities,TRMFLAGS_V_HARD)) {
	row_ptrs = (char **)malloc(4*tt_termheight);
	tmp_ptrs = (char **)malloc(4*tt_termheight);
	for (i = 0;i < tt_termheight;i++) {
	    row_ptrs[i] = (char *)malloc(tt_termwidth+1);
	    row_ptrs[i][0] = '\0';
	}
	tmp_row = (char *)malloc(tt_termwidth+1);
	vdu_flush(1);
	vdu_clearscr();
	vdu_flush(1);
    }
    ctrl_c_ptr = ctrl_c_flag;
    return 1;
}


/*
procedure vdu_free{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void vdu_free()
{
    int i;

    signal(SIGINT, SIG_IGN);
    if (isclr(tt_capabilities,TRMFLAGS_V_HARD)) {
	vdu_putcurs(0,tt_termheight-1);
    }
    vdu_resetterm();
    if (tmp_row) free(tmp_row);
    if (row_ptrs) {
	for (i = 0;i < tt_termheight;i++)
	    if (row_ptrs[i]) free(row_ptrs[i]);
	free(row_ptrs);
    }
    if (tmp_ptrs) free(tmp_ptrs);
    fputc('\n',stdout);
}

