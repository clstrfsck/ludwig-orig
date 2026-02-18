{++
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Kelvin B. Nicolle                                     5-May-1987
!       Add the definition of the new variable ludwig_version.
! 4-003 Kelvin B. Nicolle                                    22-May-1987
!       Move the definition of ludwig_version into "version.i".
! 4-004 Kelvin B. Nicolle                                    29-May-1987
!       Change the prompt on the I and O commands from no_prompt to
!       text_prompt.
!       Unix: Allow multi-line tpar on the I command.
! 4-005 Francis Vaughan                                      24-Aug-1988
!       Replace underscores in identifiers.
!--}

#include "const.i"
#include "type.i"
#include "var.i"

#include "value.h"

procedure setupinitialvalues{};

  var
    i : integer;
    keycode : keycoderange;

  begin {setupinitialvalues}

#include "version.i"
  currentframe         := nil;
  for i := 1 to maxfiles do begin
    files[i] := nil;
    filesframes[i] := nil
    end;
  ludwigmode         := ludwigbatch;
  editmode           := modeinsert;
  commandintroducer  := ord('\');
  scrframe           := nil;
  scrmsgrow         := maxint;
  vdufreeflag       := false;
  execlevel          := 0;

  { Set up the Free Group/Line/Mark Pools }
  freegrouppool     := nil;
  freelinepool      := nil;
  freemarkpool      := nil;

  { Set up all the Default Default characteristics for a frame.}

  for i := minmarknumber to maxmarknumber do initialmarks[i] := nil;
  initialscrheight    := 1;           { Set to ttheight for terminals. }
  initialscrwidth     := 132;         { Set to ttwidth  for terminals. }
  initialscroffset    := 0;
  initialmarginleft   := 1;
  initialmarginright  := 132;         { Set to ttwidth  for terminals. }
  initialmargintop    := 0;
  initialmarginbottom := 0;
  initialoptions       := [];

  for i := 1 to maxstrlen do blankstring[i] := ' ';
  for i := 1 to maxverify do initialverify[i] := false;
  defaulttabstops[0]  := true;
  for i := 1 to maxstrlen do defaulttabstops[i] := false;
  defaulttabstops[maxstrlenp] := true;

  {set up sets for prefixes}

	     { NOTE - this matches prefixcommands }
  prefixes:= [cmdprefixast..cmdprefixtilde];

  repeatsyms:= ['+','-','@','<','>','=','0'..'9', ',', '.'];

  dfltprompts[noprompt        ] := '        ';
  dfltprompts[charprompt      ] := 'Charset:';
  dfltprompts[getprompt       ] := 'Get    :';
  dfltprompts[equalprompt     ] := 'Equal  :';
  dfltprompts[keyprompt       ] := 'Key    :';
  dfltprompts[cmdprompt       ] := 'Command:';
  dfltprompts[spanprompt      ] := 'Span   :';
  dfltprompts[textprompt      ] := 'Text   :';
  dfltprompts[frameprompt     ] := 'Frame  :';
  dfltprompts[fileprompt      ] := 'File   :';
  dfltprompts[columnprompt    ] := 'Column :';
  dfltprompts[markprompt      ] := 'Mark   :';
  dfltprompts[paramprompt     ] := 'Param  :';
  dfltprompts[topicprompt     ] := 'Topic  :';
  dfltprompts[replaceprompt   ] := 'Replace:';
  dfltprompts[byprompt        ] := 'By     :';
  dfltprompts[verifyprompt    ] := 'Verify ?';
  dfltprompts[patternprompt   ] := 'Pattern:';
  dfltprompts[patternsetprompt] := 'Pat Set:';

  spaceset     := [ 32];
		   {' '}
		   { the S (space) pattern specifier }

  numericset   := [ 48.. 57];
		   {'0'..'9'}
		   { the N (numeric) pattern specifier }

  upperset     := [ 65.. 90];
		   {'A'..'Z'}
		   { the U (uppercase) pattern specifier }

  lowerset     := [ 97..122];
		   {'a'..'z'}
		   { the L (lowercase) pattern specifier }

  alphaset     := upperset + lowerset;
		   {the A (alphabetic) pattern specifier }

  punctuationset:= [ 33, 34,  39, 40, 41, 44, 46, 58, 59, 63, 96];
		   {'!','"','''','(',')',',','.',':',';','?','`'}
		   { the P (punctuation) pattern specifier }

  printableset :=  [ 32..126];
		   {' '..'~'}
		   { the C (printable char) pattern specifier }

  filedata.oldcmds := true;
  filedata.entab := false;
  filedata.space := 500000;
  for i := 1 to maxstrlen do
    filedata.initial[i] := ' ';
  filedata.purge := false;
  filedata.versions := 1;

  wordelements[0] := spaceset;
  wordelements[1] := alphaset + numericset;
  wordelements[2] := printableset - (wordelements[0] + wordelements[1]);
  end; {setupinitialvalues}

{}procedure initailizecommandtablepart1;

  begin {initailizecommandtablepart1}
  { initialize cmdattrib }
  with cmdattrib[cmdnoop            ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdup              ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmddown            ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdright           ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdleft            ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdhome            ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdreturn          ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdtab             ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdbacktab         ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdrubout          ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdjump            ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdadvance         ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdpositioncolumn  ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdpositionline    ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdopsyscommand    ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := cmdprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowforward   ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowbackward  ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowright     ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowleft      ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowscroll    ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef       ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowtop       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowend       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindownew       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowmiddle    ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowsetheight ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwindowupdate    ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdget             ] do begin
    lpallowed := [none,plus,minus,pint,nint                     ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := getprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdnext            ] do begin
    lpallowed := [none,plus,minus,pint,nint                     ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := charprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdbridge          ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := charprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdreplace         ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef       ];
    eqaction := eqnil; tpcount := 2;
    with tparinfo[1] do
      begin
      promptname := replaceprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := byprompt;  trimreply := false;
      mlallowed := true;
      end;
    end;
  with cmdattrib[cmdequalstring     ] do begin
    lpallowed := [none,plus,minus,          pindef,nindef       ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := equalprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdequalcolumn     ] do begin
    lpallowed := [none,plus,minus,          pindef,nindef       ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := columnprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdequalmark       ] do begin
    lpallowed := [none,plus,minus,          pindef,nindef       ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := markprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdequaleol        ] do begin
    lpallowed := [none,plus,minus,          pindef,nindef       ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdequaleop        ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdequaleof        ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdovertypemode    ] do begin
    lpallowed := [none                                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdinsertmode      ] do begin
    lpallowed := [none                                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdovertypetext    ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqold; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := textprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdinserttext      ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqold; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := textprompt;  trimreply := false;
      mlallowed := true;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdtypetext        ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqold; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := textprompt;  trimreply := false;
      mlallowed := true;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdinsertline      ] do begin
    lpallowed := [none,plus,minus,pint,nint                     ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdinsertchar      ] do begin
    lpallowed := [none,plus,minus,pint,nint                     ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdinsertinvisible ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmddeleteline      ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqdel; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmddeletechar      ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  end; {initailizecommandtablepart1}

{}procedure initailizecommandtablepart2;

  begin {initailizecommandtablepart2}
  with cmdattrib[cmdswapline        ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqdel; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdsplitline       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmddittoup         ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef       ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmddittodown       ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef       ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdcaseup          ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef       ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdcaselow         ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef       ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdcaseedit        ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef       ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdsetmarginleft   ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdsetmarginright  ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdlinefill        ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdlinejustify     ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdlinesquash      ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdlinecentre      ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdlineleft        ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdlineright       ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdwordadvance     ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdworddelete      ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdadvanceparagraph] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmddeleteparagraph ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspandefine      ] do begin
    lpallowed := [none,plus,minus,pint,                   marker];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := spanprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspantransfer    ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := spanprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspancopy        ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := spanprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspancompile     ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := spanprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspanjump        ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := spanprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspanindex       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspanassign      ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef              ];
    eqaction := eqnil; tpcount := 2;
    with tparinfo[1] do
      begin
      promptname := spanprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := textprompt;  trimreply := false;
      mlallowed := true;
      end;
    end;
  with cmdattrib[cmdblockdefine     ] do begin
    lpallowed := [none,plus,minus,pint,                   marker];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdblocktransfer   ] do begin
    lpallowed := [none                                         ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdblockcopy       ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdframekill       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := frameprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdframeedit       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := frameprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdframereturn     ] do begin
    lpallowed := [none,plus,      pint                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspanexecute     ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := spanprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdspanexecutenorecompile] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := spanprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdframeparameters ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := paramprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileoutput      ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := -1;
    with tparinfo[1] do
      begin
      promptname := fileprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileinput       ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := -1;
    with tparinfo[1] do
      begin
      promptname := fileprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileedit        ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := fileprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileread        ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfilewrite       ] do begin
    lpallowed := [none,plus,minus,pint,nint,pindef,nindef,marker];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileclose       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfilerewind      ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfilekill        ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileexecute     ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := fileprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfiletable       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileglobalinput ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := -1;
    with tparinfo[1] do
      begin
      promptname := fileprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileglobaloutput] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := -1;
    with tparinfo[1] do
      begin
      promptname := fileprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileglobalrewind] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdfileglobalkill  ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdusercommandintroducer] do begin
    lpallowed := [none                                          ];
    eqaction := eqold; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmduserkey         ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 2;
    with tparinfo[1] do
      begin
      promptname := keyprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := cmdprompt;  trimreply := false;
      mlallowed := true;
      end;
    end;
  with cmdattrib[cmduserparent      ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdusersubprocess  ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmduserundo        ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdhelp            ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := topicprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdverify          ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := verifyprompt;  trimreply := true;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdcommand         ] do begin
    lpallowed := [none,plus,minus                               ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdmark            ] do begin
    lpallowed := [none,plus,minus,pint,nint                     ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdpage            ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdquit            ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmddump            ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdvalidate        ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdexecutestring   ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := cmdprompt;  trimreply := false;
      mlallowed := true;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmddolastcommand   ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdextended        ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdexitabort       ] do begin
    lpallowed := [none                                          ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdexitfail        ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdexitsuccess     ] do begin
    lpallowed := [none,plus,      pint,     pindef              ];
    eqaction := eqnil; tpcount := 0;
    with tparinfo[1] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdpatterndummypattern] do begin
    lpallowed := [                                              ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := patternprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  with cmdattrib[cmdpatterndummytext] do begin
    lpallowed := [                                              ];
    eqaction := eqnil; tpcount := 1;
    with tparinfo[1] do
      begin
      promptname := textprompt;  trimreply := false;
      mlallowed := false;
      end;
    with tparinfo[2] do
      begin
      promptname := noprompt;  trimreply := false;
      mlallowed := false;
      end;
    end;
  end; {initailizecommandtablepart2}

begin {valueinitializations}
setupinitialvalues;
initailizecommandtablepart1;
initailizecommandtablepart2;
end; {valueinitializations}
