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
! Name:         OPSYS
!
! Description:  This routine executes a command in a subprocess and
!               transfers the result into the current frame.
!
! Revision History:
! 4-001 Mark R. Prior                                           Apr-1987
!       Original code
! 4-002 Mark R. Prior                                        20-Feb-1988
!       Strings passed to ch routines are now passed using conformant
!         arrays, or as type str_object.
!               string[offset],length -> string,offset,length
!       Where conformant arrays are not implemented and the array is not
!         of type str_object, separate routines are provided for each
!         type.
!--}

{#if vms}
[inherit('sys$library:starlet'),
 ident('4-002'),
 overlaid]
module opsys;
{#elseif turbop}
unit opsys;
{#endif}

{#if turbop}
interface
uses value;
{$I opsys.h}

implementation
uses ch, filesys, line, screen;
{#elseif vms}
%include 'const.inc/nolist'
%include 'type.inc/nolist'
%include 'var.inc/nolist'

%include 'opsys.fwd/nolist'
%include 'ch.ext/nolist'
%include 'filesys.ext/nolist'
%include 'line.ext/nolist'
%include 'screen.ext/nolist'
{#elseif unix}
#include "const.i"
#include "type.i"
#include "var.i"

#include "opsys.h"
#include "ch.h"
#include "filesys.h"
#include "line.h"
#include "screen.h"
{#endif}

{#if vms}
[asynchronous]
{}function lib$spawn (
		command_string : [class_s] packed array [l1..h1:integer] of char
								:= %immed 0;
		input_file : [class_s] packed array [l2..h2:integer] of char
								:= %immed 0;
		output_file : [class_s] packed array [l3..h3:integer] of char
								:= %immed 0;
		flags : unsigned := %immed 0;
		process_name : [class_s] packed array [l5..h5:integer] of char
								:= %immed 0;
	var     process_id : unsigned := %immed 0;
	var     completion_status : integer := %immed 0;
		completion_efn : byte := %immed 0;
	%immed [unbound, asynchronous] procedure completion_astadr
			({%immed} astprm,r0,r1,pc,psl : integer) := %immed 0;
	%immed  completion_astarg : integer := %immed 0;
		prompt : [class_s] packed array [l11..h11:integer] of char
								:= %immed 0;
		cli : [class_s] packed array [l12..h12:integer] of char
								:= %immed 0)
	: integer;  external;
{#endif}

function opsys_command {(
		command    : tpar_object;
	var     first,last : line_ptr;
	var     actual_cnt : integer)
	: boolean};

  label
    98,99;

{#if vms}
  const
    prot     = %B'1111 1111 0000 1111';
{#endif}

  var
{#if vms}
    channel  : word;
    status   : integer;
    buffer   : varying [max_strlen] of char;
    mbxname  : varying [64] of char;
    mbxlen   : integer;
    itemlist : packed record
      length   : word;
      item     : word;
      buffer   : unsigned;
      ret_len  : unsigned;
      end_list : integer
    end;
{#endif}
    mbx      : file_ptr;
    result   : str_object;
    line,
    line_2   : line_ptr;
    outlen   : strlen_range;

  begin
  opsys_command := false;
  first := nil;
  last := nil;
  actual_cnt := 0;
{#if vms}
  status := $crembx(chan  :=channel,
		    maxmsg:=max_strlen,
		    promsk:=prot,
		    lognam:='LUD_MAILBOX');
  if status <> ss$_normal then
    begin
    writev(buffer,'Error creating mailbox : status = ',status:1);
    screen_vms_message(buffer);
    goto 99;
    end;
  with itemlist do
    begin
    length := 64;
    item := dvi$_devnam;
    buffer := iaddress(mbxname.body);
    ret_len := iaddress(mbxname.length);
    end_list := 0
    end;
  $getdvi(chan:=channel,itmlst:=itemlist);
  buffer := substr(command.str,1,command.len);
  status := lib$spawn(command_string:=buffer,output_file:=mbxname,flags:=cli$m_nowait);
  if status <> ss$_normal then
    begin
    writev(buffer,'Error creating subprocess : status = ',status:1);
    screen_vms_message(buffer);
    goto 99;
    end;
{#endif}
  new(mbx);
  with mbx^ do
    begin
    valid       := false;
    first_line  := nil;
    last_line   := nil;
    line_count  := 0;
    output_flag := false;
{#if vms}
    fnm := mbxname;
    fns := mbxname.length;
    with buf_dsc do
      begin
      typ := 512;
      len := 0;
      str := nil;
      end;
    dns := 0;
{#elseif unix}
    if command.len <= file_name_len then
      begin
{#if ISO1}
      ch_move(command.str,1,fnm,1,file_name_len);
{#else}
      ch_move_str_fnm(command.str,1,fnm,1,file_name_len);
{#endif}
      fns := command.len;
      end
    else
      fns := 0;
{#endif}
    zed         := 'Z';
    end;
  if not filesys_create_open(mbx,nil,false) then
    goto 99;
  while not mbx^.eof do
    if filesys_read(mbx,result,outlen) then
      begin
      if not lines_create(1,line,line_2) then goto 98;
      if not line_change_length(line,outlen) then
	begin
	if lines_destroy(line,line_2) then;
	goto 98;
	end;
      if line^.len > 0 then
	ch_copy(result,1,outlen,line^.str^,1,line^.len,' ');
      line^.used  := outlen;
      line^.blink := last;
      if last <> nil then
	last^.flink := line
      else
	first := line;
      last := line;
      actual_cnt := actual_cnt + 1;
      end
    else if not mbx^.eof then { Something terrible has happened! }
      goto 98;
  opsys_command := true;
98:
  if filesys_close(mbx,false,false) then;
99:
  end;

{#if vms or turbop}
end.
{#endif}
