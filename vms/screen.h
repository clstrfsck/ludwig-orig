procedure screen_message (
		message : packed array [l1..msg_len:strlen_range] of char);
  external;

function screen_vms_message (
		message : [class_s] packed array [l1..h1:integer] of char)
	: boolean;
  external;

procedure screen_draw_line (
		line : line_ptr);
  external;

procedure screen_redraw;
  external;

procedure screen_slide (
		dist : integer);
  external;

procedure screen_unload;
  external;

procedure screen_scroll (
		count  : integer;
		expand : boolean);
  external;

procedure screen_lines_extract (
		first_line : line_ptr;
		last_line  : line_ptr);
  external;

procedure screen_lines_inject (
		first_line  : line_ptr;
		count       : line_range;
		before_line : line_ptr);
  external;

procedure screen_load (
		line : line_ptr;
		col  : col_range);
  external;

procedure screen_position (
		new_line : line_ptr;
		new_col  : col_range);
  external;

procedure screen_pause;
  external;

procedure screen_clear_msgs (
		pause : boolean);
  external;

procedure screen_fixup;
  external;

procedure screen_getlinep (
		prompt     : packed array [l1..h1:strlen_range] of char;
		prompt_len : strlen_range;
	var     outbuf     : str_object;
	var     outlen     : strlen_range;
		max_tp,
		this_tp    : tpcount_type);
  external;

procedure screen_free_bottom_line;
  external;

function screen_verify (
		prompt     : packed array [l1..h1:strlen_range] of char;
		prompt_len : strlen_range)
	: verify_response;
  external;

procedure screen_beep;
  external;

procedure screen_home (
		clear:boolean);
  external;

procedure screen_write_int (
		int   : integer;
		width : scr_col_range);
  external;

procedure screen_write_ch (
		indent : scr_col_range;
		ch     : char);
  external;

procedure screen_write_str (
		indent : scr_col_range;
		str    : packed array [l1..h1:strlen_range] of char;
		width  : scr_col_range);
  external;

procedure screen_write_name_str (
		indent : scr_col_range;
		str    : name_str;
		width  : scr_col_range);
  external;

procedure screen_write_file_name_str (
		indent : scr_col_range;
		str    : file_name_str;
		width  : scr_col_range);
  external;

procedure screen_writeln;
  external;

procedure screen_writeln_clel;
  external;

