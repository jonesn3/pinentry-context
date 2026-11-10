PREFIX ?= $(HOME)/.local

install:
	install -Dm755 pinentry-context $(DESTDIR)$(PREFIX)/bin/pinentry-context
	ln -sf pinentry-context $(DESTDIR)$(PREFIX)/bin/ssh-askpass-context

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/pinentry-context $(DESTDIR)$(PREFIX)/bin/ssh-askpass-context

.PHONY: install uninstall
