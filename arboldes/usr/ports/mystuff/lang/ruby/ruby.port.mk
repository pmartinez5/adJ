# $OpenBSD: ruby.port.mk,v 1.90 2017/01/06 16:03:54 jeremy Exp $

# ruby module

CATEGORIES+=		lang/ruby

# Whether the ruby module should automatically add FLAVORs.
# If left blank, does so only for gem and extconf ports.
.if ${CONFIGURE_STYLE:L:Mgem} || ${CONFIGURE_STYLE:L:Mextconf}
MODRUBY_HANDLE_FLAVORS ?= Yes
.else
MODRUBY_HANDLE_FLAVORS ?= No
.endif

# This allows you to build packages for multiple ruby versions and
# implementations using the same port directory for gem and extconf based
# ports.  It does this by adding FLAVORS automatically, unless FLAVORS are
# already defined or the port defines MODRUBY_REV to tie the port to a specific
# ruby version.  For example, JDBC gem ports want to set FLAVOR=jruby, since
# they don't work on other ruby implementations.
.if !defined(MODRUBY_REV)
.  if ${MODRUBY_HANDLE_FLAVORS:L:Myes}

# If ruby.pork.mk should handle FLAVORs, define a separate FLAVOR
# for each ruby interpreter
.    if !defined(FLAVORS)
FLAVORS=		ruby23 ruby24 ruby25
.      if !${CONFIGURE_STYLE:L:Mext} && !${CONFIGURE_STYLE:L:Mextconf}
FLAVORS+=		jruby
.      endif
.    endif

# Instead of adding flavors to the end of the package name, we use
# different package stems for different ruby versions and implementations.
# ruby 1.8 uses the historical ruby-* package stem, newer ruby versions
# use rubyXY-* and jruby uses jruby-*.  In most cases,
# PKGNAME in the port should be set to the same as DISTNAME, and this
# will insert the correct package prefix.
FULLPKGNAME?=		${MODRUBY_PKG_PREFIX}-${PKGNAME}

# If the port installs binary files or man pages and can work on multiple
# versions of ruby, those files should have the appropriate suffix so that
# they do not conflict.  GEM_BIN_SUFFIX should be added after such a filename
# in the PLIST so that the gem will correctly package on all supported
# versions of ruby.
SUBST_VARS+=		GEM_BIN_SUFFIX GEM_MAN_SUFFIX

FLAVOR?=
# Without a FLAVOR, assume the use of ruby 2.3.
.    if empty(FLAVOR)
FLAVOR =		ruby23
.    endif

# Check for conflicting FLAVORs and set MODRUBY_REV appropriately based
# on the FLAVOR.
.    for i in ruby23 ruby24 ruby25 jruby
.      if ${FLAVOR:M$i}
MODRUBY_REV = ${i:C/ruby([0-9])/\1./}
.        if ${FLAVOR:N$i:Mruby23} || \ 
            ${FLAVOR:N$i:Mruby24} || \ 
            ${FLAVOR:N$i:Mruby25} || \ 
	    ${FLAVOR:N$i:Mjruby}
ERRORS += "Fatal: Conflicting flavors used: ${FLAVOR}"
.        endif
.      endif
.    endfor

.    if ${FLAVOR:Mruby18}
# Handle updates from older ruby 1.8 ports that didn't use the ruby18
# FLAVOR by adding a @pkgpath entry to the PLIST.
SUBST_VARS+=	PKGPATH
PKG_ARGS+=	-f ${PORTSDIR}/lang/ruby/ruby18.PLIST
.    endif
.  endif
.endif

# The default ruby version to use for non-gem/extconf ports.  Defaults to ruby
# 2.3 for consistency with the default ruby23 FLAVOR for gem/extconf ports.
MODRUBY_REV?=		2.3

# Because the jruby FLAVORs use same binary names but in
# different directories, GEM_MAN_SUFFIX is used for the man pages to avoid
# conflicts since all man files go in the same directory.
GEM_MAN_SUFFIX =	${GEM_BIN_SUFFIX}

# Use the FLAVOR as the prefix for the package, to avoid conflicts.
MODRUBY_PKG_PREFIX =	${MODRUBY_FLAVOR}

