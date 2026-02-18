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
! Name:         LUDWIGHLP
!
! Description:  This program converts a sequential Ludwig help file into
!               an indexed file for fast access.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Kelvin B. Nicolle                                     6-May-1987
!       The input text has been reformatted so that column one contains
!       only flag characters.
! 4-003 Kelvin B. Nicolle                                     1-Dec-1987
!       Prompt for version and use the appropriate file names.
!--}

[ident('4-002')]

PROGRAM ludwighlp (input,output);

  const
    ludwighlp_txt_v40 = 'ludwighlp.txt';
    ludwighlp_idx_v40 = 'ludwighlp.idx';
    ludwighlp_txt_v41 = 'ludwignewhlp.txt';
    ludwighlp_idx_v41 = 'ludwignewhlp.idx';
    keylen = 4;                         {size of help file selector}
    txtlen = 77;                        {max length of help file record}
    blanks      = '    ';               {string constants keylen chars long}
    index       = '0   ';
    ss$_normal  = %x00000001;
    rms$_normal = %x00010001;
    rms$_ok_dup = %x00018011;

  type
    byte    = 0..255;
    word    = 0..65535;
    address = integer;
    status  = integer;
    xab$b_dtp_type = (xab$c_stg, xab$c_in2, xab$c_bn2,
		      xab$c_in4, xab$c_bn4, xab$c_pac);
    iseq_key_type = packed array[1..keylen] of char;
    txtstr = packed array[1..txtlen] of char;
    iseq_record_type = record
		       key:iseq_key_type;
		       txt:txtstr
		       end;

  var
    version : char;
    buf : iseq_record_type;
    section : iseq_key_type;
    flag,flag2 : char;
    buflen,i : integer;
    done : boolean;
    seqfile : text;
    iseq_file : address;
    iseq_status : status;

%include 'Cs_Lib:ISEQIO.INC'

  procedure lib$signal (%immed status : integer); extern;

  begin
  repeat
    writeln;
    writeln('Please indicate which version you wish to build.');
    writeln('  For version 4.0 enter "OLD"');
    writeln('  For version 4.1 enter "NEW"');
    write  ('_Version: ');
    version := input^;
    readln;
  until version in ['O','o','N','n'];
  if version in ['O','o'] then
    open(seqfile,ludwighlp_txt_v40,readonly)
  else
    open(seqfile,ludwighlp_txt_v41,readonly);
  reset(seqfile);
  iseq_status := iseq_initialize(iseq_file);
  if iseq_status <> ss$_normal then lib$signal(iseq_status);
  iseq_status := iseq_define_key(iseq_file,0,0,keylen,xab$c_stg,true,false);
  if iseq_status <> ss$_normal then lib$signal(iseq_status);
  if version in ['O','o'] then
    iseq_status := iseq_create(iseq_file,ludwighlp_idx_v40,0,false)
  else
    iseq_status := iseq_create(iseq_file,ludwighlp_idx_v41,0,false);
  if iseq_status <> rms$_normal then lib$signal(iseq_status);
  section := blanks;
  done := false;
  repeat
    if not eoln(seqfile) then
      read(seqfile,flag)
    else
      flag := ' ';
    read(seqfile,buf.txt);
    If not eoln(seqfile) Then
      Begin
      Writeln('Line too long--truncated');
      Writeln(flag, Buf.Txt, '>>');
      End;
    Readln(Seqfile);
    done := eof(seqfile);
    {strip trailing blanks}
    buflen := txtlen;
    while (buflen > 1) and (buf.txt[buflen] = ' ') do
      buflen := buflen - 1;
    if (buflen = 1) and (buf.txt[1] = ' ') then
      buflen := 0;
    buflen := buflen + keylen;
    if flag = '\' then
      begin
      {deal with control lines}
      flag2 := buf.txt[1];
      if flag2 = '%' then                {pause line}
	begin
	buf.key := section;
	buf.txt[1] := '\';
	buf.txt[2] := '%';
	iseq_status := iseq_put(iseq_file,keylen+2,buf);
	if (iseq_status <> rms$_normal) and (iseq_status <> rms$_ok_dup)
	then lib$signal(iseq_status);
	end
      else
      if flag2 = '#' then           {end of file}
	done := true
      else                              {new section}
	for i := 1 to keylen do
	  section[i] := buf.txt[i]
      end
    else
    if (flag = '+') or (flag = ' ') then
      begin
      if flag = '+' then           {put line in index}
	begin
	buf.key := index;
	iseq_status := iseq_put(iseq_file,buflen,buf);
	if (iseq_status <> rms$_normal) and (iseq_status <> rms$_ok_dup)
	then lib$signal(iseq_status);
	end;
      buf.key := section;
      iseq_status := iseq_put(iseq_file,buflen,buf);
      if (iseq_status <> rms$_normal) and (iseq_status <> rms$_ok_dup)
      then lib$signal(iseq_status);
      end
    else
    if not ((flag = '!') or (flag = '{')) then
      begin
      writeln('Illegal flag character.');
      writeln(flag,buf.txt);
      end;
  until done;
  iseq_status := iseq_close(iseq_file);
  if iseq_status <> rms$_normal then lib$signal(iseq_status);
  iseq_status := iseq_terminate(iseq_file);
  if iseq_status <> ss$_normal then lib$signal(iseq_status);
  close(seqfile)
  end.
