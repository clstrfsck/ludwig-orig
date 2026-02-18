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
! Name:         HELP
!
! Description:  Ludwig HELP facility.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Kelvin B. Nicolle                                     4-May-1987
!       Change the indent of the displayed help text from 3 to 2.
!--}

{#if vms}
[ident('4-002'),
 overlaid]
module help (output);
{#elseif turbop}
unit help;
{#endif}

{#if turbop}
interface
uses value;
{$I help.h}

implementation
uses ch, helpfile, screen;
const
  space_or_return : write_str =
'<space> for more, <return> to exit :                                            ';
  command_or_section : write_str =
'Command or Section or <return> to exit :                                        ';
  spaces      = '    ';               {string constants key_len chars long}
  index       = '0   ';
  sts_rnf     = 98994;                {record not found status return}
{#elseif vms}
%include 'const.inc/nolist'
    spaces      = '    ';               {string constants key_len chars long}
    index       = '0   ';
    sts_rnf     = %x182b2;              {record not found status return}
%include 'type.inc/nolist'
%include 'var.inc/nolist'

%include 'help.fwd/nolist'
%include 'screen.ext/nolist'
%include 'ch.ext/nolist'
%include 'helpfile.ext/nolist'
%include 'vdu.ext/nolist'
{#elseif unix}
#include "const.i"
    spaces      = '    ';               {string constants key_len chars long}
    index       = '0   ';
    sts_rnf     = 98994;                {record not found status return}
#include "type.i"
#include "var.i"

#include "help.h"
#include "ch.h"
#include "helpfile.h"
#include "screen.h"
{#endif}


procedure help_help {(
		selection_len : integer;
	var     selection     : str_object)};

{#if not multimax}
  {The argument selects a particular part of the help file to read e.g. SD}
  var
    buf : help_record;
    reply : key_str;
    i,len,reply_len,
    sts : integer;
    read_on : boolean;
    topic     : key_str;
    topic_len : integer;
    continue : boolean;
{#if turbop}
    buffer : write_str;
    tmp_str : string;
{#endif}

{#if vms}
  procedure ask_user (prompt     : packed array [l1..h1:strlen_range] of char;
		      prompt_len : strlen_range;
		      var reply     : key_str;
		      var reply_len : integer);
{#elseif unix or turbop}
  procedure ask_user (prompt     : write_str;
		      prompt_len : strlen_range;
		      var reply     : key_str;
		      var reply_len : integer);
{#endif}

    begin {ask_user}
    screen_writeln;
    reply := spaces;
{#if vms}
    vdu_get_help(prompt,prompt_len,reply,key_len,reply_len);
{#elseif unix or turbop}
    screen_help_prompt (prompt,prompt_len,reply,reply_len);
{#endif}
    { Note that all characters not overwritten by the user will be spaces! }
    screen_writeln;
{#if ISO1}
    ch_upcase_str(reply,reply_len);
{#else}
    ch_upcase_key(reply,reply_len);
{#endif}
    end; {ask_user}
{#endif}

  begin {help_help}
{#if not multimax}
  screen_unload;
  screen_home(true);
  if selection_len = 0 then
    begin
    topic := index;
    topic_len := key_len;
    end
  else
    begin
    if selection_len > key_len then
      topic_len := key_len
    else
      topic_len := selection_len;
    topic := spaces;
    for i := 1 to topic_len do topic[i] := selection[i];
    end;
  if not helpfile_open(file_data.old_cmds) then
    begin
{#if turbop}
    tmp_str := 'Can''t open HELP file';
    move(tmp_str[1], buffer[1], length(tmp_str));
    screen_write_str(3,buffer,20);
{#else}
    screen_write_str(3,'Can''t open HELP file',20);
{#endif}
    screen_writeln;
    screen_pause;
    topic_len := 0;
    end;
  while topic_len <> 0 do
    begin
    screen_home(true);
    {Note: the topic is space padded to key_len characters. }
    sts := helpfile_read(topic,key_len,buf,key_len+write_str_len,len);
    if sts = sts_rnf then
      begin
{#if turbop}
    tmp_str := 'Can''t find Command or Section in HELP';
    move(tmp_str[1], buffer[1], length(tmp_str));
    screen_write_str(3,buffer,37);
{#else}
      screen_write_str(3,'Can''t find Command or Section in HELP',37);
{#endif}
      screen_writeln;
      end;
    continue := odd(sts);
    if not continue then
      topic := spaces;
    while continue do
      begin
      if (buf.txt[1] = '\') and (buf.txt[2] = '%') then
	begin
{#if turbop}
	ask_user(space_or_return,37,
{#else}
	ask_user('<space> for more, <return> to exit : ',37,
{#endif}
		 reply,reply_len);
	if tt_controlc then
	  reply_len := 0;
	if (reply_len = 0) or (reply[1] <> ' ') then
	  begin
	  continue := false;
	  topic := reply;
	  topic_len := reply_len;
	  end;
	end
      else
	begin
{#if turbop}
	screen_write_str(2,buf.txt,len); {len was len-key_len for c version}
{#else}
	screen_write_str(2,buf.txt,len-key_len);
{#endif}
	screen_writeln;
	end;
      if continue then
	begin
	read_on := odd(helpfile_next(buf,key_len+write_str_len,len));
	if read_on then     {check key still valid}
	  for i := 1 to key_len do
	    if buf.key[i]<>topic[i] then read_on := false;
	if not read_on then
	  begin
	  continue := false;
	  topic := spaces;
	  end;
	end;
      if tt_controlc then
	begin
	topic_len := 0;
	continue := false;
	end;
      end;
    if topic_len <> 0 then
      begin
      if topic[1] = ' ' then
	begin
{#if turbop}
	ask_user(command_or_section,41,
{#else}
	ask_user('Command or Section or <return> to exit : ',41,
{#endif}
		  topic,topic_len);
	if (topic_len <> 0) and (topic[1] = ' ') then
	  begin
	  topic := index;
	  topic_len := key_len;
	  end;
	if tt_controlc then topic_len := 0;
	end;
      end;
    end;
{#endif}
  end; {help_help}

{#if vms or turbop}
end.
{#endif}
