LIBDIR ?= /usr/lib
INCLUDEDIR ?= /usr/include
SYSCONFDIR ?= /etc
DESTDIR ?=

CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -fPIC

LIB_SRCS = libexample/libexample.c
LIB_SO = libexample.so.1
LIB_SO_LINK = libexample.so

# Install targets

install-common:
	install -m 775 -D example.sh $(DESTDIR)/usr/lib/qubes/example/example.sh

install-dom0: install-common
	install -m 664 -D README.dom0 $(DESTDIR)/usr/lib/qubes/example/README

install-vm: install-common
	install -m 664 -D README.vm $(DESTDIR)/usr/lib/qubes/example/README

# Compiled library targets (arch package with debuginfo)
build-lib:
	$(CC) $(CFLAGS) -shared -Wl,-soname,$(LIB_SO) \
		-o $(LIB_SO) $(LIB_SRCS)

install-lib: build-lib
	install -d $(DESTDIR)$(LIBDIR)
	install -d $(DESTDIR)$(INCLUDEDIR)/example
	install -m 755 $(LIB_SO) $(DESTDIR)$(LIBDIR)/$(LIB_SO)
	ln -sf $(LIB_SO) $(DESTDIR)$(LIBDIR)/$(LIB_SO_LINK)
	install -m 644 libexample/example.h $(DESTDIR)$(INCLUDEDIR)/example/example.h

install-lib-devel:
	install -d $(DESTDIR)$(LIBDIR)/pkgconfig
	install -m 644 libexample/example.pc.in \
		$(DESTDIR)$(LIBDIR)/pkgconfig/example.pc
	sed -i "s|@LIBDIR@|$(LIBDIR)|g;s|@INCLUDEDIR@|$(INCLUDEDIR)|g;s|@LIBVERSION@|$(VERSION)|g" \
		$(DESTDIR)$(LIBDIR)/pkgconfig/example.pc

# noarch data/config targets (subpackages)
install-data:
	install -d $(DESTDIR)$(SYSCONFDIR)/example
	install -m 644 data/example.conf $(DESTDIR)$(SYSCONFDIR)/example/example.conf

install-extra:
	install -d $(DESTDIR)/usr/share/example
	install -m 644 data/example-extra.txt $(DESTDIR)/usr/share/example/example-extra.txt

clean:
	rm -rf pkgs $(LIB_SO)