# Set MODRUBY_* variables as well as the path for the ruby interpreter and
# related commands used by MODRUBY_TEST and manually in some port targets.
.if ${MODRUBY_REV} == jruby
GEM_MAN_SUFFIX =	-${MODRUBY_FLAVOR}
MODRUBY_ARCH=		${MACHINE_ARCH:S/amd64/x86_64/}-java
MODRUBY_BIN_RSPEC =	${RUBY} -S rspec
MODRUBY_BIN_TESTRB =	${RUBY} -S testrb
MODRUBY_FLAVOR =	jruby
MODRUBY_LIBDIR=		${LOCALBASE}/jruby/lib/ruby
MODRUBY_LIBREV =	2.3.0
MODRUBY_SITEARCHDIR =	${MODRUBY_SITEDIR}/java
MODRUBY_SITEDIR =	jruby/lib/ruby/site_ruby/${MODRUBY_LIBREV}
RAKE=			${RUBY} -S rake
RSPEC=			${RUBY} -S spec
RUBY=			${LOCALBASE}/jruby/bin/jruby

.  if ${CONFIGURE_STYLE:L:Mext} || ${CONFIGURE_STYLE:L:Mextconf}
ERRORS += "Fatal: Ruby C extensions are unsupported on JRuby"
.  else
MODRUBY_RUN_DEPENDS=	lang/jruby
.  endif

.else # not jruby

.  if ${MODRUBY_REV} == 1.8
MODRUBY_PKG_PREFIX =	ruby
.  endif

