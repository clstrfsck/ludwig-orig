[global]
procedure screen_message (
		message : packed array [l1..msg_len:strlen_range] of char);
  forward;

[global]
function screen_vms_message (
		message : [class_s] packed array [l1..h1:integer] of char)
	: boolean;
  forward;

[global]
procedure screen_draw_line (
		line : line_ptr);
  forward;

[global]
procedure screen_redraw;
  forward;

[global]
procedure screen_slide (
		dist : integer);
  forward;

[global]
procedure screen_unload;
  forward;

[global]
procedure screen_scroll (
		count  : integer;
		expand : boolean);
  forward;

[global]
procedure screen_lines_extract (
		first_line : line_ptr;
		last_line  : line_ptr);
  forward;

[global]
procedure screen_lines_inject (
		first_line  : line_ptr;
		count       : line_range;
		before_line : line_ptr);
  forward;

[global]
procedure screen_load (
		line : line_ptr;
		col  : col_range);
  forward;

[global]
procedure screen_position (
		new_line : line_ptr;
		new_col  : col_range);
  forward;

[global]
procedure screen_pause;
  forward;

[global]
procedure screen_clear_msgs (
		pause : boolean);
  forward;

[global]
procedure screen_fixup;
  forward;

[global]
procedure screen_getlinep (
		prompt     : packed array [l1..h1:strlen_range] of char;
		prompt_len : strlen_range;
	var     outbuf     : str_object;
	var     outlen     : strlen_range;
		max_tp,
		this_tp    : tpcount_type);
  forward;

[global]
procedure screen_free_bottom_line;
  forward;

[global]
function screen_verify (
		prompt     : packed array [l1..h1:strlen_range] of char;
		prompt_len : strlen_range)
	: verify_response;
  forward;

[global]
procedure screen_beep;
  forward;

[global]
procedure screen_home (
		clear:boolean);
  forward;

[global]
procedure screen_write_int (
		int   : integer;
		width : scr_col_range);
  forward;

[global]
procedure screen_write_ch (
		indent : scr_col_range;
		ch     : char);
  forward;

[global]
procedure screen_write_str (
		indent : scr_col_range;
		str    : packed array [l1..h1:strlen_range] of char;
		width  : scr_col_range);
  forward;

[global]
procedure screen_write_name_str (
		indent : scr_col_range;
		str    : name_str;
		width  : scr_col_range);
  forward;

[global]
procedure screen_write_file_name_str (
		indent : scr_col_range;
		str    : file_name_str;
		width  : scr_col_range);
  forward;

[global]
procedure screen_writeln;
  forward;

[global]
procedure screen_writeln_clel;
  forward;

