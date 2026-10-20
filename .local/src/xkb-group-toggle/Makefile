CXX ?= g++
CXXFLAGS ?= -O2 -std=c++17 -Wall -Wextra -Wpedantic
LDFLAGS ?= -lX11
TARGET = xkb-group-toggle
INSTALL_DIR ?= $(HOME)/.local/bin
REPO_BIN_DIR ?= $(shell realpath ../bin)

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) $< $(LDFLAGS) -o $@

install: $(TARGET)
	install -d $(INSTALL_DIR)
	install -m 755 $(TARGET) $(INSTALL_DIR)/$(TARGET)
	@if [ -d "$(REPO_BIN_DIR)" ]; then \
		install -m 755 $(TARGET) $(REPO_BIN_DIR)/$(TARGET); \
	fi

clean:
	rm -f $(TARGET)

.PHONY: all install clean
