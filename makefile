.PHONY: all
all:
	@echo "Run 'make install' to install raefetch"

.PHONY: install
install:
	@cp -v raefetch.sh /usr/bin/raefetch
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/raefetch

.PHONY: uninstall
uninstall:
	@rm -rf -v $(DESTDIR)$(PREFIX)/bin/raefetch