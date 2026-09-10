# spotifyd

> Lightweight Spotify streaming daemon written in Rust with MPRIS support.
> Managed locally in ~/.local/bin/spotifyd.

- Start spotifyd daemon manually:
  `spotifyd --no-daemon --config-path ~/.config/spotifyd/spotifyd.conf`

- Start spotifyd systemd user service:
  `systemctl --user start spotifyd`

- Enable spotifyd to start on login:
  `systemctl --user enable spotifyd`

- Check spotifyd status:
  `systemctl --user status spotifyd`

- View live logs:
  `journalctl --user -u spotifyd -f`
