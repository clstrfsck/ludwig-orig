{++
! Name:         rm_
!
! Description:  Convert a Pascal program by removing underscores, leaving the
!               contents of strings and comments alone.
!
! Author:       Kelvin B. Nicolle
!               Department of Computer Science
!               University of Adelaide
!               G.P.O. Box 498
!               Adelaide  S.A.  5001
!               Australia
!
! Revision History:
! 1-001 Kelvin B. Nicolle                                     1-May-1985
!       Original version.
! 1-002 Kelvin B. Nicolle                                     6-May-1985
!       Add checks for '*' and right_brace to state check2.
! 1-003 Jeff Blows                                            5-Nov-1985
!       Modified lower to only remove underscores.
! 1-004 Jeff Blows                                            9-Dec-1985
!       Removed VMS varying strings and added packed arrays.
! 1-005 Kelvin B. Nicolle                                    30-Sep-1988
!       Change lower bound of line.length subrange from 1 to 0.
!       Add conditional include for UMAX.
!--}

program removeunderscores (input, output);

const
  maxlinelength = 120;
  maxlinelengthplusone = 121;

var
  line : record
	   body : packed array [1..maxlinelength] of char;
	   length : 0..maxlinelengthplusone;
	 end;
  state : (ordinary, string, comment, check1, check2);
  j,i : integer;
  ch : char;

{#if ns32000}
#include "libberkx.pas"
{#endif}

begin {rm_}
state := ordinary;
while not eof do
  begin
  line.length:= 0;
  while not eoln and (line.length < maxlinelength) do
    begin
      line.length:= line.length+1;
      read(line.body[line.length]);
    end;
  if not eoln then
    begin
    writeln ('***** Line exceeds ', maxlinelength:1, ' characters');
    writeln (line.body, '...');
    halt;
    end;
  readln;
  j:= 0;
  for i := 1 to line.length do
    begin
    ch := line.body[i];
    j:= j+1;
    line.body[j]:= ch;
    case state of
    ordinary:
      if ch = '''' then
	state := string
      else if ch = '{' then
	state := comment
      else if ch = '(' then
	state := check1
      else if ch = '_' then
	j:= j-1;
    string:
      if ch = '''' then
	state := ordinary;
    comment:
      if ch = '}' then
	state := ordinary
      else if ch = '*' then
	state := check2;
    check1:
      if ch = '*' then
	state := comment
      else if ch = '''' then
	state := string
      else if ch = '{' then
	state := comment
      else if ch = '(' then
      else
	begin
	state := ordinary;
	if ch = '_' then
	j:= j-1;
	end;
    check2:
      if ch = ')' then
	state := ordinary
      else if ch = '}' then
	state := ordinary
      else if ch = '*' then
      else
	state := comment;
    end{case};
    end;
  if j > 0 then
    write(line.body:j);
  writeln;
  end;
end. {rm_}
