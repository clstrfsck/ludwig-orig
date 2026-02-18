procedure ch_move (
	var     src : packed array [l1..h1:integer] of char;
		st1 : strlen_range;
	var     dst : packed array [l2..h2:integer] of char;
		st2 : strlen_range;
		len : strlen_range);
  {umax:nonpascal}
  {mach:nonpascal}
  external;

procedure ch_copy (
	var     src  : packed array [l1..h1:integer] of char;
		st1  : strlen_range;
		len1 : strlen_range;
	var     dst  : packed array [l2..h2:integer] of char;
		st2  : strlen_range;
		len2 : strlen_range;
		fill : char);
  {umax:nonpascal}
  {mach:nonpascal}
  external;

procedure ch_fill (
	var     dst  : packed array [l1..h1:integer] of char;
		st1  : strlen_range;
		len  : strlen_range;
		fill : char);
  {umax:nonpascal}
  {mach:nonpascal}
  external;

function ch_length (
	var     str : packed array [l1..h1:integer] of char;
		len : strlen_range)
	: strlen_range;
  {umax:nonpascal}
  {mach:nonpascal}
  external;

procedure ch_upcase_str (
	var     str : packed array [l1..h1:integer] of char;
		len : strlen_range);
  {umax:nonpascal}
  {mach:nonpascal}
  external;

procedure ch_locase_str (
	var     str : packed array [l1..h1:integer] of char;
		len : strlen_range);
  {umax:nonpascal}
  {mach:nonpascal}
  external;

function ch_upcase_chr (
		ch      : char)
	: char;
  {umax:nonpascal}
  {mach:nonpascal}
  external;

function ch_locase_chr (
		ch      : char)
	: char;
  {umax:nonpascal}
  {mach:nonpascal}
  external;

procedure ch_reverse_str (
	var     src : packed array [l1..h1:integer] of char;
	var     dst : packed array [l2..h2:integer] of char;
		len : strlen_range);
  {umax:nonpascal}
  {mach:nonpascal}
  external;

function ch_compare_str (
	var     target    : packed array [l1..h1:integer] of char;
		st1       : strlen_range;
		len1      : strlen_range;
	var     text      : packed array [l2..h2:integer] of char;
		st2       : strlen_range;
		len2      : strlen_range;
		exactcase : boolean;
	var     nch_ident : strlen_range)
	: integer;
  {umax:nonpascal}
  {mach:nonpascal}
  external;

function ch_search_str (
	var     target    : packed array [l1..h1:integer] of char;
		st1       : strlen_range;
		len1      : strlen_range;
	var     text      : packed array [l2..h2:integer] of char;
		st2       : strlen_range;
		len2      : strlen_range;
		exactcase : boolean;
		backwards : boolean;
	var     found_loc : strlen_range)
	: boolean;
  {umax:nonpascal}
  {mach:nonpascal}
  external;

