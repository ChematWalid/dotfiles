# wallpaper-rotate

> Automatic background wallpaper rotator (runs every 30 minutes).

- Check status of the background wallpaper rotation daemon:
  `systemctl --user status wallpaper-rotate.service`

- Restart the wallpaper rotation timer:
  `systemctl --user restart wallpaper-rotate.service`

- Run one rotation pass manually:
  `wallpaper-rotate.sh`
