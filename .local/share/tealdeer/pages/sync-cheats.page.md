# sync-cheats

> Automated Cheatsheet & Documentation Synchronizer for tealdeer (tldr) and navi.
> Audits all tools in ~/.local/bin, ensures proper tldr pages and navi cheats, and syncs dotfiles.

- Run audit report and verify cheatsheet coverage:
  `sync-cheats`

- Automatically generate missing tldr pages and navi cheats for all uncataloged tools:
  `sync-cheats --auto`

- Generate tldr page and navi cheat template for a specific tool:
  `sync-cheats --generate {{tool_name}}`

- Read-only audit check:
  `sync-cheats --check`
