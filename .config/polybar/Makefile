CC ?= gcc
CXX ?= g++
CFLAGS ?= -O3 -Wall -Wextra -s
CXXFLAGS ?= -O3 -std=c++17 -Wall -Wextra -Wpedantic -s
LIBS = -lX11 -lXtst

all: tray-autohide network-eth-live network-status-live

tray-autohide: tray-autohide.c
	$(CC) $(CFLAGS) $< -o $@ $(LIBS)

network-eth-live: network-eth-live.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

network-status-live: network-status-live.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

clean:
	rm -f tray-autohide network-eth-live network-status-live

.PHONY: all clean
