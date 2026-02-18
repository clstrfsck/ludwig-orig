{++
! Revision History:
! 4-001 Ludwig V4.0 release.                                  7-Apr-1987
! 4-002 Kelvin B. Nicolle                                     5-May-1987
!       Add the definition of the new variable ludwig_version.
! 4-003 Kelvin B. Nicolle                                    22-May-1987
!       Move the definition of ludwig_version into "version.inc".
! 4-004 Kelvin B. Nicolle                                    29-May-1987
!       Change the prompt on the I and O commands from no_prompt to
!       text_prompt.
!--}

value

%include 'version.inc/nolist'
  current_frame         := nil;
  files                 := (max_files of nil);
  files_frames          := (max_files of nil);
  first_span            := nil;
  ludwig_mode           := ludwig_batch;
  edit_mode             := mode_insert;
  command_introducer    := ord('\');
  scr_frame             := nil;
  scr_msg_row           := maxint;
  ludwig_aborted        := false;
  vdu_free_flag         := false;
  exec_level            := 0;

{ Set up the Free Group/Line/Mark Pools }
  free_group_pool       := nil;
  free_line_pool        := nil;
  free_mark_pool        := nil;

{ Set up all the Default Default characteristics for a frame.}

  initial_marks         := (max_mark_number-min_mark_number+1 of nil);
  initial_scr_height    := 1;           { Set to TT_HEIGHT for terminals. }
  initial_scr_width     := 132;         { Set to TT_WIDTH  for terminals. }
  initial_scr_offset    := 0;
  initial_margin_left   := 1;
  initial_margin_right  := 132;         { Set to TT_WIDTH  for terminals. }
  initial_margin_top    := 0;
  initial_margin_bottom := 0;
  initial_options       := [];

  blank_string          := (max_strlen of ' ');
  initial_verify        := (max_verify of false);
  default_tab_stops     := (true, max_strlen of false, true);

cmd_attrib:= (
{Noop        }([none,plus,minus,pint,nint,pindef,nindef,marker],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

			{ ARROW implements these commands. }
{Up          }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Down        }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Left        }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Right       }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Home        }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Return      }([none,plus,      pint                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Tab         }([none,plus,      pint                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{BackTab     }([none,plus,      pint                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{Rubout      }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Jump        }([none,plus,minus,pint,nint,pindef,nindef,marker],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Advance     }([none,plus,minus,pint,nint,pindef,nindef,marker],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{PositionCol }([none,plus,      pint                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{PositionLine}([none,plus,      pint                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{OpSysCommand}([none                                          ],eqnil, 1,((cmd_prompt,f,f),(no_prompt,f,f))),

{WindowForw  }([none,plus,      pint                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowBack  }([none,plus,      pint                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowLeft  }([none,plus,      pint                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowRight }([none,plus,      pint                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowScroll}([none,plus,minus,pint,nint,pindef,nindef       ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowTop   }([none                                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowEnd   }([none                                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowNew   }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowMiddle}([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowSetHei}([none,plus,      pint                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WindowUpdate}([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{Get         }([none,plus,minus,pint,nint                     ],eqnil, 1,((get_prompt,f,f),(no_prompt,f,f))),
{Next        }([none,plus,minus,pint,nint                     ],eqnil, 1,((char_prompt,f,f),(no_prompt,f,f))),
{Bridge      }([none,plus,minus                               ],eqnil, 1,((char_prompt,f,f),(no_prompt,f,f))),
{Replace     }([none,plus,minus,pint,nint,pindef,nindef       ],eqnil, 2,((replace_prompt,f,f),(by_prompt,f,t))),
{EqualString }([none,plus,minus,          pindef,nindef       ],eqnil, 1,((equal_prompt,f,f),(no_prompt,f,f))),
{EqualColumn }([none,plus,minus,          pindef,nindef       ],eqnil, 1,((column_prompt,t,f),(no_prompt,f,f))),
{EqualMark   }([none,plus,minus,          pindef,nindef       ],eqnil, 1,((mark_prompt,t,f),(no_prompt,f,f))),
{EqualEOL    }([none,plus,minus,          pindef,nindef       ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{EqualEOP    }([none,plus,minus                               ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{EqualEOF    }([none,plus,minus                               ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{OvertypeMode}([none                                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{InsertMode  }([none                                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{OvertypeText}([none,plus,      pint                          ],eqold, 1,((text_prompt,f,f),(no_prompt,f,f))),
{InsertText  }([none,plus,      pint                          ],eqold, 1,((text_prompt,f,t),(no_prompt,f,f))),
{TypeText    }([none,plus,      pint                          ],eqold, 1,((text_prompt,f,t),(no_prompt,f,f))),
{InsertLine  }([none,plus,minus,pint,nint                     ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{InsertChar  }([none,plus,minus,pint,nint                     ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{InsertInvis }([none,plus,      pint,     pindef              ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{DeleteLine  }([none,plus,minus,pint,nint,pindef,nindef,marker],eqdel, 0,((no_prompt,f,f),(no_prompt,f,f))),
{DeleteChar  }([none,plus,minus,pint,nint,pindef,nindef,marker],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{SwapLine    }([none,plus,minus,pint,nint,pindef,nindef,marker],eqdel, 0,((no_prompt,f,f),(no_prompt,f,f))),
{SplitLine   }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{DittoUp     }([none,plus,minus,pint,nint,pindef,nindef       ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{DittoDown   }([none,plus,minus,pint,nint,pindef,nindef       ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{CaseUp      }([none,plus,minus,pint,nint,pindef,nindef       ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{CaseLow     }([none,plus,minus,pint,nint,pindef,nindef       ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{CaseEdit    }([none,plus,minus,pint,nint,pindef,nindef       ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{SetMarginLef}([none,plus,minus                               ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{SetMarginRig}([none,plus,minus                               ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{LineFill    }([none,plus,      pint,     pindef              ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{LineJustify }([none,plus,      pint,     pindef              ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{LineSquash  }([none,plus,      pint,     pindef              ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{LineCenter  }([none,plus,      pint,     pindef              ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{LineLeft    }([none,plus,      pint,     pindef              ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{LineRight   }([none,plus,      pint,     pindef              ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WordAdvance }([none,plus,minus,pint,nint,pindef,nindef,marker],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{WordDelete  }([none,plus,minus,pint,nint,pindef,nindef,marker],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{ParagAdvance}([none,plus,minus,pint,nint,pindef,nindef,marker],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{ParagDelete }([none,plus,minus,pint,nint,pindef,nindef,marker],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{SpanDefine  }([none,plus,minus,pint,                   marker],eqnil, 1,((span_prompt,t,f),(no_prompt,f,f))),
{SpanTransfer}([none                                          ],eqnil, 1,((span_prompt,t,f),(no_prompt,f,f))),
{SpanCopy    }([none,plus,      pint                          ],eqnil, 1,((span_prompt,t,f),(no_prompt,f,f))),
{SpanCompile }([none                                          ],eqnil, 1,((span_prompt,t,f),(no_prompt,f,f))),
{SpanJump    }([none,plus,minus                               ],eqnil, 1,((span_prompt,t,f),(no_prompt,f,f))),
{SpanIndex   }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{SpanAssign  }([none,plus,minus,pint,nint,pindef              ],eqnil, 2,((span_prompt,t,f),(text_prompt,f,t))),

{BlockDefine }([none,plus,minus,pint,                   marker],eqnil, 1,((no_prompt,f,f),(no_prompt,f,f))),
{BlockTransf }([none                                          ],eqnil, 1,((no_prompt,f,f),(no_prompt,f,f))),
{BlockCopy   }([none,plus,      pint                          ],eqnil, 1,((no_prompt,f,f),(no_prompt,f,f))),

{FrameKill   }([none                                          ],eqnil, 1,((frame_prompt,t,f),(no_prompt,f,f))),
{FrameEdit   }([none                                          ],eqnil, 1,((frame_prompt,t,f),(no_prompt,f,f))),
{FrameReturn }([none,plus,      pint                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{FrameExecute}([none,plus,      pint,     pindef              ],eqnil, 1,((span_prompt,t,f),(no_prompt,f,f))),
{FrameNoComp }([none,plus,      pint,     pindef              ],eqnil, 1,((span_prompt,t,f),(no_prompt,f,f))),
{FrameParams }([none                                          ],eqnil, 1,((param_prompt,t,f),(no_prompt,f,f))),

{FileCreate  }([none,plus,minus                               ],eqnil,-1,((file_prompt,f,f),(no_prompt,f,f))),
{FileOpen    }([none,plus,minus                               ],eqnil,-1,((file_prompt,f,f),(no_prompt,f,f))),
{FileEdit    }([none,plus,minus                               ],eqnil, 1,((file_prompt,f,f),(no_prompt,f,f))),
{FileRead    }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{FileWrite   }([none,plus,minus,pint,nint,pindef,nindef,marker],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{FileClose   }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{FileRewind  }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{FileKill    }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{FileExecute }([none,plus,      pint,     pindef              ],eqnil, 1,((file_prompt,f,f),(no_prompt,f,f))),
{FileTable   }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{GlobalInput }([none,plus,minus                               ],eqnil,-1,((file_prompt,f,f),(no_prompt,f,f))),
{GlobalOutput}([none,plus,minus                               ],eqnil,-1,((file_prompt,f,f),(no_prompt,f,f))),
{GlobalRewind}([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{GlobalKill  }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{CommandIntro}([none                                          ],eqold, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Key         }([none                                          ],eqnil, 2,((key_prompt,t,f),(cmd_prompt,f,t))),
{Parent      }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Subprocess  }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Undo        }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Learn       }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Recall      }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{Help        }([none                                          ],eqnil, 1,((topic_prompt,t,f),(no_prompt,f,f))),
{Verify      }([none                                          ],eqnil, 1,((verify_prompt,t,f),(no_prompt,f,f))),
{Command     }([none,plus,minus                               ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Mark        }([none,plus,minus,pint,nint                     ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Page        }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Quit        }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Dump        }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{Validate    }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{ExecuteStrin}([none,plus,      pint,     pindef              ],eqnil, 1,((cmd_prompt,f,t),(no_prompt,f,f))),
{LastCommand }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{Extended    }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),

{ExitAbort   }([none                                          ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{ExitFail    }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{ExitSuccess }([none,plus,      pint,     pindef              ],eqnil, 0,((no_prompt,f,f),(no_prompt,f,f))),
{DummyPattern}([                                              ],eqnil, 1,((pattern_prompt,f,f),(no_prompt,f,f))),
{DummyText   }([                                              ],eqnil, 1,((text_prompt,f,f),(no_prompt,f,f)))

									  );


  {set up sets for prefixes}

	     { NOTE - this matches prefix_commands }
  prefixes:= [cmd_prefix_ast..cmd_prefix_tilde];

  repeatsyms:= ['+','-','@','<','>','=','0'..'9', ',', '.'];

  dflt_prompts :=(
		 '        ',
		 'Charset:',
		 'Get    :',
		 'Equal  :',
		 'Key    :',
		 'Command:',
		 'Span   :',
		 'Text   :',
		 'Frame  :',
		 'File   :',
		 'Column :',
		 'Mark   :',
		 'Param  :',
		 'Topic  :',
		 'Replace:',
		 'By     :',
		 'Verify ?',
		 'Pattern:',
		 'Pat Set:'
		);

  space_set     := [%x20];
		   { ' ' }
		   { the S (space) pattern specifier }

  numeric_set   := [%x30..%x39];
		   { '0'.. '9'}
		   { the N (numeric) pattern specifier }

  upper_set     := [%x41..%x5a, %xc0..%xcf, %xd1..%xdd];
		   { 'A'.. 'Z',  'À'.. 'Ï',  'Ñ'.. 'Ý'}
		   { the U (uppercase) pattern specifier }

  lower_set     := [%x61..%x7a, %xe0..%xef, %xf1..%xfd, %xdf];
		   { 'a'.. 'z',  'à'.. 'ï',  'ñ'.. 'ý',  'ß'}
		   { the L (lowercase) pattern specifier }

  alpha_set     := [%x41..%x5a, %xc0..%xcf, %xd1..%xdd] +
		   { 'A'.. 'Z',  'À'.. 'Ï',  'Ñ'.. 'Ý'}
		   [%x61..%x7a, %xe0..%xef, %xf1..%xfd, %xdf];
		   { 'a'.. 'z',  'à'.. 'ï',  'ñ'.. 'ý',  'ß'}
		   {the A (alphabetic) pattern specifier }

  punctuation_set := [%x21,%x22,%x27,%x28,%x29,%x2c,%x2e,%x3a,%x3b,%x3f,%x60];
		     { '!', '"','''', '(', ')', ',', '.', ':', ';', '?', '`'}
		     { the P (punctuation) pattern specifier }

  printable_set := [%x20..%x7e, %xa1..%xfd] -
		   { ' '.. '~',  '¡'.. 'ý'}
		   [%xa4,%xa6,%xac..%xaf,%xb4,%xb8,%xbe,%xd0,%xde,%xf0];
		   {            undefined characters                  }
		   { the C (printable char) pattern specifier }

  file_data := (true,     false, 500000, (max_strlen of ' '), false, 1);
	       {old_cmds, entab, space,   initial,            purge, versions}

  word_elements[0] := [%x20]; { space_set }
  word_elements[1] := { numeric_set + alpha_set }
		      [%x30..%x39] +
		      [%x41..%x5a, %xc0..%xcf, %xd1..%xdd] +
		      [%x61..%x7a, %xe0..%xef, %xf1..%xfd, %xdf];
  word_elements[2] := { printable_set - (word_elements[0] + word_elements[1]) }
		      [%x21..%x7e, %xa1..%xfd] -
		      [%xa4,%xa6,%xac..%xaf,%xb4,%xb8,%xbe,%xd0,%xde,%xf0] -
		      [%x30..%x39] -
		      [%x41..%x5a, %xc0..%xcf, %xd1..%xdd] -
		      [%x61..%x7a, %xe0..%xef, %xf1..%xfd, %xdf];
