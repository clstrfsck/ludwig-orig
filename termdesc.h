/*
 *
 * Name:        termdesc.h
 *
 * Description: A parser for termdesc files.
 *
 * Revision History:
 * 1-001 Released with Ludwig V4.0 release.                   7-Apr-1987
 * 1-002 Kelvin B. Nicolle                                    5-Jun-1987
 *       See const.h and type.h.
 */

# define INITIAL_MAX_KEY_NAMES  100
# define KEY_NAME_INCREMENT     20
# define INITIAL_PARSE_TABLE    300
# define PARSE_TABLE_INCREMENT  50

# ifndef  NBBY
# define  NBBY                  8
# endif   NBBY
# define  setbit(a,i)           ((a)[(i)/NBBY] |= 1 << ((i)%NBBY))
# define  clrbit(a,i)           ((a)[(i)/NBBY] &= ~(1 << ((i)%NBBY)))
# define  isset(a,i)            ((a)[(i)/NBBY] & (1 << ((i)%NBBY)))
# define  isclr(a,i)            (((a)[(i)/NBBY] & (1 << ((i)%NBBY))) == 0)


PARSE_TABLE_RECORD *parse_table;
KEY_NAME_RECORD    *key_name_list;
char               introducers[32];
long               nr_key_names;
KEY_CODE_RANGE     cmd_introducer;
