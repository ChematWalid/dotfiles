CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra
LIBS ?= -lX11

all: x11-grab-probe

x11-grab-probe: x11-grab-probe.c
	$(CC) $(CFLAGS) $< -o $@ $(LIBS)

install: x11-grab-probe
	install -d $(HOME)/.local/bin
	install -m 755 x11-grab-probe $(HOME)/.local/bin/

clean:
	rm -f x11-grab-probe

.PHONY: all install clean
