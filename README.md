```text
{**********************************************************************}
{                                                                      }
{            L      U   U   DDDD   W      W  IIIII   GGGG              }
{            L      U   U   D   D   W    W     I    G                  }
{            L      U   U   D   D   W ww W     I    G   GG             }
{            L      U   U   D   D    W  W      I    G    G             }
{            LLLLL   UUU    DDDD     W  W    IIIII   GGGG              }
{                                                                      }
{**********************************************************************}
```

# About

Efficient, and powerful text editor, with command programming language.

Ludwig is a text editor developed at the University of Adelaide. 
It is an interactive, screen-oriented text editor.
It may be used to create and modify computer programs, documents 
or any other text which consists only of printable characters.

Ludwig may also be used on hardcopy terminals or non-interactively, 
but it is primarily an interactive screen editor.

This code is here for historic interest— if you would prefer something that
you can compile and run on a modern machine, the following will be easier
options:

- The original Pascal code is available here: [cjbarter/ludwig](https://github.com/cjbarter/ludwig).  This compiles with FreePascal and runs on Linux.  It has been compiled on MacOS in the past, but the current version of FreePascal in Homebrew has broken support for arrow keys, which appears to be an ncurses issue.
- There is also a C++ port available here: [clstrfsck/ludwig-c](https://github.com/clstrfsck/ludwig-c). This compiles and runs on Linux and MacOS with Clang and GCC.  I expect it would be easy to get it running on WSL, but I have not tried to do so.
- There is a Go port available here: [clstrfsck/ludwig-go](https://github.com/clstrfsck/ludwig-go).  This compiles and runs on Linux and MacOS.  It uses CGo for a simplified ncurses interface.

# This code

This code is the original code for Ludwig V4.1-048 as received circa 2002.
It includes support for an assortment of operating systems, including Solaris,
VMS and MS-DOS. 

Conditional compilation was achieved by running the code through the `pcc`
tool, which has been included in the `pcc/` directory.
