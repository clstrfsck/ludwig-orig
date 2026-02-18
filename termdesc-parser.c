/*
L   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   TR
 *
 * Name:        termdesc-parser
 *
 * Description: A parser for termdesc files.
 *
 * Revision History:
 * 1-001 Released with Ludwig V4.0 release.                   7-Apr-1987
 * 1-002 Mark R. Prior                                       11-Apr-1987
 *       Add the primary name of the terminal to the binary file.
 * 1-003 Jeff Blows                                          29-May-1987
 *       Add the missing ptr parameter to the calls to realloc.
 * 1-004 Kelvin B. Nicolle                                    5-Jun-1987
 *       See const.h and type.h.
 * 1-005 Kelvin B. Nicolle                                   18-Sep-1987
 *       insert_c1 was generating entries for all escape sequences, not
 *       only those in the range '@'..'_'.
 */

# include <stdio.h>
# include <ctype.h>
# ifdef VMS
#   include <types.h>
#   include <rms.h>
# else
#   include <sys/types.h>
#   include <sys/file.h>
# endif

# include "const.h"
# include "type.h"
# include "termdesc.h"

#if pyr || ns32000
#define isgraph(c)      ((_ctype_+1)[c]&(_P|_U|_L|_N))
#endif

# define ESC                        033
# define NUMBER_OF_CONTROL_NAMES    65
# define SKIP_SPACES(s)             while (s != NULL && (*s == ' ' || *s == '\t')) next()
# define ERROR(message)             fprintf(stderr,"%s%*c %s\n",buffer,pos,'^',message)
# define ADD_TO_SEQUENCE(seq,ch)    if ((seq).length < MAX_STRLEN) \
					(seq).body[(seq).length++] = (char)ch; \
				    else \
					ERROR("Sequence too long.")

typedef struct {
	unsigned char body[MAX_STRLEN];
	long length;
	} sequence_type;

typedef struct node {
	unsigned char seq_char;
	struct node *left,*right,*next;
	KEY_CODE_RANGE key_code;
	} *node_ptr, node;

FILE     *description;
node_ptr tree_head = NULL, current_node, esc_ptr;
char     primary[MAX_STRLEN],termdesc_dir[MAX_STRLEN];
char     *s,buffer[MAX_STRLEN],def_name[MAX_STRLEN];
char     *getenv(),*next(),*fill_buffer();
char     **secondary;
char     control_charset[32],c1_charset[32];
char     control_names[NUMBER_OF_CONTROL_NAMES][4] = {
	"NUL","SOH","STX","ETX","EOT","ENQ","ACK","BEL","BS","HT","LF","VT",
	"FF","CR","SO","SI","DLE","DC1","DC2","DC3","DC4","NAK","SYN","ETB",
	"CAN","EM","SUB","ESC","FS","GS","RS","US","DEL",
	"?","?","?","?","IND","NEL","SSA","ESA","HTS","HTJ","VTS","PLD","PLU",
	"RI","SS2","SS3","DCS","PU1","PU2","STS","CCH","MW","SPA","EPA","?","?",
	"?","CSI","ST","OSC","PM","APC" };
long     i,j,pos,nr_sequences,nr_key_codes,ansi_terminal,max_key_names;
long     parse_table_size,c1_index,c1_index_2,parse_table_top;
long     nr_secondaries,max_secondaries;

main(argc,argv)
long argc;
char *argv[];

