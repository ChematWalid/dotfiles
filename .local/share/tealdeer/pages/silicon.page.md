# silicon

> High-resolution code snippet image generator in Rust with Catppuccin Mocha styling.
> Configured in ~/.config/silicon/config.

- Generate image from a source file:
  `silicon <file.rs> -o <output.png>`

- Generate image from clipboard and copy result back to clipboard:
  `xclip -o | silicon -l <lang> -c`

- Highlight specific lines:
  `silicon --highlight-lines 5-10 <file.py> -o <output.png>`
