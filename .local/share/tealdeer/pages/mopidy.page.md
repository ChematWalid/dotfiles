# mopidy

> Extensible music server with Iris web client frontend.
> Managed locally in ~/.local/bin/mopidy.

- Start Mopidy server in foreground:
  `mopidy`

- Start Mopidy systemd user service:
  `systemctl --user start mopidy`

- Open Iris web client in browser (port 6680):
  `xdg-open http://localhost:6680/iris/`

- Connect ncmpcpp to Mopidy MPD server:
  `ncmpcpp -p 6601`

- Check Mopidy status and logs:
  `systemctl --user status mopidy`
