# ======================================================================
# System dependent definitions
#
# CPU:  Pyramid
# O/S:  OSx
# ======================================================================

P       = p

RM_     = $#

PCCFLAGS= -Dpyr -Dunix -DISO1 -Ddebug

PFLAGS  = -gx

CFLAGS  = -DDEBUG -gx

LDFLAGS = -w
LD2FLAGS= -lc /.attlib/libc.a

# ======================================================================
# System Independent definitions
# ======================================================================

SHELL   = /bin/csh

PSRC    = pcc.$P rm_.$P

PCC     = ~/pcc $(PCCFLAGS)

no-target:
	@echo "Please supply a target."

makefile: makefile.definitions ../makefile.body
	cat makefile.definitions ../makefile.body > makefile

sources:$(PSRC)

$(PSRC):
	set SRC=$@ ; \
	$(PCC) <../$$SRC:r.pas >$$SRC ; \
	$(RM_) <$@ >$@.x ; mv $@.x $@

pcc: pcc.$P
	$(PC) $(PFLAGS) -o pcc pcc.$P

install-pcc: pcc
	install -m 711 -s pcc $${HOME}

rm_: rm_.$P
	$(PC) $(PFLAGS) -o rm_ rm_.$P

install-rm_: rm_
	install -m 711 -s rm_ $${HOME}
