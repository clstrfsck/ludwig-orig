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

/*
 * Name:        UNIX
 *
 * Description: Provide low level interface outines to Unix system.
 *
 * Revision History:
 * 4-001 Ludwig V4.0 release.                                 7-Apr-1987
 * 4-002 Jeff Blows                                           5-May-1987
 *       In hsearch: remove c, change type of i from unsigned to int.
 *       In hash: change type of i and j from unsigned to int.
 * 4-003 Jeff Blows                                           7-May-1987
 *       Added timed_read function.
 * 4-004 Kelvin B. Nicolle                                   23-Sep-1988
 *       In cvt_int_str: in a BSD environment, sprintf returns the
 *       address of the string, not the number of characters in the
 *       string.
 * 4-005 John Warburton                                       6-Apr-1989
 *       In unix_suspend: replaced vdu_clearscr by tt_clsc, and vdu_initterm
 *       with vdu_redrawscr. removed all screen_fixup 's
 * 4-006 Jeff Blows                                          19-Jun-1989
 *       Rearrange unix_suspend so that the screen looks better on returning.
 *
 */

#include <stdio.h>
#include <signal.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/times.h>

#ifdef sun
#include <sys/time.h>
#include <sys/uio.h>
#endif


#define MAX_K_STRLEN    400
#define FILE_NAME_LEN   252
#define NAME_LEN        31

#if vax && unix
#define cvt_int_str             cvtintstr
#define cvt_str_int             cvtstrint
#define get_environment         getenvironment
#define init_signals            initsignals
#define exit_handler            exithandler
#define unix_suspend            unixsuspend
#define unix_shell              unixshell
#define screen_fixup            screenfixup
#define screen_redraw           screenredraw
#define vdu_clearscr            vduclearscr
#define vdu_resetterm           vduresetterm
#define vdu_flush               vduflush
#define vdu_initterm            vduinitterm
#define vdu_redrawscr           vduredrawscr
#define tt_clsc                 ttclsc
#define prog_windup             progwindup
#endif

/*
function malloc {(
		size : integer)
	: str_ptr};
  {umax:nonpascal}
  {mach:nonpascal}

procedure free {(
		ptr : str_ptr)};
  {umax:nonpascal}
  {mach:nonpascal}

procedure exit {(
		status : integer)};
  {umax:nonpascal}
  {mach:nonpascal}

*/

/*
function cvt_int_str {(
		num : integer;
	var     str : str_object;
		width : scr_col_range)
	: boolean};
  {umax:nonpascal}
  {mach:nonpascal}

*/
int cvt_int_str(num, str, width)
int num, width;
char *str;
{
    sprintf(str, "%*d", width, num);
    return strlen(str) > 0;
}

/*
function cvt_str_int {(
	var     num : integer;
	var     str : str_object)
	: boolean};
  {umax:nonpascal}
  {mach:nonpascal}

*/
int cvt_str_int(num, str)
int  *num;
char *str;
{
    return sscanf(str,"%d",num) == 1;
}

/*
function get_environment {(
	var     environ : name_str;
	var     res_len : strlen_range;
	var     result  : str_object)
	: boolean};
  {umax:nonpascal}
  {mach:nonpascal}

*/
int get_environment(env,reslen,result)
char  *env,*result;
short *reslen;

{
	char *p,*q,*getenv();
	int  i;

	for (i = 0,p = env;i < NAME_LEN && *p != ' ';p++,i++)
		continue;
	*p = '\0';
	if ((q = getenv(env)) != NULL) {
		strcpy(result,q);
		*reslen = strlen(q);
		*p = ' ';
		return 1;
	} else {
		*reslen = 0;
		*p = ' ';
		return 0;
	}
}

/*
procedure init_signals{};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void init_signals()

{
    void exit_handler();
    long unix_suspend();

    signal(SIGHUP, exit_handler);
    signal(SIGQUIT, exit_handler);
    signal(SIGILL, exit_handler);
    signal(SIGTRAP, exit_handler);
    signal(SIGIOT, exit_handler);
    signal(SIGEMT, exit_handler);
    signal(SIGFPE, exit_handler);
    signal(SIGBUS, exit_handler);
    signal(SIGSEGV, exit_handler);
    signal(SIGALRM, SIG_IGN);
    signal(SIGTERM, exit_handler);
    signal(SIGURG, SIG_IGN);
    signal(SIGTSTP, unix_suspend);
    signal(SIGCONT, SIG_IGN);
}

/*
procedure exit_handler {(
		sig : integer)};
  {umax:nonpascal}
  {mach:nonpascal}

*/
void exit_handler(sig)
int sig;
{
    void prog_windup();

    fflush(stdout);
    prog_windup(sig == SIGHUP);
    if (sig == SIGHUP) {
	signal(sig,SIG_DFL);
	kill(0,sig);
	return;
    }
    fflush(stdout);
    if (sig != 0) {
	/* if it was signalled then abort now!! */
	printf("Ludwig aborted due to signal : ");
	fflush(stdout);
	signal(sig,SIG_DFL);
	kill(0,sig);
    }
}

/*
function unix_suspend {
	: boolean};
  {umax:nonpascal}
  {mach:nonpascal}

*/
unix_suspend()

