.PHONY: install uninstall clean

bin/bsdscheme: src/*.d
	ldc2 -of $@ $^

install:
	ln -s $(CURDIR)/bin/bsdscheme /usr/local/bin/bsdscheme

uninstall:
	rm /usr/local/bin/bsdscheme

clean:
	rm -rf bin