GEM_BIN_SUFFIX =	${MODRUBY_BINREV}
MODRUBY_ARCH=		${MACHINE_ARCH:S/amd64/x86_64/}-openbsd
MODRUBY_BINREV =	${MODRUBY_LIBREV:S/.//}
MODRUBY_BIN_RSPEC =	${LOCALBASE}/bin/rspec${MODRUBY_BINREV}
MODRUBY_BIN_TESTRB =	${LOCALBASE}/bin/testrb${MODRUBY_BINREV}
MODRUBY_FLAVOR =	ruby${MODRUBY_BINREV}
MODRUBY_LIBDIR=		${LOCALBASE}/lib/ruby
MODRUBY_LIBREV =	${MODRUBY_REV}
MODRUBY_LIB_DEPENDS=	${MODRUBY_RUN_DEPENDS}
MODRUBY_RUN_DEPENDS=	lang/ruby/${MODRUBY_REV}
MODRUBY_SITEARCHDIR =	${MODRUBY_SITEDIR}/${MODRUBY_ARCH}
MODRUBY_SITEDIR =	lib/ruby/site_ruby/${MODRUBY_LIBREV}
MODRUBY_WANTLIB=	ruby${MODRUBY_BINREV}
RAKE=			${LOCALBASE}/bin/rake${MODRUBY_BINREV}
RSPEC=			${LOCALBASE}/bin/spec${MODRUBY_BINREV}
RUBY=			${LOCALBASE}/bin/ruby${MODRUBY_BINREV}
.endif

MODRUBY_RSPEC_DEPENDS =	devel/ruby-rspec/1,${MODRUBY_FLAVOR}<2.0
MODRUBY_RSPEC3_DEPENDS = devel/ruby-rspec/3/rspec,${MODRUBY_FLAVOR}>=3.0

.if defined(MODRUBY_TEST)
.  if !${MODRUBY_TEST:L:Mrspec} && !${MODRUBY_TEST:L:Mrspec3} && \
     !${MODRUBY_TEST:L:Mrake} && !${MODRUBY_TEST:L:Mruby} && \
     !${MODRUBY_TEST:L:Mtestrb}
ERRORS += "Fatal: Unsupported MODRUBY_TEST value: ${MODRUBY_TEST}"
.  endif
.else
.  if ${CONFIGURE_STYLE:L:Mextconf} || ${CONFIGURE_STYLE:L:Mgem} || \
	${CONFIGURE_STYLE:L:Msetup}
.    if !target(do-test)
# Disable regress for extconf, gem, and setup based ports, since they
# won't use make check for test.
NO_TEST =	Yes
.    endif
.  endif
MODRUBY_TEST?=
.endif

MODRUBY_BUILD_DEPENDS=	${MODRUBY_RUN_DEPENDS}

# common directories for ruby extensions
# used to create docs and examples install path
MODRUBY_RELDOCDIR=	share/doc/${MODRUBY_PKG_PREFIX}
MODRUBY_RELEXAMPLEDIR=	share/examples/${MODRUBY_PKG_PREFIX}
MODRUBY_DOCDIR=		${PREFIX}/${MODRUBY_RELDOCDIR}
MODRUBY_EXAMPLEDIR=	${PREFIX}/${MODRUBY_RELEXAMPLEDIR}
SUBST_VARS +=		^MODRUBY_RELDOCDIR ^MODRUBY_RELEXAMPLEDIR

# Assume that we want to automatically add ruby to BUILD_DEPENDS
# and RUN_DEPENDS unless the port specifically requests not to.
MODRUBY_BUILDDEP?=	Yes
MODRUBY_RUNDEP?=	Yes

.if ${NO_BUILD:L} == no && ${MODRUBY_BUILDDEP:L} == yes
BUILD_DEPENDS+=		${MODRUBY_BUILD_DEPENDS}
.endif
.if ${MODRUBY_RUNDEP:L} == yes
RUN_DEPENDS+=		${MODRUBY_RUN_DEPENDS}
.endif

.if ${MODRUBY_TEST:L:Mrake} && ${MODRUBY_REV} == 1.8
TEST_DEPENDS+=	devel/ruby-rake
.endif
.if ${MODRUBY_TEST:L:Mrspec}
TEST_DEPENDS+=	${MODRUBY_RSPEC_DEPENDS}
.endif
.if ${MODRUBY_TEST:L:Mrspec3}
TEST_DEPENDS+=	${MODRUBY_RSPEC3_DEPENDS}
.endif

MODRUBY_RUBY_ADJ =	perl -pi \
		-e '$$. == 1 && s|^.*env ruby.*$$|\#!${RUBY}|;' \
		-e '$$. == 1 && s|^.*bin/ruby.*$$|\#!${RUBY}|;' \
		-e 'close ARGV if eof;'
MODRUBY_ADJ_FILES?=
.if !empty(MODRUBY_ADJ_FILES)
MODRUBY_ADJ_REPLACE=	for pat in ${MODRUBY_ADJ_FILES:QL}; do \
			 find ${WRKSRC} -type f -name "$$pat" -print0 | \
			  xargs -0r ${MODRUBY_RUBY_ADJ} ; \
			done
MODRUBY_pre-configure += ${MODRUBY_ADJ_REPLACE}
.endif

MODRUBY_WANTLIB+=	c m
.if ${MODRUBY_REV} != 1.8
MODRUBY_WANTLIB+=	gmp pthread
.endif

.if ${CONFIGURE_STYLE:L:Mext} || ${CONFIGURE_STYLE:L:Mextconf}
# Ruby C exensions are specific to an arch and are loaded as
# shared libraries (not compiled into ruby), so make sure PKG_ARCH=*
# is not set.
.  if defined(PKG_ARCH) && ${PKG_ARCH} == *
ERRORS+=	"Fatal: Should not have PKG_ARCH=* when compiling extensions"
.  endif

# Add appropriate libraries to WANTLIB depending on ruby version and
# implementation
WANTLIB+=	${MODRUBY_WANTLIB}
LIB_DEPENDS+=	${MODRUBY_LIB_DEPENDS}
.endif

.if ${CONFIGURE_STYLE:L:Mextconf}
CONFIGURE_STYLE=	simple
CONFIGURE_SCRIPT=	${SETENV} ${MAKE_ENV} ${RUBY} extconf.rb
.elif ${CONFIGURE_STYLE:L:Mgem}
# All gems should be in the same directory on rubygems.org.
MASTER_SITES?=	${MASTER_SITE_RUBYGEMS}
EXTRACT_SUFX=	.gem

# Require versions that no longer create the .require_paths files.
.  if ${MODRUBY_REV} == 1.8
BUILD_DEPENDS+=	devel/ruby-gems>=1.8.23p3
RUN_DEPENDS+=	devel/ruby-gems>=1.3.7p0
.  elif ${MODRUBY_REV} == jruby
BUILD_DEPENDS+=	lang/jruby>=1.6.5
.  elif ${MODRUBY_REV} == 2.1
# Require version that fixes extensions directory path
BUILD_DEPENDS+=	lang/ruby/2.1>=2.1.0p0
.  endif

# Pure ruby gem ports without C extensions are arch-independent.
.  if !${CONFIGURE_STYLE:L:Mext}
PKG_ARCH=	*
.  elif ${MODRUBY_REV} != 1.8
# Add build complete file to package so rubygems doesn't complain
# or build extensions at runtime
GEM_EXTENSIONS_DIR ?= ${GEM_LIB}/extensions/${MODRUBY_ARCH:S/i386/x86/}/${MODRUBY_REV}/${DISTNAME}
GEM_EXTENSIONS_FILE ?= ${GEM_EXTENSIONS_DIR}/gem.build_complete
SUBST_VARS+=	GEM_EXTENSIONS_DIR
PKG_ARGS+=	-f ${PORTSDIR}/lang/ruby/rubygems-ext.PLIST
.  endif

# PLIST magic.  Set variables so that the same PLIST will work for
# all ruby versions and implementations.
SUBST_VARS+=	^GEM_LIB ^GEM_BIN DISTNAME

.  if ${MODRUBY_REV} == jruby
GEM=		${RUBY} -S gem
GEM_BIN =	jruby/bin
GEM_LIB =	jruby/lib/ruby/gems/1.8
GEM_BASE_LIB=	${GEM_BASE}/jruby/${MODRUBY_LIBREV}
.  else
GEM=		${LOCALBASE}/bin/gem${MODRUBY_BINREV}
GEM_BIN =	bin
GEM_LIB =	lib/ruby/gems/${MODRUBY_LIBREV}
GEM_BASE_LIB=	${GEM_BASE}/ruby/${MODRUBY_LIBREV}
.  endif
GEM_BASE=	${WRKDIR}/gem-tmp/.gem
GEM_ABS_PATH=	${PREFIX}/${GEM_LIB}
GEM_BASE_BIN=	${GEM_BASE_LIB}/bin

# We purposely do not install documentation for ruby gems, because
# the filenames are generated differently on different ruby versions,
# and most use 1 file per method, which is insane.
GEM_FLAGS+=	--local --no-rdoc --no-ri --no-force --verbose --backtrace \
		--user-install
_GEM_CONTENT=	${WRKDIR}/gem-content
_GEM_DATAFILE=	${_GEM_CONTENT}/data.tar.gz
_GEM_PATCHED=	${DISTNAME}${EXTRACT_SUFX}
_GEM_MAKE=	"make V=1"

# Unpack the gem into WRKDIST so it can be patched.  Include the gem metadata
# under WRKDIST so it can be patched easily to remove or change dependencies.
# Remove any signing of packages, as patching the gem could then break the
# signatures.
EXTRACT_CASES += *.gem) \
    mkdir ${WRKDIST} ${_GEM_CONTENT}; \
    cd ${_GEM_CONTENT} && tar -xf ${FULLDISTDIR}/$$archive; \
    cd ${WRKDIST} && tar -xzf ${_GEM_DATAFILE} && rm -f ${_GEM_DATAFILE}; \
    gzcat ${_GEM_CONTENT}/metadata.gz > ${WRKDIST}/.metadata; \
    rm -f ${_GEM_CONTENT}/*.gz.sig ${_GEM_CONTENT}/checksums.yaml.gz;;

# Rebuild the gem manually after possible patching, then install it to a
# temporary directory (not the final directory under fake, since that would
# require root access and building C extensions as root).
MODRUBY_BUILD_TARGET = \
    if [ -f ${WRKDIST}/.metadata ]; then \
	    cd ${WRKDIST} && gzip .metadata && \
		    mv -f .metadata.gz ${_GEM_CONTENT}/metadata.gz; \
    fi; \
    cd ${WRKDIST} && pax -wz -s '/.*${PATCHORIG:S@.@\.@g}$$//' \
	    -x ustar -o write_opt=nodir . >${_GEM_DATAFILE}; \
    cd ${_GEM_CONTENT} && tar -cf ${WRKDIR}/${_GEM_PATCHED} *.gz; \
    mkdir -p ${GEM_BASE}; \
    env -i ${MAKE_ENV} HOME=`dirname ${GEM_BASE}` GEM_HOME=${GEM_BASE} \
	    make=${_GEM_MAKE} \
	    ${GEM} install ${GEM_FLAGS} ${WRKDIR}/${_GEM_PATCHED} \
	    -- ${CONFIGURE_ARGS}

# Take the temporary gem directory, install the binary stub files to
# the appropriate directory, and move and fix ownership the gem library
# files.
MODRUBY_INSTALL_TARGET = \
    if [ -d ${GEM_BASE_BIN} ]; then \
	    ${INSTALL_DATA_DIR} ${PREFIX}/${GEM_BIN}; \
	    for f in ${GEM_BASE_BIN}/*; do \
		    ${INSTALL_SCRIPT} $$f ${PREFIX}/${GEM_BIN}; \
	    done; \
	    rm -r ${GEM_BASE_BIN}; \
    fi; \
    ${INSTALL_DATA_DIR} ${GEM_ABS_PATH}; \
    cd ${GEM_BASE_LIB} && mv * ${GEM_ABS_PATH}; \
    if [ 'X' != "X${GEM_EXTENSIONS_FILE}" ]; then \
	mkdir -p ${PREFIX}/${GEM_EXTENSIONS_DIR}; \
	touch ${PREFIX}/${GEM_EXTENSIONS_FILE}; \
    fi
    chown -R ${SHAREOWN}:${SHAREGRP} ${GEM_ABS_PATH}

.  if !target(do-build)
do-build: 
	${MODRUBY_BUILD_TARGET}
.  endif
.  if !target(do-install)
do-install: 
	${MODRUBY_INSTALL_TARGET}
.  endif

.elif ${CONFIGURE_STYLE:L:Msetup}
MODRUBY_configure= \
	cd ${WRKSRC}; ${SETENV} ${CONFIGURE_ENV} ${RUBY} setup.rb config \
		--prefix=${PREFIX} ${CONFIGURE_ARGS};

MODRUBY_BUILD_TARGET = \
    cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${RUBY} setup.rb setup

MODRUBY_INSTALL_TARGET = \
    cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${RUBY} setup.rb install \
		--prefix=${DESTDIR}

.  if !target(do-build)
do-build: 
	${MODRUBY_BUILD_TARGET}
.  endif
.  if !target(do-install)
do-install: 
	${MODRUBY_INSTALL_TARGET}
.  endif
.endif

# These are mostly used by the non-gem ports.
SUBST_VARS+=		^MODRUBY_SITEARCHDIR ^MODRUBY_SITEDIR MODRUBY_LIBREV \
			MODRUBY_ARCH

# test stuff

.if !empty(MODRUBY_TEST)
.  if !target(do-test)

.    if ${MODRUBY_TEST:L:Mrake}
MODRUBY_TEST_BIN ?=	${RAKE} --trace
.    elif ${MODRUBY_TEST:L:Mrspec}
MODRUBY_TEST_BIN ?=	${RSPEC}
.    elif ${MODRUBY_TEST:L:Mrspec3}
MODRUBY_TEST_BIN ?=	${MODRUBY_BIN_RSPEC}
.    elif ${MODRUBY_TEST:L:Mtestrb}
.        if ${MODRUBY_REV} == "1.8" || ${MODRUBY_REV} == "2.1"
MODRUBY_TEST_BIN ?=	${MODRUBY_BIN_TESTRB}
.        else
MODRUBY_TEST_BIN ?=	${RUBY} ${PORTSDIR}/lang/ruby/files/testrb.rb
.        endif
.    elif ${MODRUBY_TEST:L:Mruby}
MODRUBY_TEST_BIN ?=	${RUBY}
.    endif

.    if ${MODRUBY_TEST:L:Mrspec} || ${MODRUBY_TEST:L:Mrspec3}
MODRUBY_TEST_TARGET ?=	spec
.    else
MODRUBY_TEST_TARGET ?=	test
.    endif

MODRUBY_TEST_ENV ?= 
MODRUBY_TEST_ENV += RUBYLIB=.:"$$RUBYLIB"
MODRUBY_TEST_DIR ?= ${WRKSRC}
do-test:
	cd ${MODRUBY_TEST_DIR} && ${SETENV} ${MAKE_ENV} HOME=${WRKBUILD} \
		${MODRUBY_TEST_ENV} ${MODRUBY_TEST_BIN} \
		${MODRUBY_TEST_TARGET}
.  endif
.endif