{
    tt_clsc();
    vdu_resetterm();
    sigsetmask(0);
    signal(SIGTSTP, SIG_DFL);
    if (kill(0, SIGTSTP) != 0)
	perror("kill");
    /* resumed again! */
    signal(SIGTSTP, unix_suspend);
    tt_clsc();
    vdu_initterm();
    vdu_redrawscr();
    return 1;
}

/*
function unix_shell {
	: boolean};
  {umax:nonpascal}
  {mach:nonpascal}

*/
unix_shell()

{
    char *shell, *getenv();
    int (*interrupt)(), (*quit)(), (*term)();
    int status, pid;

    if ((pid = fork()) == -1)
       return 0;
    vdu_clearscr();
    vdu_resetterm();
    vdu_flush(1);
    if (pid == 0) {
	if ((shell = getenv("SHELL")) == NULL)
	    shell = "/bin/sh";
	execlp(shell,shell,0);
	/* something has gone wrong! */
	exit(1);
    }
    interrupt = signal(SIGINT, SIG_IGN);
    quit = signal(SIGQUIT, SIG_IGN);
    term = signal(SIGTERM, SIG_IGN);
    do {
	status = wait(0);
    } while (status != pid && status != -1);
    signal(SIGINT, interrupt);
    signal(SIGQUIT, quit);
    signal(SIGTERM, term);
    vdu_initterm();
    screen_redraw();
    vdu_flush(1);
    return status != -1;
}

#ifdef sun

int timed_read(filedes, buffer, len, timeout, end_ch, ret_len)
/*
 *      Function will read a string from filedes and perform a timeout
 *      between each character.
 *
 *      Parameters -
 *                      filedes - file descriptor as used by read(2).
 *                      buffer  - pointer to a place to store the string.
 *                      len     - length of buffer.
 *                      timeout - pointer to a timeval structure.
 *                      end_ch  - single character to consider as end of string.
 *                      ret_len - length of string read in.
 *
 *      Returns -
 *               0 For success.
 *              -1 For a timeout.
 */

char buffer[];
int filedes, len, *ret_len;
struct timeval *timeout;
char end_ch;

{
	int     tab_size, timedout, i, readmask, count;

	i = 0;
	tab_size = getdtablesize();
	timedout = 0;
	readmask = 1 << filedes;
	while (timedout == 0) {
		if (select(tab_size, &readmask, 0, 0, timeout) > 0) {
			count = read(filedes, &buffer[i], 1);
			if ((buffer[i] == end_ch) || (++i > len)) {
				*ret_len = i;
				return(0);
			}
		}
		else
			timedout =  1;
	}
	*ret_len = i;
	return(-1);
}

#endif

#ifdef NOSYSV

/*
 * These System V routines are only called from C so we supply them here
 * without a Pascal type declaration for vanilla BSD4.2 that don't have them.
 *
 */

typedef struct entry { char *key, *data; } ENTRY;
typedef enum { FIND, ENTER } ACTION;

ENTRY *htable;
unsigned M,N;

#define K(n)    ((n)%M)

unsigned hash(key)
char *key;

{
    int i,j;
    char     *s;

    i = 0;
    for (j = 10,s = key;j > 0 && *s;j = j-3,s++)
	i += j*(*s);
    return i;
}

ENTRY *hsearch(item,action)
ENTRY  item;
ACTION action;

{
    int i;

    i = K(hash(item.key));
    while (htable[i].key != NULL) {
	if (strcmp(htable[i].key,item.key) == 0)
	    return &htable[i];
	else
	    if (--i < 0) i += M;
    }
    if (action == ENTER) {
	if (N == M-1)
	    return NULL;
	else {
	    N++;
	    htable[i].key = item.key;
	    htable[i].data = item.data;
	    return &htable[i];
	}
    } else
	return NULL;
}

int hcreate(nel)
unsigned nel;

{
    N = 0;
    M = 2*nel;
    htable = (ENTRY *)malloc(M*sizeof(ENTRY));
    return htable != NULL;
}

void hdestroy()

{
    free(htable);
}

/*
 * 'strspn' returns the length of the initial segment of string 'source' which
 * consists entirely of characters from string 'keys'.
 */

strspn(source, keys)
char *source, *keys;
{
    register int loc, key_index;

    for (loc = 0;source[loc];loc++)
	for (key_index = 0;keys[key_index] != source[loc];key_index++)
	    if (keys[key_index] == '\0')
		return(loc);
    return loc;
}

/*
 * 'strnspn' returns the length of the initial segment of string 'source' which
 * consists entirely of characters not from string 'keys'.
 */

strnspn(source, keys)
char *source, *keys;
{
    register int loc = 0, key_index;

    for (loc = 0;source[loc];loc++)
	for (key_index = 0;keys[key_index];key_index++)
	    if (keys[key_index] == source[loc])
		return loc;
    return loc;
}

char *strtok(string,separators)
char *string,*separators;

{
    static char *save;
    char *p,*s;
    long i,j;

    if (string != NULL) save = string;
    if (save != NULL && *save != NULL && separators != NULL) {
	p = save;
	i = strnspn(p,separators);
	if (save[i] == NULL) {
	    save = NULL;
	} else {
	    j = strspn(&save[i],separators);
	    save[i] = '\0';
	    save = &save[i+j];
	}
    } else
	p = NULL;
    return p;
}

#endif
