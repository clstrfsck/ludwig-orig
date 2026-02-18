# ======================================================================
#
#                  ====================================
#            ***** DO NOT MODIFY THIS MAKEFILE DIRECTLY *****
#                  ====================================
#
# This makefile consists of the concatenation of
#       ~/current/makefile.warning
#       ~/current/?/makefile.definitions
#       ~/current/makefile.body
#
# To modify the makefile, edit the appropriate file(s) as listed above,
# and execute 'make makefile'.
#
# To contruct a makefile for a new system, copy 'makfile.definitions'
# and 'makefile' from another system, edit 'makefile.definitions', and
# execute 'make makefile'.
#
# ======================================================================
# ======================================================================
# System dependent definitions
#
# CPU:  Multimax
# O/S:  Umax
# ======================================================================

P       = pas

RM_     = $#

PCCFLAGS= -Dns32000 -Dunix -DISO1
PCCFLAGS= -Dns32000 -Dunix -DISO1 -Ddebug

PFLAGS  = -berkeley
PFLAGS  = -berkeley -g

CFLAGS  = -DDEBUG -DISO1
CFLAGS  = -DDEBUG -DISO1 -g

LDFLAGS = -n

# ======================================================================
# System Independent definitions
# ======================================================================

SHELL   = /bin/csh

PSRC    = arrow.$P caseditto.$P charcmd.$P code.$P dfa.$P eqsgetrep.$P \
	exec.$P execimmed.$P file.$P frame.$P help.$P line.$P mark.$P \
	nextbridge.$P opsys.$P patparse.$P quit.$P recognize.$P \
	screen.$P span.$P swap.$P text.$P tpar.$P user.$P validate.$P \
	value.$P window.$P word.$P newword.$P \
	ludwig.$P
ISRC    = const.i type.i var.i version.i
PHED    = arrow.h  caseditto.h  charcmd.h  code.h  dfa.h  eqsgetrep.h  \
	exec.h  execimmed.h  file.h  frame.h  help.h  line.h  mark.h  \
	nextbridge.h  opsys.h  patparse.h  quit.h  recognize.h  \
	screen.h  span.h  swap.h  text.h  tpar.h  user.h  validate.h  \
	value.h  window.h  word.h  newword.h
POBJ    = arrow.o  caseditto.o  charcmd.o  code.o  dfa.o  eqsgetrep.o  \
	exec.o  execimmed.o  file.o  frame.o  help.o  line.o  mark.o  \
	nextbridge.o  opsys.o  patparse.o  quit.o  recognize.o  \
	screen.o  span.o  swap.o  text.o  tpar.o  user.o  validate.o  \
	value.o  window.o  word.o  newword.o  \
	ludwig.o

CSRC    = ch.c filesys.c helpfile.c unix.c vdu.c
HSRC    = const.h type.h termdesc.h
CHED    = ch.h filesys.h helpfile.h unix.h vdu.h
COBJ    = ch.o filesys.o helpfile.o unix.o vdu.o

TSRC    = ludwighlp.t   ludwignewhlp.t
TIDX    = ludwighlp.idx ludwignewhlp.idx

XSRC    = termdesc-parser.c ludwighlpbld.c
XOBJ    = termdesc-parser.o ludwighlpbld.o

PCC     = ~/pcc $(PCCFLAGS)
LUD     = ludwig -O -t -M

all:    sources ludwig termdesc-parser ludwig-help

makefile:../makefile.warning makefile.definitions ../makefile.body
	cat ../makefile.warning makefile.definitions ../makefile.body \
		> makefile

sources:$(PSRC) $(ISRC) $(PHED) $(CSRC) $(HSRC) $(CHED) $(TSRC) $(XSRC)

ludwig: $(POBJ) $(COBJ)
	$(PC) $(PFLAGS) $(LDFLAGS) -o ludwig $(POBJ) $(COBJ) \
	    -ltermcap $(LD2FLAGS)

install:
	cp ludwig ludwig.ins
	strip ludwig.ins
	mv -f ludwig.ins /usr/local/bin/ludwig
	chmod 711 /usr/local/bin/ludwig
	chown -f root /usr/local/bin/ludwig

install-help:$(TIDX)
	cp $(TIDX) /usr/local/help
	chmod 444 /usr/local/help/lud*.idx
	chown -f root /usr/local/help/lud*.idx

$(PSRC):
	set SRC=$@ ; \
	$(PCC) <../$$SRC:r.pas >$$SRC ; \
	$(RM_) <$@ >$@.x ; mv $@.x $@

$(ISRC):
	$(PCC) <../$@  >$@ ; \
	$(RM_) <$@ >$@.x ; mv $@.x $@

$(CSRC) $(HSRC) $(XSRC):
	cp ../$@ .

$(TSRC):
	$(PCC) <../$@ >$@

$(PHED):
	set SRC=$@ ; \
	$(LUD) -B 0 -i ../make-header.lud $$SRC:r.$P $$SRC ; \
	$(RM_) <$@ >$@.x ; mv $@.x $@

$(CHED):
	set SRC=$@ ; \
	$(LUD) -B 0 -i ../make-header.lud $$SRC:r.c $$SRC ; \
	$(RM_) <$@ >$@.x ; mv $@.x $@

