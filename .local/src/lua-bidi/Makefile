CC ?= gcc
CFLAGS ?= -O3 -Wall -Wextra -Werror -fPIC
LUA_INC ?= -I/usr/include/lua5.4
LIBS ?= -lfribidi
TARGET = bidi.so

DESTDIR ?= $(HOME)/.config/conky
DOTFILES_DEST ?= $(shell git rev-parse --show-toplevel 2>/dev/null)/.config/conky

all: $(TARGET)

$(TARGET): bidi.c
	$(CC) $(CFLAGS) $(LUA_INC) -shared $< $(LIBS) -o $@

clean:
	rm -f $(TARGET)

install: $(TARGET)
	mkdir -p "$(DESTDIR)"
	install -m 755 $(TARGET) "$(DESTDIR)/$(TARGET)"
	@if [ -n "$(DOTFILES_DEST)" ] && [ -d "$(DOTFILES_DEST)" ]; then \
		install -m 755 $(TARGET) "$(DOTFILES_DEST)/$(TARGET)"; \
	fi

test: $(TARGET)
	lua5.4 -e 'package.cpath = "./?.so;" .. package.cpath; local b = require("bidi"); assert(b.shape("[Paused] Amr Diab — تملي معاك") ~= ""); print("bidi test passed successfully!")'

.PHONY: all clean install test
