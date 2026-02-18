{=======================================================================}
{                                                                       }
{ Conditional Compilation for pascal.                                   }
{                                                                       }
{ Author     Jeff Blows,                                                }
{                                                                       }
{ Paper                                                                 }
{ Address    Department of Computer Science                             }
{            University of Adelaide                                     }
{            GPO Box 498 Adelaide 5001                                  }
{                                                                       }
{ Electronic                                                            }
{ Address    jeff@smokey.ua.oz                                          }
{                                                                       }
{ Revision History:                                                     }
{ 30 Dec 1987   Kelvin B. Nicolle                                       }
{               Allow for nested conditionals.                          }
{ 20 Mar 1987   Kelvin B. Nicolle                                       }
{               Under VMS, open the input file with read sharing.       }
{ 23 Mar 1987   Kelvin B. Nicolle                                       }
{               Cleanup reproduce line--blank lines should be processed.}
{  2 Apr 1987   Kelvin B. Nicolle                                       }
{               Correct code for #else.                                 }
{ 17 Jul 1987   Kelvin B. Nicolle                                       }
{               Implement the "clean" option.                           }
{               Under VMS, allow p2 to be defaulted completely.         }
{ 30 Sep 1988   Kelvin B. Nicolle                                       }
{               Modifications required for Multimax UMAX:               }
{               . errortype.body should be packed.                      }
{               . include file needed for berkeley extensions.          }
{               . UMAX Pascal does not implement the message function.  }
{                 Write the error message into the output file.         }
{=======================================================================}

{#if vms}
{##[inherit('cs_lib:cli','cs_lib:lib','cs_lib:str')]}
{##}
{##program conditionalcompilation(output,errorfile,infile);}
{#elseif unix}
program conditionalcompilation(input,output);
{#endif}

const
curlystart              = '{';
curlyend                = '}';
conditionalstart        = '#';
space                   = ' ';
asterisk                = '*';
leftbracket             = '(';
rightbracket            = ')';
tab                     = 9;    {tab character}
tablen                  = 8;    {spaces to a tab}
linelenmax              = 256;  {maximum allowable length of input lines}
errorlenmax             = 40;   {maximum length of error messages}
maxerrors               = 12;   {maximum number of error messages}
commandlength           = 16;   {maximum length of commands}
maxnesting              = 5;

type
{#if vms }
{##linetype                = varying [linelenmax] of char;}
{##errortype               = varying [errorlenmax] of char;}
{#elseif unix }
linetype                = record
			    length      : integer;
			    body        : array [1..linelenmax] of char;
			  end;
errortype                = record
			    length      : integer;
			    body        : packed array [1..errorlenmax] of char;
			  end;
{#endif }
namestring              = packed array [1..commandlength] of char;
ptrtoidentifier         = ^identifier;
identifier              = record
			    name        : namestring;
			    left,right  : ptrtoidentifier;
			  end;
keysymbols              = (definesym,elsesym,elseifsym,endifsym,ifsym,
			   undefinesym,orsym,andsym,notsym,haltsym);
statustype              = (fatal,warning);

var
linenumber,
lineindex       : integer;
line            : linetype;

replacechar     : char;

error,
seenelse,
acommand,
optionclean,
addedtext,
makecomment     : boolean;

whitespace,
terminators     : set of char;

here,
root            : ptrtoidentifier;

errormessages   : array [1..maxerrors] of errortype;
keywords        : array [keysymbols] of namestring;

nestinglevel    : 0..maxnesting;
nestingstack    : array [1..maxnesting] of
		  record
		    seenelse,
		    addedtext,
		    makecomment : boolean;
		  end;

{#if vms}
{##infile,}
{##errorfile       : text;}
{#endif}

{#if ns32000}
{##include 'libberkx.pas';}
{#endif}

procedure skipwhitespace(line:linetype; var lineindex:integer);
begin
  while line.body[lineindex] in whitespace do
    lineindex:= lineindex + 1;
end;  {of skipwhitespace}

procedure reporterror(status:statustype; messagenumber:integer;
		      linenumber:integer);
begin
{#if vms }
{##  write(errorfile,'pcc: ');}
{##  write(errorfile,errormessages[messagenumber]);}
{##  if linenumber <> 0 then}
{##    write(errorfile,linenumber:1);}
{##  writeln(errorfile);}
{#elseif ns32000 }
  { UMAX Pascal does not implement the message function. }
  { Write the error message into the output file.        }
  if linenumber <> 0 then
    writeln('pcc: ',errormessages[messagenumber].body:
	    errormessages[messagenumber].length,linenumber:1)
  else
    writeln('pcc: ',errormessages[messagenumber].body:
	    errormessages[messagenumber].length);
{#else}
{##  if linenumber <> 0 then}
{##    message('pcc: ',errormessages[messagenumber].body:}
{##            errormessages[messagenumber].length,linenumber:1)}
{##  else}
{##    message('pcc: ',errormessages[messagenumber].body:}
{##            errormessages[messagenumber].length);}
{#endif}
  error:= status = fatal;
end;  {of reporterror}

function startofcomment(line:linetype; var lineindex:integer;
			var replacechar:char):boolean;
begin
  startofcomment := false;
  if line.body[lineindex] = curlystart then
    begin
      replacechar:= '<';
      startofcomment := true;
    end
  else
    if (line.body[lineindex] = leftbracket) and
       (line.body[lineindex+1] = asterisk) then
      begin
	lineindex:= lineindex + 1;
	replacechar:= '(';
	startofcomment := true;
      end
end;  {of startofcomment}

function endofcomment(line:linetype; var lineindex:integer;
		      var replacechar:char):boolean;
begin
  endofcomment := false;
  if line.body[lineindex] = curlyend then
    begin
      replacechar:= '>';
      endofcomment := true;
    end
  else
    if (line.body[lineindex] = asterisk) and
       (line.body[lineindex+1] = rightbracket) then
      begin
	lineindex:= lineindex + 1;
	replacechar:= ')';
	endofcomment := true;
      end
end;  {of endofcomment}

procedure getnewline(var line:linetype);
var
i : integer;
begin
{#if unix }
  i:= 1;
  while not eoln do
    begin
      read(line.body[i]);
      i:= i + 1;
    end;
  readln;
  line.length:= i - 1;
{#elseif vms }
{##  readln(infile,line);}
{#endif }
end;  {of getnewline}

procedure dumpidtree(here:ptrtoidentifier);
begin
  if here <> nil then
    with here^ do
      begin
	dumpidtree(left);
	writeln(name);
	dumpidtree(right);
      end;
end;  {of dumpidtree}

function findidentifier(here:ptrtoidentifier; thisname:namestring):boolean;
var
stop    : boolean;

begin
  stop:= false;
  while (here <> nil) and not stop do
    begin
      if thisname < here^.name then
	here:= here^.left
      else
	if thisname > here^.name then
	  here:= here^.right
	else
	  stop:= true;
    end;
  findidentifier:= stop;
end;  {of findidentifier}

procedure defineidentifier(var here:ptrtoidentifier;
			   identifiername:namestring);

begin  {defineidentifier}
  if here = nil then
    begin
      new(here);
      with here^ do
	begin
	  name:= identifiername;
	  left:= nil;
	  right:= nil;
	end;
    end
  else
    if identifiername < here^.name then
      defineidentifier(here^.left,identifiername)
    else
      if identifiername > here^.name then
	defineidentifier(here^.right,identifiername);
end; {of defineidentifier}

procedure undefineidentifier(var here:ptrtoidentifier; thisname:namestring);

var
oldhere : ptrtoidentifier;

  procedure delnode(var here:ptrtoidentifier);
  begin
    if here^.right <> nil then
      delnode(here^.right)
    else
      begin
	oldhere^.name := here^.name;
	oldhere:= here;
	here:= here^.left;
      end;
    end;  {of delnode}

begin  {undefineidentifier}
  if here <> nil then
    if thisname < here^.name then
      undefineidentifier(here^.left,thisname)
    else
      if thisname > here^.name then
	undefineidentifier(here^.right,thisname)
      else
	begin
	  {delete here^}
	  oldhere:= here;
	  if oldhere^.right = nil then
	    here:= oldhere^.left
	  else
	    if oldhere^.left = nil then
	      here:= oldhere^.right
	    else
	      delnode(oldhere^.left);
	  dispose(oldhere);
	end;
end; {of undefineidentifier}

procedure initialisedefaults;
begin
  linenumber:= 0;
  acommand:= false;
  optionclean := false;
  nestinglevel:= 0;
  makecomment:= false;
  addedtext:= true;
  whitespace:= [chr(tab),space];
  terminators:= [space,conditionalstart,curlyend,rightbracket];
  here:= nil;
  root:= nil;

{#if unix }
  {maximum length is 16 chars}
  keywords[definesym]  := 'define          ';
  keywords[elsesym]    := 'else            ';
  keywords[elseifsym]  := 'elseif          ';
  keywords[endifsym]   := 'endif           ';
  keywords[ifsym]      := 'if              ';
  keywords[undefinesym]:= 'undefine        ';
  keywords[orsym]      := 'or              ';
  keywords[andsym]     := 'and             ';
  keywords[notsym]     := 'not             ';
  keywords[haltsym]    := '                ';
{#elseif vms }
{##  keywords[definesym]  := 'DEFINE          ';}
{##  keywords[elsesym]    := 'ELSE            ';}
{##  keywords[elseifsym]  := 'ELSEIF          ';}
{##  keywords[endifsym]   := 'ENDIF           ';}
{##  keywords[ifsym]      := 'IF              ';}
{##  keywords[undefinesym]:= 'UNDEFINE        ';}
{##  keywords[orsym]      := 'OR              ';}
{##  keywords[andsym]     := 'AND             ';}
{##  keywords[notsym]     := 'NOT             ';}
{##  keywords[haltsym]    := '                ';}
{#endif }


  {maximum lengths is 40 chars}
  errormessages[1].body:= 'Directive may not be terminated on line ';
  errormessages[1].length:= 40;
  errormessages[2].body:= 'No identifier for DEFINE on line        ';
  errormessages[2].length:= 33;
  errormessages[3].body:= 'No if for else on line                  ';
  errormessages[3].length:= 23;
  errormessages[4].body:= 'No if for elseif on line                ';
  errormessages[4].length:= 25;
  errormessages[5].body:= 'No identifier for UNDEFINE on line      ';
  errormessages[5].length:= 35;
  errormessages[6].body:= 'Invalid transformation found on line    ';
  errormessages[6].length:= 37;
  errormessages[7].body:= 'Unrecognized directive on line          ';
  errormessages[7].length:= 31;
  errormessages[8].body:= 'IFs nested too deeply on line           ';
  errormessages[8].length:= 30;
  errormessages[9].body:= 'else follows else on line               ';
  errormessages[9].length:= 26;
  errormessages[10].body:= 'elseif follows else on line             ';
  errormessages[10].length := 28;
  errormessages[11].body:= 'No if for endif on line                 ';
  errormessages[11].length := 24;
  errormessages[12].body:= 'Unterminated if on line                 ';
  errormessages[12].length := 24;

  defineidentifier(here,'true            ');
  root:= here;
end;  {of initialisedefaults}

{# if unix }
procedure processcmdline;
var
option        : namestring;
optionnumber,
i,j        : integer;

begin
  optionnumber:= 1;
  while optionnumber <= argc - 1 do
    begin
      argv(optionnumber,option);
      if option[1] = '-' then
	begin
	  if option[2] = 'D' then
	    begin
	      j:= 1;
	      i:= 3;        {skip over D}
	      while (option[i] <> space) and (i < commandlength) do
		begin
		  option[j]:= option[i];
		  i:= i+1;
		  j:= j+1;
		end;
	      if (option[i] <> space) and (i = commandlength) then
		begin
		  option[j]:= option[i];
		  i:= i+1;
		  j:= j+1;
		end;
	      if j > 1 then        {something was defined}
		begin
		  while j < commandlength do        {blank fill the array}
		    begin
		      option[j]:= ' ';
		      j:= j+1;
		    end;
		  here:= root;
		  defineidentifier(here,option);
		end;
	    end
	  else if option[2] = 'C' then
	    optionclean := true;
	end;
      optionnumber:= optionnumber+1;
    end;
end;  {of processcmdline}

{#elseif vms}
{##}
{##procedure processcmdline;}
{##var}
{##inputfilename,}
{##outputfilename,}
{##param_string,}
{##command_string : varying [255] of char;}
{##identifiername : namestring;}
{##i : integer;}
{##pcctable : [external] integer;}
{##}
{##begin #<processcmdline#>}
{##}
{###< Get the command line and parse it. #>}
{##lib$get_foreign(command_string.body, ,command_string.length ,);}
{##command_string := 'pcc ' + command_string;}
{##if cli$dcl_parse(command_string, pcctable, lib$get_input) <> cli$_nocomd then}
{##  begin}
{##    #<lets process the command line#>}
{##    if cli$present('p1') = cli$_present then}
{##      begin}
{##        cli$get_value('p1', inputfilename);}
{##        open(infile, inputfilename, history := readonly);}
{##        reset(infile);}
{##      end;}
{##    if cli$present('p2') = cli$_present then}
{##      cli$get_value('p2', outputfilename)}
{##    else}
{##      outputfilename := '';}
{##    open(output, outputfilename, default := inputfilename);}
{##    rewrite(output);}
{##    if cli$present('define') = cli$_present then}
{##      begin}
{##        while cli$get_value('define',param_string)}
{##          <> cli$_absent do}
{##          begin}
{##            i:= 1;}
{##            while (i <= param_string.length) and (i <= commandlength) do}
{##              begin}
{##                identifiername[i]:= param_string[i];}
{##                i:= i+1;}
{##              end;}
{##            for i := param_string.length+1 to commandlength do}
{##              identifiername[i]:= space;}
{##            here:= root;}
{##            defineidentifier(here,identifiername);}
{##          end;}
{##      end;}
{##    if cli$present('clean') = cli$_present then}
{##      optionclean := true;}
{##  end;}
{##end;  #<of processcmdline#>}
{#endif}

procedure reproduceline;

  var
    i,
    index           : integer;
    ch              : char;
    oldcomment      : boolean;

  begin {reproduceline}
  index:= 1;
  if acommand then
    while index <= line.length do
      begin
      write(line.body[index]);
      index:= index + 1;
      end
  else
    begin
    oldcomment := false;
    if line.length >= 3 then
      oldcomment:= (line.body[1] = curlystart) and
		   (line.body[2] = conditionalstart) and
		   (line.body[3] = conditionalstart);
    if optionclean then
      makecomment := false;
    if not oldcomment and makecomment then
      begin       {add in transformation}
      write(curlystart,conditionalstart,conditionalstart);
      while index <= line.length do
	begin
	ch:= line.body[index];
	{tabs here should become spaces else ludwig kills them}
	if ch = chr(tab) then
	  begin
	  ch:= space;       {write out as usual}
	  for i := 1 to tablen-1 do
	    write(space);
	  end;
	if endofcomment(line,index,replacechar) then
	  write(conditionalstart,replacechar)
	else
	  if startofcomment(line,index,replacechar) then
	    write(conditionalstart,replacechar)
	  else
	    if ch = conditionalstart then
	      write(conditionalstart,conditionalstart)
	    else
	      write(ch);
	index:= index + 1;
	end;
      write(curlyend);
      end
    else
      if oldcomment and not makecomment then
	begin     {remove old transformation}
	index:= 4;      {skip added comment bracket}
	while index < line.length do  {do not include trailing comment}
	  begin
	  ch := line.body[index];
	  if ch = conditionalstart then
	    begin
	    index:= index + 1;
	    ch:= line.body[index];
	    if ch in ['#','(',')','<','>'] then
	      case ch of
		'#' : write(conditionalstart);
		'(' : write(ch,asterisk);
		')' : write(asterisk,ch);
		'<' : write(curlystart);
		'>' : write(curlyend);
	      end  {of case}
	    else
	      begin         {there was a corrupt transformation}
	      reporterror(fatal,6,linenumber);
	      end;
	    end
	  else
	    write(ch);
	  index:= index + 1;
	  end;
	end
      else
	if (oldcomment and makecomment) or
	   (not oldcomment and not makecomment) then
	  while index <= line.length do
	    begin
	    write(line.body[index]);
	    index:= index + 1;
	    end
    end;
  writeln;
  end; {reproduceline}

procedure processcomment;
var
keyindex       : keysymbols;

  function getsymbol(line:linetype; var lineindex:integer;
		     var command:namestring):boolean;
  var
  commindex,
  i         : integer;
  begin
    skipwhitespace(line,lineindex);
    commindex:= 1;
    while not(line.body[lineindex] in terminators) and
	  (commindex <= commandlength) and
	  (lineindex < line.length) do
      begin
	command[commindex]:= line.body[lineindex];
	commindex:= commindex + 1;
	lineindex:= lineindex + 1;
      end;
    getsymbol:= commindex > 1;
    for i:= commindex to commandlength do
      command[i] := ' ';
{#if vms }
{##    #<in vms unquoted command line values are uppercased#>}
{##    str$upcase(command,command);}
{#endif }
  end;  {of getsymbol}

  function commandword(line:linetype; var lineindex:integer;
		       var keyindex:keysymbols):boolean;
  var
  command       : namestring;
  found         : boolean;

  begin
    commandword:= false;
    if getsymbol(line,lineindex,command) then
      begin
	keyindex:= definesym;
	found:= false;
	while (keyindex < haltsym) and not found do
	  begin
	    found:= command = keywords[keyindex];
	    if found then
	      commandword:= true
	    else
	      keyindex:= succ(keyindex);
	  end;
      end;
  end;  {of commandword}

  procedure processkeyword(keyindex:keysymbols);
  var
  idname        : namestring;

    function evaluateline(line:linetype; var lineindex:integer):boolean;
    var
    result   : boolean;

      procedure term(var line:linetype; var lineindex:integer;
		     var result:boolean);                        forward;

      procedure expression(line:linetype; var lineindex:integer;
			   var result:boolean);
      var
      endexpression : boolean;
      tempresult : boolean;

      begin {expression}
	endexpression := false;
	term(line,lineindex,result);
	while not error
	  and not endexpression
	  and commandword(line,lineindex,keyindex) do
	  begin
	    case keyindex of
	      andsym   : begin
			   term(line,lineindex,tempresult);
			   result:= result and tempresult;
			 end;
	      orsym    : begin
			   term(line,lineindex,tempresult);
			   result:= result or tempresult;
			 end;
	    end;  {case}
	    skipwhitespace(line,lineindex);
	    endexpression:= line.body[lineindex] = curlyend;
	    if not endexpression then
	      term(line,lineindex,result);
	  end;
	end;  {of expression}

      procedure term;
      var
      command : namestring;
      begin {term}
	skipwhitespace(line,lineindex);
	if line.body[lineindex] = leftbracket then
	  begin
	    lineindex:= lineindex + 1;
	    expression(line,lineindex,result);
	    if line.body[lineindex] = rightbracket then
	      lineindex:= lineindex + 1;
	  end
	else
	  if getsymbol(line,lineindex,command) then
	    if command = keywords[notsym] then
	      begin
		term(line,lineindex,result);
		result:= not result;
	      end
	    else
	      begin
		here:= root;
		result:= findidentifier(here,command)
	      end
	  else
	    if line.body[lineindex] = curlyend then
	      begin
	      result:= true;
	      if (line.length = lineindex) and
		 (keyindex <> definesym) and
		 (keyindex <> undefinesym) then
		reporterror(fatal,1,linenumber);
	      end;
     end;  {of term}

    begin  {evaluateline}
      expression(line,lineindex,result);
      evaluateline:= result;
    end;    {of evaluateline}


  begin  {processkeyword}
    case keyindex of
      definesym        : begin
			 if getsymbol(line,lineindex,idname) then
			   begin
			   if evaluateline(line,lineindex) then
			     begin
			     here:= root;
			     defineidentifier(here,idname);
			     end
			   end
			 else
			   reporterror(warning,2,linenumber);
			 end;
      elsesym          : begin
			 if (nestinglevel <> 0) and not seenelse then
			   begin
			   seenelse := true;
			   makecomment:= addedtext;
			   addedtext := true;
			   end
			 else
			   begin
			     if nestinglevel = 0 then
			       reporterror(fatal,3,linenumber)
			     else
			       reporterror(fatal,9,linenumber);
			   end;
			 end;
      elseifsym        : begin
			 if (nestinglevel <> 0) and not seenelse then
			   begin
			     if not addedtext then
			       begin
				 makecomment:= not evaluateline(line,lineindex);
				 addedtext:= not makecomment;
			       end
			     else
			       makecomment:= addedtext;
			   end
			 else
			   begin
			     if nestinglevel = 0 then
			       reporterror(fatal,4,linenumber)
			     else
			       reporterror(fatal,10,linenumber);
			   end;
			 end;
      endifsym         : begin
			 if nestinglevel <> 0 then
			   begin
			   seenelse:= nestingstack[nestinglevel].seenelse;
			   addedtext:= nestingstack[nestinglevel].addedtext;
			   makecomment:= nestingstack[nestinglevel].makecomment;
			   nestinglevel:= nestinglevel - 1;
			   end
			 else
			   reporterror(fatal,11,linenumber);
			 end;
      ifsym            : begin
			 if nestinglevel = maxnesting then
			   reporterror(fatal,8,linenumber);
			 nestinglevel:= nestinglevel + 1;
			 nestingstack[nestinglevel].seenelse:= seenelse;
			 nestingstack[nestinglevel].addedtext:= addedtext;
			 nestingstack[nestinglevel].makecomment:= makecomment;
			 seenelse := false;
			 if addedtext and not makecomment then
			   begin
			   makecomment:= not evaluateline(line,lineindex);
			   addedtext:= not makecomment;
			   end
			 else
			   begin
			   makecomment:= true;
			   addedtext:= true;
			   end;
			 end;
      undefinesym      : begin
			 if getsymbol(line,lineindex,idname) then
			   begin
			   here:= root;
			   undefineidentifier(here,idname)
			   end
			 else
			   reporterror(warning,5,linenumber);
			 end;
      haltsym          : {error -- abort??};
    end;  {of case}
  end;  {of processkeyword}

begin  {processcomment}
  if commandword(line,lineindex,keyindex) then
    begin
      processkeyword(keyindex);
      acommand:= true;
    end
  else
    if not (line.body[lineindex] in terminators) then
      reporterror(warning,7,linenumber);
end;  {of processcomment}

begin  {main}
{#if vms }
{##  open(errorfile,'SYS$ERROR',new);}
{##  rewrite(errorfile);}
{#endif}
  initialisedefaults;
  processcmdline;
{#if vms }
{##  while not eof(infile) do}
{#elseif unix }
  while not eof do
{#endif }
    begin
      lineindex:= 1;
      getnewline(line);
      linenumber:= linenumber + 1;

      if line.length > lineindex then
	begin
	  skipwhitespace(line,lineindex);
	  if (line.body[lineindex] = curlystart) and
	     (line.body[lineindex+1] = conditionalstart) then
	    begin
	      lineindex:= lineindex + 2;
	      processcomment;
	    end;
	end;
      reproduceline;
      acommand:= false;
    end;
  if nestinglevel <> 0 then
    reporterror(fatal,12,linenumber);
end.