{
    long i;

# ifdef VMS
    termdesc_dir[0] = '\0';
# else
    strcpy(termdesc_dir,".");
# endif
    while (--argc > 0 && (*++argv)[0] == '-')
	switch ((*argv)[1]) {
	    case 'd' :
		if (--argc > 0 && (*++argv)[0] != '-')
		    strcpy(termdesc_dir,*argv);
		else {
		    fprintf(stderr,"Directory name missing\n");
		    exit(1);
		}
	}
    if (argc == 1) {
	if ((description = fopen(*argv,"r")) == NULL) {
	    perror(*argv);
	    exit(1);
	}
    } else if (argc == 0)
	description = stdin;
    else {
	fprintf(stderr,"Too many parameters\n");
	exit(1);
    }
    nr_key_names = nr_sequences = nr_key_codes = nr_secondaries = 0;
    ansi_terminal = FALSE;
    primary[0] = '\0';
    for (i = 0;i < sizeof control_charset;i++) {
	control_charset[i] = 0;
	c1_charset[i] = 0;
    }
    for (i = 0;i < 32;i++)
	setbit(control_charset,i);
    setbit(control_charset,127);
    for (i = 128;i < 160;i++) {
	setbit(control_charset,i);
	setbit(c1_charset,i);
    }
    setbit(control_charset,255);
    setbit(c1_charset,255);
    max_key_names = INITIAL_MAX_KEY_NAMES;
    if ((key_name_list = (KEY_NAME_RECORD *)calloc(max_key_names,sizeof(KEY_NAME_RECORD))) == NULL) {
	perror("calloc");
	exit(1);
    }
    parse_table_size = INITIAL_PARSE_TABLE;
    if ((parse_table = (PARSE_TABLE_RECORD *)calloc(parse_table_size,sizeof(PARSE_TABLE_RECORD))) == NULL) {
	perror("calloc");
	exit(1);
    }
    max_secondaries = 5;
    if ((secondary = (char **)calloc(max_secondaries,sizeof(char *))) == NULL) {
	perror("calloc");
	exit(1);
    }
    while ((s = fill_buffer(buffer)) != NULL) {
	SKIP_SPACES(s);
	if (!get_def_name(def_name,TRUE))
	    continue;
	if (strncmp(def_name,"KEY-",4) == 0)
	    process_key_definition(def_name);
	else if (strcmp(def_name,"TERMINAL") == 0) {
	    SKIP_SPACES(s);
	    if (*s != '=') {
		ERROR("'=' expected.");
		continue;
	    }
	    do {
		next();
		SKIP_SPACES(s);
		if (!get_def_name(def_name,FALSE))
		    continue;
		if (primary[0] == '\0')
		    strcpy(primary,def_name);
		else {
		    if (max_secondaries == nr_secondaries)
			if ((secondary = (char **)realloc(secondary,++max_secondaries*sizeof(char *))) == NULL) {
			    perror("realloc");
			    exit(1);
			}
		    if ((secondary[nr_secondaries] = (char *)malloc(strlen(def_name)+1)) == NULL) {
			perror("malloc");
			exit(1);
		    }
		    strcpy(secondary[nr_secondaries++],def_name);
		}
		SKIP_SPACES(s);
	    } while (*s == '|');
	} else if (strcmp(def_name,"ANSI-TERMINAL") == 0) {
	    SKIP_SPACES(s);
	    if (*s != '=') {
		ERROR("'=' expected.");
		continue;
	    }
	    next();
	    SKIP_SPACES(s);
	    if (!get_def_name(def_name,TRUE))
		continue;
	    if (strcmp(def_name,"TRUE") == 0)
		ansi_terminal = TRUE;
	    else if (strcmp(def_name,"FALSE") == 0)
		ansi_terminal = FALSE;
	    else {
		ERROR("Invalid boolean value.");
		continue;
	    }
	} else {
	    ERROR("Unknown definition type.");
	    continue;
	}
    }
    fprintf(stderr,"Number of key names = %d.\n",nr_key_names);
    fprintf(stderr,"Number of key codes = %d.\n",nr_key_codes);
# ifdef TRACE
    trace_key_name_list();
# endif
    fprintf(stderr,"Number of sequences = %d.\n",nr_sequences);
# ifdef TRACE
    trace_tree();
# endif
    parse_table_top = 0;
    if (tree_head != NULL) generate_parse_table(tree_head,1);
    fprintf(stderr,"Length of parse table = %d.\n",parse_table_top);
# ifdef TRACE
    trace_parse_table();
# endif
    /* Blank pad the names for Pascal's benefit! */
    for (i = 0;i < nr_key_names;i++)
	for (j = strlen(key_name_list[i].key_name);j < KEY_NAME_LEN;j++)
	    key_name_list[i].key_name[j] = ' ';
    write_tables();
}

char *fill_buffer(buffer)

{
    char *s,*p,*index();

    pos = 1;
    do {
	s = fgets(buffer,MAX_STRLEN,description);
	if (s != NULL) {
	    if ((p = index(buffer,'!')) != NULL) {
		*p++ = '\n';
		*p   = '\0';
	    }
	    while (*s && (*s == ' ' || *s == '\t'))
		s++;
	}
    } while (s != NULL && *s == '\n');
    return s;
}

char *next()

{
    if (*++s == NULL) {
	s = fill_buffer(buffer);
	pos = 0;
    }
    pos++;
    return s;
}

long get_def_name(name,upcase)
char *name;
long upcase;

