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
! Name:         QUIT
!
! Description:  Quit Ludwig
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Kelvin B. Nicolle                                    26-Aug-1988
!       The EXEC module is too big for the Multimax pc compiler.  Move
!       the code for the quit command to the QUIT module.
! 4-003 John Warburton                                       11-May-1989
!       Modified the quit_command function to take into account the new option
!       that will alert the user if any frame has been modified and not saved.
!       Useful for those people using the -M option
!--}

{#if vms}
{##[ident('4-002'),}
{## overlaid]}
{##module quit (output);}
{#endif}

{#if vms}
{##%include 'const.inc/nolist'}
{##%include 'type.inc/nolist'}
{##%include 'var.inc/nolist'}
{##}
{##%include 'quit.fwd/nolist'}
{##%include 'file.ext/nolist'}
{##%include 'mark.ext/nolist'}
{##%include 'screen.ext/nolist'}
{##%include 'vdu.ext/nolist'}
{##%include 'vms.ext/nolist'}
{#elseif unix}
#include "const.i"
#include "type.i"
#include "var.i"

#include "quit.h"
#include "file.h"
#include "mark.h"
#include "screen.h"
#include "vdu.h"
#include "unix.h"
{#endif}


function quit_command {:boolean};

  label 2, 99;
  var
    new_span : span_ptr;

  begin {quit_command}
  quit_command := false;
  with current_frame^ do
    begin
    if ludwig_mode <> ludwig_batch then
      begin
      new_span := first_span;
      while new_span <> nil do
	begin
	if (new_span^.frame <> nil) then
	  if (new_span^.frame <> frame_oops) and (new_span^.frame <> frame_heap) and (new_span^.frame <> frame_cmd) then
	    with new_span^.frame^ do
	     if opt_save_frame in options then
	      if text_modified and (output_file=0) then
		begin
		current_frame := new_span^.frame;
		with marks[mark_modified]^ do
		  if not mark_create(line,col,dot) then ;
		if ludwig_mode = ludwig_screen then screen_fixup;
		screen_beep;
		case screen_verify(
	    'This frame has no output file--are you sure you want to QUIT? '
				   ,62) of
		  verify_reply_yes :
		    ;
		  verify_reply_always :
		    goto 2;
		  verify_reply_no,
		  verify_reply_quit :
		    begin
		    exit_abort := true;
		    goto 99;
		    end;
		end{case};
		end
	      else
	      if text_modified and (output_file=0) and (input_file <> 0) then
	       begin
		current_frame := new_span^.frame;
		with marks[mark_modified]^ do
		  if not mark_create(line,col,dot) then ;
		if ludwig_mode = ludwig_screen then screen_fixup;
		screen_beep;
		case screen_verify(
	    'This frame has no output file--are you sure you want to QUIT? '
				   ,62) of
		  verify_reply_yes :
		    ;
		  verify_reply_always :
		    goto 2;
		  verify_reply_no,
		  verify_reply_quit :
		    begin
		    exit_abort := true;
		    goto 99;
		    end;
		end{case};
		end;


	  new_span := new_span^.flink;
	end;
      end;
2:  screen_unload;
    if ludwig_mode <> ludwig_batch then screen_message(msg_quitting);
    if ludwig_mode = ludwig_screen then vdu_flush(false);
    ludwig_aborted := false;
    quit;
{#if vms}
{##    sys$exit(normal_exit);}
{#elseif unix}
    exit_handler(0);
    exit(normal_exit);
{#endif}
    end;
99:
  end; {quit_command}


procedure quit{};

  label 99;
  var
    next_span  : span_ptr;
    next_frame : frame_ptr;
    file_index : file_range;

  function do_frame (f:frame_ptr) : boolean;

    label 99;

    begin {do_frame}
    with f^ do
      begin
      do_frame := true;
      if output_file = 0 then goto 99;
      if files[output_file] = nil then goto 99;
      do_frame := false;
      {Wind out and close the associated input file.}
      if not file_windthru(f,true) then
	goto 99;
      if input_file <> 0 then
	if files[input_file] <> nil then
	  begin
	  if not file_close_delete(files[input_file],false,true) then goto 99;
	  input_file := 0;
	  end;
      {Close the output file.}
      if not ludwig_aborted then
	do_frame := file_close_delete(files[output_file],not text_modified,text_modified)
      else
	do_frame := true;
      output_file := 0;
      end;
   99:
    end {do_frame};

  begin {quit}

  { THIS ROUTINE DOES BOTH THE NORMAL "Q" COMMAND, AND ALSO IS CALLED AS PART}
  { OF THE LUDWIG "PROG_WINDUP" SEQUENCE.  THUS BY TYPING "^Y EXIT" USERS MAY}
  { SAFELY ABORT LUDWIG AND NOT LOSE ANY FILES.                              }
  next_span := first_span;
  while next_span <> nil do
    begin
    next_frame := next_span^.frame;
    if next_frame <> nil then
      if not do_frame(next_frame) then goto 99;
    next_span := next_span^.flink;
    end;
  { Close all remaining files. }
  if not ludwig_aborted then
  for file_index := 1 to max_files do
    begin
    if files[file_index] <> nil then
      if not file_close_delete(files[file_index],false,true) then goto 99;
    end;
 99:
  { Now free up the VDU, thus re-setting anything we have changed }
  if not vdu_free_flag then   { Has it been called already? }
    begin
    vdu_free;
    vdu_free_flag := true;    { Well it has now }
    ludwig_mode := ludwig_batch;
    end;
  if ludwig_aborted then
    begin
    screen_message(msg_not_renamed);
    screen_message(msg_abort);
    end;
  end; {quit}

{#if vms}
{##end.}
{#endif}
