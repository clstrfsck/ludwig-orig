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
! Name:         ARROW
!
! Description:  The arrow key, TAB, and BACKTAB commands.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
!--}

{#if vms}
{##[ident('4-001'),}
{## overlaid]}
{##module arrow;}
{#elseif turbop}
{##unit arrow;}
{#endif}

{#if turbop}
{##interface}
{##uses value;}
{##}
{###<$I arrow.h#>}
{##}
{##implementation}
{##}
{##uses line, mark, screen, text, vduibm;}
{#elseif vms}
{##%include 'const.inc/nolist'}
{##%include 'type.inc/nolist'}
{##%include 'var.inc/nolist'}
{##}
{##%include 'arrow.fwd/nolist'}
{##%include 'line.ext/nolist'}
{##%include 'mark.ext/nolist'}
{##%include 'screen.ext/nolist'}
{##%include 'text.ext/nolist'}
{##%include 'vdu.ext/nolist'}
{##%include 'vdu_vms.ext/nolist'}
{#elseif unix}
#include "const.i"
#include "type.i"
#include "var.i"

#include "arrow.h"
#include "line.h"
#include "mark.h"
#include "screen.h"
#include "text.h"
#include "vdu.h"
{#endif}

function function_arrow {(
		command   : commands;
		rept      : leadparam;
		count     : integer;
		from_span : boolean)
	: boolean};

  label
    1,        { EXITLOOP label. }
    9;        { Exit. }

  var
    key          : key_code_range;
    cmd_status,
    cmd_valid    : boolean;
    step         : integer;
    line_nr      : line_range;
    eop_line_nr  : line_range;
    new_col      : col_width_range;
    dot_col      : col_range;
    dot_line     : line_ptr;
    old_dot,
    new_eql      : mark_object;
    counter      : integer;

  begin {function_arrow}
  cmd_status := false;
  with current_frame^ do
    begin
    old_dot := dot^;
    with last_group^ do
      eop_line_nr := first_line_nr + last_line^.offset_nr;

    repeat
      cmd_valid := false;
      if command in [cmd_return, cmd_home, cmd_tab, cmd_backtab,
		     cmd_left, cmd_right, cmd_down, cmd_up] then
	case command of

	  cmd_return:
	    begin
	    cmd_valid := true;
	    new_eql := dot^;
	    with dot^ do begin dot_line := line; dot_col  := col; end;
	    for counter := 1 to count do
	      begin
	      if tt_controlc then goto 9;
	      if dot_line^.flink = nil then
		begin
		if not text_realize_null(dot_line) then goto 9;
		eop_line_nr := eop_line_nr+1;
		dot_line := dot_line^.blink;
		if counter = 1 then new_eql.line := dot_line;
		end;
	      dot_col  := text_return_col(dot_line,dot_col,false);
	      dot_line := dot_line^.flink;
	      end;
	    if not mark_create(dot_line,dot_col,dot) then goto 9;
	    end;

	  cmd_home:
	    begin
	    cmd_valid := true;
	    new_eql := dot^;
	    if current_frame = scr_frame then
	      if not mark_create(scr_top_line,scr_offset+1,dot) then goto 9;
	    end;

	  cmd_tab, cmd_backtab:
	    begin
	    new_col := dot^.col;
	    if command = cmd_tab then
	      begin
	      if new_col = max_strlenp then goto 1;
	      step := 1;
	      end
	    else
	      step := -1;
	    for counter := 1 to count do
	      begin
	      repeat
		new_col := new_col+step;
	      until (tab_stops[new_col]     or
		    (new_col = margin_left) or
		    (new_col = margin_right) );
	      if (new_col = 0) or (new_col = max_strlenp) then goto 1;
	      end;
	    cmd_valid := true;
	    new_eql := dot^;
	    dot^.col := new_col;
	    1:
	    end;

	  cmd_left:
	    with dot^ do
	      begin
	      case rept of
		none, plus, pint:
		  if col-count >= 1 then
		    begin
		    cmd_valid := true;
		    new_eql := dot^;
		    col := col-count;
		    end;
		pindef:
		  if col >= margin_left then
		    begin
		    cmd_valid := true;
		    new_eql := dot^;
		    col := margin_left;
		    end;
	      end{case};
	      end;

	  cmd_right:
	    with dot^ do
	      begin
	      case rept of
		none, plus, pint:
		  if col+count <= max_strlenp then
		    begin
		    cmd_valid := true;
		    new_eql := dot^;
		    col := col+count;
		    end;
		pindef:
		  if col <= margin_right then
		    begin
		    cmd_valid := true;
		    new_eql := dot^;
		    col := margin_right;
		    end;
	      end{case};
	      end;

	  cmd_down:
	    begin
	    dot_line := dot^.line;
	    if not line_to_number(dot_line,line_nr) then goto 9;
	    case rept of
	      none, plus, pint:
		if line_nr+count <= eop_line_nr then
		  begin
		  cmd_valid := true;
		  new_eql := dot^;
		  if count < max_grouplines div 2 then
		    for counter := 1 to count do dot_line := dot_line^.flink
		  else
		    if not line_from_number(current_frame,line_nr+count,
							dot_line) then goto 9;
		  end;
	      pindef:
		  begin
		  cmd_valid := true;
		  new_eql := dot^;
		  dot_line := last_group^.last_line;
		  end;
	    end{case};
	    if not mark_create(dot_line,dot^.col,dot) then goto 9;
	    end;

	  cmd_up:
	    begin
	    dot_line := dot^.line;
	    if not line_to_number(dot_line,line_nr) then goto 9;
	    case rept of
	      none, plus, pint:
		if line_nr-count > 0 then
		  begin
		  cmd_valid := true;
		  new_eql := dot^;
		  if count < max_grouplines div 2 then
		    for counter := 1 to count do dot_line := dot_line^.blink
		  else
		    if not line_from_number(current_frame,line_nr-count,
							  dot_line) then goto 9;
		  end;
	      pindef:
		begin
		cmd_valid := true;
		new_eql := dot^;
		dot_line := first_group^.first_line;
		end;
	    end{case};
	    if not mark_create(dot_line,dot^.col,dot) then goto 9;
	    end;
	end{case}
      else
	begin
	vdu_take_back_key(key);
	goto 9;
	end;

      if cmd_valid then
	cmd_status := true;
      if from_span then goto 9;
      screen_fixup;
      if not cmd_valid  or
	 ((command = cmd_down) and (rept <> pindef) and
				   (dot^.line^.flink = nil)) then
	vdu_beep;
      key := vdu_get_key;
      if tt_controlc then goto 9;
      rept    := none;
      count   := 1;
      command := lookup[key].command;
      if (command = cmd_return) and (edit_mode = mode_insert) then
	command := cmd_split_line;
    until false;

  9:if tt_controlc then
      begin
      if mark_create(old_dot.line,old_dot.col,dot) then ;
      end
    else
      begin
      { Define Equals. }
      if cmd_status then
	begin
	if not mark_create(new_eql.line,new_eql.col,marks[mark_equals]) then ;
	if (command = cmd_down) and (rept <> pindef) and
				    (dot^.line^.flink = nil) then
	  cmd_status := false;
	end;
      end;
    function_arrow := cmd_status or not from_span;
    end;
  end; {arrow}

{#if vms or turbop}
{##end.}
{#endif}