{
    char *ptr = name;
    long def_name_length = 0;

    if (!isalnum(*s)) {
	ERROR("Alphanumeric expected.");
	return FALSE;
    }
    do {
	if (++def_name_length >= KEY_NAME_LEN) {
	    ERROR("Name too long.");
	    return FALSE;
	}
	if (upcase && islower(*s))
	    *ptr++ = toupper(*s);
	else
	    *ptr++ = *s;
	next();
    } while (*s && (isalnum(*s) || *s == '-'));
    *ptr = '\0';
    return TRUE;
}

long process_key_definition(def_name)
char *def_name;

{
    long           i,first_key_name;
    sequence_type  sequence;
    KEY_CODE_RANGE key_code;
    char           key_name[MAX_STRLEN];

    first_key_name = nr_key_names;
    do {
	strcpy(key_name,&def_name[4]);
	if (strlen(key_name) < 2) {
	    ERROR("Key name must be more than one character");
	    return FALSE;
	}
	if (!isalpha(*key_name)) {
	    ERROR("Key name must begin with a letter.");
	    return FALSE;
	}
	if (nr_key_names == max_key_names) {
	    max_key_names += KEY_NAME_INCREMENT;
	    if ((key_name_list = (KEY_NAME_RECORD *)
realloc(key_name_list,max_key_names*sizeof(KEY_NAME_RECORD))) == NULL) {
		perror("realloc");
		return FALSE;
	    }
	}
	for (i = 0;i < nr_key_names;i++)
	    if (strcmp(key_name_list[i].key_name,key_name) == 0) {
		ERROR("Duplicate definition of key name");
		return FALSE;
	    }
	strcpy(key_name_list[nr_key_names++].key_name,key_name);
	SKIP_SPACES(s);
	if (*s == ',') {
	    next();
	    SKIP_SPACES(s);
	    if (!get_def_name(def_name))
		return FALSE;
	    if (strncmp(def_name,"KEY-",4) != 0) {
		ERROR("Alias must begin with 'KEY-'.");
		return FALSE;
	    }
	} else
	    break;
    } while (TRUE);
    SKIP_SPACES(s);
    if (*s != '=') {
	ERROR("'=' expected.");
	return FALSE;
    }
    next();
    SKIP_SPACES(s);
    if (!get_sequence(&sequence)) return FALSE;
    if (sequence.length == 1) {
	key_code = (short)sequence.body[0];
    } else if (ansi_terminal && sequence.length == 2 &&
	       sequence.body[0] == ESC && sequence.body[1] >= '@' &&
	       sequence.body[1] <= '_')
	key_code = (short)(sequence.body[1] - '@' + 128);
    else
	key_code = -++nr_key_codes;
    for (i = first_key_name; i < nr_key_names;i++)
	key_name_list[i].key_code = key_code;
    if (!enter_sequence(key_code,sequence)) return FALSE;
    if (*s == '|' && key_code >= 0) {
	ERROR("Alternatives not allowed on control characters.");
	return FALSE;
    }
    while (*s == '|') {
	next();
	SKIP_SPACES(s);
	if (*s == '\n') next();
	if (!get_sequence(&sequence)) return FALSE;
	if (   sequence.length == 1
	    || (ansi_terminal && sequence.length == 2 &&
		sequence.body[0] == ESC && sequence.body[1] >= '@' &&
		sequence.body[1] <= '_')) {
	    ERROR("Alternatives not allowed on control characters.");
	    return FALSE;
	}
	if (!enter_sequence(key_code,sequence)) return FALSE;
    }
    if (*s != '\n') {
	ERROR("'+' or '|' expected.");
	return FALSE;
    }
    return TRUE;
}

long get_sequence(sequence)
sequence_type *sequence;

