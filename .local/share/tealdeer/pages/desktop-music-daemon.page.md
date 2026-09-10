# desktop-music-daemon

> High-efficiency Rust DBus daemon streaming active MPRIS music player metadata to /tmp/conky-music.txt.

- Check background user service status:
  `systemctl --user status desktop-music-daemon.service`

- Restart the desktop music daemon:
  `systemctl --user restart desktop-music-daemon.service`
