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
! Name:         VDU_VMS
!
! Description:  This module does all the complex control of the VDU type
!               screens that Ludwig demands.
!               This is the VMS version.
!               Currently most of the VMS version of VDU is still in
!               Bliss.  This module contains new routines and some
!               rewritten routines.
!
! Revision History:
! 4-001 Kelvin B. Nicolle                                    16-Dec-1986
!       The Pascal version started.
!--}

{#if vms}
{##[ident('4-001'),}
{## inherit('sys$library:starlet')]}
{##module vdu_vms (output);}
{##}
{##%include 'const.inc/nolist'}
{##%include 'type.inc/nolist'}
{##var}
{##  parse_table : parse_table_ptr;}
{##  introducers : accept_set_type;}
{##  trmhnd_data : [external] record}
{##                imag_x  : integer;}
{##                imag_y  : integer;}
{##                real_x  : integer;}
{##                real_y  : integer;}
{##                channel : integer;}
{##                efn   : integer;}
{##                putstr: integer;}
{##                getesc: integer;}
{##                fail  : integer;}
{##                speed : integer;}
{##                nuls  : integer;}
{##                nlln  : integer;}
{##                nlch  : integer;}
{##                nlcl  : integer;}
{##                ownarea : packed array [1..32] of byte;}
{##                sysarea : packed array [1..32] of byte;}
{##                end;}
{##  wait_efn : [external] integer;}
{##  takeback_flag : [external] boolean;}
{##  takeback_buffer : [external,word] key_code_range;}
{##}
{##}
{##%include 'vdu_vms.fwd/nolist'}
{##%include 'screen.ext/nolist'}
{##%include 'vdu.ext/nolist'}
{##%include 'vms.ext/nolist'}
{##}
{##procedure vdu_keyboard_init #<(}
{##        var     nr_key_names      : key_names_range;}
{##        var     key_name_list_ptr : key_name_array_ptr;}
{##        var     key_introducers   : accept_set_type;}
{##        var     terminal_info     : terminal_info_type)#>;}
{##}
{##  #<++}
{##  !  Purpose:}
{##  !    Open the keyboard definitions file.}
{##  !    Read the key names table.}
{##  !    Read the keyboard parser table.}
{##  !    Read the keyboard sequences introducer character set.}
{##  !    Load the 32 control key name definitions.}
{##  !--#>}
{##}
{##  label}
{##    98, #< Definitions file does not exist, or is invalid; #>}
{##        #<   the 32 control key names are to be loaded.    #>}
{##    99; #< Definitions file does not exist, or is invalid. #>}
{##}
{##  var}
{##    fab : fab$type;}
{##    rab : rab$type;}
{##    termdesc, terminal : varying [255] of char;}
{##    size_item, nr_items : word;}
{##    descr : string_descriptor;}
{##}
{##  function lib$sys_trnlog(}
{##                  logical_name : [class_s] packed array [l1..h1:integer] of char;}
{##          var     dst_len      : word := %immed 0;}
{##          var     dst_str      : [class_s] packed array [l3..h3:integer] of char)}
{##          : integer; external;}
{##}
{##  begin #<vdu_keyboard_init#>}
{##  #< Set up a few things in case the description file is absent/in error. #>}
{##  nr_key_names := 0;}
{##  size_item := size(key_name_record);}
{##  key_name_list_ptr := nil;}
{##  parse_table := nil;}
{##  key_introducers := [];}
{##  #< Open the terminal description file. #>}
{##  with fab, rab do}
{##    begin}
{##    termdesc := 'TERMDESC:.BIN';}
{##    terminal := 'TRMHND:';}
{##    #< Initialize the FAB. #>}
{##    fab := zero;}
{##    fab$b_bid := fab$c_bid;}
{##    fab$b_bln := fab$c_bln;}
{##    fab$b_fac := fab$m_get;}
{##    fab$l_fop := fab$m_sqo;}
{##    fab$l_fna := iaddress(termdesc.body);}
{##    fab$b_fns := termdesc.length;}
{##    fab$l_dna := iaddress(terminal.body);}
{##    fab$b_dns := terminal.length;}
{##    if not odd($open(fab)) then}
{##      begin}
{##      screen_message(msg_error_opening_keys_file);}
{##      goto 98;}
{##      end;}
{##    #< Initialize the RAB. #>}
{##    rab := zero;}
{##    rab$b_bid := rab$c_bid;}
{##    rab$b_bln := rab$c_bln;}
{##    rab$l_fab := iaddress(fab);}
{##    if not odd($connect(rab)) then}
{##      begin}
{##      screen_message(msg_error_opening_keys_file);}
{##      goto 98;}
{##      end;}
{##    #< Read the key name table. #>}
{##    rab$l_ubf := iaddress(size_item);}
{##    rab$w_usz := 2;}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 98;}
{##      end;}
{##    if size_item <> size(key_name_record) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 98;}
{##      end;}
{##    rab$l_ubf := iaddress(nr_items);}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 98;}
{##      end;}
{##    nr_key_names := nr_items;}
{##  98: #<}
{##      ! If anything has gone wrong with reading the keyboard}
{##      ! definitions, we pick up here and load the control key names.}
{##      #>}
{##    nr_key_names := nr_key_names + 32;}
{##    with descr do}
{##      begin}
{##      typ := 512;}
{##      len := 0;}
{##      str := nil;}
{##      end;}
{##    if not odd(lib$sget1_dd(size_item * (nr_key_names+1),descr)) then}
{##      begin}
{##      screen_message(msg_exceeded_dynamic_memory);}
{##      goto 99;}
{##      end;}
{##    key_name_list_ptr := descr.str::key_name_array_ptr;}
{##    key_name_list_ptr^[ 1] := key_name_record('CONTROL-@', 0);}
{##    key_name_list_ptr^[ 2] := key_name_record('CONTROL-A', 1);}
{##    key_name_list_ptr^[ 3] := key_name_record('CONTROL-B', 2);}
{##    key_name_list_ptr^[ 4] := key_name_record('CONTROL-C', 3);}
{##    key_name_list_ptr^[ 5] := key_name_record('CONTROL-D', 4);}
{##    key_name_list_ptr^[ 6] := key_name_record('CONTROL-E', 5);}
{##    key_name_list_ptr^[ 7] := key_name_record('CONTROL-F', 6);}
{##    key_name_list_ptr^[ 8] := key_name_record('CONTROL-G', 7);}
{##    key_name_list_ptr^[ 9] := key_name_record('CONTROL-H', 8);}
{##    key_name_list_ptr^[10] := key_name_record('CONTROL-I', 9);}
{##    key_name_list_ptr^[11] := key_name_record('CONTROL-J',10);}
{##    key_name_list_ptr^[12] := key_name_record('CONTROL-K',11);}
{##    key_name_list_ptr^[13] := key_name_record('CONTROL-L',12);}
{##    key_name_list_ptr^[14] := key_name_record('CONTROL-M',13);}
{##    key_name_list_ptr^[15] := key_name_record('CONTROL-N',14);}
{##    key_name_list_ptr^[16] := key_name_record('CONTROL-O',15);}
{##    key_name_list_ptr^[17] := key_name_record('CONTROL-P',16);}
{##    key_name_list_ptr^[18] := key_name_record('CONTROL-Q',17);}
{##    key_name_list_ptr^[19] := key_name_record('CONTROL-R',18);}
{##    key_name_list_ptr^[20] := key_name_record('CONTROL-S',19);}
{##    key_name_list_ptr^[21] := key_name_record('CONTROL-T',20);}
{##    key_name_list_ptr^[22] := key_name_record('CONTROL-U',21);}
{##    key_name_list_ptr^[23] := key_name_record('CONTROL-V',22);}
{##    key_name_list_ptr^[24] := key_name_record('CONTROL-W',23);}
{##    key_name_list_ptr^[25] := key_name_record('CONTROL-X',24);}
{##    key_name_list_ptr^[26] := key_name_record('CONTROL-Y',25);}
{##    key_name_list_ptr^[27] := key_name_record('CONTROL-Z',26);}
{##    key_name_list_ptr^[28] := key_name_record('CONTROL-[',27);}
{##    key_name_list_ptr^[29] := key_name_record('CONTROL-\',28);}
{##    key_name_list_ptr^[30] := key_name_record('CONTROL-]',29);}
{##    key_name_list_ptr^[31] := key_name_record('CONTROL-^',30);}
{##    key_name_list_ptr^[32] := key_name_record('CONTROL-_',31);}
{##    if nr_key_names = 32 then}
{##      goto 99; #< An error has occurred earlier. #>}
{##    rab$l_ubf := iaddress(key_name_list_ptr^) + size_item * 33;}
{##    rab$w_usz := size_item * nr_items;}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    #< Read the parse table. #>}
{##    rab$l_ubf := iaddress(size_item);}
{##    rab$w_usz := 2;}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    if size_item <> size(parse_table_record) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    rab$l_ubf := iaddress(nr_items);}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    with descr do}
{##      begin}
{##      typ := 512;}
{##      len := 0;}
{##      str := nil;}
{##      end;}
{##    if not odd(lib$sget1_dd(size_item * nr_items,descr)) then}
{##      begin}
{##      screen_message(msg_exceeded_dynamic_memory);}
{##      goto 99;}
{##      end;}
{##    parse_table := descr.str::parse_table_ptr;}
{##    rab$l_ubf := iaddress(parse_table^);}
{##    rab$w_usz := size_item * nr_items;}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    #< Read the sequence introducer character set. #>}
{##    rab$l_ubf := iaddress(size_item);}
{##    rab$w_usz := 2;}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    if size_item <> size(char_set) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    rab$l_ubf := iaddress(key_introducers);}
{##    rab$w_usz := size_item;}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    #< Get ther terminal's generic name #>}
{##    rab$l_ubf := iaddress(size_item);}
{##    rab$w_usz := 2;}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    with descr do}
{##      begin}
{##      typ := 512;}
{##      len := 0;}
{##      str := nil;}
{##      end;}
{##    if not odd(lib$sget1_dd(size_item,descr)) then}
{##      begin}
{##      screen_message(msg_exceeded_dynamic_memory);}
{##      goto 99;}
{##      end;}
{##    terminal_info.name := descr.str;}
{##    rab$l_ubf := iaddress(terminal_info.name^);}
{##    rab$w_usz := size_item;}
{##    if not odd($get(rab)) then}
{##      begin}
{##      screen_message(msg_invalid_keys_file);}
{##      goto 99;}
{##      end;}
{##    terminal_info.namelen := size_item;}
{##    end;}
{##  #< Close the file. #>}
{##  if not odd($close(fab)) then;}
{##99:}
{##  introducers := key_introducers;}
{##  end; #<vdu_keyboard_init#>}
{##}
{##}
{##function vdu_get_key #<}
{##        : key_code_range#>;}
{##}
{##  label 99;}
{##  var}
{##    ch : char;}
{##    key : key_code_range;}
{##    ptr : parse_table_index;}
{##    terminators : array [1..2] of integer;}
{##    iosb : packed record}
{##           status : word;}
{##           count : word;}
{##           termch : packed array [1..2] of char;}
{##           termsz : word;}
{##           end;}
{##}
{##  begin #<vdu_get_key#>}
{##  vdu_get_key := 0;}
{##  terminators[1] := 0;}
{##  terminators[2] := 0;}
{##  if takeback_flag then}
{##    begin}
{##    key := takeback_buffer;}
{##    takeback_flag := false;}
{##    end}
{##  else}
{##    begin}
{##    vdu_flush(true);}
{##    key := 0; #< QIO will fill only the lower byte. #>}
{##    $qiow(chan := trmhnd_data.channel,}
{##          func := int(uor(io$_readvblk,}
{##                      uor(io$m_noecho,}
{##                          io$m_nofiltr))),}
{##          efn  := wait_efn,}
{##          iosb := iosb,}
{##          p1   := key,}
{##          p2   := 1,}
{##          p4   := %ref terminators);}
{##    if iosb.status <> ss$_normal then}
{##      goto 99;}
{##    end;}
{##  if key in introducers then}
{##    begin}
{##    ch := chr(key);}
{##    ptr := 0;}
{##    repeat}
{##      parse_table^[parse_table^[ptr].index].ch := ch;}
{##      repeat}
{##        ptr := ptr + 1;}
{##      until parse_table^[ptr].ch = ch;}
{##      key := parse_table^[ptr].key_code;}
{##      ptr := parse_table^[ptr].index;}
{##      if ptr <> 0 then}
{##        begin}
{##        $qiow(chan := trmhnd_data.channel,}
{##              func := int(uor(io$_readvblk,}
{##                          uor(io$m_noecho,}
{##                              io$m_nofiltr))),}
{##              efn  := wait_efn,}
{##              iosb := iosb,}
{##              p1   := ch,}
{##              p2   := 1,}
{##              p4   := %ref terminators);}
{##        if iosb.status <> ss$_normal then}
{##          goto 99;}
{##        end;}
{##    until ptr = 0;}
{##    end;}
{##  vdu_get_key := key;}
{##99:}
{##  end; #<vdu_getkey#>}
{##}
{##}
{##end.}
{#else}
***** This file is not relevant to this operating system.
{#endif}
