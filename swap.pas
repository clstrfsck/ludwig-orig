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
! Name:         SWAP
!
! Description:  Swap Line command.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
!--}

{#if vms}
[ident('4-001'),
 overlaid]
module swap (output);
{#elseif turbop}
unit swap;
{#endif}

{#if turbop}
interface
uses value;
{$I swap.h}

implementation
uses mark, text;
{#elseif vms}
%include 'const.inc/nolist'
%include 'type.inc/nolist'
%include 'var.inc/nolist'

%include 'swap.fwd/nolist'
%include 'mark.ext/nolist'
%include 'text.ext/nolist'
{#elseif unix}
#include "const.i"
#include "type.i"
#include "var.i"

#include "swap.h"
#include "mark.h"
#include "text.h"
{#endif}


function swap_line {(
		rept  : leadparam;
		count : integer)
	: boolean};

  { SW is implemented as a ST of the dot line to before the other line. }
  label 99;
  var
    this_line, next_line, dest_line : line_ptr;
    top_mark, end_mark, dest_mark : mark_ptr;
    dot_col : col_range;
    i : integer;

  begin {swap_line}
  swap_line := false;
  top_mark := nil; end_mark := nil; dest_mark := nil;
  with current_frame^ do
    begin
    this_line := dot^.line;
    next_line := this_line^.flink;
    if next_line = nil then goto 99;
    dot_col := dot^.col;
    case rept of
      none,plus,pint:
	begin
	dest_line := next_line;
	for i := 1 to count do
	  begin
	  dest_line := dest_line^.flink;
	  if dest_line = nil then goto 99;
	  end;
	end;
      minus,nint:
	begin
	dest_line := this_line;
	for i := -1 downto count do
	  begin
	  dest_line := dest_line^.blink;
	  if dest_line = nil then goto 99;
	  end;
	end;
      pindef:
	begin
	dest_line := last_group^.last_line;
	end;
      nindef:
	begin
	dest_line := first_group^.first_line;
	end;
      marker:
	begin
	dest_line := marks[count]^.line;
	end;
    end{case};
    if not mark_create(this_line,1,top_mark) then goto 99;
    if not mark_create(next_line,1,end_mark) then goto 99;
    if not mark_create(dest_line,1,dest_mark) then goto 99;
    if not text_move(false,1,top_mark,end_mark,dest_mark,dot,top_mark)
    then goto 99;
    text_modified := true;
    dot^.col := dot_col;
    if not mark_create(dot^.line,dot^.col,marks[mark_modified]) then goto 99;
    end;
  swap_line := true;
99:
  if top_mark <> nil then if not mark_destroy(top_mark) then ;
  if end_mark <> nil then if not mark_destroy(end_mark) then ;
  if dest_mark <> nil then if not mark_destroy(dest_mark) then ;
  end; {swap_line}

{#if vms or turbop}
end.
{#endif}
