{**********************************************************************}
{                                                                      }
{            L      U   U   DDDD   W      W  IIIII   GGGG              }
{            L      U   U   D   D   W    W     I    G                  }
{            L      U   U   D   D   W ww W     I    G   GG             }
{            L      U   U   D   D    W  W      I    G    G             }
{            LLLLL   UUU    DDDD     W  W    IIIII   GGGG              }
{                                                                      }
{**********************************************************************}
{                                                                      }
{   Copyright (C) 1981, 1987                                           }
{   Department of Computer Science, University of Adelaide, Australia  }
{   All rights reserved.                                               }
{   Reproduction of the work or any substantial part thereof in any    }
{   material form whatsoever is prohibited.                            }
{                                                                      }
{**********************************************************************}

{++
! Name:         LUDWIG
!
! Description:  LUDWIG startup and shutdown.   Organize the timing of
!               the session, and the other general details.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
!--}

{#if vms}
[ident('4-001'),
 overlaid]
{#endif}
program ludwig (output);

{#if turbop}
uses value, ch, execimmed, exec, file_module, quit_module,
     user, screen, vduibm, frame,
     msdos, version;
{#elseif vms}
%include 'const.inc/nolist'
%include 'type.inc/nolist'
%include 'var.inc/nolist'
%include 'value.inc/nolist'

%include 'bug.ext/nolist'
%include 'ch.ext/nolist'
%include 'exec.ext/nolist'
%include 'execimmed.ext/nolist'
%include 'file_module.ext/nolist'
%include 'frame.ext/nolist'
%include 'quit_module.ext/nolist'
%include 'screen.ext/nolist'
%include 'user.ext/nolist'
%include 'vdu.ext/nolist'
%include 'vdu_vms.ext/nolist'
%include 'vms.ext/nolist'
{#elseif unix}
#include "const.i"
#include "type.i"
#include "var.i"

#include "ch.h"
#include "exec.h"
#include "execimmed.h"
#include "file_module.h"
#include "frame.h"
#include "quit_module.h"
#include "screen.h"
#include "user.h"
#include "vdu.h"
#include "value.h"
#include "unix.h"
{#if ns32000}
#include "libberkx.pas"
{#endif}
{#endif}


{#if vms}
{}procedure prog_windup (status:vms_status_code);
{#elseif unix}
{}procedure prog_windup (set_hangup:boolean);
{#elseif turbop}
{}procedure prog_windup (set_hangup:boolean);
{#endif}

{#if ns32000}
  nonpascal;
{#else}
  forward;
{#endif}


{}procedure prog_windup;

    begin {prog_windup}
{#if vms}
    hangup := false;
{#else}
    hangup := set_hangup;
{#endif}

    { DISABLE EVERYTHING TO DO WITH VDU'S AND INTERACTIVE USERS. }
    { THIS IS BECAUSE VDU_FREE MUST HAVE BEEN INVOKED BEFORE     }
    { THIS EXIT HANDLER WAS, HENCE THE VDU IS NO LONGER AVAIL.   }

    ludwig_mode  := ludwig_batch;
    scr_frame    := nil;
    scr_top_line := nil;
    scr_bot_line := nil;
    tt_controlc  := false;
    exit_abort   := false;

    { WIND OUT EVERYTHING FOR THE USER -- Gee that's nice of us! }

    quit;

{#if vms}
    {
    ! The following writeln is to prevent the following command prompt
    ! from sometimes overwriting the last Ludwig message.
    }
    writeln;
{#endif}

    end; {prog_windup}


{}procedure initialize;

    var
      i : integer;

    begin {initialize}
    { Set up the Default Tab stops, this can't be done by VALUE             }
    i := 1;
    repeat
      default_tab_stops[i] := true;
      i := i + 8;
    until i > max_strlen;
    initial_tab_stops := default_tab_stops;

    { Now create the Code Header for the compiler to use }
    code_top := 0;
    new(code_list);
    with code_list^ do
      begin
      flink := code_list;
      blink := code_list;
      ref   := 1;
      code  := 1;
      len   := 0;
      end;
    end; {initialize}


{}procedure load_command_table(old_version:boolean);

  var
    key_code : key_code_range;

  begin {load_command_table}
  for key_code := -max_special_keys to -1 do
    lookup[key_code].command := cmd_noop;
  if old_version then
    begin
    lookup[ 0].command := cmd_noop;
    lookup[ 1].command := cmd_noop;
    lookup[ 2].command := cmd_window_backward;
    lookup[ 3].command := cmd_noop;
    lookup[ 4].command := cmd_delete_char;
    lookup[ 5].command := cmd_window_end;
    lookup[ 6].command := cmd_window_forward;
    lookup[ 7].command := cmd_do_last_command;
    lookup[ 8].command := cmd_left;
    lookup[ 9].command := cmd_tab;
    lookup[10].command := cmd_down;
    lookup[11].command := cmd_delete_line;
    lookup[12].command := cmd_insert_line;
    lookup[13].command := cmd_return;
    lookup[14].command := cmd_window_new;
    lookup[15].command := cmd_noop;
    lookup[16].command := cmd_user_command_introducer;
    lookup[17].command := cmd_noop;
    lookup[18].command := cmd_right;
    lookup[19].command := cmd_noop;
    lookup[20].command := cmd_window_top;
    lookup[21].command := cmd_up;
    lookup[22].command := cmd_noop;
    lookup[23].command := cmd_word_advance;
    lookup[24].command := cmd_noop;
    lookup[25].command := cmd_noop;
    lookup[26].command := cmd_noop;
    lookup[27].command := cmd_noop;
    lookup[28].command := cmd_noop;
    lookup[29].command := cmd_noop;
    lookup[30].command := cmd_insert_char;
    lookup[31].command := cmd_noop;
    lookup[ord(' ')].command := cmd_noop;
    lookup[ord('!')].command := cmd_noop;
    lookup[ord('"')].command := cmd_ditto_up;
    lookup[ord('#')].command := cmd_noop;
    lookup[ord('$')].command := cmd_noop;
    lookup[ord('%')].command := cmd_noop;
    lookup[ord('&')].command := cmd_noop;
    lookup[ord('''')].command := cmd_ditto_down;
    lookup[ord('(')].command := cmd_noop;
    lookup[ord(')')].command := cmd_noop;
    lookup[ord('*')].command := cmd_prefix_ast;
    lookup[ord('+')].command := cmd_noop;
    lookup[ord(';')].command := cmd_noop;
    lookup[ord('-')].command := cmd_noop;
    lookup[ord('.')].command := cmd_noop;
    lookup[ord('/')].command := cmd_noop;
    for key_code := ord('0') to ord('9') do
      lookup[key_code].command := cmd_noop;
    lookup[ord(':')].command := cmd_noop;
    lookup[ord(';')].command := cmd_noop;
    lookup[ord('<')].command := cmd_noop;
    lookup[ord('=')].command := cmd_noop;
    lookup[ord('>')].command := cmd_noop;
    lookup[ord('?')].command := cmd_insert_invisible;
    lookup[ord('@')].command := cmd_noop;
    lookup[ord('A')].command := cmd_advance;
    lookup[ord('B')].command := cmd_prefix_b;
    lookup[ord('C')].command := cmd_insert_char;
    lookup[ord('D')].command := cmd_delete_char;
    lookup[ord('E')].command := cmd_prefix_e;
    lookup[ord('F')].command := cmd_prefix_f;
    lookup[ord('G')].command := cmd_get;
    lookup[ord('H')].command := cmd_help;
    lookup[ord('I')].command := cmd_insert_text;
    lookup[ord('J')].command := cmd_jump;
    lookup[ord('K')].command := cmd_delete_line;
    lookup[ord('L')].command := cmd_insert_line;
    lookup[ord('M')].command := cmd_mark;
    lookup[ord('N')].command := cmd_next;
    lookup[ord('O')].command := cmd_overtype_text;
    lookup[ord('P')].command := cmd_noop;
    lookup[ord('Q')].command := cmd_quit;
    lookup[ord('R')].command := cmd_replace;
    lookup[ord('S')].command := cmd_prefix_s;
    lookup[ord('T')].command := cmd_noop;
    lookup[ord('U')].command := cmd_prefix_u;
    lookup[ord('V')].command := cmd_verify;
    lookup[ord('W')].command := cmd_prefix_w;
    lookup[ord('X')].command := cmd_prefix_x;
    lookup[ord('Y')].command := cmd_prefix_y;
    lookup[ord('Z')].command := cmd_prefix_z;
    lookup[ord('[')].command := cmd_noop;
    lookup[ord('\')].command := cmd_command;
    lookup[ord(']')].command := cmd_noop;
    lookup[ord('^')].command := cmd_execute_string;
    lookup[ord('_')].command := cmd_noop;
    lookup[ord('`')].command := cmd_noop;
    for key_code := ord('a') to ord('z') do
      lookup[key_code].command := cmd_noop;
    lookup[ord('{')].command := cmd_set_margin_left;
    lookup[ord('|')].command := cmd_noop;
    lookup[ord('}')].command := cmd_set_margin_right;
{#if debug}
    lookup[ord('~')].command := cmd_prefix_tilde;
{#else}
    lookup[ord('~')].command := cmd_noop;
{#endif}
    lookup[127].command := cmd_rubout;
    for key_code := 128 to ord_maxchar do
      lookup[key_code].command := cmd_noop;
    for key_code := -max_special_keys to ord_maxchar do
      begin
      lookup[key_code].code := nil;
      lookup[key_code].tpar := nil;
      end;

    { initialize lookupexp }
    { case change command ; command :=  * prefix }      {start at 1}
    with lookupexp[ 1] do begin extn := 'U'; command := cmd_case_up end;
    with lookupexp[ 2] do begin extn := 'L'; command := cmd_case_low end;
    with lookupexp[ 3] do begin extn := 'E'; command := cmd_case_edit end;

    { A prefix }    {4}
    { There aren't any in this table! }

    { B prefix }    {4}
    with lookupexp[ 4] do begin extn := 'R'; command := cmd_bridge end;

    { C prefix }    {5}
    { There aren't any in this table! }

    { D prefix }    {5}
    { There aren't any in this table! }

    { E prefix }    {5}
    with lookupexp[ 5] do begin extn := 'X'; command := cmd_span_execute end;
    with lookupexp[ 6] do begin extn := 'D'; command := cmd_frame_edit end;
    with lookupexp[ 7] do begin extn := 'R'; command := cmd_frame_return end;
    with lookupexp[ 8] do begin extn := 'N'; command := cmd_span_execute_no_recompile end;
    with lookupexp[ 9] do begin extn := 'Q'; command := cmd_prefix_eq end;
    with lookupexp[10] do begin extn := 'O'; command := cmd_prefix_eo end;
    with lookupexp[11] do begin extn := 'K'; command := cmd_frame_kill end;
    with lookupexp[12] do begin extn := 'P'; command := cmd_frame_parameters end;

    { EO prefix }   {13}
    with lookupexp[13] do begin extn := 'L'; command := cmd_equal_eol end;
    with lookupexp[14] do begin extn := 'F'; command := cmd_equal_eof end;
    with lookupexp[15] do begin extn := 'P'; command := cmd_equal_eop end;

    { EQ prefix }   {16}
    with lookupexp[16] do begin extn := 'S'; command := cmd_equal_string end;
    with lookupexp[17] do begin extn := 'C'; command := cmd_equal_column end;
    with lookupexp[18] do begin extn := 'M'; command := cmd_equal_mark end;

    { F prefix - files }    {19}
    with lookupexp[19] do begin extn := 'B'; command := cmd_file_rewind end;
    with lookupexp[20] do begin extn := 'I'; command := cmd_file_input end;
    with lookupexp[21] do begin extn := 'E'; command := cmd_file_edit end;
    with lookupexp[22] do begin extn := 'O'; command := cmd_file_output end;
    with lookupexp[23] do begin extn := 'G'; command := cmd_prefix_fg end;
    with lookupexp[24] do begin extn := 'K'; command := cmd_file_kill end;
    with lookupexp[25] do begin extn := 'X'; command := cmd_file_execute end;
    with lookupexp[26] do begin extn := 'T'; command := cmd_file_table end;
    with lookupexp[27] do begin extn := 'P'; command := cmd_page end;

    { FG prefix - global files }    {28}
    with lookupexp[28] do begin extn := 'I'; command := cmd_file_global_input end;
    with lookupexp[29] do begin extn := 'O'; command := cmd_file_global_output end;
    with lookupexp[30] do begin extn := 'B'; command := cmd_file_global_rewind end;
    with lookupexp[31] do begin extn := 'K'; command := cmd_file_global_kill end;
    with lookupexp[32] do begin extn := 'R'; command := cmd_file_read end;
    with lookupexp[33] do begin extn := 'W'; command := cmd_file_write end;

    { I prefix }    {34}
    { There aren't any in this table! }

    { K prefix }    {34}
    { There aren't any in this table! }

    { L prefix }    {34}
    { There aren't any in this table! }

    { O prefix }    {34}
    { There aren't any in this table! }

    { P prefix }    {34}
    { There aren't any in this table! }

    { S prefix - mainly spans }     {34}
    with lookupexp[34] do begin extn := 'A'; command := cmd_span_assign end;
    with lookupexp[35] do begin extn := 'C'; command := cmd_span_copy end;
    with lookupexp[36] do begin extn := 'D'; command := cmd_span_define end;
    with lookupexp[37] do begin extn := 'T'; command := cmd_span_transfer end;
    with lookupexp[38] do begin extn := 'W'; command := cmd_swap_line end;
    with lookupexp[39] do begin extn := 'L'; command := cmd_split_line end;
    with lookupexp[40] do begin extn := 'J'; command := cmd_span_jump end;
    with lookupexp[41] do begin extn := 'I'; command := cmd_span_index end;
    with lookupexp[42] do begin extn := 'R'; command := cmd_span_compile end;

    { T prefix }    {43}
    { There aren't any in this table! }

    { TC prefix }    {43}
    { There aren't any in this table! }

    { TF prefix }    {43}
    { There aren't any in this table! }

    { U prefix - user keyboard mappings }   {43}
    with lookupexp[43] do begin extn := 'C'; command := cmd_user_command_introducer end;
    with lookupexp[44] do begin extn := 'K'; command := cmd_user_key end;
    with lookupexp[45] do begin extn := 'P'; command := cmd_user_parent end;
    with lookupexp[46] do begin extn := 'S'; command := cmd_user_subprocess end;

    { W prefix - window commands }  {47}
    with lookupexp[47] do begin extn := 'F'; command := cmd_window_forward end;
    with lookupexp[48] do begin extn := 'B'; command := cmd_window_backward end;
    with lookupexp[49] do begin extn := 'M'; command := cmd_window_middle end;
    with lookupexp[50] do begin extn := 'T'; command := cmd_window_top end;
    with lookupexp[51] do begin extn := 'E'; command := cmd_window_end end;
    with lookupexp[52] do begin extn := 'N'; command := cmd_window_new end;
    with lookupexp[53] do begin extn := 'R'; command := cmd_window_right end;
    with lookupexp[54] do begin extn := 'L'; command := cmd_window_left end;
    with lookupexp[55] do begin extn := 'H'; command := cmd_window_setheight end;
    with lookupexp[56] do begin extn := 'S'; command := cmd_window_scroll end;
    with lookupexp[57] do begin extn := 'U'; command := cmd_window_update end;

    { X prefix - exit }             {58}
    with lookupexp[58] do begin extn := 'S'; command := cmd_exit_success end;
    with lookupexp[59] do begin extn := 'F'; command := cmd_exit_fail end;
    with lookupexp[60] do begin extn := 'A'; command := cmd_exit_abort end;

    { Y prefix - word processing }  {61}
    with lookupexp[61] do begin extn := 'F'; command := cmd_line_fill end;
    with lookupexp[62] do begin extn := 'J'; command := cmd_line_justify end;
    with lookupexp[63] do begin extn := 'S'; command := cmd_line_squash end;
    with lookupexp[64] do begin extn := 'C'; command := cmd_line_centre end;
    with lookupexp[65] do begin extn := 'L'; command := cmd_line_left end;
    with lookupexp[66] do begin extn := 'R'; command := cmd_line_right end;
    with lookupexp[67] do begin extn := 'A'; command := cmd_word_advance end;
    with lookupexp[68] do begin extn := 'D'; command := cmd_word_delete end;

    { Z prefix - cursor commands }  {69}
    with lookupexp[69] do begin extn := 'U'; command := cmd_up end;
    with lookupexp[70] do begin extn := 'D'; command := cmd_down end;
    with lookupexp[71] do begin extn := 'R'; command := cmd_right end;
    with lookupexp[72] do begin extn := 'L'; command := cmd_left end;
    with lookupexp[73] do begin extn := 'H'; command := cmd_home end;
    with lookupexp[74] do begin extn := 'C'; command := cmd_return end;
    with lookupexp[75] do begin extn := 'T'; command := cmd_tab end;
    with lookupexp[76] do begin extn := 'B'; command := cmd_backtab end;
    with lookupexp[77] do begin extn := 'Z'; command := cmd_rubout end;

    { ~ prefix - miscellaneous debugging commands}  {78}
    with lookupexp[78] do begin extn := 'V'; command := cmd_validate end;
    with lookupexp[79] do begin extn := 'D'; command := cmd_dump end;

    { sentinel }                    {80}
    with lookupexp[80] do begin extn := '?'; command := cmd_nosuch end;


    { initialize lookupexp_ptr }
    { These magic numbers point to the start of each section in lookupexp table }
    lookupexp_ptr[cmd_prefix_ast  ] := 1;
    lookupexp_ptr[cmd_prefix_a    ] := 4;
    lookupexp_ptr[cmd_prefix_b    ] := 4;
    lookupexp_ptr[cmd_prefix_c    ] := 5;
    lookupexp_ptr[cmd_prefix_d    ] := 5;
    lookupexp_ptr[cmd_prefix_e    ] := 5;
    lookupexp_ptr[cmd_prefix_eo   ] := 13;
    lookupexp_ptr[cmd_prefix_eq   ] := 16;
    lookupexp_ptr[cmd_prefix_f    ] := 19;
    lookupexp_ptr[cmd_prefix_fg   ] := 28;
    lookupexp_ptr[cmd_prefix_i    ] := 34;
    lookupexp_ptr[cmd_prefix_k    ] := 34;
    lookupexp_ptr[cmd_prefix_l    ] := 34;
    lookupexp_ptr[cmd_prefix_o    ] := 34;
    lookupexp_ptr[cmd_prefix_p    ] := 34;
    lookupexp_ptr[cmd_prefix_s    ] := 34;
    lookupexp_ptr[cmd_prefix_t    ] := 43;
    lookupexp_ptr[cmd_prefix_tc   ] := 43;
    lookupexp_ptr[cmd_prefix_tf   ] := 43;
    lookupexp_ptr[cmd_prefix_u    ] := 43;
    lookupexp_ptr[cmd_prefix_w    ] := 47;
    lookupexp_ptr[cmd_prefix_x    ] := 58;
    lookupexp_ptr[cmd_prefix_y    ] := 61;
    lookupexp_ptr[cmd_prefix_z    ] := 69;
    lookupexp_ptr[cmd_prefix_tilde] := 78;
    lookupexp_ptr[cmd_nosuch      ] := 80;
    end
  else
    begin
    lookup[ 0].command := cmd_noop;
    lookup[ 1].command := cmd_noop;
    lookup[ 2].command := cmd_window_backward;
    lookup[ 3].command := cmd_noop;
    lookup[ 4].command := cmd_delete_char;
    lookup[ 5].command := cmd_window_end;
    lookup[ 6].command := cmd_window_forward;
    lookup[ 7].command := cmd_do_last_command;
    lookup[ 8].command := cmd_left;
    lookup[ 9].command := cmd_tab;
    lookup[10].command := cmd_down;
    lookup[11].command := cmd_delete_line;
    lookup[12].command := cmd_insert_line;
    lookup[13].command := cmd_return;
    lookup[14].command := cmd_window_new;
    lookup[15].command := cmd_noop;
    lookup[16].command := cmd_user_command_introducer;
    lookup[17].command := cmd_noop;
    lookup[18].command := cmd_right;
    lookup[19].command := cmd_noop;
    lookup[20].command := cmd_window_top;
    lookup[21].command := cmd_up;
    lookup[22].command := cmd_noop;
    lookup[23].command := cmd_word_advance;
    lookup[24].command := cmd_noop;
    lookup[25].command := cmd_noop;
    lookup[26].command := cmd_noop;
    lookup[27].command := cmd_noop;
    lookup[28].command := cmd_noop;
    lookup[29].command := cmd_noop;
    lookup[30].command := cmd_insert_char;
    lookup[31].command := cmd_noop;
    lookup[ord(' ')].command := cmd_noop;
    lookup[ord('!')].command := cmd_noop;
    lookup[ord('"')].command := cmd_ditto_up;
    lookup[ord('#')].command := cmd_noop;
    lookup[ord('$')].command := cmd_noop;
    lookup[ord('%')].command := cmd_noop;
    lookup[ord('&')].command := cmd_noop;
    lookup[ord('''')].command := cmd_ditto_down;
    lookup[ord('(')].command := cmd_noop;
    lookup[ord(')')].command := cmd_noop;
    lookup[ord('*')].command := cmd_noop;
    lookup[ord('+')].command := cmd_noop;
    lookup[ord(';')].command := cmd_noop;
    lookup[ord('-')].command := cmd_noop;
    lookup[ord('.')].command := cmd_noop;
    lookup[ord('/')].command := cmd_noop;
    for key_code := ord('0') to ord('9') do
      lookup[key_code].command := cmd_noop;
    lookup[ord(':')].command := cmd_noop;
    lookup[ord(';')].command := cmd_noop;
    lookup[ord('<')].command := cmd_noop;
    lookup[ord('=')].command := cmd_noop;
    lookup[ord('>')].command := cmd_noop;
    lookup[ord('?')].command := cmd_noop;
    lookup[ord('@')].command := cmd_noop;
    lookup[ord('A')].command := cmd_prefix_a;
    lookup[ord('B')].command := cmd_prefix_b;
    lookup[ord('C')].command := cmd_prefix_c;
    lookup[ord('D')].command := cmd_prefix_d;
    lookup[ord('E')].command := cmd_prefix_e;
    lookup[ord('F')].command := cmd_prefix_f;
    lookup[ord('G')].command := cmd_get;
    lookup[ord('H')].command := cmd_help;
    lookup[ord('I')].command := cmd_noop;
    lookup[ord('J')].command := cmd_noop;
    lookup[ord('K')].command := cmd_prefix_k;
    lookup[ord('L')].command := cmd_prefix_l;
    lookup[ord('M')].command := cmd_mark;
    lookup[ord('N')].command := cmd_noop;
    lookup[ord('O')].command := cmd_prefix_o;
    lookup[ord('P')].command := cmd_prefix_p;
    lookup[ord('Q')].command := cmd_quit;
    lookup[ord('R')].command := cmd_replace;
    lookup[ord('S')].command := cmd_prefix_s;
    lookup[ord('T')].command := cmd_prefix_t;
    lookup[ord('U')].command := cmd_prefix_u;
    lookup[ord('V')].command := cmd_verify;
    lookup[ord('W')].command := cmd_prefix_w;
    lookup[ord('X')].command := cmd_prefix_x;
    lookup[ord('Y')].command := cmd_noop;
    lookup[ord('Z')].command := cmd_noop;
    lookup[ord('[')].command := cmd_noop;
    lookup[ord('\')].command := cmd_command;
    lookup[ord(']')].command := cmd_noop;
    lookup[ord('^')].command := cmd_noop;
    lookup[ord('_')].command := cmd_noop;
    lookup[ord('`')].command := cmd_noop;
    for key_code := ord('a') to ord('z') do
      lookup[key_code].command := cmd_noop;
    lookup[ord('{')].command := cmd_set_margin_left;
    lookup[ord('|')].command := cmd_noop;
    lookup[ord('}')].command := cmd_set_margin_right;
{#if debug}
    lookup[ord('~')].command := cmd_prefix_tilde;
{#else}
    lookup[ord('~')].command := cmd_noop;
{#endif}
    lookup[127].command := cmd_rubout;
    for key_code := 128 to ord_maxchar do
      lookup[key_code].command := cmd_noop;
    for key_code := -max_special_keys to ord_maxchar do
      begin
      lookup[key_code].code := nil;
      lookup[key_code].tpar := nil;
      end;

    { initialize lookupexp }
    { Ast ( * ) prefix } {start at 1}
    { There aren't any in this table! }

    { A prefix }    {start at 1}
    with lookupexp[  1] do begin extn := 'C'; command := cmd_jump end;
    with lookupexp[  2] do begin extn := 'L'; command := cmd_advance end;
    with lookupexp[  3] do begin extn := 'O'; command := cmd_bridge end;
    with lookupexp[  4] do begin extn := 'P'; command := cmd_advance_paragraph end;
    with lookupexp[  5] do begin extn := 'S'; command := cmd_noop end;
    with lookupexp[  6] do begin extn := 'T'; command := cmd_next end;
    with lookupexp[  7] do begin extn := 'W'; command := cmd_word_advance end;

    { B prefix }    {8}
    with lookupexp[  8] do begin extn := 'B'; command := cmd_noop end;
    with lookupexp[  9] do begin extn := 'C'; command := cmd_noop {cmd_block_copy} end;
    with lookupexp[ 10] do begin extn := 'D'; command := cmd_noop {cmd_block_define} end;
    with lookupexp[ 11] do begin extn := 'I'; command := cmd_noop end;
    with lookupexp[ 12] do begin extn := 'K'; command := cmd_noop end;
    with lookupexp[ 13] do begin extn := 'M'; command := cmd_noop {cmd_block_transfer} end;
    with lookupexp[ 14] do begin extn := 'O'; command := cmd_noop end;

    { C prefix }    {15}
    with lookupexp[ 15] do begin extn := 'C'; command := cmd_insert_char end;
    with lookupexp[ 16] do begin extn := 'L'; command := cmd_insert_line end;

    { D prefix }    {17}
    with lookupexp[ 17] do begin extn := 'C'; command := cmd_delete_char end;
    with lookupexp[ 18] do begin extn := 'L'; command := cmd_delete_line end;
    with lookupexp[ 19] do begin extn := 'P'; command := cmd_delete_paragraph end;
    with lookupexp[ 20] do begin extn := 'S'; command := cmd_noop end;
    with lookupexp[ 21] do begin extn := 'W'; command := cmd_word_delete end;

    { E prefix }    {22}
    with lookupexp[ 22] do begin extn := 'D'; command := cmd_frame_edit end;
    with lookupexp[ 23] do begin extn := 'K'; command := cmd_frame_kill end;
    with lookupexp[ 24] do begin extn := 'O'; command := cmd_prefix_eo end;
    with lookupexp[ 25] do begin extn := 'P'; command := cmd_frame_parameters end;
    with lookupexp[ 26] do begin extn := 'Q'; command := cmd_prefix_eq end;
    with lookupexp[ 27] do begin extn := 'R'; command := cmd_frame_return end;

    { EO prefix }   {28}
    with lookupexp[ 28] do begin extn := 'L'; command := cmd_equal_eol end;
    with lookupexp[ 29] do begin extn := 'F'; command := cmd_equal_eof end;
    with lookupexp[ 30] do begin extn := 'P'; command := cmd_equal_eop end;

    { EQ prefix }   {31}
    with lookupexp[ 31] do begin extn := 'C'; command := cmd_equal_column end;
    with lookupexp[ 32] do begin extn := 'L'; command := cmd_noop end;
    with lookupexp[ 33] do begin extn := 'M'; command := cmd_equal_mark end;
    with lookupexp[ 34] do begin extn := 'S'; command := cmd_equal_string end;

    { F prefix - files }    {35}
    with lookupexp[ 35] do begin extn := 'B'; command := cmd_file_rewind end;
    with lookupexp[ 36] do begin extn := 'E'; command := cmd_file_edit end;
    with lookupexp[ 37] do begin extn := 'G'; command := cmd_prefix_fg end;
    with lookupexp[ 38] do begin extn := 'I'; command := cmd_file_input end;
    with lookupexp[ 39] do begin extn := 'K'; command := cmd_file_kill end;
    with lookupexp[ 40] do begin extn := 'O'; command := cmd_file_output end;
    with lookupexp[ 41] do begin extn := 'P'; command := cmd_page end;
    with lookupexp[ 42] do begin extn := 'S'; command := cmd_noop end;
    with lookupexp[ 43] do begin extn := 'T'; command := cmd_file_table end;
    with lookupexp[ 44] do begin extn := 'X'; command := cmd_file_execute end;

    { FG prefix - global files }    {45}
    with lookupexp[ 45] do begin extn := 'B'; command := cmd_file_global_rewind end;
    with lookupexp[ 46] do begin extn := 'I'; command := cmd_file_global_input end;
    with lookupexp[ 47] do begin extn := 'K'; command := cmd_file_global_kill end;
    with lookupexp[ 48] do begin extn := 'O'; command := cmd_file_global_output end;
    with lookupexp[ 49] do begin extn := 'R'; command := cmd_file_read end;
    with lookupexp[ 50] do begin extn := 'W'; command := cmd_file_write end;

    { I prefix }    {51}
    { There aren't any yet! }

    { K prefix }    {51}
    with lookupexp[ 51] do begin extn := 'B'; command := cmd_backtab end;
    with lookupexp[ 52] do begin extn := 'C'; command := cmd_return end;
    with lookupexp[ 53] do begin extn := 'D'; command := cmd_down end;
    with lookupexp[ 54] do begin extn := 'H'; command := cmd_home end;
    with lookupexp[ 55] do begin extn := 'I'; command := cmd_insert_mode end;
    with lookupexp[ 56] do begin extn := 'L'; command := cmd_left end;
    with lookupexp[ 57] do begin extn := 'M'; command := cmd_user_key end;
    with lookupexp[ 58] do begin extn := 'O'; command := cmd_overtype_mode end;
    with lookupexp[ 59] do begin extn := 'R'; command := cmd_right end;
    with lookupexp[ 60] do begin extn := 'T'; command := cmd_tab end;
    with lookupexp[ 61] do begin extn := 'U'; command := cmd_up end;
    with lookupexp[ 62] do begin extn := 'X'; command := cmd_rubout end;

    { L prefix }    {63}
    with lookupexp[ 63] do begin extn := 'R'; command := cmd_noop end;
    with lookupexp[ 64] do begin extn := 'S'; command := cmd_noop end;

    { O prefix }    {65}
    with lookupexp[ 65] do begin extn := 'P'; command := cmd_user_parent end;
    with lookupexp[ 66] do begin extn := 'S'; command := cmd_user_subprocess end;
    with lookupexp[ 67] do begin extn := 'X'; command := cmd_op_sys_command end;

    { P prefix }    {68}
    with lookupexp[ 68] do begin extn := 'C'; command := cmd_position_column end;
    with lookupexp[ 69] do begin extn := 'L'; command := cmd_position_line end;

    { S prefix }    {70}
    with lookupexp[ 70] do begin extn := 'A'; command := cmd_span_assign end;
    with lookupexp[ 71] do begin extn := 'C'; command := cmd_span_copy end;
    with lookupexp[ 72] do begin extn := 'D'; command := cmd_span_define end;
    with lookupexp[ 73] do begin extn := 'E'; command := cmd_span_execute_no_recompile end;
    with lookupexp[ 74] do begin extn := 'J'; command := cmd_span_jump end;
    with lookupexp[ 75] do begin extn := 'M'; command := cmd_span_transfer end;
    with lookupexp[ 76] do begin extn := 'R'; command := cmd_span_compile end;
    with lookupexp[ 77] do begin extn := 'T'; command := cmd_span_index end;
    with lookupexp[ 78] do begin extn := 'X'; command := cmd_span_execute end;

    { T prefix }    {79}
    with lookupexp[ 79] do begin extn := 'B'; command := cmd_split_line end;
    with lookupexp[ 80] do begin extn := 'C'; command := cmd_prefix_tc end;
    with lookupexp[ 81] do begin extn := 'F'; command := cmd_prefix_tf end;
    with lookupexp[ 82] do begin extn := 'I'; command := cmd_insert_text end;
    with lookupexp[ 83] do begin extn := 'N'; command := cmd_insert_invisible end;
    with lookupexp[ 84] do begin extn := 'O'; command := cmd_overtype_text end;
    with lookupexp[ 85] do begin extn := 'R'; command := cmd_noop end;
    with lookupexp[ 86] do begin extn := 'S'; command := cmd_swap_line end;
    with lookupexp[ 87] do begin extn := 'X'; command := cmd_execute_string end;

    { TC prefix }   {88}
    with lookupexp[ 88] do begin extn := 'E'; command := cmd_case_edit end;
    with lookupexp[ 89] do begin extn := 'L'; command := cmd_case_low end;
    with lookupexp[ 90] do begin extn := 'U'; command := cmd_case_up end;

    { TF prefix }   {91}
    with lookupexp[ 91] do begin extn := 'C'; command := cmd_line_centre end;
    with lookupexp[ 92] do begin extn := 'F'; command := cmd_line_fill end;
    with lookupexp[ 93] do begin extn := 'J'; command := cmd_line_justify end;
    with lookupexp[ 94] do begin extn := 'L'; command := cmd_line_left end;
    with lookupexp[ 95] do begin extn := 'R'; command := cmd_line_right end;
    with lookupexp[ 96] do begin extn := 'S'; command := cmd_line_squash end;

    { U prefix - user keyboard mappings }   {97}
    with lookupexp[ 97] do begin extn := 'C'; command := cmd_user_command_introducer end;

    { W prefix - window commands }  {98}
    with lookupexp[ 98] do begin extn := 'B'; command := cmd_window_backward end;
    with lookupexp[ 99] do begin extn := 'C'; command := cmd_window_middle end;
    with lookupexp[100] do begin extn := 'E'; command := cmd_window_end end;
    with lookupexp[101] do begin extn := 'F'; command := cmd_window_forward end;
    with lookupexp[102] do begin extn := 'H'; command := cmd_window_setheight end;
    with lookupexp[103] do begin extn := 'L'; command := cmd_window_left end;
    with lookupexp[104] do begin extn := 'M'; command := cmd_window_scroll end;
    with lookupexp[105] do begin extn := 'N'; command := cmd_window_new end;
    with lookupexp[106] do begin extn := 'O'; command := cmd_noop end;
    with lookupexp[107] do begin extn := 'R'; command := cmd_window_right end;
    with lookupexp[108] do begin extn := 'S'; command := cmd_noop end;
    with lookupexp[109] do begin extn := 'T'; command := cmd_window_top end;
    with lookupexp[110] do begin extn := 'U'; command := cmd_window_update end;

    { X prefix - exit }             {111}
    with lookupexp[111] do begin extn := 'A'; command := cmd_exit_abort end;
    with lookupexp[112] do begin extn := 'F'; command := cmd_exit_fail end;
    with lookupexp[113] do begin extn := 'S'; command := cmd_exit_success end;

    { Y prefix }        {114}
    { There aren't any in this table! }

    { Z prefix }        {114}
    { There aren't any in this table! }

    { ~ prefix - miscellaneous debugging commands}  {114}
    with lookupexp[114] do begin extn := 'D'; command := cmd_dump end;
    with lookupexp[115] do begin extn := 'V'; command := cmd_validate end;

    { sentinel }                    {116}
    with lookupexp[116] do begin extn := '?'; command := cmd_nosuch end;


    { initialize lookupexp_ptr }
    { These magic numbers point to the start of each section in lookupexp table }
    lookupexp_ptr[cmd_prefix_ast  ] :=   1;
    lookupexp_ptr[cmd_prefix_a    ] :=   1;
    lookupexp_ptr[cmd_prefix_b    ] :=   8;
    lookupexp_ptr[cmd_prefix_c    ] :=  15;
    lookupexp_ptr[cmd_prefix_d    ] :=  17;
    lookupexp_ptr[cmd_prefix_e    ] :=  22;
    lookupexp_ptr[cmd_prefix_eo   ] :=  28;
    lookupexp_ptr[cmd_prefix_eq   ] :=  31;
    lookupexp_ptr[cmd_prefix_f    ] :=  35;
    lookupexp_ptr[cmd_prefix_fg   ] :=  45;
    lookupexp_ptr[cmd_prefix_i    ] :=  51;
    lookupexp_ptr[cmd_prefix_k    ] :=  51;
    lookupexp_ptr[cmd_prefix_l    ] :=  63;
    lookupexp_ptr[cmd_prefix_o    ] :=  65;
    lookupexp_ptr[cmd_prefix_p    ] :=  68;
    lookupexp_ptr[cmd_prefix_s    ] :=  70;
    lookupexp_ptr[cmd_prefix_t    ] :=  79;
    lookupexp_ptr[cmd_prefix_tc   ] :=  88;
    lookupexp_ptr[cmd_prefix_tf   ] :=  91;
    lookupexp_ptr[cmd_prefix_u    ] :=  97;
    lookupexp_ptr[cmd_prefix_w    ] :=  98;
    lookupexp_ptr[cmd_prefix_x    ] := 111;
    lookupexp_ptr[cmd_prefix_y    ] := 114;
    lookupexp_ptr[cmd_prefix_z    ] := 114;
    lookupexp_ptr[cmd_prefix_tilde] := 114;
    lookupexp_ptr[cmd_nosuch      ] := 116;
    end
  end; {load_command_table}


{}function start_up : boolean;

    label 99;
    const
      frame_name_cmd  = 'COMMAND                        ';
      frame_name_oops = 'OOPS                           ';
      frame_name_heap = 'HEAP                           ';
    var
      command             : commands;
      tparam              : tpar_ptr;
      command_line        : file_name_str;
      initial_len         : integer;
{#if unix or turbop}
      i,offset            : integer;
      temp_len            : strlen_range;
{#endif}
{#if turbop}
      temp                : string;
{#elseif unix}
      temp                : str_object;
{#endif}

    begin {start_up}
    start_up := false;

    { Get the command line. }

{#if vms}
    vms_check_status(lib$get_foreign(command_line));
{#elseif unix}
    { Build a command string to pass to file_create_open so it can parse it }
    offset := 1;
    i := 1;
    while (i < argc) and (offset <= file_name_len) do
      begin
      argv(i,temp);
      temp_len := ch_length(temp,file_name_len);
{#if ISO1}
      ch_copy(temp,1,temp_len,command_line,offset,file_name_len-offset+1,' ');
{#else}
      ch_copy_str_fnm(temp,1,temp_len,command_line,offset,file_name_len-offset+1,' ');
{#endif}
      offset := offset + temp_len + 1;
      i := i + 1;
      end;
    if (offset > file_name_len) or (i < argc) then
      begin
      screen_message(msg_parameter_too_long);
      goto 99;
      end;
{#elseif turbop}
    offset := 1;
    i := 1;
    fillchar(command_line[1], sizeof(command_line), ' ');
    while (i <= paramcount) and (offset < file_name_len) do
      begin
      temp := paramstr(i);
      move(temp[1], command_line[offset], length(temp));
      offset := offset + length(temp) + 1;
      i := i + 1;
      end;
    if (offset > file_name_len) or (i < paramcount) then
      begin
      screen_message(msg_parameter_too_long);
      goto 99;
      end;
{#endif}

    { Open the files. }

    if not file_create_open(command_line,parse_command,files[1],files[2]) then
      goto 99;

{#if vms}
    if file_data.space > max_space then file_data.space := max_space;
{#elseif unix}
   { let unix grab whatever it can get! }
{#elseif msdos}
  {memory usage is set at compile time!!!}
{#endif}

    load_command_table(file_data.old_cmds);

    { Try to get started on the terminal.  If this fails assume carry on }
    { in BATCH mode. }

{#if debug_screen}
    if vdu_init(1,
{#else}
    if vdu_init(maxint,
{#endif}
                tt_capabilities,
                terminal_info,
                tt_controlc) then
      begin
      initial_scr_width  := terminal_info.width;
      initial_scr_height := terminal_info.height;
      initial_margin_right := terminal_info.width;
      if trmflags_v_hard in tt_capabilities then
        ludwig_mode := ludwig_hardcopy
      else
        begin
        ludwig_mode := ludwig_screen;
        vdu_new_introducer(command_introducer);
        end;
      end;
    { Set the scr_msg_row as one more than the terminal height (which may  }
    { be zero). This avoids any need for special checks about Ludwig being }
    { in Screen mode before clearing messages.                             }

    scr_msg_row := terminal_info.height+1;

    { Create the three automatically defined frames: OOPS, COMMAND and LUDWIG. }
    { Save pointers to COMMAND & OOPS  frames for use in later frame routines. }

    if not frame_edit(frame_name_oops) then goto 99;
    if not frame_setheight(initial_scr_height,true) then goto 99;
    frame_oops := current_frame; current_frame := nil;
    frame_oops^.space_limit := max_space;     { Big ! }
    frame_oops^.space_left  := max_space-50;  { Big ! - space for <eop> line !! }
    frame_oops^.options := frame_oops^.options + [opt_special_frame];
    if not frame_edit(frame_name_cmd ) then goto 99;
    frame_cmd  := current_frame; current_frame := nil;
    frame_cmd^.options := frame_cmd^.options + [opt_special_frame];
    if not frame_edit(frame_name_heap) then goto 99;
    frame_heap := current_frame; current_frame := nil;
    frame_heap^.options := frame_heap^.options + [opt_special_frame];
    if not frame_edit(default_frame_name) then goto 99;

    if ludwig_mode = ludwig_screen then
      screen_fixup;

    { Load the key definitions. }

    if ludwig_mode = ludwig_screen then
      user_key_initialize;

    { Hook our input and output files into the current frame. }

    with current_frame^ do
      begin
      if files[1] <> nil then
        begin input_file  := 1; files_frames[1] := current_frame; end;
      if files[2] <> nil then
        begin output_file := 2; files_frames[2] := current_frame; end;
      end;

    { Load the input file. }

    if ludwig_mode <> ludwig_batch then
      begin
      screen_message(msg_copyright_and_loading_file);
      if ludwig_mode = ludwig_screen then
        vdu_flush(false);
      end;
    if not file_page(current_frame,exit_abort) then goto 99;
    if ludwig_mode <> ludwig_batch then
      screen_clear_msgs(false);
    if ludwig_mode = ludwig_screen then
      screen_fixup;

    { Execute the user's initialization string. }

    initial_len := ch_length(file_data.initial,max_strlen);
    if initial_len > 0 then
      begin
      if ludwig_mode = ludwig_screen then
        vdu_flush(false);
      new(tparam);
      with tparam^ do
        begin
        len := initial_len;
        dlm := tpd_exact;
        ch_move(file_data.initial,1,str,1,len);
        nxt := nil;
        con := nil;
        end;
      if not execute(cmd_file_execute,none,1,tparam,true) then
        if exit_abort then
          begin
          { something is wrong, but let the user continue anyway! }
          if ludwig_mode <> ludwig_batch then
            screen_beep;
          exit_abort := false;
          end;
      dispose(tparam);
      end;

    { Set the Abort Flag now.  This will suppress spurious start-up messages}
    ludwig_aborted := true;
    start_up := true;
   99:
    end; {start_up}


  begin {ludwig}
{#if vms}
  with exit_ctrl_blk do                               {Fill in exit hnd addr.}
    begin
    exh_addr := iaddress(prog_windup);
    argcnt   := 0;
    new(sts_ptr);
    end;
  vms_check_status(sys$dclexh(exit_ctrl_blk));        {Declare exit handler. }
{#elseif unix or turbop}
  init_signals;
{#endif}
{#if unix}
  value_initializations;
{#endif}
  initialize;            {Stuff VALUE can't do, like creating frames etc.    }
{#if vms}
  establish(bug_handler);
{#endif}
  if start_up then       {Parse command line, get files attached, etc.       }
    begin
    execute_immed;
{#if vms}
    sys$exit(normal_exit);
{#elseif unix}
    exit_handler(0);
    exit(normal_exit);
{#elseif turbop}
    exit_handler(0);
    msdos_exit(normal_exit);
{#endif}
    end;
  if ludwig_aborted then
    begin
{#if vms}
    sys$exit(abnormal_exit);
{#elseif unix}
    exit_handler(0);
    exit(abnormal_exit);
{#elseif turbop}
    exit_handler(0);
    msdos_exit(abnormal_exit);
{#endif}
    end;
  end. {ludwig}