{
    char name[MAX_STRLEN],*p,delimiter;
    long i,number,radix,value;

    sequence->length = 0;
    nr_sequences++;
    do {
	if (!(isalnum(*s) || *s == '^' || *s == '"' || *s == '\'')) {
	    ERROR("Item expected.");
	    return FALSE;
	}
	if (isalpha(*s)) {
	    for (i = 0;*s && isalnum(*s);i++,next())
		if (islower(*s))
		    name[i] = toupper(*s);
		else
		    name[i] = *s;
	    name[i] = '\0';
	    for (i = 0;i < NUMBER_OF_CONTROL_NAMES;i++)
		if (strcmp(name,control_names[i]) == 0)
		    break;
	    if (i == NUMBER_OF_CONTROL_NAMES) {
		ERROR("Invalid control name.");
		return FALSE;
	    }
	    if (i < 32)
		ADD_TO_SEQUENCE(*sequence,i);
	    else
		ADD_TO_SEQUENCE(*sequence,i+(127-32));
	} else if (isdigit(*s)) {
	    number = 0;
	    do {
		number = number*10 + *s - '0';
		next();
		if (number > ORD_MAXCHAR) {
		    ERROR("number > ord(maxchar)\n");
		    return FALSE;
		}
	    } while (isdigit(*s));
	    if (*s == '#') {
		radix = number;
		if (radix < 2 || radix > 16) {
		    ERROR("Radix must be in the range 2..16\n");
		    return FALSE;
		}
		number = 0;
		next();
		do {
		    if (isdigit(*s)) value = *s - '0';
		    else if (islower(*s)) value = *s - 'a' + 10;
		    else if (isupper(*s)) value = *s - 'A' + 10;
		    else value = radix;
		    if (value >= radix) {
			ERROR("Invalid digit.\n");
			return FALSE;
		    }
		    number = number*radix + value;
		    next();
		} while (isdigit(*s) || (*s >= 'A' && *s <= 'F') ||
					(*s >= 'a' && *s <= 'f'));
	    }
	    ADD_TO_SEQUENCE(*sequence,number);
	} else if (*s == '^') {
	    next();
	    if (islower(*s)) *s = toupper(*s);
	    if (*s < '@' || *s > '_') {
		ERROR("Illegal control code.\n");
		return FALSE;
	    }
	    ADD_TO_SEQUENCE(*sequence,*s - '@');
	    next();
	} else { /* *s == '"' || *s == '\'' */
	    delimiter = *s;
	    for (next();*s && *s != delimiter && *s != '\n';next())
		ADD_TO_SEQUENCE(*sequence,*s);
	    if (*s != delimiter) {
		ERROR("Unterminated string.\n");
		return FALSE;
	    }
	    next();
	}
	SKIP_SPACES(s);
	if (*s == '+') {
	    next();
	    SKIP_SPACES(s);
	    if (*s == '\n') next();
	} else
	    break;
    } while (TRUE);
    if (sequence->length == 0) {
	ERROR("Empty sequence.");
	return FALSE;
    }
    if (isclr(control_charset,sequence->body[0])) {
	ERROR("Sequence must begin with a control character.");
	return FALSE;
    }
    if (ansi_terminal && isset(c1_charset,sequence->body[0])) {
	if (sequence->length == MAX_STRLEN) {
	    ERROR("Sequence too long.");
	    return FALSE;
	}
	for (i = sequence->length;i > 1;i--)
	    sequence->body[i] = sequence->body[i-1];
	sequence->length++;
	sequence->body[1] = sequence->body[0] - 128 + '@';
	sequence->body[0] = ESC;
    }
    return TRUE;
}

node_ptr new_node(ch)
unsigned char ch;

{
    node_ptr p;

    if ((p = (node_ptr)malloc(sizeof(node))) != NULL) {
	p->seq_char = ch;
	p->left = p->right = p->next = NULL;
	p->key_code = 0;
    }
    return p;
}

long enter_sequence(key_code,sequence)
KEY_CODE_RANGE key_code;
sequence_type  sequence;

{
    long i;
    unsigned char ch = sequence.body[0];

    if (tree_head == NULL) tree_head = new_node(ch);
    current_node = tree_head;
    for (i = 0;i < sequence.length;i++) {
	do {
	    if (ch < current_node->seq_char) {
		if (current_node->left == NULL)
		    current_node->left = new_node(ch);
		current_node = current_node->left;
	    }
	    if (ch > current_node->seq_char) {
		if (current_node->right == NULL)
		    current_node->right = new_node(ch);
		current_node = current_node->right;
	    }
	} while (current_node->seq_char != ch);
	if (i != sequence.length-1) {
	    if (current_node->key_code != 0) {
		ERROR("Sequence conflicts with an earlier definition.");
		return FALSE;
	    }
	    ch = sequence.body[i+1];
	    if (current_node->next == NULL)
		current_node->next = new_node(ch);
	    current_node = current_node->next;
	}
    }
    if (current_node->next != NULL) {
	ERROR("Sequence conflicts with an earlier definition.");
	return FALSE;
    }
    if (current_node->key_code != 0) {
	ERROR("Duplicate sequence.");
	return FALSE;
    }
    current_node->key_code = key_code;
    return TRUE;
}

generate_table(current_node)
node_ptr current_node;