arrow.o: arrow.$P arrow.h const.i type.i var.i \
	line.h mark.h screen.h text.h vdu.h

caseditto.o: caseditto.$P caseditto.h const.i type.i var.i \
	ch.h mark.h screen.h text.h vdu.h unix.h

ch.o: ch.c ch.h

charcmd.o: charcmd.$P charcmd.h const.i type.i var.i \
	ch.h mark.h screen.h text.h vdu.h

code.o: code.$P code.h const.i type.i var.i \
	ch.h exec.h frame.h line.h mark.h screen.h tpar.h vdu.h unix.h

dfa.o: dfa.$P dfa.h const.i type.i var.i \
	screen.h

eqsgetrep.o: eqsgetrep.$P eqsgetrep.h const.i type.i var.i \
	ch.h charcmd.h mark.h screen.h text.h patparse.h dfa.h recognize.h

exec.o: exec.$P exec.h const.i type.i var.i \
	arrow.h caseditto.h ch.h charcmd.h code.h eqsgetrep.h file.h \
	frame.h help.h line.h mark.h nextbridge.h opsys.h quit.h screen.h \
	span.h swap.h tpar.h text.h user.h validate.h vdu.h window.h \
	word.h newword.h unix.h

execimmed.o: execimmed.$P execimmed.h const.i type.i var.i \
	code.h exec.h file.h line.h mark.h screen.h text.h vdu.h unix.h

file.o: file.$P file.h const.i type.i var.i \
	ch.h exec.h filesys.h line.h mark.h screen.h tpar.h unix.h vdu.h

filesys.o: filesys.c const.h type.h

frame.o: frame.$P frame.h const.i type.i var.i \
	line.h span.h mark.h ch.h screen.h vdu.h tpar.h dfa.h unix.h

help.o: help.$P help.h const.i type.i var.i \
	ch.h helpfile.h screen.h

helpfile.o: helpfile.c const.h type.h

line.o: line.$P line.h const.i type.i var.i \
	ch.h screen.h unix.h

ludwig.o: ludwig.$P const.i type.i var.i \
	ch.h exec.h execimmed.h file.h frame.h quit.h screen.h vdu.h unix.h
	$(PC) $(PFLAGS) -c ludwig.$P

mark.o: mark.$P mark.h const.i type.i var.i \
	screen.h unix.h

nextbridge.o: nextbridge.$P nextbridge.h const.i type.i var.i \
	mark.h

opsys.o: opsys.$P opsys.h const.i type.i var.i \
	filesys.h line.h screen.h

patparse.o: patparse.$P patparse.h const.i type.i var.i \
	ch.h screen.h tpar.h

quit.o: quit.$P quit.h const.i type.i var.i \
	file.h screen.h tpar.h vdu.h unix.h

recognize.o: recognize.$P recognize.h const.i type.i var.i

screen.o: screen.$P screen.h const.i type.i var.i \
	ch.h line.h vdu.h unix.h

span.o: span.$P span.h const.i type.i var.i \
	ch.h code.h file.h line.h mark.h screen.h unix.h

swap.o: swap.$P span.h const.i type.i var.i \
	mark.h text.h

text.o: text.$P text.h const.i type.i var.i \
	ch.h line.h mark.h screen.h vdu.h unix.h

tpar.o: tpar.$P tpar.h const.i type.i var.i \
	ch.h screen.h span.h swap.h unix.h

user.o: user.$P user.h const.i type.i var.i \
	code.h mark.h screen.h span.h text.h tpar.h unix.h vdu.h

validate.o: validate.$P validate.h const.i type.i var.i \
	screen.h

value.o: value.h const.i type.i var.i version.i

vdu.o:  vdu.c const.h type.h termdesc.h

window.o: window.$P window.h const.i type.i var.i \
	frame.h line.h mark.h screen.h vdu.h

word.o: word.$P word.h const.i type.i var.i \
	line.h mark.h text.h

newword.o: newword.$P newword.h const.i type.i var.i \
	line.h mark.h text.h

termdesc-parser: termdesc-parser.c const.h type.h termdesc.h
	$(CC) $(CFLAGS) -o termdesc-parser termdesc-parser.c

ludwig-help: $(TIDX)

ludwighlpbld: ludwighlpbld.c
	$(CC) $(CFLAGS) -o ludwighlpbld ludwighlpbld.c

ludwighlp.idx:  ludwighlpbld ludwighlp.t
	ludwighlpbld ludwighlp.t ludwighlp.idx

ludwignewhlp.idx:  ludwighlpbld ludwignewhlp.t
	ludwighlpbld ludwignewhlp.t ludwignewhlp.idx

tidy:
	rm -f $(PSRC)
	rm -f $(ISRC)
	rm -f $(PHED)
	rm -f $(POBJ)
	rm -f $(CSRC)
	rm -f $(HSRC)
	rm -f $(CHED)
	rm -f $(COBJ)
	rm -f $(TSRC)
	rm -f $(XSRC)
	rm -f $(XOBJ)

clean:  tidy
	rm -f ludwig
	rm -f termdesc-parser
	rm -f ludwighlpbld
	rm -f $(TIDX)
