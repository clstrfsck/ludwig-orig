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
! Name:         BUG
!
! Description:  Generate BUG_CHECK messages, attempt to recover,
!               organize controlled shutdown if can't recover.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Mark R. Prior                                        22-Jun-1987
!       Version 4.1 developments incorporated into main source code.
!       . Replace the tt_width and tt_height parameters of vdu_init by
!         terminal_info.
!--}

{#if vms}
[ident('4-002'),
 overlaid]
module bug (output);

%include 'const.inc/nolist'
%include 'sigdef.inc/nolist'
%include 'type.inc/nolist'
%include 'var.inc/nolist'

%include 'bug.fwd/nolist'
%include 'screen.ext/nolist'
%include 'vdu.ext/nolist'
%include 'vms.ext/nolist'

function bug_handler {(
	var     sa : vms_sigargs;
	var     ma : vms_mchargs)
	: vms_status_code};

  {   THIS ROUTINE IS HIGHLY VMS DEPENDENT. }
  {Condition Handler, catches signals, tries to output the message and to    }
  {recover from the problem.                                                 }
  label 99;
  var
    sts      : vms_status_code;
    severity : integer;
    facility : integer;
{#if debug}
    buffer   : str_object;
    buflen   : strlen_range;
    old_scrf : frame_ptr;
{#endif}

{ This is a modified version of the definition of $PUTMSG from STARLET.
! The chief modification is to make ACTRTN a function so that $PUTMSG
! can be told not to write the messages to SYS$ERROR.
}
[ASYNCHRONOUS] FUNCTION sys$PUTMSG (
	%REF MSGVEC : [UNSAFE] ARRAY [$l1..$u1:INTEGER] OF BYTE;
	%IMMED [UNBOUND] function ACTRTN
	  (message : [class_s] packed array [l1..h1:integer] of char) : boolean
							:= %IMMED 0;
	FACNAM : [CLASS_S] PACKED ARRAY [$l3..$u3:INTEGER] OF CHAR := %IMMED 0;
	%IMMED ACTPRM : UNSIGNED := %IMMED 0) : INTEGER; EXTERNAL;

  procedure lib$stop (
      %immed  status : vms_status_code);
    external;

  begin {bug_handler}
  with sa,ma do
    begin
    bug_handler := ss$_resignal;              { Resignal errors by default.  }
    if  (chf$l_sig_name <> ss$_debug)         { Don't handle DEBUG, UNWIND   }
    and (chf$l_sig_name <> ss$_unwind)        { requests.                    }
    then
      begin
      facility := chf$l_sig_name div 65536 mod 4096;
      if facility <> system$_facility then
	chf$l_sig_args := chf$l_sig_args-2;   { Drop the PC, PSL pair.       }
      sys$putmsg(sa, screen_vms_message);
      if facility <> system$_facility then
	chf$l_sig_args := chf$l_sig_args+2;   { Restore the PC, PSL pair.    }
      severity := chf$l_sig_name mod 8;
      if not odd(severity)                    { If not -S- or -I- message    }
	 and (facility <> cli$_facility) then
	begin
{#if debug}
	{Organize a traceback if the user wants one.}
	if ludwig_mode = ludwig_screen then
	  begin
	  vdu_movecurs(1,1);
	  vdu_get_input(' : Traceback (Y or N)? ',23,buffer,1,buflen);
	  if  (buflen > 0)
	  and ((buffer[1] = 'Y') or (buffer[1] = 'y'))
	  then
	    begin
	    ludwig_mode := ludwig_hardcopy;
	    old_scrf := scr_frame;  scr_frame := nil;
	    vdu_free;
	    vms_trace_back(sa,ma);
	    screen_writeln;
	    screen_getlinep('Press RETURN to continue: ',26,buffer,buflen,1,1);
{#if debug_screen}
	    if vdu_init(1,
{#else}
	    if vdu_init(maxint,
{#endif}
			tt_capabilities,
			terminal_info,
			tt_controlc) then ;
	    vdu_new_introducer(command_introducer);
	    scr_frame := old_scrf;
	    ludwig_mode := ludwig_screen;
	    end;
	  if scr_frame <> nil then screen_redraw else vdu_clearscr;
	  end
	else
	  begin
	  if chf$l_sig_name <> ss$_accvio then    { Restore the PC PSL stuff.}
	    chf$l_sig_args := chf$l_sig_args+2;
	      vms_trace_back(sa,ma);
	  end;
{#endif}
	if severity <> 0 {warning} then
	  begin
	  chf$l_mch_savr0 := 0;               { Force the failing function   }
	  chf$l_mch_savr1 := 0;               { to return 0 or NIL.          }
	  sts := sys$unwind(1,0);             { Unwind to failing routine's  }
	  if not odd(sts) then lib$stop(sts); { caller.                      }
	  end;
	end;
      bug_handler := ss$_continue;            { Bug_Handler handled the cnd. }
      end;
    end;
 99:
  end; {bug_handler}

end.
{#else}
***** This file is not relevant to this operating system.
{#endif}
