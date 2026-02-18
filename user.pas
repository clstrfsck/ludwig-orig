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
! Name:         USER
!
! Description:  The user commands (UC, UK, UP, US, and UU).
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Jeff Blows                                           28-Jun-1989
!       Added Page-up and Page-down to the predefined list of key names.
!--}

{#if vms}
[ident('4-001'),
 overlaid]
module user (output);
{#elseif turbop}
unit user;
{#endif}

{#if turbop}
interface
uses value;
{$I user.h}

implementation
uses code, mark, screen, span, text, tpar, vduibm, msdos;
{#elseif vms}
%include 'const.inc/nolist'
%include 'type.inc/nolist'
%include 'var.inc/nolist'

%include 'user.fwd/nolist'
%include 'code.ext/nolist'
%include 'mark.ext/nolist'
%include 'screen.ext/nolist'
%include 'span.ext/nolist'
%include 'text.ext/nolist'
%include 'tpar.ext/nolist'
%include 'vdu_vms.ext/nolist'
%include 'vms.ext/nolist'
{#elseif unix}
#include "const.i"
#include "type.i"
#include "var.i"

#include "user.h"
#include "code.h"
#include "mark.h"
#include "screen.h"
#include "span.h"
#include "text.h"
#include "tpar.h"
#include "vdu.h"
#include "unix.h"
{#endif}


function user_key_code_to_name {(
		key_code : key_code_range;
	var     key_name : key_name_str)
	: boolean};

  var
    i : integer;

  begin {user_key_code_to_name}
  user_key_code_to_name := false;
  key_name_list_ptr^[0].key_code := key_code;
  i := nr_key_names;
  while key_name_list_ptr^[i].key_code <> key_code do
    i := i - 1;
  if i <> 0 then
    begin
    key_name := key_name_list_ptr^[i].key_name;
    user_key_code_to_name := true;
    end;
  end; {user_key_code_to_name}


function user_key_name_to_code {(
		key_name : key_name_str;
	var     key_code : key_code_range)
	: boolean};

  var
    i : integer;

  begin {user_key_name_to_code}
  user_key_name_to_code := false;
  key_name_list_ptr^[0].key_name := key_name;
  i := nr_key_names;
  while key_name_list_ptr^[i].key_name <> key_name do
    i := i - 1;
  if i <> 0 then
    begin
    key_code := key_name_list_ptr^[i].key_code;
    user_key_name_to_code := true;
    end;
  end; {user_key_name_to_code}



procedure user_key_initialize{};

  { WARNING - A value of 40 for key_name_len is assumed here }

  var
    key_code : key_code_range;
    tpar : tpar_ptr;

  begin {user_key_initialize}
  { Initialize terminal-defined key map table. }
  vdu_keyboard_init(nr_key_names,key_name_list_ptr,key_introducers,terminal_info);
  if user_key_name_to_code('UP-ARROW                                ',key_code) then
    lookup[key_code].command := cmd_up;
  if user_key_name_to_code('DOWN-ARROW                              ',key_code) then
    lookup[key_code].command := cmd_down;
  if user_key_name_to_code('RIGHT-ARROW                             ',key_code) then
    lookup[key_code].command := cmd_right;
  if user_key_name_to_code('LEFT-ARROW                              ',key_code) then
    lookup[key_code].command := cmd_left;
  if user_key_name_to_code('HOME                                    ',key_code) then
    lookup[key_code].command := cmd_home;
  if user_key_name_to_code('BACK-TAB                                ',key_code) then
    lookup[key_code].command := cmd_backtab;
  if user_key_name_to_code('INSERT-CHAR                             ',key_code) then
    lookup[key_code].command := cmd_insert_char;
  if user_key_name_to_code('DELETE-CHAR                             ',key_code) then
    lookup[key_code].command := cmd_delete_char;
  if user_key_name_to_code('INSERT-LINE                             ',key_code) then
    lookup[key_code].command := cmd_insert_line;
  if user_key_name_to_code('DELETE-LINE                             ',key_code) then
    lookup[key_code].command := cmd_delete_line;
  if user_key_name_to_code('HELP                                    ',key_code) then
    begin
    lookup[key_code].command := cmd_help;
    new(tpar);
    with tpar^ do
      begin
      dlm := tpd_prompt;
      len := 0;
{#if turbop}
      fillchar(str[1], sizeof(str), ' ');
{#else}
      str := '  ';
{#endif}
      con := nil;
      nxt := nil;
      end;
    lookup[key_code].tpar := tpar;
    end;
  if user_key_name_to_code('FIND                                    ',key_code) then
    begin
    lookup[key_code].command := cmd_get;
    new(tpar);
    with tpar^ do
      begin
      dlm := tpd_prompt;
      len := 0;
{#if turbop}
      fillchar(str[1], sizeof(str), ' ');
{#else}
      str := '  ';
{#endif}
      con := nil;
      nxt := nil;
      end;
    lookup[key_code].tpar := tpar;
    end;
  if user_key_name_to_code('PREV-SCREEN                             ',key_code) then
    lookup[key_code].command := cmd_window_backward;
  if user_key_name_to_code('NEXT-SCREEN                             ',key_code) then
    lookup[key_code].command := cmd_window_forward;
  if user_key_name_to_code('PAGE-UP                                 ',key_code) then
    lookup[key_code].command := cmd_window_backward;
  if user_key_name_to_code('PAGE-DOWN                               ',key_code) then
    lookup[key_code].command := cmd_window_forward;
  end; {user_key_initialize}


function user_command_introducer {
	: boolean};

  var
    temp : str_object;
    cmd_success : boolean;

  begin {user_command_introducer}
  if not (command_introducer in printable_set) then
    begin
    screen_message(msg_nonprintable_introducer);
    cmd_success := false;
    end
  else
    begin
    { enter command introducer into text in correct keyboard mode}
    temp[1] := chr(command_introducer);
    with current_frame^ do
      begin
      case edit_mode of
	mode_insert :
	  cmd_success := text_insert(true,1,temp,1,dot);
	mode_command :
	  if previous_mode = mode_insert then
	    cmd_success := text_insert(true,1,temp,1,dot)
	  else
	    cmd_success := text_overtype(true,1,temp,1,dot);
	mode_overtype :
	  cmd_success := text_overtype(true,1,temp,1,dot);
      end{case};
      if cmd_success then
	begin
	text_modified := true;
	if not mark_create(dot^.line,dot^.col,marks[mark_modified]) then
	  cmd_success := false;
	end;
      end;
    end;
  user_command_introducer := cmd_success;
  end; {user_command_introducer}

function user_key {(
		key    : tpar_object;
		strng  : tpar_object)
	: boolean};

  label
    98,99;

  var
    i : integer;
    key_span, old_span : span_ptr;
    key_code : key_code_range;
    key_name : key_name_str;

  begin {user_key}
  user_key := false;
  if key.len = 1 then
    key_code := ord(key.str[1])
  else
    begin
    for i := 1 to key_name_len do
      key_name[i] := ' ';
    if key.len > key_name_len then
      begin
      key.len := key_name_len;
      screen_message(msg_key_name_truncated);
      end;
    for i := 1 to key.len do
      key_name[i] := key.str[i];
    if not user_key_name_to_code(key_name,key_code) then
      begin
      screen_message(msg_unrecognized_key_name);
      goto 99;
      end;
    end;
  {Create a span in frame "HEAP"}
  with frame_heap^ do
    begin
    if not mark_create(last_group^.last_line, 1, span^.mark_two) then
      goto 99;
    if not span_create(blank_frame_name, span^.mark_two, span^.mark_two) then
      goto 99;
    end;
  if span_find(blank_frame_name, key_span, old_span) then
    begin
    if not text_insert_tpar(strng, key_span^.mark_two, key_span^.mark_one) then
      goto 98;
    if not code_compile(key_span^,true) then
      goto 98;
    {discard code_ptr, if it exists, NOW!}
    if lookup[key_code].code <> nil then code_discard(lookup[key_code].code);
    if lookup[key_code].tpar <> nil then
      begin
      tpar_clean_object(lookup[key_code].tpar^);
      dispose(lookup[key_code].tpar);
      lookup[key_code].tpar := nil;
      end;
    with key_span^ do
      if     (code^.len = 2)
	 and (compiler_code[code^.code].rep = none)
	 and not (compiler_code[code^.code].op
		    in [cmd_verify,cmd_exit_abort..cmd_exit_success]) then
	 { simple command, put directly into lookup table. }
	begin
	lookup[key_code].command := compiler_code[code^.code].op;
	lookup[key_code].tpar := compiler_code[code^.code].tpar;
	compiler_code[code^.code].tpar := nil;
	end
      else
	begin
	lookup[key_code].command := cmd_extended;
	lookup[key_code].code := code;
	code := nil;
	end;
    user_key := true;
98:
    if not span_destroy(key_span) then
      {*** OOPS ***};
    end;
99:
  end; {user_key}

function user_parent {
	: boolean};

  begin {user_parent}
{#if vms}
  user_parent := vms_attach_parent;
{#elseif unix}
  user_parent := unix_suspend;
{#endif}
  end; {user_parent}

function user_subprocess {
	: boolean};

  begin {user_subprocess}
{#if vms}
  user_subprocess := vms_subprocess;
{#elseif unix}
  user_subprocess := unix_shell;
{#endif}
  end; {user_subprocess}

function user_undo {
	: boolean};

  begin {user_undo}
  user_undo := false;
  screen_message(msg_not_implemented);
  end; {user_undo}

{#if vms or turbop}
end.
{#endif}
