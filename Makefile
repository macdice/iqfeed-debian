TARGET=target
RELEASE=4.8.1.7
INSTALLER="iqfeed_client_$(shell echo $(RELEASE) | sed 's/\./_/g').exe"
DEB=iqfeed-$(RELEASE)_amd64.deb

menu:
	@echo "Because of required manual intervention, there are four steps:"
	@echo "  make fetch -- fetch $(INSTALLER) from www.iqfeed.net"
	@echo "  make install -- install into a subdirectory (requires GUI)"
	@echo "  make dlls -- install the MS DLLs needed to run"
	@echo "  make launch -- configure login/password (requires GUI)"
	@echo "  make package -- build a Debian package"

dlls:
	if [ ! -f winetricks ] ; then wget http://winetricks.org/winetricks && chmod +x winetricks ; fi
	echo "TODO -- this doesn't work yet, apparently the vcredist_x86.exe which winetricks fetches is signed with an expired certificate, still working on this..."
	PATH=$$PATH:/usr/lib/wine WINEPREFIX=$(shell pwd)/$(TARGET)/usr/lib/iqfeed/bottle ./winetricks vcrun2010

fetch:
	wget http://www.iqfeed.net/$(INSTALLER)

install:
	mkdir -p $(TARGET)/usr/lib/iqfeed/bottle
	WINEPREFIX=$(shell pwd)/$(TARGET)/usr/lib/iqfeed/bottle wine $(INSTALLER)

launch:
	@echo "Set up your username, password and autoconnect, then connect and test"
	WINEPREFIX=$(shell pwd)/$(TARGET)/usr/lib/iqfeed/bottle wine 'c:\\Program Files\\DTN\\IQFeed\\iqconnect.exe' -product IQFEED_DEMO -version 1.0.0.0

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
