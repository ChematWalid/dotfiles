# Conky desktop clock build

The user service runs Conky 1.25.3 from `~/.local/opt/conky-1.25.3` to avoid
the font-initialization warning present in the distro build. Build and install
that version with:

```sh
~/.local/src/conky/build.sh
```

The build needs CMake, Ninja, curl, tar, a C++ compiler, and the X11, Cairo,
Lua, and Imlib2 development libraries. It installs under the home directory
and does not require root access.
