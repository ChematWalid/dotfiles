CC ?= gcc
CFLAGS ?= -O3 -Wall -Wextra -s
LIBS = -lX11 -lXtst

all: tray-autohide

tray-autohide: tray-autohide.c
	$(CC) $(CFLAGS) $< -o $@ $(LIBS)

clean:
	rm -f tray-autohide

.PHONY: all clean
