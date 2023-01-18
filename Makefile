# Copyright (C) 2023 Timothe Litt litt at acm ddot org

# $Id$

# Install targets - can override on command line

# Note that DESTDIR is supported for staging environments

prefix          := /usr/local
datarootdir     := $(prefix)/share
mandir          := $(datarootdir)/man
man1dir         := $(mandir)/man1
manext          := .1
man1ext         := .1
exec_prefix     := $(prefix)
bindir          := $(exec_prefix)/bin
confdir         := $(shell if [ -f "/etc/default/ipblock.conf" ]; then echo "/etc/default"; \
	elif [ -f "/etc/sysconfig/ipblock.conf" ] || ! [ -d "/etc/default" ];       \
	then echo "/etc/sysconfig"; \
	else echo "/etc/default";  fi)
INSTALL         := install
INSTALL_PROGRAM := $(INSTALL)
INSTALL_DATA    := $(INSTALL) -m 644

# Specify key="deadbeef" or key="deadbeef beeffeed" on command line (else default)
GPG     := gpg

SHELL   := bash
SED     := sed

# https://kristaps.bsd.lv/lowdown/ - used to build man page.
LOWDOWN := lowdown

# Usage:
#  See INSTALL

# Extract version from ipblock source

kitversion := $(shell $(SED) -nEe"s/^RELEASE='([^']+)'.*$$/\1/p" ipblock)
kitname    := ipblock-$(kitversion)
kitowner   := 0:0

# location if command is installed

IPBLOCK := $(strip $(shell command -v ipblock))

# If in a Git working directory and the git command is available,
# get the last tag in case making a distribution.

ifneq "$(strip $(shell [ -d '.git' ] && echo 'true' ))" ""
  gitcmd   := $(shell command -v git)
  ifneq "$(strip $(gitcmd))" ""
    gittag := $(shell git tag --sort=version:refname | tail -n1)
  endif
endif

# file types from which tar can infer compression, if tool is installed

# kittypes = gz xz lzop lz lzma Z zst bz bz2

# kittypes to build

kittypes := gz xz

# Files to package

kitfiles := README.md LICENSE Makefile ipblock config/ipblock.conf ipblock$(manext)

.PHONY : all

all : ipblock$(man1ext)

# Compilations: man page from README and help

ipblock$(man1ext) : README.md ipblock Makefile
	$(SED) -e's,^`ipblock -h` for complete help$$,./ipblock -h,e' $< | \
	    $(LOWDOWN) -s -t man --parse-codeindent -M "title=ipblock" -M "date=$$(date -r ipblock +%d-%b-%Y)" -Msection=8 -o $@ -

.PHONY : viewreadme viewman

viewreadme : README.md
	@LANG=C $(LOWDOWN) -s -t term --parse-codeindent $< | less

viewman : ipblock$(man1ext)
	@LANG=C less $<

# Make tarball kits - various compressions

.PHONY : dist unsigned-dist signed-dist

dist : signed-dist

ifeq ($(strip $(gitcmd)),)
signed-dist : $(foreach type,$(kittypes),$(kitname).tar.$(type).sig)
else
signed-dist : $(foreach type,$(kittypes),$(kitname).tar.$(type).sig) .tagged
endif

unsigned-dist : $(foreach type,$(kittypes),$(kitname).tar.$(type))

# Tarball build directory

$(kitname)/% : %
	@mkdir -p $(dir $@)
	@-chown $(kitowner) $(dir $@)
	cp -p $< $@
	@-chown $(kitowner) $@

# Clean up after builds

.PHONY : clean

clean:
	rm -rf $(kitname) $(foreach type,$(kittypes),$(kitname).tar.$(type){,.sig})

# Install program and doc

.PHONY : install

install_dirs := $(DESTDIR)$(bindir) $(DESTDIR)$(man1dir) $(DESTDIR)$(confdir)

