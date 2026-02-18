#include <stdio.h>

main (argc,argv)
int argc;
char *argv[];
{

    char *getenv();

    static char hex[16] = "0123456789ABCDEF";
    static char ALPHA[27] = "\0ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    static char alpha[27] = "\0abcdefghijklmnopqrstuvwxyz";
    char *term;
    int key;

#if unix
    if ((term = getenv("TERM")) == NULL) return 0;
#endif
#if vms

#endif

    if (strcmp(term,"gtc101") == 0) {
	/* sequence = ESC w key text NUL
	   key      = A..P
	   text     = ESC \ key -- ASCII
	   key      = A..P
	*/
	for (key=1;key<=16;key++) {
	    printf("\033w%c\033\\%c\200",ALPHA[key],ALPHA[key]);
	}
    }
    else
    if (strcmp(term,"vis102") == 0) {
	/* sequence = ESC [ key ; text p
	   key      = 1..16
	   text     = ESC _ key ESC \  -- decimal encoded, ';' separated
	   key      = A..P
	*/
	for (key=1;key<=16;key++) {
	    printf("\033[%d;27;95;%d;27;92p",key,ALPHA[key]);
	}
    }
    else
    if (strcmp(term,"vis500") == 0) {
	/* sequence = ESC @ key text ESC @
	   key      = 1..9A..C
	   text     = ESC _ key ESC \  -- ASCII
	   key      = A..L
	*/
	for (key=1;key<=12;key++) {
	    printf("\033@%c\033_%c\033\\\033@",hex[key],ALPHA[key]);
	}
    }
    else
    if (strcmp(term,"vis550") == 0) {
	/* sequence = ESC [ key ; text p
	   key      = 1..12
	   text     = ESC _ key ESC \  -- decimal encoded, ';' separated
	   key      = A..L
	*/
	for (key=1;key<=12;key++) {
	    printf("\033[%d;27;95;%d;27;92p",key,ALPHA[key]);
	}
    }
    else
    if (strcmp(term,"vt200") == 0) {
	/* sequence = ESC P 1 ; 1 | key / text ESC \
	   key      = 17,18,19,20,21,23,24,25,26,28,29,31,32,33,34
	   text     = ESC [ key ~  -- hex encoded, two digits
	   key      = 37,38,39,40,41,43,44,45,46,48,49,51,52,53,54
	*/
	for (key=17;key<=34;key++) {
	    if (key==22 || key==27 || key==30) continue;
	    printf("\033P1;1|%d/1B5B3%d3%d7E\033\\",
		   key,(key+20)/10,(key+20)%10);
	}
    }
    else
	printf("%s does not recognize terminal type: %s.\n",
	       argv[0],term);
}