{
    if (current_node->left != NULL) generate_table(current_node->left);
    parse_table[parse_table_top].ch = current_node->seq_char;
    parse_table[parse_table_top].key_code = current_node->key_code;
    parse_table_top++;
    if (current_node->right != NULL) generate_table(current_node->right);
}

insert_c1(current_node)
node_ptr current_node;

{
    unsigned char new_ch;

    if (current_node->left != NULL) insert_c1(current_node->left);
    if (current_node->seq_char >= '@' && current_node->seq_char <= '_') {
	new_ch = current_node->seq_char - '@' + 128;
	parse_table[parse_table_top].ch = new_ch;
	parse_table[parse_table_top].key_code = current_node->key_code;
	parse_table_top++;
	if (current_node->next != NULL) setbit(introducers,new_ch);
    }
    if (current_node->right != NULL) insert_c1(current_node->right);
}

insert_c1_characters(current_node)
node_ptr current_node;

{
    do {
	if (current_node->seq_char > ESC)
	    current_node = current_node->left;
	else if (current_node->seq_char < ESC)
	    current_node = current_node->right;
	else
	    esc_ptr = current_node->next;
    } while (esc_ptr == NULL && current_node != NULL);
    if (esc_ptr != NULL) {
	c1_index = parse_table_top;
	insert_c1(esc_ptr);
    }
}

generate_sub_table(level,header,current_node)
long     level,*header;
node_ptr current_node;

{
    if (current_node->left != NULL)
	generate_sub_table(level,header,current_node->left);
    if (current_node->next != NULL) {
	if (level == 1) setbit(introducers,parse_table[*header].ch);
	parse_table[*header].index = parse_table_top;
	generate_parse_table(current_node->next,level+1);
    } else
	parse_table[*header].index = 0;
    (*header)++;
    if (current_node->right != NULL)
	generate_sub_table(level,header,current_node->right);
}

fix_c1_indexes(header,current_node)
long     *header;
node_ptr current_node;

{
    if (current_node->left != NULL) fix_c1_indexes(header,current_node->left);
    if (current_node->seq_char >= '@' && current_node->seq_char <= '_')
	parse_table[(*header)++].index = parse_table[c1_index_2].index;
    c1_index_2++;
    if (current_node->right != NULL) fix_c1_indexes(header,current_node->right);
}

generate_parse_table(current_node,level)
node_ptr current_node;
long     level;

{
    long i,header;

    header = parse_table_top++;
    if (current_node == esc_ptr) c1_index_2 = parse_table_top;
    generate_table(current_node);
    if (level == 1) {
	for (i = 0; i < sizeof introducers;i++)
	    introducers[i] = 0;
	esc_ptr = NULL;
	c1_index = 0;
	if (ansi_terminal) insert_c1_characters(current_node);
    }
    parse_table[header++].index = parse_table_top;
    parse_table[parse_table_top++].key_code = 0;
    generate_sub_table(level,&header,current_node);
    if (header == c1_index) fix_c1_indexes(&header,esc_ptr);
    parse_table[header].index = 0;
}

write_tables()