install : ipblock ipblock$(man1ext) config/ipblock.conf installdirs
	$(INSTALL_PROGRAM) ipblock $(DESTDIR)$(bindir)/ipblock
	$(INSTALL_DATA) ipblock$(man1ext) $(DESTDIR)$(man1dir)/ipblock$(man1ext)
	-if [ -f "$(confdir)/ipblock.conf" ]; then $(INSTALL_DATA) config/ipblock.conf $(DESTDIR)$(confdir)/ipblock.conf.new ; else  $(INSTALL_DATA) config/ipblock.conf $(DESTDIR)$(confdir)/ipblock.conf; fi
	@echo ""
	@echo "Please read 'man 1 ipblock' before using the command'"

# un-install

.PHONY : uninstall

#    uninstall should have the command in $(bindir)...
#    uninstall may encounter no IPvX rule, no chain.  So flush and disable are best effort.
uninstall :
	@-if ! [ -x "$(DESTDIR)$(bindir)/ipblock" ]; then                                      \
	     echo "The ipblock command is not in '$(DESTDIR)$(bindir)'" >&2 ;                  \
	     echo "This uninstall will not find it and may not do what you expect." >&2 ;      \
	     if [ -n "$(IPBLOCK)" ] && [ "$(IPBLOCK)" != "$(DESTDIR)$(bindir)/ipblock" ]; then \
		echo "Did you forget to set 'prefix=$(dir $(IPBLOCK))'?" >&2 ;                 \
	     fi ;                                                                              \
	  fi
	-$(DESTDIR)$(bindir)/ipblock -4F >/dev/null 2>&1 || true
	-$(DESTDIR)$(bindir)/ipblock -4X >/dev/null 2>&1 || true
	-$(DESTDIR)$(bindir)/ipblock -6F >/dev/null 2>&1 || true
	-$(DESTDIR)$(bindir)/ipblock -6X >/dev/null 2>&1 || true
	-rm -f "$(DESTDIR)$(bindir)/ipblock"
	-rm -f "$(DESTDIR)$(man1dir)/ipblock$(man1ext)"
	@-[ -f "$(DESTDIR)$(confdir)/ipblock.conf" ] && echo "Not deleting $(DESTDIR)$(confdir)/ipblock.conf in case you want to reinstall later"

# create install directory tree (especially when staging)

installdirs : $(install_dirs)
	$(INSTALL) -d $(install_dirs)

# rules for making tarballs - $1 is file type that implies compression

define make_tar =

%.tar.$(1) : $$(foreach f,$$(kitfiles), %/$$(f))
	tar -caf $$@ $$^
	@-chown $(kitowner) $$@

endef

$(foreach type,$(kittypes),$(eval $(call make_tar,$(type))))

# Ensure that the release is tagged, providing the working directory is clean
# Depends on everything in git (not just kitfiles), everything compiled, and
# all the release kits.

ifneq ($(strip $(gitcmd)),)
.PHONY : tag

tag : .tagged

.tagged : $(shell git ls-tree --full-tree --name-only -r HEAD) unsigned-dist
	@if git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' >/dev/null 2>/dev/null || \
	    [ -n "$$(git diff --name-only)$$(git diff --name-only --staged)" ]; then \
	    echo " *** Not tagging V$(kitversion) because working directory is dirty"; echo ""; false ;\
	 elif [ "$(strip $(gittag))" == "V$(kitversion)" ]; then                 \
	    echo " *** Not tagging because V$(kitversion) already exists";       \
	    echo ""; false;                                                      \
	 else                                                                    \
	    git tag V$(kitversion) && echo "Tagged as V$(kitversion)" | tee .tagged || true; \
	 fi

endif

# create a detached signature for a file

%.sig : % Makefile
	@-rm -f $<.sig
	$(GPG) --output $@ --detach-sig $(foreach k,$(key), --local-user "$(k)") $(basename $@)
	@-chown $(kitowner) $@
