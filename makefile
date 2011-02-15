# $Id: Makefile.in 701 2011-02-08 22:27:13Z mclay $
PATH_TO_HASHSUM := /usr/bin/sha1sum
PATH_TO_LUA	:= /opt/apps/lua/lua/bin
VERSION_SRC	:= src/Version.lua
VERSION_LIB	:= $(subst .lua,,$(VERSION_SRC))
prefix		:= /opt/apps
package		:= lmod
version		:= $(shell $(PATH_TO_LUA)/lua -l $(VERSION_LIB) -e "print(Version.name())" | awk '{print $$1}')
PKG		:= $(prefix)/$(package)/$(package)
LIBEXEC		:= $(prefix)/$(package)/$(version)/libexec
INIT		:= $(prefix)/$(package)/$(version)/init

DIRLIST		:= $(DESTDIR)$(LIBEXEC) $(DESTDIR)$(INIT)

STANDALONE_PRGM := src/lmod.in src/addto.in src/getmt.in src/processMT.in  src/spider.in \
                   src/processModuleUsage.in src/reportUsers.in
SHELL_INIT	:= bash.in csh.in ksh.in tcsh.in zsh.in sh.in
SHELL_INIT	:= $(patsubst %, setup/%, $(SHELL_INIT))

STARTUP		:= profile.in cshrc.in
STARTUP		:= $(patsubst %, setup/%, $(STARTUP))

MAIN_DIR	:= Makefile.in INSTALL configure README_lua_modulefiles.txt

lua_code	:= $(wildcard src/*.lua) $(wildcard src/*.tcl) src/COPYRIGHT 
VDATE		:= $(shell date +'%F %H:%M')

ComputeHashSum  := src/computeHashSum.in

REQUIRED_PKGS	:= \
                   BeautifulTbl  \
                   ColumnTable   \
                   Dbg           \
                   Optiks        \
                   Optiks_Option \
                   capture       \
                   fileOps       \
	           fillWords     \
                   hash          \
                   inherits      \
                   pairsByKeys   \
                   serialize     \
                   strict        \
                   string_split  \
                   string_trim

.PHONY: test

all:
	@echo done

install: $(DIRLIST) shell_init startup libexec other_tools
	$(RM) $(PKG)
	ln -s $(version) $(PKG)

echo:
	@echo Version: $(version)
echo_version:
	@echo $(version)


$(DIRLIST) :
	mkdir -p $@

__installMe:
	-for i in $(FILELIST); do                                 \
	  fn=`basename $$i .in`;                                  \
          sed -e 's|@PREFIX@|/opt/apps|g'                          \
	      -e 's|@path_to_lua@|$(PATH_TO_LUA)|g'               \
	      -e 's|@path_to_hashsum@|$(PATH_TO_HASHSUM)|g'       \
              -e 's|@PKG@|$(PKG)|g'         < $$i > $$fn;         \
          [ -n "$(DIRLOC)" ] && mv $$fn $(DESTDIR)$(DIRLOC) && chmod +x $(DESTDIR)$(DIRLOC)/$$fn; \
        done

shell_init: $(SHELL_INIT)
	$(MAKE) FILELIST="$^" DIRLOC=$(INIT)    __installMe

startup: $(STARTUP)
	$(MAKE) FILELIST="$^" DIRLOC=$(INIT)    __installMe

other_tools: $(ComputeHashSum) $(STANDALONE_PRGM)
	$(MAKE) FILELIST="$^" DIRLOC=$(LIBEXEC) __installMe

src/computeHashSum: $(ComputeHashSum)
	$(MAKE) FILELIST="$^" DIRLOC="src"      __installMe
	chmod +x $@

makefile: Makefile.in config.status
	config.status

config.status:
	./configure

dist:  
	$(MAKE) DistD=DIST _dist

_dist: _distMkDir _distMainDir _distSrc _distSetup _distReqPkg    \
       _distMF    _distTar

_distMkDir:
	$(RM) -r $(DistD)
	mkdir $(DistD)

_distSrc:
	mkdir $(DistD)/src
	cp $(lua_code) $(ComputeHashSum) $(STANDALONE_PRGM) $(DistD)/src

_distSetup:
	mkdir $(DistD)/setup
	cp $(SHELL_INIT) $(STARTUP) $(DistD)/setup

_distMainDir:
	cp $(MAIN_DIR) $(DistD)

_distReqPkg:
	cp `findLuaPkgs $(REQUIRED_PKGS)` $(DistD)/src

_distMF:
	mkdir $(DistD)/mf
	cp -r mf $(DistD)/mf
	find $(DistD)/mf -name .svn | xargs rm -rf 

_distTar:
	echo "Lmod"-$(version) > .fname;                		   \
	$(RM) -r `cat .fname` `cat .fname`.tar*;         		   \
	mv ${DistD} `cat .fname`;                            		   \
	tar chf `cat .fname`.tar `cat .fname`;           		   \
	gzip `cat .fname`.tar;                           		   \
	rm -rf `cat .fname` .fname; 


test:
	cd rt; unset TMFuncPATH; tm .

tags:
	find . \( -regex '.*~$$\|.*/\.svn$$\|.*/\.svn/' -prune \)  \
               -o -type f > file_list.1
	sed -e 's|.*/.svn.*||g'                                    \
            -e 's|.*/rt/.*/t1/.*||g'                               \
            -e 's|./TAGS||g'                                       \
            -e 's|./configure$$||g'                                \
            -e 's|./config.log$$||g'                               \
            -e 's|./testreports/.*||g'                             \
            -e 's|./config.status$$||g'                            \
            -e 's|.*\~$$||g'                                       \
            -e 's|./file_list.*||g'                                \
            -e '/^\s*$$/d'                                         \
	       < file_list.1 > file_list.2
	etags  `cat file_list.2`
	$(RM) file_list.*


libexec:  $(lua_code)
	cp $^ $(DESTDIR)$(LIBEXEC)

clean:
	$(RM) config.log

clobber: clean

distclean: clobber
	$(RM) makefile config.status

svntag:
        ifneq ($(TAG),)
	  @svn st > /tmp/lmod$$$$;                                                   \
          if [ -s /tmp/lmod$$$$ ]; then                                              \
	    echo "All files not checked in => try again";                            \
	  else                                                                       \
	    $(RM)                                                    $(VERSION_SRC); \
	    echo "module('Version')"                              >  $(VERSION_SRC); \
	    echo 'function name() return "'$(TAG) $(VDATE)'" end' >> $(VERSION_SRC); \
	    svn ci -m'moving to TAG_VERSION $(TAG)'         	   $(VERSION_SRC);   \
            SVN=`svn info | grep "Repository Root" | sed -e 's/Repository Root: //'`;\
	    svn cp -m'moving to TAG_VERSION $(TAG)' $$SVN/trunk $$SVN/tags/$(TAG);   \
          fi;                                                                        \
          rm -f /tmp/lmod$$$$
        else
	  @echo "To svn tag do: make svntag TAG=?"
        endif
