# hdd-route

> Automated HDD storage routing and migration utility for Arch Linux.
> Moves large app directories and caches to secondary HDD (/mnt/drive2) and creates symlinks.

- View current HDD cache routing status and free disk space:
  hdd-route status

- Route Steam games library and shader cache to HDD:
  hdd-route steam

- Route VSCode extensions and cache to HDD:
  hdd-route vscode

- Route Docker daemon root storage to HDD:
  hdd-route docker

- Route Flatpak applications and runtimes to HDD:
  hdd-route flatpak

- Route any custom directory to HDD:
  hdd-route custom {{path/to/directory}}
