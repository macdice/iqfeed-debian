TARGET=target
RELEASE=4.7.2.0
INSTALLER="iqfeed_client_$(shell echo $(RELEASE) | sed 's/\./_/g').exe"
DEB=iqfeed-$(RELEASE)_amd64.deb

menu:
	@echo "Because of required manual intervention, there are three steps:"
	@echo "  make fetch -- fetch $(INSTALLER) from www.iqfeed.net"
	@echo "  make install -- install into a subdirectory (requires GUI)"
	@echo "  make package -- build a Debian package"

fetch:
	wget http://www.iqfeed.net/$(INSTALLER)

install:
	mkdir -p $(TARGET)/usr/lib/iqfeed/bottle
	WINEPREFIX=$(shell pwd)/$(TARGET)/usr/lib/iqfeed/bottle wine $(INSTALLER)

package: build
	fakeroot dpkg-deb --build $(TARGET) $(DEB)

build:
	rm -fr $(TARGET)/usr/lib/iqfeed/bottle/drive_c/windows/temp/*
	mkdir -p $(TARGET)/usr/lib/iqfeed
	mkdir -p $(TARGET)/etc/init.d
	mkdir -p $(TARGET)/usr/share/doc/iqfeed
	mkdir -p $(TARGET)/DEBIAN
	cp src/etc/iqfeed.conf $(TARGET)/etc/
	cp src/etc/init.d/iqfeed $(TARGET)/etc/init.d/
	cp src/usr/lib/iqfeed/run-iqfeed $(TARGET)/usr/lib/iqfeed/
	cp src/usr/share/doc/iqfeed/copyright $(TARGET)/usr/share/doc/iqfeed/
	sed "s/@RELEASE@/$(RELEASE)/g" < DEBIAN/control > $(TARGET)/DEBIAN/control
	cp DEBIAN/postinst $(TARGET)/DEBIAN/
	cp DEBIAN/postrm $(TARGET)/DEBIAN/
	cp DEBIAN/conffiles $(TARGET)/DEBIAN/
	chmod 755 $(TARGET)/DEBIAN/postinst $(TARGET)/DEBIAN/postrm

check:
	lintian $(DEB)

clean:
	rm -fr $(TARGET)
