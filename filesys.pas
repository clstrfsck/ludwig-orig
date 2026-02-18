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
! Name:         FILESYS
!
! Description:  This routine parses the command line, and filenames
!               When we get around to translating the Bliss the rest
!               of FILESYS will move here.
!
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Kelvin B. Nicolle                                     5-May-1987
!       Change the default PRN for a file with carriage_return or
!       fortran record attributes to (lf,cr) to prevent losing a blank
!       line at top of file.
!       Also changed the case labels in process_control_character to
!       symbols instead of numeric literals.
! 4-003 Mark R. Prior                                         9-Nov-1987
!       Sometimes filesys_write is called with a nil buffer so
!       protect the tabbing code from this.
! 4-004 Kelvin B. Nicolle                                     4-Dec-1987
!       The error vectors in filesys_write and filesys_rewind were
!       missing the length header.
! 4-005 Kelvin B. Nicolle                                     9-Dec-1988
!       Move the ascii constants from const.inc.
!--}

{#if vms}
{##[inherit('sys$library:starlet'),}
{## ident('4-005'),}
{## overlaid]}
{##module filesys;}
{##}
{##%include 'const.inc/nolist'}
{##  #< ASCII CHARACTERS #>}
{##  ascii_ht    = chr(9);     #< Horizontal Tab #>}
{##  ascii_lf    = chr(10);    #< Line feed #>}
{##  ascii_vt    = chr(11);    #< Vertical Tab #>}
{##  ascii_ff    = chr(12);    #< Form feed #>}
{##  ascii_cr    = chr(13);    #< Carriage return #>}
{##%include 'type.inc/nolist'}
{##    rms_record = packed array [1..65535] of char;}
{##    rms_record_ptr = ^ rms_record;}
{##%include 'var.inc/nolist'}
{##}
{##%include 'filesys.fwd/nolist'}
{##%include 'ch.ext/nolist'}
{##%include 'screen.ext/nolist'}
{##%include 'vms.ext/nolist'}
{##}
{##const}
{##  cli$_normal    = %x'00030001';}
{##  cli$_absent    = %x'000381f0';}
{##  cli$_negated   = %x'000381f8';}
{##  cli$_present   = %x'0003fd19';}
{##  cli$_defaulted = %x'0003fd21';}
{##}
{##}
{###<#>function cli$dcl_parse (}
{##                command_string : [class_s] packed array [l1..h1:integer] of}
{##                                                               char := %immed 0;}
{##                tables : [unsafe] unsigned;}
{##        %immed [unbound] function param_routine (}
{##                var     get_str : [class_s] packed array [l1..h1:integer] of}
{##                                                                           char;}
{##                        prompt_str : [class_s] packed array [l2..u2:integer] of}
{##                                                               char := %immed 0;}
{##                var     out_len : word := %immed 0)}
{##                : integer := %immed 0;}
{##        %immed [unbound] function prompt_routine (}
{##                var     get_str : [class_s] packed array [l1..h1:integer] of}
{##                                                                           char;}
{##                        prompt_str : [class_s] packed array [l2..u2:integer] of}
{##                                                               char := %immed 0;}
{##                var     out_len : word := %immed 0)}
{##                : integer := %immed 0;}
{##                prompt_string : [class_s] packed array [l4..h4:integer] of}
{##                                                               char := %immed 0)}
{##        : integer;  external;}
{##}
{##}
{###<#>function cli$get_value (}
{##                name : [class_s] packed array [l1..h1:integer] of char;}
{##        var     retbuf : varying [len2] of char)}
{##        : integer;  external;}
{##}
{##}
{###<#>function cli$present (}
{##                name : [class_s] packed array [l1..h1:integer] of char)}
{##        : integer;  external;}
{##}
{##}
{###< This is a modified version of the definition of $PUTMSG from STARLET.}
{##! The chief modification is to make ACTRTN a function so that $PUTMSG}
{##! can be told not to write the messages to SYS$ERROR.}
{###>}
{##[ASYNCHRONOUS] FUNCTION sys$PUTMSG (}
{##        %REF MSGVEC : [UNSAFE] ARRAY [$l1..$u1:INTEGER] OF BYTE;}
{##        %IMMED [UNBOUND] function ACTRTN}
{##          (message : [class_s] packed array [l1..h1:integer] of char) : boolean}
{##                                                        := %IMMED 0;}
{##        FACNAM : [CLASS_S] PACKED ARRAY [$l3..$u3:INTEGER] OF CHAR := %IMMED 0;}
{##        %IMMED ACTPRM : UNSIGNED := %IMMED 0) : INTEGER; EXTERNAL;}
{##}
{##}
{##function filesys_parse #<(}
{##                command_line : packed array [l1..h1:integer] of char;}
{##                parse        : parse_type;}
{##        var     file_data    : file_data_type;}
{##        var     fileptr1     : file_ptr;}
{##        var     fileptr2     : file_ptr)}
{##        : boolean#>;}
{##}
{##  label}
{##    99;}
{##}
{##  var}
{##    tables : [external(ludwig_tables)] integer;}
{##    tab, old_version : integer;}
{##    len : word;}
{##    temp, result, memory : varying [max_strlen] of char;}
{##    command_ok, check_input : boolean;}
{##}
{##  function lib$get_input (}
{##          var     get_str : [class_s] packed array [l1..h1:integer] of char;}
{##                  prompt_str : [class_s] packed array [l2..u2:integer] of char}
{##                                                                := %immed 0;}
{##          var     out_len : word := %immed 0)}
{##          : integer; external;}
{##}
{##  begin #<filesys_parse#>}
{##  filesys_parse := false;}
{##  if parse <> parse_stdin then}
{##    begin}
{##    case parse of}
{##      parse_command :}
{##        temp := 'C ' + command_line;}
{##      parse_input, parse_execute :}
{##        temp := 'I ' + command_line;}
{##      parse_output :}
{##        temp := 'O ' + command_line;}
{##      parse_edit :}
{##        temp := 'E ' + command_line;}
{##    end#<case#>;}
{##    while temp[temp.length] = ' ' do}
{##      temp.length := temp.length-1;}
{##    repeat}
{##      if cli$dcl_parse((temp),tables) <> cli$_normal then}
{##        goto 99;}
{##      #< Process memory qualifier. #>}
{##      if odd(cli$present('memory')) then}
{##        cli$get_value('memory',memory)}
{##      else}
{##        memory := '';}
{##      command_ok := true;}
{##      if parse = parse_command then}
{##        if (cli$present('file1') <> cli$_present) and (memory.length > 0) then}
{##          if $trnlog(memory,result.length,result.body) = ss$_notran then}
{##            begin}
{##            command_ok := false;}
{##            if lib$get_input(result.body,'File: ',result.length) = rms$_eof}
{##            then goto 99;}
{##            temp := temp + ' ' + result;}
{##            end;}
{##    until command_ok;}
{##    end;}
{##  if parse in [parse_command,parse_output,parse_edit] then}
{##    begin}
{##    fileptr2^.create := false;}
{##    fileptr2^.memory := pad(memory,' ',max_strlen);}
{##    #< Process type qualifier. #>}
{##    if odd(cli$present('type.variable')) then}
{##      fileptr2^.format := variable}
{##    else if odd(cli$present('type.stream_lf')) then}
{##      fileptr2^.format := stream_lf}
{##    else if odd(cli$present('type.numbered')) then}
{##      fileptr2^.format := numbered}
{##    else}
{##      fileptr2^.format := same_format;}
{##    #< Process attribute qualifier. #>}
{##    if odd(cli$present('attribute.carriage_return')) or}
{##       odd(cli$present('attribute.list')) then}
{##      fileptr2^.attribute := carriage_return}
{##    else if odd(cli$present('attribute.fortran')) then}
{##      fileptr2^.attribute := fortran_attribute}
{##    else}
{##      fileptr2^.attribute := same_attribute;}
{##    #< Process tab qualifier. #>}
{##    tab := cli$present('tab');}
{##    if (tab = cli$_present) or (tab = cli$_negated) then}
{##      fileptr2^.entab := tab = cli$_present}
{##    else}
{##      fileptr2^.entab := file_data.entab;}
{##    case parse of}
{##      parse_command :}
{##        begin}
{##        old_version := cli$present('old_version');}
{##        file_data.old_cmds :=    (old_version = cli$_present)}
{##                              or (old_version = cli$_defaulted);}
{##        if    (cli$present('number') = cli$_present)}
{##           or (cli$present('number') = cli$_negated)}
{##           or (cli$present('fortran') = cli$_present)}
{##           or (cli$present('list') = cli$_present) then}
{##          screen_message(msg_decommitted);}
{##        if cli$present('initialize') <> cli$_negated then}
{##          begin}
{##          cli$get_value('initialize',result);}
{##          file_data.initial := pad(result,' ',max_strlen);}
{##          end;}
{##        if cli$present('space') = cli$_present then}
{##          begin}
{##          cli$get_value('space',result);}
{##          readv(result,file_data.space,error:=continue);}
{##          end;}
{##        file_data.entab := cli$present('tab') = cli$_present;}
{##        check_input := false;}
{##        fileptr1^.fns := 0;}
{##        if cli$present('file1') = cli$_present then}
{##          begin}
{##          cli$get_value('file1',result);}
{##          if result.length > file_name_len then}
{##            result := substr(result,1,file_name_len);}
{##          fileptr1^.fnm := pad(result,' ',file_name_len);}
{##          fileptr1^.fns := result.length;}
{##          end}
{##        else if cli$present('memory') <> cli$_negated then}
{##          begin}
{##          check_input := true;}
{##          if $trnlog(memory,len,fileptr1^.fnm) = ss$_normal then}
{##            fileptr1^.fns := len;}
{##          end;}
{##        if cli$present('file2') = cli$_present then}
{##          begin}
{##          check_input := true;}
{##          cli$get_value('file2',result);}
{##          if result.length > file_name_len then}
{##            result := substr(result,1,file_name_len);}
{##          fileptr2^.fnm := pad(result,' ',file_name_len);}
{##          fileptr2^.fns := result.length;}
{##          end}
{##        else}
{##          fileptr2^.fns := 0;}
{##        if cli$present('number') = cli$_present then}
{##          fileptr2^.format := numbered;}
{##        if cli$present('fortran') = cli$_present then}
{##          fileptr2^.attribute := fortran_attribute;}
{##        if cli$present('list') = cli$_present then}
{##          fileptr2^.attribute := carriage_return;}
{##        if cli$present('create') = cli$_present then}
{##          begin}
{##          fileptr2^.fnm := fileptr1^.fnm;}
{##          fileptr2^.fns := fileptr1^.fns;}
{##          fileptr2^.create := true;}
{##          if filesys_create_open(fileptr2,nil,true) then}
{##            begin}
{##            fileptr2^.valid := true;}
{##            filesys_parse := true;}
{##            end;}
{##          end}
{##        else}
{##        if cli$present('read_only') = cli$_present then}
{##          begin}
{##          if filesys_create_open(fileptr1,nil,true) then}
{##            begin}
{##            fileptr1^.valid := true;}
{##            filesys_parse := true;}
{##            end;}
{##          end}
{##        else}
{##          begin}
{##          #<}
{##          ! Load the file, don't worry if there isn't an input file unless we}
{##          ! are told to. It is OK to not even load a file at all!}
{##          #>}
{##          if fileptr1^.fns <> 0 then}
{##            if filesys_create_open(fileptr1,nil,check_input) then}
{##              begin}
{##              fileptr1^.valid := true;}
{##              if filesys_create_open(fileptr2,fileptr1,true) then}
{##                begin}
{##                fileptr2^.valid := true;}
{##                filesys_parse := true;}
{##                end;}
{##              end}
{##            else}
{##              if check_input then}
{##                #< fail #>}
{##              else}
{##                begin}
{##                fileptr2^.fnm := fileptr1^.fnm;}
{##                fileptr2^.fns := fileptr1^.fns;}
{##                if filesys_create_open(fileptr2,nil,true) then}
{##                  begin}
{##                  fileptr2^.valid := true;}
{##                  filesys_parse := true;}
{##                  end;}
{##                end}
{##          else}
{##            filesys_parse := true;}
{##          end;}
{##        end;}
{##      parse_output :}
{##        begin}
{##        if cli$present('file1') = cli$_present then}
{##          begin}
{##          cli$get_value('file1',result);}
{##          if result.length > file_name_len then}
{##            result := substr(result,1,file_name_len);}
{##          fileptr2^.fns := result.length;}
{##          fileptr2^.fnm := pad(result,' ',file_name_len);}
{##          end}
{##        else}
{##          fileptr2^.fns := 0;}
{##        if filesys_create_open(fileptr2,fileptr1,true) then}
{##          begin}
{##          fileptr2^.valid := true;}
{##          filesys_parse := true;}
{##          end;}
{##        end;}
{##      parse_edit :}
{##        begin}
{##        fileptr1^.fns := 0;}
{##        if cli$present('file1') = cli$_present then}
{##          begin}
{##          cli$get_value('file1',result);}
{##          if result.length > file_name_len then}
{##            result := substr(result,1,file_name_len);}
{##          fileptr1^.fnm := pad(result,' ',file_name_len);}
{##          fileptr1^.fns := result.length;}
{##          end}
{##        else if cli$present('memory') = cli$_present then}
{##          begin}
{##          if $trnlog(memory,len,fileptr1^.fnm) = ss$_normal then}
{##            fileptr1^.fns := len;}
{##          end;}
{##        if cli$present('file2') = cli$_present then}
{##          begin}
{##          cli$get_value('file2',result);}
{##          if result.length > file_name_len then}
{##            result := substr(result,1,file_name_len);}
{##          fileptr2^.fnm := pad(result,' ',file_name_len);}
{##          fileptr2^.fns := result.length;}
{##          end}
{##        else}
{##          fileptr2^.fns := 0;}
{##        if filesys_create_open(fileptr1,nil,true) then}
{##          begin}
{##          fileptr1^.valid := true;}
{##          if filesys_create_open(fileptr2,fileptr1,true) then}
{##            begin}
{##            fileptr2^.valid := true;}
{##            filesys_parse := true;}
{##            end;}
{##          end;}
{##        end;}
{##    end;}
{##    end}
{##  else if parse = parse_input then}
{##    begin}
{##    fileptr1^.fns := 0;}
{##    if cli$present('file1') = cli$_present then}
{##      begin}
{##      cli$get_value('file1',result);}
{##      fileptr1^.fnm := pad(result,' ',file_name_len);}
{##      fileptr1^.fns := result.length;}
{##      end}
{##    else if cli$present('memory') = cli$_present then}
{##      begin}
{##      if $trnlog(memory,len,fileptr1^.fnm) = ss$_normal then}
{##        fileptr1^.fns := len;}
{##      end;}
{##    if fileptr1^.fns > 0 then  #< must have some value, else fail #>}
{##      begin}
{##      if filesys_create_open(fileptr1,nil,true) then}
{##        begin}
{##        fileptr1^.valid := true;}
{##        filesys_parse := true;}
{##        end;}
{##      end;}
{##    end}
{##  else if parse = parse_execute then}
{##    begin}
{##    fileptr1^.fns := 0;}
{##    fileptr1^.dnm := '.lud';}
{##    fileptr1^.dns := 4;}
{##    if cli$present('file1') = cli$_present then}
{##      begin}
{##      cli$get_value('file1',result);}
{##      fileptr1^.fnm := pad(result,' ',file_name_len);}
{##      fileptr1^.fns := result.length;}
{##      end;}
{##    if fileptr1^.fns > 0 then  #< must have some value, else fail #>}
{##      begin}
{##      if filesys_create_open(fileptr1,nil,false) then}
{##        begin}
{##        fileptr1^.valid := true;}
{##        filesys_parse := true;}
{##        end;}
{##      end;}
{##    end}
{##  else}
{##    begin}
{##    fileptr1^.fnm := 'SYS$INPUT';}
{##    fileptr1^.fns := 9;}
{##    if filesys_create_open(fileptr1,nil,true) then}
{##      begin}
{##      fileptr1^.valid := true;}
{##      filesys_parse := true;}
{##      end;}
{##    end;}
{##99:}
{##  end; #<filesys_parse#>}
{##}
{##}
{##function filesys_create_open #<(}
{##                fyle : file_ptr;}
{##                related_file : file_ptr;}
{##                msgs : boolean)}
{##        : boolean#>;}
{##}
{##  label 99;}
{##}
{##  var}
{##    expanded_name, resultant_name : file_name_str;}
{##    xabpro, xabfhc, xabdat : xab$type;}
{##    error_message : varying [max_strlen] of char;}
{##    rms_error : array [0..2] of unsigned;}
{##}
{##  begin #<filesys_create_open#>}
{##  filesys_create_open := false;}
{#if debug}
{##  if (vms_fab$c_bln <> fab$c_bln) or}
{##     (vms_rab$c_bln <> rab$c_bln) or}
{##     (vms_nam$c_bln <> nam$c_bln) or}
{##     (file_name_len <> nam$c_maxrss) or}
{##     (fyle^.zed <> 'Z') then}
{##    begin}
{##    screen_message(dbg_badfile);}
{##    goto 99;}
{##    end;}
{#endif}
{##  with fyle^, fab::fab$type, rab::rab$type, nam::nam$type do}
{##    begin}
{##    #< Initialize the FAB. #>}
{##    fab := zero;}
{##    fab$b_bid := fab$c_bid;}
{##    fab$b_bln := fab$c_bln;}
{##    fab$l_fna := iaddress(fnm);}
{##    fab$b_fns := fns;}
{##    fab$l_dna := iaddress(dnm);}
{##    fab$b_dns := dns;}
{##    fab$l_nam := iaddress(nam);}
{##    #< Initialize the RAB. #>}
{##    rab := zero;}
{##    rab$b_bid := rab$c_bid;}
{##    rab$b_bln := rab$c_bln;}
{##    rab$l_fab := iaddress(fab);}
{##    rab$b_mbc := 12;}
{##    rab$l_rop := rab$m_rah + rab$m_wbh + rab$m_loc;}
{##    #< Initialize the NAM. #>}
{##    nam := zero;}
{##    nam$b_bid := nam$c_bid;}
{##    nam$b_bln := nam$c_bln;}
{##    nam$l_esa := iaddress(expanded_name);}
{##    nam$b_ess := file_name_len;}
{##    nam$l_rsa := iaddress(fnm);}
{##    nam$b_rss := file_name_len;}
{##    eof := false;}
{##    if not output_flag then}
{##      begin #< Open an existing file for read access. #>}
{##      #< Initialize the XABFHC. #>}
{##      xabfhc := zero;}
{##      with xabfhc do}
{##        begin}
{##        xab$b_cod := xab$c_fhc;}
{##        xab$b_bln := xab$c_fhclen;}
{##        end;}
{##      fab$l_xab := iaddress(xabfhc);}
{##      rbf_ind := 0;}
{##      skipping_after_cr := true;}
{##      if odd($open(fab)) then}
{##        begin}
{##        #< FNM has been replaced by the resultant name. #>}
{##        fns := nam$b_rsl;}
{##        #< Allocate a read buffer of size LRL. #>}
{##        if xabfhc.xab$w_lrl = 0 then xabfhc.xab$w_lrl := 1024;}
{##        with buf_dsc do}
{##          begin}
{##          typ := 512;}
{##          len := 0;}
{##          str := nil;}
{##          vms_check_status(lib$sget1_dd(xabfhc.xab$w_lrl,buf_dsc));}
{##          rab$l_ubf := str::integer;}
{##          rab$w_usz := len;}
{##          end;}
{##        #<}
{##        ! Process the record attributes.}
{##        ! . Process record oriented devices as CR files.}
{##        ! . Set a default PRN for non PRN files.}
{##        ! . Reset the attribute field to the value to be assigned}
{##        !   to a related output file.}
{##        #>}
{##        fab$v_blk := false;}
{##        if fab$l_dev::dev$type.dev$v_rec then}
{##          fab$b_rat := fab$m_cr;}
{##        if fab$b_rat = 0 then}
{##          begin}
{##          #< No end-of-line's. #>}
{##          prn_default.prefix := 0;}
{##          prn_default.postfix := 0}
{##          end}
{##        else}
{##          begin}
{##          #< LF at beginning of record and CR at end of record. #>}
{##          prn_default.prefix := 1;}
{##          prn_default.postfix := 128 + ord(ascii_cr);}
{##          end;}
{##        case fab$b_rat of}
{##          0:}
{##            fab$b_rat := fab$m_cr;}
{##          fab$m_prn:}
{##            begin}
{##            rab$l_rhb := iaddress(prn);}
{##            #< PRN files written as VAR files. #>}
{##            fab$b_rfm := fab$c_var;}
{##            fab$b_rat := fab$m_cr;}
{##            end;}
{##          otherwise}
{##            ;}
{##        end#<case#>;}
{##        end}
{##      else}
{##        begin}
{##        #<}
{##        ! If FNM has been replaced by the resultant name,}
{##        ! then update its length.}
{##        #>}
{##        if nam$b_rsl <> 0 then}
{##          fns := nam$b_rsl;}
{##        end;}
{##      end}
{##    else}
{##      begin #< Create a new file. #>}
{##      if related_file <> nil then}
{##        begin}
{##        nam$l_rlf := iaddress(related_file^.nam);}
{##        if fns <> 0 then}
{##          fab$v_ofp := true;}
{##        end;}
{##      #< Parse to get the real file name and device characteristics. #>}
{##      if odd($parse(fab)) then}
{##        begin}
{##        fnm := expanded_name;}
{##        fns := nam$b_esl;}
{##        fab$b_fns := fns;}
{##        nam$l_rlf := 0;}
{##        with fab$l_dev::dev$type do}
{##          directory_structured := dev$v_dir and}
{##                                  not (dev$v_sdi or dev$v_for);}
{##        if directory_structured then}
{##          begin}
{##          #< Initialize the XABDAT. #>}
{##          xabdat := zero;}
{##          with xabdat do}
{##            begin}
{##            xab$b_cod := xab$c_dat;}
{##            xab$b_bln := xab$c_datlen;}
{##            end;}
{##          fab$l_xab := iaddress(xabdat);}
{##          #< Check if there is an existing version of the file. #>}
{##          nam$l_rsa := iaddress(resultant_name);}
{##          if odd($open(fab)) then}
{##            begin}
{##            $close(fab);}
{##            if create or}
{##                (substr(expanded_name ,1,nam$b_esl) =}
{##                 substr(resultant_name,1,nam$b_rsl)) then}
{##              begin}
{##              error_message := 'File ' + substr(resultant_name,1,nam$b_rsl) +}
{##                               ' already exists.';}
{##              screen_message(error_message);}
{##              fab$l_xab := 0;}
{##              goto 99;}
{##              end;}
{##            previous_file_id := xabdat.xab$q_rdt;}
{##            nam$b_rsl := 0;}
{##            end;}
{##          #< Create file with a temporary name and rename after close. #>}
{##          tnm := fnm;}
{##          tns := fns;}
{##          while tnm[tns] <> ';' do}
{##            tns := tns - 1;}
{##          tnm[tns  ] := '-';}
{##          tnm[tns+1] := 'L';}
{##          tnm[tns+2] := 'W';}
{##          tns := tns + 2;}
{##          fab$l_fna := iaddress(tnm);}
{##          fab$b_fns := tns;}
{##          #< Initialize the XABPRO. #>}
{##          xabpro := zero;}
{##          with xabpro do}
{##            begin}
{##            xab$b_cod := xab$c_pro;}
{##            xab$b_bln := xab$c_prolen;}
{##            xab$w_pro := %xff00;  #< (RWED,RWED,,) #>}
{##            end;}
{##          fab$l_xab := iaddress(xabpro);}
{##          nam$l_rsa := iaddress(tnm);}
{##          end;}
{##        fab$b_fac := fab$m_put;}
{##        fab$l_fop := fab$m_sqo + fab$m_tef;}
{##        #< Process record format. #>}
{##        case format of}
{##          same_format:}
{##            if related_file <> nil then}
{##              begin}
{##              case related_file^.fab::fab$type.fab$b_rfm of}
{##                fab$c_fix,}
{##                fab$c_var:   fab$b_rfm := fab$c_var;}
{##                fab$c_vfc:   fab$b_rfm := fab$c_vfc;}
{##                fab$c_stm,}
{##                fab$c_stmcr,}
{##                fab$c_stmlf: fab$b_rfm := fab$c_stmlf;}
{##                otherwise    fab$b_rfm := fab$c_var;}
{##              end#<case#>;}
{##              end}
{##            else}
{##              fab$b_rfm := fab$c_var;}
{##          variable:}
{##            fab$b_rfm := fab$c_var;}
{##          stream_lf:}
{##            fab$b_rfm := fab$c_stmlf;}
{##          numbered:}
{##            fab$b_rfm := fab$c_vfc;}
{##        end#<case#>;}
{##        if fab$b_rfm = fab$c_vfc then}
{##          begin}
{##          fab$b_fsz := 2;}
{##          rab$l_rhb := iaddress(l_counter);}
{##          end;}
{##        #< Process record attribute. #>}
{##        case attribute of}
{##          same_attribute:}
{##            if related_file <> nil then}
{##              fab$b_rat := related_file^.fab::fab$type.fab$b_rat}
{##            else}
{##              fab$b_rat := fab$m_cr;}
{##          carriage_return:}
{##            fab$b_rat := fab$m_cr;}
{##          fortran_attribute:}
{##            fab$b_rat := fab$m_ftn;}
{##        end#<case#>;}
{##        if fab$b_rat <> fab$m_cr then}
{##          entab := false;}
{##        if related_file <> nil then}
{##          begin}
{##          fab$l_alq := related_file^.fab::fab$type.fab$l_alq;}
{##          fab$w_deq := related_file^.fab::fab$type.fab$w_deq;}
{##          end}
{##        else}
{##          begin}
{##          fab$w_deq := 12;}
{##          end;}
{##        if odd($create(fab)) then}
{##          begin}
{##          if not directory_structured then}
{##            fns := nam$b_rsl;}
{##          end}
{##        else}
{##          begin}
{##          if nam$b_rsl <> 0  then}
{##            begin}
{##            if directory_structured then}
{##              fnm := tnm;}
{##            fns := nam$b_rsl;}
{##            end;}
{##          end;}
{##        end;}
{##      end;}
{##    if odd(fab$l_sts) then}
{##      begin}
{##      if not odd($connect(rab)) then}
{##        begin}
{##        #< Copy the error status to the fab. #>}
{##        fab$l_sts := rab$l_sts;}
{##        fab$l_stv := rab$l_stv;}
{##        end;}
{##      end;}
{##    if odd(fab$l_sts) then}
{##      filesys_create_open := true}
{##    else if msgs then}
{##      begin}
{##      error_message := 'Error opening ';}
{##      if (nam$b_rsl = 0) and (nam$b_esl <> 0) then}
{##        error_message := error_message + substr(expanded_name,1,nam$b_esl)}
{##      else}
{##        error_message := error_message + substr(fnm,1,fns);}
{##      if output_flag then}
{##        error_message := error_message + ' for output.'}
{##      else}
{##        error_message := error_message + ' for input.';}
{##      screen_message(error_message);}
{##      rms_error[0] := 2;}
{##      rms_error[1] := fab$l_sts;}
{##      rms_error[2] := fab$l_stv;}
{##      sys$putmsg(rms_error, screen_vms_message);}
{##      end;}
{##    fab$l_xab := 0;}
{##    end;}
{##99:}
{##  end; #<filesys_create_open#>}
{##}
{##}
{##function filesys_close #<(}
{##                fyle   : file_ptr;}
{##                delete : boolean;}
{##                msgs   : boolean)}
{##        : boolean#>;}
{##}
{##  var}
{##    fab2 : fab$type;}
{##    nam2 : nam$type;}
{##    length : integer;}
{##    xabpro : xab$type;}
{##    lines, message : varying [max_strlen] of char;}
{##    rms_error : array [0..2] of unsigned;}
{##    resultant_name, expanded_name1, expanded_name2 : file_name_str;}
{##}
{##  function lib$set_logical(}
{##                  log_nam : [class_s] packed array [l1..h1:integer] of char;}
{##                  value   : [class_s] packed array [l2..h2:integer] of char)}
{##          : integer; external;}
{##}
{##  begin #<filesys_close#>}
{##  filesys_close := false;}
{##  with fyle^, fab::fab$type, nam::nam$type do}
{##    begin}
{##    if not output_flag then}
{##      vms_check_status(lib$sfree1_dd(buf_dsc))}
{##    else}
{##      begin}
{##      if delete then}
{##        begin}
{##        fab$v_dlt := true;}
{##        end}
{##      end;}
{##    $close(fab);}
{##    if odd(fab$l_sts) and output_flag and not delete and}
{##       directory_structured then}
{##      begin}
{##      tns := nam$b_rsl;}
{##      fab$l_fna := iaddress(tnm);}
{##      fab$b_fns := tns;}
{##      nam$l_esa := iaddress(expanded_name1);}
{##      nam$l_rsa := 0;}
{##      nam$b_rss := 0;}
{##      fab2 := zero;}
{##      nam2 := zero;}
{##      with fab2, nam2 do}
{##        begin}
{##        fab$b_bid := fab$c_bid;}
{##        fab$b_bln := fab$c_bln;}
{##        fab$l_fna := iaddress(fnm);}
{##        fab$b_fns := fns;}
{##        fab$l_nam := iaddress(nam2);}
{##        nam$b_bid := nam$c_bid;}
{##        nam$b_bln := nam$c_bln;}
{##        nam$l_esa := iaddress(expanded_name2);}
{##        nam$b_ess := file_name_len;}
{##        nam$l_rsa := iaddress(resultant_name);}
{##        nam$b_rss := file_name_len;}
{##        xabpro := zero;}
{##        with xabpro do}
{##          begin}
{##          xab$b_cod := xab$c_pro;}
{##          xab$b_bln := xab$c_prolen;}
{##          xab$v_propagate := true;}
{##          end;}
{##        fab$l_xab := iaddress(xabpro);}
{##        end;}
{##      $rename(fab,,,fab2);}
{##      if odd(fab$l_sts) then}
{##        begin}
{##        fnm := resultant_name;}
{##        fns := nam2.nam$b_rsl;}
{##        end}
{##      else}
{##        begin}
{##        message := 'Error renaming ' + substr(tnm,1,tns) +}
{##                   ' to ' + substr(fnm,1,fns) + '.';}
{##        screen_message(message);}
{##        rms_error[0] := 2;}
{##        rms_error[1] := fab$l_sts;}
{##        rms_error[2] := fab$l_stv;}
{##        sys$putmsg(rms_error, screen_vms_message);}
{##        fnm := tnm;}
{##        fns := tns;}
{##        fab$l_sts := ss$_normal;}
{##        end;}
{##      end;}
{##    if odd(fab$l_sts) then}
{##      begin}
{##      if msgs then}
{##        begin}
{##        writev(lines,l_counter:1,' line');}
{##        if l_counter <> 1 then lines := lines + 's';}
{##        message := 'File ' + substr(fnm,1,fns);}
{##        if output_flag then}
{##          if delete then}
{##            message := message + ' deleted.'}
{##          else}
{##            begin}
{##            message := message + ' created (' + lines + ' written).';}
{##            length := ch_length(memory,max_strlen);}
{##            if length > 0 then}
{##              begin}
{##              tns := index(substr(fnm,1,fns),';');}
{##              if tns <> 0 then}
{##                fns := tns - 1;}
{##              lib$set_logical(substr(memory,1,length),substr(fnm,1,fns));}
{##              end;}
{##            end}
{##        else}
{##          message := message + ' closed (' + lines + ' read).';}
{##        screen_message(message);}
{##        end;}
{##      end}
{##    else}
{##      begin}
{##      message := 'Error trying to close ' + substr(fnm,1,fns) + '.';}
{##      screen_message(message);}
{##      rms_error[0] := 2;}
{##      rms_error[1] := fab$l_sts;}
{##      rms_error[2] := fab$l_stv;}
{##      sys$putmsg(rms_error, screen_vms_message);}
{##      end;}
{##    end;}
{##  filesys_close := true;}
{##  end; #<filesys_close#>}
{##}
{##}
{##function filesys_read #<(}
{##                fyle   : file_ptr;}
{##        var     buffer : str_object;}
{##        var     outlen : strlen_range)}
{##        : boolean#>;}
{##}
{##  #<++}
{##  ! Description:}
{##  !   This routine forms "lines" out of the input file. Great care is}
{##  !   taken to try to interpret most of the input sensibly, especially}
{##  !   TAB, LF, VT, FF, CR.}
{##  ! Input Parameters:}
{##  !   fyle    provides context}
{##  ! Output Parameters:}
{##  !   buffer  returns the text of the line}
{##  !   outlen  returns the length of the line}
{##  ! Function value:}
{##  !   Indicates whether a valid line has been returned.}
{##  ! Side effects:}
{##  !   fyle^.eof is set when end-of-file or an error is encountered.}
{##  !   fyle^.lf_count <> 0 while processing LF counts from a PRN field.}
{##  !   fyle^.rbf_ind records current position in record buffer.}
{##  !   fyle^.skipping_after_cr is set after encountering a CR.  It is}
{##  !     turned off by the next terminator or printing character.}
{##  !--#>}
{##}
{##  label read_new_record,}
{##        process_buffer,}
{##        process_PRN_field,}
{##        process_control_character,}
{##        return,}
{##        fail;}
{##}
{##  var}
{##    ch : char;}
{##    int, i : integer;}
{##    status : vms_status_code;}
{##    error_message : varying [max_strlen] of char;}
{##    rms_error : array [0..2] of unsigned;}
{##}
{##  begin #<filesys_read#>}
{##  with fyle^, rab::rab$type do}
{##    begin}
{##    filesys_read := false;}
{##    outlen := 0;}
{##    if lf_count > 0 then}
{##      begin}
{##      lf_count := lf_count - 1;}
{##      goto return;}
{##      end;}
{##}
{##    if rbf_ind < rab$w_rsz then}
{##      goto process_buffer;}
{##}
{##  read_new_record:}
{##    prn := prn_default;}
{##    rbf_ind := 0;}
{##    status := $get(rab);}
{##    if not odd(status) then}
{##      begin}
{##      if status = rms$_eof then}
{##        begin}
{##        eof := true;}
{##        if outlen > 0 then}
{##          goto return;}
{##        goto fail;}
{##        end}
{##      else}
{##        begin}
{##        error_message := 'Error reading ' + substr(fnm,1,fns) + '.';}
{##        if status = rms$_rtb then}
{##          error_message := error_message + ' Record truncated.';}
{##        screen_message(error_message);}
{##        rms_error[0] := 2;}
{##        rms_error[1] := status;}
{##        rms_error[2] := rab$l_stv;}
{##        sys$putmsg(rms_error, screen_vms_message);}
{##        eof := status mod 8 = 4;}
{##        if eof then}
{##          goto fail;}
{##        end;}
{##      end;}
{##    if prn.prefix <> 0 then}
{##      begin}
{##      int := prn.prefix;}
{##      goto process_PRN_field;}
{##      end;}
{##}
{##  process_buffer:}
{##    while rbf_ind < rab$w_rsz do}
{##      begin}
{##      rbf_ind := rbf_ind + 1;}
{##      ch := rab$l_rbf::rms_record_ptr^[rbf_ind];}
{##      if not (ord(ch) in printable_set) then}
{##        goto process_control_character;}
{##      skipping_after_cr := false;}
{##      if outlen = max_strlen then}
{##        begin}
{##        rbf_ind := rbf_ind - 1;}
{##        screen_message(msg_long_input_line);}
{##        goto return;}
{##        end;}
{##      outlen := outlen + 1;}
{##      buffer[outlen] := ch;}
{##      end;}
{##    if prn.postfix <> 0 then}
{##      begin}
{##      int := prn.postfix;}
{##      prn.postfix := 0;}
{##      goto process_PRN_field;}
{##      end;}
{##    goto read_new_record;}
{##}
{##  process_PRN_field:}
{##    #< int <> 0 #>}
{##    if int <= 127 then}
{##      begin #< 1..127 -> LF count. #>}
{##      lf_count := int - 1;}
{##      ch := ascii_lf;}
{##      goto process_control_character;}
{##      end}
{##    else if int <= 159 then}
{##      begin #< 128..159 -> C0 character. #>}
{##      ch := chr(int-128);}
{##      goto process_control_character;}
{##      end}
{##    else if (int >= 192) and (int <=223) then}
{##      begin #< 192..223 -> C1 character. #>}
{##      ch := chr(int-64);}
{##      goto process_control_character;}
{##      end}
{##    else}
{##      #< 160..191, 224..255 -> ignore. #>}
{##      goto process_buffer;}
{##}
{##  process_control_character:}
{##    case ch of}
{##      ascii_ht:}
{##        begin}
{##        skipping_after_cr := false;}
{##        if outlen = max_strlen then}
{##          begin}
{##          rbf_ind := rbf_ind - 1;}
{##          screen_message(msg_long_input_line);}
{##          goto return;}
{##          end;}
{##        int := min(8 - outlen mod 8, max_strlen - outlen);}
{##        for i := 1 to int do}
{##          begin}
{##          outlen := outlen + 1;}
{##          buffer[outlen] := ' ';}
{##          end;}
{##        goto process_buffer;}
{##        end;}
{##      ascii_lf, ascii_vt, ascii_ff:}
{##        begin}
{##        if skipping_after_cr then}
{##          begin}
{##          skipping_after_cr := false;}
{##          goto process_buffer;}
{##          end}
{##        else}
{##          begin}
{##          skipping_after_cr := false;}
{##          goto return;}
{##          end;}
{##        end;}
{##      ascii_cr:}
{##        begin}
{##        if skipping_after_cr then}
{##          goto process_buffer}
{##        else}
{##          begin}
{##          skipping_after_cr := true;}
{##          goto return;}
{##          end;}
{##        end;}
{##      otherwise}
{##        goto process_buffer;}
{##    end#<case#>;}
{##}
{##  return:}
{##    l_counter := l_counter + 1;}
{##    filesys_read := true;}
{##  fail:}
{##    end; #<with#>}
{##  end; #<filesys_read#>}
{##}
{##}
{##function filesys_write #<(}
{##                fyle   : file_ptr;}
{##        var     buffer : str_object;}
{##                bufsiz : strlen_range)}
{##        : boolean#>;}
{##}
{##  #<++}
{##  ! Description:}
{##  !   This routines writes one line to the given file.}
{##  !   If reqested, leading spaces are replaces by tabs.}
{##  ! Parameters:}
{##  !   fyle    provides context}
{##  !   buffer  the text to be written (VAR to get reference in Unix pc)}
{##  !   bufsiz  the length of the text}
{##  ! Function value:}
{##  !   Fails if the call to the system write routine fails.}
{##  ! Side effects:}
{##  !   Issues messages.}
{##  !--#>}
{##}
{##  var}
{##    nr_spaces, nr_tabs, i : integer;}
{##    status : vms_status_code;}
{##    error_message : varying [max_strlen] of char;}
{##    rms_error : array [0..2] of unsigned;}
{##}
{##  begin #<filesys_write#>}
{##  filesys_write := false;}
{##  with fyle^, rab::rab$type do}
{##    begin}
{##    nr_tabs := 0;}
{##    if entab and (bufsiz > 0) then}
{##      begin}
{##      nr_spaces := 0;}
{##      while (nr_spaces < bufsiz) and (buffer[nr_spaces+1] = ' ') do}
{##        nr_spaces := nr_spaces + 1;}
{##      nr_tabs := nr_spaces div 8;}
{##      end;}
{##    if nr_tabs <> 0 then}
{##      begin}
{##      for i := 1 to nr_tabs do}
{##        buffer[nr_tabs*7+i] := ascii_ht;}
{##      rab$l_rbf := iaddress(buffer) + nr_tabs * 7;}
{##      rab$w_rsz := bufsiz - nr_tabs * 7;}
{##      end}
{##    else}
{##      begin}
{##      rab$l_rbf := iaddress(buffer);}
{##      rab$w_rsz := bufsiz;}
{##      end;}
{##    l_counter := l_counter + 1;}
{##    status := $put(rab);}
{##    if (status = rms$_ext) and (rab$l_stv = ss$_exdiskquota) then}
{##      begin}
{##      #< Try again--may be able to go into overdraft. #>}
{##      status := $put(rab);}
{##      if odd(status) then}
{##        begin}
{##        screen_message('Now using disk quota overdraft, writing file ' +}
{##                       substr(fnm,1,fns) + '.');}
{##        filesys_write := true;}
{##        end;}
{##      end;}
{##    if odd(status) then}
{##      filesys_write := true}
{##    else}
{##      begin}
{##      l_counter := l_counter - 1;}
{##      screen_message('Error writing ' + substr(fnm,1,fns) + '.');}
{##      rms_error[0] := 2;}
{##      rms_error[1] := status;}
{##      rms_error[2] := rab$l_stv;}
{##      sys$putmsg(rms_error, screen_vms_message);}
{##      end;}
{##    if nr_tabs <> 0 then}
{##      begin}
{##      for i := 1 to nr_tabs do}
{##        buffer[nr_tabs*7+i] := ' ';}
{##      end;}
{##    end;}
{##  end; #<filesys_write#>}
{##}
{##}
{##function filesys_rewind #<(}
{##                fyle   : file_ptr)}
{##        : boolean#>;}
{##}
{##  #<++}
{##  ! Description:}
{##  !   This routines rewinds the given file.}
{##  ! Parameters:}
{##  !   fyle    provides file context.}
{##  ! Function value:}
{##  !   Fails if the call to the system rewind routine fails.}
{##  ! Side effects:}
{##  !   Issues messages.}
{##  !--#>}
{##}
{##  var}
{##    status : vms_status_code;}
{##    rms_error : array [0..2] of unsigned;}
{##}
{##  begin #<filesys_rewind#>}
{##  filesys_rewind := false;}
{##  with fyle^, rab::rab$type do}
{##    begin}
{##    status := $rewind(rab);}
{##    if odd(status) then}
{##      begin}
{##      eof := false;}
{##      skipping_after_cr := true;}
{##      lf_count := 0;}
{##      l_counter := 0;}
{##      filesys_rewind := true;}
{##      end}
{##    else}
{##      begin}
{##      screen_message('Error rewinding ' + substr(fnm,1,fns) + '.');}
{##      rms_error[0] := 2;}
{##      rms_error[1] := status;}
{##      rms_error[2] := rab$l_stv;}
{##      sys$putmsg(rms_error, screen_vms_message);}
{##      end;}
{##    end;}
{##  end; #<filesys_rewind#>}
{##}
{##}
{##end.}
{#else}
***** This file is not relevant to this operating system.
{#endif}