{
# ifdef VMS
    char path[NAM$C_MAXRSS+1];
    struct FAB fab;
    struct RAB rab;
    long sts,nr_items,size_item;

# define CHECK(fn)  if (!((sts = fn) & 1)) exit(sts)

    sprintf(path, "%s%s.bin", termdesc_dir, primary);
    fab = cc$rms_fab;
    fab.fab$b_rfm = FAB$C_VAR;
    fab.fab$b_fac = FAB$M_PUT;
    fab.fab$l_fop = FAB$M_SQO + FAB$M_TEF;
    fab.fab$l_fna = path;
    fab.fab$b_fns = strlen(path);
    CHECK(sys$create(&fab));
    rab = cc$rms_rab;
    rab.rab$l_fab = &fab;
    CHECK(sys$connect(&rab));
    /* Write the key name table */
    size_item = sizeof(KEY_NAME_RECORD);
    rab.rab$l_rbf = &size_item;
    rab.rab$w_rsz = 2;
    CHECK(sys$put(&rab));
    nr_items = nr_key_names;
    rab.rab$l_rbf = &nr_items;
    CHECK(sys$put(&rab));
    rab.rab$l_rbf = key_name_list;
    rab.rab$w_rsz = size_item*nr_items;
    CHECK(sys$put(&rab));
    /* Write the parse table */
    size_item = sizeof(PARSE_TABLE_RECORD);
    rab.rab$l_rbf = &size_item;
    rab.rab$w_rsz = 2;
    CHECK(sys$put(&rab));
    nr_items = parse_table_top;
    rab.rab$l_rbf = &nr_items;
    CHECK(sys$put(&rab));
    rab.rab$l_rbf = parse_table;
    rab.rab$w_rsz = size_item*nr_items;
    CHECK(sys$put(&rab));
    /* Write the sequence introducer character set */
    size_item = sizeof introducers;
    rab.rab$l_rbf = &size_item;
    rab.rab$w_rsz = 2;
    CHECK(sys$put(&rab));
    rab.rab$l_rbf = introducers;
    rab.rab$w_rsz = size_item;
    CHECK(sys$put(&rab));
    /* Write out the terminal's primary name */
    size_item = strlen(primary);
    rab.rab$l_rbf = &size_item;
    rab.rab$w_rsz = 2;
    CHECK(sys$put(&rab));
    rab.rab$l_rbf = primary;
    rab.rab$w_rsz = size_item;
    CHECK(sys$put(&rab));
    CHECK(sys$close(&fab));
# else
    char  path[1024],path2[1024];
    short buffer;
    long  fd;

    sprintf(path, "%s/%s", termdesc_dir, primary);
    if ((fd = open(path, O_WRONLY|O_CREAT|O_TRUNC, 0755)) < 0) {
	perror(path);
	exit(1);
    }
    buffer = sizeof(KEY_NAME_RECORD);
    write(fd, &buffer, sizeof buffer);
    buffer = nr_key_names;
    write(fd, &buffer, sizeof buffer);
    write(fd, key_name_list, nr_key_names*sizeof(KEY_NAME_RECORD));
    buffer = sizeof(PARSE_TABLE_RECORD);
    write(fd, &buffer, sizeof buffer);
    buffer = parse_table_top;
    write(fd, &buffer, sizeof buffer);
    write(fd, parse_table, parse_table_top*sizeof(PARSE_TABLE_RECORD));
    buffer = sizeof introducers;
    write(fd, &buffer, sizeof buffer);
    write(fd, introducers, sizeof introducers);
    buffer = strlen(primary);
    write(fd, &buffer, sizeof buffer);
    write(fd, primary, buffer);
    close(fd);
    for (i = 0;i < nr_secondaries;i++) {
	sprintf(path2, "%s/%s", termdesc_dir, secondary[i]);
	symlink(path,path2);
    }
# endif
}

trace_key_name_list()

{
    long i;

    for (i = 0;i < nr_key_names;i++)
	fprintf(stderr,"%s \t%d\n",key_name_list[i].key_name,key_name_list[i].key_code);
}

trace_node(current_node,level)
node_ptr current_node;
long     level;

{
    if (current_node->left != NULL) trace_node(current_node->left, level);
    fprintf(stderr,"%*c",level*2,' ');
    if (isgraph(current_node->seq_char))
	fprintf(stderr,"\"%c\"",current_node->seq_char);
    else if (current_node->seq_char >= 0 && current_node->seq_char <= 255)
	fprintf(stderr,"%s",(current_node->seq_char < 32)
			    ?control_names[current_node->seq_char]
			    :control_names[current_node->seq_char-127+32]);
    else
	fprintf(stderr,"%d",current_node->seq_char);
    fprintf(stderr," %d\n",current_node->key_code);
    if (current_node->next != NULL) trace_node(current_node->next, level+1);
    if (current_node->right != NULL) trace_node(current_node->right, level);
}

trace_tree()

{
    if (tree_head != NULL) trace_node(tree_head,1);
}

trace_parse_table()

{
    long i;

    for (i = 0;i < parse_table_top;i++) {
	fprintf(stderr,"%3d  ",i);
	if (parse_table[i].ch >= ' ' && parse_table[i].ch <= '~')
	    fprintf(stderr,"\"%c\"",parse_table[i].ch);
	else
	    fprintf(stderr,"%3d",parse_table[i].ch);
	fprintf(stderr,"%5d %5d\n",parse_table[i].key_code,parse_table[i].index);
    }
    fprintf(stderr,"Introducers = [ ");
    for (i = 0;i <= ORD_MAXCHAR;i++)
	if (isset(introducers,i))
	    if (i >= ' ' && i <= '~')
		fprintf(stderr,"\"%c\" ",i);
	    else
		fprintf(stderr,"%3d ",i);
    fprintf(stderr,"]\n");
}

# ifdef VMS

char *index(buffer,ch)
char *buffer,ch;

{
    char *s;

    for (s = buffer;*s;s++)
	if (*s == ch) return s;
    return NULL;
}

# endif
