/*
 *
 * Name:        const.h
 *
 * Description: A parser for termdesc files.
 *
 * Revision History:
 * 1-001 Kelvin B. Nicolle                                    5-Jun-1987
 *       Created by collecting definitions from vdu.c, filesys.c, and
 *       termdesc.h.
 *       Some names have been changed to make them consistent with the
 *       names in the pascal include files, and all have been put into
 *       upper case.
 */

#define FALSE                   0
#define TRUE                    1
#define MAXINT                  2147483647

#ifdef vms
#define ORD_MAXCHAR             255
#else
#define ORD_MAXCHAR             127
#endif

#define MAX_LINES               MAXINT  /* Max lines per frame          */
#define MAX_STRLEN              400     /* Max length of a string       */
#define MAX_SCR_ROWS            100     /* Max nr of rows on screen     */
#define MAX_SCR_COLS            255     /* Max nr of cols on screen     */

/* String lengths */
#ifdef vms
#define FILE_NAME_LEN           255
#else
#define FILE_NAME_LEN           252
#endif

/* Keyboard interface. */
#define MAX_SPECIAL_KEYS        100
#define KEY_NAME_LEN            40  /* WARNING - this value is assumed in USER.PAS */
#define MAX_NR_KEY_NAMES        200
#define MAX_PARSE_TABLE         300
