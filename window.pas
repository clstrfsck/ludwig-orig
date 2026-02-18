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
! Name:         WINDOW
!
! Description:  Implement the window commands.
!
! Revision History:
! 4-001 Kelvin B. Nicolle                                    30-Sep-1988
!       The EXEC module is too big for the Multimax pc compiler.  Move
!       the code for the window commands to a new module.
!--}

{#if vms}
{##[ident('4-001'),}
{## overlaid]}
{##module window;}
{#elseif turbop}
unit window;
{#endif}

{#if turbop}
interface
uses value;
{$I window.h}

implementation
uses frame, line, mark, screen, vduibm;
{#elseif vms}
{##%include 'const.inc/nolist'}
{##%include 'type.inc/nolist'}
{##%include 'var.inc/nolist'}
{##}
{##%include 'window.fwd/nolist'}
{##%include 'frame.ext/nolist'}
{##%include 'line.ext/nolist'}
{##%include 'mark.ext/nolist'}
{##%include 'screen.ext/nolist'}
{##%include 'vdu.ext/nolist'}
{##%include 'vdu_vms.ext/nolist'}
{#elseif unix}
#include "const.i"
#include "type.i"
#include "var.i"

#include "window.h"
#include "frame.h"
#include "line.h"
#include "mark.h"
#include "screen.h"
#include "vdu.h"
{#endif}


function window_command {(
		command   : commands;
		rept      : leadparam;
		count     : integer;
		tparam    : tpar_ptr;
		from_span : boolean)
	: boolean};

  label 99;
  var
    cmd_success    : boolean;
    new_line       : line_ptr;
    key            : key_code_range;
    i              : integer;
    line_nr,
    line2_nr,
    line3_nr       : line_range;

  begin {window_command}
  cmd_success := false;

  with current_frame^,dot^ do
    begin
    case command of

      cmd_window_backward:
	begin
	if not line_to_number(line,line_nr) then goto 99;
	if line_nr <= scr_height*count then
	  begin
	  if mark_create(first_group^.first_line,col,dot) then ;
	  end
	else
	  begin
	  new_line := line;
	  for i := 1 to scr_height*count do
	    new_line := new_line^.blink;
	  if count = 1 then
	    begin
	    with line^ do
	      if scr_row_nr <> 0 then
		if scr_row_nr > scr_height - margin_bottom then
		  screen_scroll(-2*scr_height+scr_row_nr+margin_bottom,true)
		else
		  screen_scroll(-scr_height,true);
	    end
	  else
	    screen_unload;
	  if not mark_create(new_line,col,dot) then ;
	  end;
	cmd_success := true;
	end;

      cmd_window_end:
	cmd_success := mark_create(last_group^.last_line,col,dot);

      cmd_window_forward:
	begin
	if not line_to_number(line,line_nr) then goto 99;
	with last_group^ do
	  if line_nr+scr_height*count > first_line_nr+last_line^.offset_nr then
	    begin
	    if mark_create(last_line,col,dot) then ;
	    end
	  else
	    begin
	    new_line := line;
	    for i := 1 to scr_height*count do
	      new_line := new_line^.flink;
	    if count = 1 then
	      begin
	      with line^ do
		if scr_row_nr <> 0 then
		  if scr_row_nr <= margin_top then
		    screen_scroll(scr_height+scr_row_nr-margin_top-1,true)
		  else
		    screen_scroll(scr_height,true);
	      end
	    else
	      screen_unload;
	    if not mark_create(new_line,col,dot) then ;
	    end;
	cmd_success := true;
	end;

      cmd_window_left:
	begin
	cmd_success := true;
	if scr_frame = current_frame then
	  begin
	  if rept = none then count := scr_width div 2;
	  if scr_offset < count then count := scr_offset;
	  screen_slide(-count);
	  if scr_offset+scr_width < col then col := scr_offset+scr_width;
	  end;
	end;

      cmd_window_middle:
	begin
	cmd_success := true;
	if scr_frame = current_frame then
	if line_to_number(line,line_nr)   and
	   line_to_number(scr_top_line,line2_nr) and
	   line_to_number(scr_bot_line,line3_nr)
	then
	  screen_scroll(line_nr-((line2_nr+line3_nr) div 2) ,true);
	end;

      cmd_window_new:
	begin
	cmd_success := true;
	screen_redraw;
	end;

      cmd_window_right:
	begin
	cmd_success := true;
	if scr_frame = current_frame then
	  begin
	  if rept = none then count := scr_width div 2;
	  if max_strlenp < (scr_offset+scr_width)+count then
	    count := max_strlenp-(scr_offset+scr_width);
	  screen_slide(count);
	  if col <= scr_offset then col := scr_offset+1;
	  end;
	end;

      cmd_window_scroll:
	begin
	cmd_success := true;
	if current_frame = scr_frame then
	  begin
	  repeat
	    if rept = pindef then
	      begin
	      count := line^.scr_row_nr-1;
	      if count < 0 then count := 0;
	      end
	    else
	    if rept = nindef then
	      begin
	      count := line^.scr_row_nr - scr_height;
	      end;
	    if rept <> none then screen_scroll(count,true);
	    key := 0;

	    { If the dot is still visible and the command is interactive }
	    { then support stay-behind mode. }
	    if  (not from_span)
	    and (line^.scr_row_nr <> 0)
	    and (scr_offset < col )
	    and (col <= scr_offset+scr_width)
	    then
	      begin
	      if not cmd_success then
		begin
		vdu_beep;
		cmd_success := true;
		end;
	      vdu_movecurs(col-scr_offset,line^.scr_row_nr);
	      key := vdu_get_key;
	      if tt_controlc then
		key := 0
	      else
		if lookup[key].command = cmd_up then
		  begin rept := pint; count :=  1; end
		else if lookup[key].command = cmd_down then
		  begin rept := nint; count := -1; end
		else begin vdu_take_back_key(key); key := 0; end;
	    end;
	  until key = 0;
	  end;
	end;

      cmd_window_setheight:
	begin
	if rept = none then count := terminal_info.height;
	cmd_success := frame_setheight(count,false);
	end;

      cmd_window_top:
	cmd_success := mark_create(first_group^.first_line,col,dot);

      cmd_window_update:
	begin
	cmd_success := true;
	if ludwig_mode = ludwig_screen then
	  screen_fixup;
	end;

    end{case};
    end{with};
99:
  window_command := cmd_success;
  end; {window_command}

{#if vms or turbop}
{##end.}
{#endif}
