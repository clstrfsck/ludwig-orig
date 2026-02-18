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
! Name:         NEXTBRIDGE
!
! Description:  The NEXT and BRIDGE commands.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Jeff Blows                                           15-May-1987
!       Add conditional code to bypass a compiler problem on the Unity.
!--}

{#if vms}
[ident('4-001'),
 overlaid]
module nextbridge (output);
{#elseif turbop}
unit nextbridge_module;
{#endif}

{#if turbop}
interface
uses value;
{$I nextbrid.h}

implementation
uses mark;
{#elseif vms}
%include 'const.inc/nolist'
%include 'type.inc/nolist'
%include 'var.inc/nolist'

%include 'nextbridge.fwd/nolist'
%include 'mark.ext/nolist'
{#elseif unix}
#include "const.i"
#include "type.i"
#include "var.i"

#include "nextbridge.h"
#include "mark.h"
{#endif}


function nextbridge {(
		rept      : leadparam;
		count     : integer;
		tpar      : tpar_object;
		bridge    : boolean)
	: boolean};

  label 1,2,99;
  var
    i        : integer;
    new_col  : integer;
    new_line : line_ptr;
    ch1,ch2  : char;
    chars    : set of char;

  begin {nextbridge}
  nextbridge := false;
  chars := [];
  { Form the character set. }
  with tpar do
    begin
    i := 1;
    while i <= len do
      begin
      ch1 := str[i]; ch2 := ch1; i := i+1;
      if i+2 <= len then
	if (str[i] = '.') and (str[i+1] = '.') then
	  begin ch2 := str[i+2]; i := i+3; end;
      chars := chars+[ch1..ch2];
      end;
    end;
{#if unity }
  ch1 := chr(0);
  ch2 := chr(ord_maxchar);
  if bridge then chars := [ch1..ch2]-chars;
{#else }
  if bridge then chars := [chr(0)..chr(ord_maxchar)]-chars;
{#endif }
  { Search for a character in the set. }
  with current_frame^ do
    begin
    new_line := dot^.line;
    if count > 0 then
      begin
      new_col := dot^.col;
      if not bridge then new_col := new_col+1;
      repeat
	while new_line <> nil do
	  with new_line^ do
	    begin
	    i := new_col;
	    while i <= used do
	      begin
	      if str^[i] in chars then
		begin
		new_col := i;
		goto 1;
		end;
	      i := i+1;
	      end;
	    if ' ' in chars then              { Match a space at EOL. }
	    if i = used+1 then
	      begin
	      new_col := i;
	      goto 1;
	      end;
	    new_line := flink;
	    new_col := 1;
	    end;
	goto 99;
      1:
	new_col := new_col+1;
	count := count-1;
      until count=0;
      new_col := new_col-1;
      if not mark_create(dot^.line,dot^.col,marks[mark_equals]) then
	goto 99;
      end
    else
    if count < 0 then
      begin
      new_col := dot^.col-1;
      if not bridge then new_col := new_col-1;
      repeat
	while new_line <> nil do
	  with new_line^ do
	    begin
	    if used < new_col then
	      begin
	      if ' ' in chars then goto 2;
	      new_col := used;
	      end;
	    for i := new_col downto 1 do
	      if str^[i] in chars then
		begin
		new_col := i;
		goto 2;
		end;
	    if blink <> nil then
	      begin
	      new_line := blink;
	      new_col := new_line^.used+1;
	      end
	    else if bridge then
	      goto 2 { This is safe since only -1BR is allowed }
	    else
	      goto 99;
	    end;
	goto 99;
      2:
	new_col := new_col-1;
	count := count+1;
      until count = 0;
      new_col := new_col+2;
      if not mark_create(dot^.line,dot^.col,marks[mark_equals]) then
	goto 99;
      end
    else
      begin
      nextbridge := mark_create(dot^.line,dot^.col,marks[mark_equals]);
      goto 99;
      end;
    { Found it, move dot to new point. }
    nextbridge := mark_create(new_line,new_col,dot);
    end;
 99:
  end; {nextbridge}

{#if vms or turbop}
end.
{#endif}
