## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

CRTOBJS = crtfv.o
OUTPUTS = $(CRTOBJS)

noinst_LIBRARIES = lib.a

#exec_prefix= @exec_prefix@
#target_alias= @target_alias@
#MULTISUBDIR=
tooldir = $(exec_prefix)/$(target_alias)

lib_a_SOURCES = syscalls.c setjmp.S
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)

all: crt0.o $(OUTPUTS)

install:
	${INSTALL_DATA} $(OUTPUTS) $(DESTDIR)${tooldir}/lib${MULTISUBDIR}

ACLOCAL_AMFLAGS = -I ../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host
