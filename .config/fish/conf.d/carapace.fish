# fish_add_path '/home/walid/.config/carapace/bin'

function get-env -d "get environment variable"; echo $$argv[1]; end
function set-env -d "set environment variable"; set -g -x $argv[1] $argv[2]; end
function unset-env -d "unset environment variable"; set -e $argv[1]; end

function _carapace_completer
  set --local --export CARAPACE_SHELL fish
  set --local --export CARAPACE_SHELL_ALIASES (alias | string replace -r 'alias ' '' | string replace -r '=.*' '')
  set --local --export CARAPACE_SHELL_BUILTINS (builtin --names)
  set --local --export CARAPACE_SHELL_FUNCTIONS (functions --all)
  set --local --export CARAPACE_SHELL_JOBS (jobs 2>/dev/null | string match -r '^\d+\s+\d+\s+(running|stopped|suspended|continued)' | string replace -r '^(\d+).*' '%$1')
  set --local --export CARAPACE_SHELL_VARIABLES (set --names)
  set --local data
  IFS='' set data (echo (commandline -cp)'' | sed "s/ \$/ ''/" | xargs carapace $argv[1] fish 2>/dev/null)
  if [ $status -eq 1 ]
    IFS='' set data (echo (commandline -cp)"'" | sed "s/ \$/ ''/" | xargs carapace $argv[1] fish 2>/dev/null)
    if [ $status -eq 1 ]
      IFS='' set data (echo (commandline -cp)'"' | sed "s/ \$/ ''/" | xargs carapace $argv[1] fish 2>/dev/null)
    end
  end
  echo $data
end

complete -e "'spring'"
complete -c "'spring'" -f -a '(_carapace_completer "'spring'")'
complete -e "5g"
complete -c "5g" -f -a '(_carapace_completer "5g")'
complete -e "5l"
complete -c "5l" -f -a '(_carapace_completer "5l")'
complete -e "6g"
complete -c "6g" -f -a '(_carapace_completer "6g")'
complete -e "6l"
complete -c "6l" -f -a '(_carapace_completer "6l")'
complete -e "7z"
complete -c "7z" -f -a '(_carapace_completer "7z")'
complete -e "7za"
complete -c "7za" -f -a '(_carapace_completer "7za")'
complete -e "7zr"
complete -c "7zr" -f -a '(_carapace_completer "7zr")'
complete -e "7zz"
complete -c "7zz" -f -a '(_carapace_completer "7zz")'
complete -e "8g"
complete -c "8g" -f -a '(_carapace_completer "8g")'
complete -e "8l"
complete -c "8l" -f -a '(_carapace_completer "8l")'
complete -e "Mosaic"
complete -c "Mosaic" -f -a '(_carapace_completer "Mosaic")'
complete -e "a2ps"
complete -c "a2ps" -f -a '(_carapace_completer "a2ps")'
complete -e "aaaa"
complete -c "aaaa" -f -a '(_carapace_completer "aaaa")'
complete -e "aac2mp4"
complete -c "aac2mp4" -f -a '(_carapace_completer "aac2mp4")'
complete -e "aap"
complete -c "aap" -f -a '(_carapace_completer "aap")'
complete -e "abcde"
complete -c "abcde" -f -a '(_carapace_completer "abcde")'
complete -e "ack"
complete -c "ack" -f -a '(_carapace_completer "ack")'
complete -e "ack-grep"
complete -c "ack-grep" -f -a '(_carapace_completer "ack-grep")'
complete -e "ack-standalone"
complete -c "ack-standalone" -f -a '(_carapace_completer "ack-standalone")'
complete -e "ack2"
complete -c "ack2" -f -a '(_carapace_completer "ack2")'
complete -e "acpi"
complete -c "acpi" -f -a '(_carapace_completer "acpi")'
complete -e "acpid"
complete -c "acpid" -f -a '(_carapace_completer "acpid")'
complete -e "acpitool"
complete -c "acpitool" -f -a '(_carapace_completer "acpitool")'
complete -e "acroread"
complete -c "acroread" -f -a '(_carapace_completer "acroread")'
complete -e "act"
complete -c "act" -f -a '(_carapace_completer "act")'
complete -e "adb"
complete -c "adb" -f -a '(_carapace_completer "adb")'
complete -e "add-zle-hook-widget"
complete -c "add-zle-hook-widget" -f -a '(_carapace_completer "add-zle-hook-widget")'
complete -e "add-zsh-hook"
complete -c "add-zsh-hook" -f -a '(_carapace_completer "add-zsh-hook")'
complete -e "addpart"
complete -c "addpart" -f -a '(_carapace_completer "addpart")'
complete -e "afew"
complete -c "afew" -f -a '(_carapace_completer "afew")'
complete -e "age"
complete -c "age" -f -a '(_carapace_completer "age")'
complete -e "age-keygen"
complete -c "age-keygen" -f -a '(_carapace_completer "age-keygen")'
complete -e "agg"
complete -c "agg" -f -a '(_carapace_completer "agg")'
complete -e "alacritty"
complete -c "alacritty" -f -a '(_carapace_completer "alacritty")'
complete -e "ali"
complete -c "ali" -f -a '(_carapace_completer "ali")'
complete -e "alsamixer"
complete -c "alsamixer" -f -a '(_carapace_completer "alsamixer")'
complete -e "amaya"
complete -c "amaya" -f -a '(_carapace_completer "amaya")'
complete -e "analyseplugin"
complete -c "analyseplugin" -f -a '(_carapace_completer "analyseplugin")'
complete -e "animate"
complete -c "animate" -f -a '(_carapace_completer "animate")'
complete -e "anno"
complete -c "anno" -f -a '(_carapace_completer "anno")'
complete -e "ansible"
complete -c "ansible" -f -a '(_carapace_completer "ansible")'
complete -e "ansible-config"
complete -c "ansible-config" -f -a '(_carapace_completer "ansible-config")'
complete -e "ansible-console"
complete -c "ansible-console" -f -a '(_carapace_completer "ansible-console")'
complete -e "ansible-creator"
complete -c "ansible-creator" -f -a '(_carapace_completer "ansible-creator")'
complete -e "ansible-doc"
complete -c "ansible-doc" -f -a '(_carapace_completer "ansible-doc")'
complete -e "ansible-galaxy"
complete -c "ansible-galaxy" -f -a '(_carapace_completer "ansible-galaxy")'
complete -e "ansible-inventory"
complete -c "ansible-inventory" -f -a '(_carapace_completer "ansible-inventory")'
complete -e "ansible-playbook"
complete -c "ansible-playbook" -f -a '(_carapace_completer "ansible-playbook")'
complete -e "ansible-pull"
complete -c "ansible-pull" -f -a '(_carapace_completer "ansible-pull")'
complete -e "ansible-vault"
complete -c "ansible-vault" -f -a '(_carapace_completer "ansible-vault")'
complete -e "ant"
complete -c "ant" -f -a '(_carapace_completer "ant")'
complete -e "antiword"
complete -c "antiword" -f -a '(_carapace_completer "antiword")'
complete -e "anyconv"
complete -c "anyconv" -f -a '(_carapace_completer "anyconv")'
complete -e "aodh"
complete -c "aodh" -f -a '(_carapace_completer "aodh")'
complete -e "aoss"
complete -c "aoss" -f -a '(_carapace_completer "aoss")'
complete -e "apache2ctl"
complete -c "apache2ctl" -f -a '(_carapace_completer "apache2ctl")'
complete -e "apachectl"
complete -c "apachectl" -f -a '(_carapace_completer "apachectl")'
complete -e "apk"
complete -c "apk" -f -a '(_carapace_completer "apk")'
complete -e "apko"
complete -c "apko" -f -a '(_carapace_completer "apko")'
complete -e "aplay"
complete -c "aplay" -f -a '(_carapace_completer "aplay")'
complete -e "apm"
complete -c "apm" -f -a '(_carapace_completer "apm")'
complete -e "appletviewer"
complete -c "appletviewer" -f -a '(_carapace_completer "appletviewer")'
complete -e "appstreamcli"
complete -c "appstreamcli" -f -a '(_carapace_completer "appstreamcli")'
complete -e "apptainer"
complete -c "apptainer" -f -a '(_carapace_completer "apptainer")'
complete -e "apropos"
complete -c "apropos" -f -a '(_carapace_completer "apropos")'
complete -e "apt"
complete -c "apt" -f -a '(_carapace_completer "apt")'
complete -e "apt-cache"
complete -c "apt-cache" -f -a '(_carapace_completer "apt-cache")'
complete -e "apt-get"
complete -c "apt-get" -f -a '(_carapace_completer "apt-get")'
complete -e "apvlv"
complete -c "apvlv" -f -a '(_carapace_completer "apvlv")'
complete -e "aqua"
complete -c "aqua" -f -a '(_carapace_completer "aqua")'
complete -e "ar"
complete -c "ar" -f -a '(_carapace_completer "ar")'
complete -e "archlinux-java"
complete -c "archlinux-java" -f -a '(_carapace_completer "archlinux-java")'
complete -e "arduino-ctags"
complete -c "arduino-ctags" -f -a '(_carapace_completer "arduino-ctags")'
complete -e "arecord"
complete -c "arecord" -f -a '(_carapace_completer "arecord")'
complete -e "arena"
complete -c "arena" -f -a '(_carapace_completer "arena")'
complete -e "argo"
complete -c "argo" -f -a '(_carapace_completer "argo")'
complete -e "argocd"
complete -c "argocd" -f -a '(_carapace_completer "argocd")'
complete -e "aria2c"
complete -c "aria2c" -f -a '(_carapace_completer "aria2c")'
complete -e "arp"
complete -c "arp" -f -a '(_carapace_completer "arp")'
complete -e "arping"
complete -c "arping" -f -a '(_carapace_completer "arping")'
complete -e "arptables"
complete -c "arptables" -f -a '(_carapace_completer "arptables")'
complete -e "artisan"
complete -c "artisan" -f -a '(_carapace_completer "artisan")'
complete -e "asciidoctor"
complete -c "asciidoctor" -f -a '(_carapace_completer "asciidoctor")'
complete -e "asciinema"
complete -c "asciinema" -f -a '(_carapace_completer "asciinema")'
complete -e "ash"
complete -c "ash" -f -a '(_carapace_completer "ash")'
complete -e "ast-grep"
complete -c "ast-grep" -f -a '(_carapace_completer "ast-grep")'
complete -e "at"
complete -c "at" -f -a '(_carapace_completer "at")'
complete -e "atach"
complete -c "atach" -f -a '(_carapace_completer "atach")'
complete -e "atq"
complete -c "atq" -f -a '(_carapace_completer "atq")'
complete -e "atrm"
complete -c "atrm" -f -a '(_carapace_completer "atrm")'
complete -e "attr"
complete -c "attr" -f -a '(_carapace_completer "attr")'
complete -e "atuin"
complete -c "atuin" -f -a '(_carapace_completer "atuin")'
complete -e "audit2allow"
complete -c "audit2allow" -f -a '(_carapace_completer "audit2allow")'
complete -e "audit2why"
complete -c "audit2why" -f -a '(_carapace_completer "audit2why")'
complete -e "auditctl"
complete -c "auditctl" -f -a '(_carapace_completer "auditctl")'
complete -e "augenrules"
complete -c "augenrules" -f -a '(_carapace_completer "augenrules")'
complete -e "augmatch"
complete -c "augmatch" -f -a '(_carapace_completer "augmatch")'
complete -e "augparse"
complete -c "augparse" -f -a '(_carapace_completer "augparse")'
complete -e "augprint"
complete -c "augprint" -f -a '(_carapace_completer "augprint")'
complete -e "augtool"
complete -c "augtool" -f -a '(_carapace_completer "augtool")'
complete -e "aureport"
complete -c "aureport" -f -a '(_carapace_completer "aureport")'
complete -e "ausearch"
complete -c "ausearch" -f -a '(_carapace_completer "ausearch")'
complete -e "autoconf"
complete -c "autoconf" -f -a '(_carapace_completer "autoconf")'
complete -e "autorandr"
complete -c "autorandr" -f -a '(_carapace_completer "autorandr")'
complete -e "avahi-browse"
complete -c "avahi-browse" -f -a '(_carapace_completer "avahi-browse")'
complete -e "avahi-browse-domains"
complete -c "avahi-browse-domains" -f -a '(_carapace_completer "avahi-browse-domains")'
complete -e "avahi-resolve"
complete -c "avahi-resolve" -f -a '(_carapace_completer "avahi-resolve")'
complete -e "avahi-resolve-address"
complete -c "avahi-resolve-address" -f -a '(_carapace_completer "avahi-resolve-address")'
complete -e "avahi-resolve-host-name"
complete -c "avahi-resolve-host-name" -f -a '(_carapace_completer "avahi-resolve-host-name")'
complete -e "avcstat"
complete -c "avcstat" -f -a '(_carapace_completer "avcstat")'
complete -e "avdmanager"
complete -c "avdmanager" -f -a '(_carapace_completer "avdmanager")'
complete -e "awk"
complete -c "awk" -f -a '(_carapace_completer "awk")'
complete -e "aws"
complete -c "aws" -f -a '(_carapace_completer "aws")'
complete -e "az"
complete -c "az" -f -a '(_carapace_completer "az")'
complete -e "b2sum"
complete -c "b2sum" -f -a '(_carapace_completer "b2sum")'
complete -e "baobab"
complete -c "baobab" -f -a '(_carapace_completer "baobab")'
complete -e "barbican"
complete -c "barbican" -f -a '(_carapace_completer "barbican")'
complete -e "base32"
complete -c "base32" -f -a '(_carapace_completer "base32")'
complete -e "base64"
complete -c "base64" -f -a '(_carapace_completer "base64")'
complete -e "basename"
complete -c "basename" -f -a '(_carapace_completer "basename")'
complete -e "basenc"
complete -c "basenc" -f -a '(_carapace_completer "basenc")'
complete -e "bash"
complete -c "bash" -f -a '(_carapace_completer "bash")'
complete -e "bash-language-server"
complete -c "bash-language-server" -f -a '(_carapace_completer "bash-language-server")'
complete -e "bat"
complete -c "bat" -f -a '(_carapace_completer "bat")'
complete -e "batch"
complete -c "batch" -f -a '(_carapace_completer "batch")'
complete -e "batdiff"
complete -c "batdiff" -f -a '(_carapace_completer "batdiff")'
complete -e "batgrep"
complete -c "batgrep" -f -a '(_carapace_completer "batgrep")'
complete -e "batman"
complete -c "batman" -f -a '(_carapace_completer "batman")'
complete -e "bats"
complete -c "bats" -f -a '(_carapace_completer "bats")'
complete -e "baz"
complete -c "baz" -f -a '(_carapace_completer "baz")'
complete -e "bazel"
complete -c "bazel" -f -a '(_carapace_completer "bazel")'
complete -e "bc"
complete -c "bc" -f -a '(_carapace_completer "bc")'
complete -e "beep"
complete -c "beep" -f -a '(_carapace_completer "beep")'
complete -e "benthos"
complete -c "benthos" -f -a '(_carapace_completer "benthos")'
complete -e "bibtex"
complete -c "bibtex" -f -a '(_carapace_completer "bibtex")'
complete -e "bison"
complete -c "bison" -f -a '(_carapace_completer "bison")'
complete -e "bitcoin-cli"
complete -c "bitcoin-cli" -f -a '(_carapace_completer "bitcoin-cli")'
complete -e "bits"
complete -c "bits" -f -a '(_carapace_completer "bits")'
complete -e "black"
complete -c "black" -f -a '(_carapace_completer "black")'
complete -e "blkdiscard"
complete -c "blkdiscard" -f -a '(_carapace_completer "blkdiscard")'
complete -e "blkid"
complete -c "blkid" -f -a '(_carapace_completer "blkid")'
complete -e "blkpr"
complete -c "blkpr" -f -a '(_carapace_completer "blkpr")'
complete -e "blkzone"
complete -c "blkzone" -f -a '(_carapace_completer "blkzone")'
complete -e "blockdev"
complete -c "blockdev" -f -a '(_carapace_completer "blockdev")'
complete -e "bloop"
complete -c "bloop" -f -a '(_carapace_completer "bloop")'
complete -e "bluetoothctl"
complete -c "bluetoothctl" -f -a '(_carapace_completer "bluetoothctl")'
complete -e "bmake"
complete -c "bmake" -f -a '(_carapace_completer "bmake")'
complete -e "bogofilter"
complete -c "bogofilter" -f -a '(_carapace_completer "bogofilter")'
complete -e "bogotune"
complete -c "bogotune" -f -a '(_carapace_completer "bogotune")'
complete -e "bogoutil"
complete -c "bogoutil" -f -a '(_carapace_completer "bogoutil")'
complete -e "bootctl"
complete -c "bootctl" -f -a '(_carapace_completer "bootctl")'
complete -e "boundary"
complete -c "boundary" -f -a '(_carapace_completer "boundary")'
complete -e "bower"
complete -c "bower" -f -a '(_carapace_completer "bower")'
complete -e "bpython"
complete -c "bpython" -f -a '(_carapace_completer "bpython")'
complete -e "bpython-gtk"
complete -c "bpython-gtk" -f -a '(_carapace_completer "bpython-gtk")'
complete -e "bpython-urwid"
complete -c "bpython-urwid" -f -a '(_carapace_completer "bpython-urwid")'
complete -e "bpython2"
complete -c "bpython2" -f -a '(_carapace_completer "bpython2")'
complete -e "bpython2-gtk"
complete -c "bpython2-gtk" -f -a '(_carapace_completer "bpython2-gtk")'
complete -e "bpython2-urwid"
complete -c "bpython2-urwid" -f -a '(_carapace_completer "bpython2-urwid")'
complete -e "bpython3"
complete -c "bpython3" -f -a '(_carapace_completer "bpython3")'
complete -e "bpython3-gtk"
complete -c "bpython3-gtk" -f -a '(_carapace_completer "bpython3-gtk")'
complete -e "bpython3-urwid"
complete -c "bpython3-urwid" -f -a '(_carapace_completer "bpython3-urwid")'
complete -e "brctl"
complete -c "brctl" -f -a '(_carapace_completer "brctl")'
complete -e "brew"
complete -c "brew" -f -a '(_carapace_completer "brew")'
complete -e "brotli"
complete -c "brotli" -f -a '(_carapace_completer "brotli")'
complete -e "bru"
complete -c "bru" -f -a '(_carapace_completer "bru")'
complete -e "bsdgrep"
complete -c "bsdgrep" -f -a '(_carapace_completer "bsdgrep")'
complete -e "bsdtar"
complete -c "bsdtar" -f -a '(_carapace_completer "bsdtar")'
complete -e "btdownloadcurses"
complete -c "btdownloadcurses" -f -a '(_carapace_completer "btdownloadcurses")'
complete -e "btdownloadgui"
complete -c "btdownloadgui" -f -a '(_carapace_completer "btdownloadgui")'
complete -e "btdownloadheadless"
complete -c "btdownloadheadless" -f -a '(_carapace_completer "btdownloadheadless")'
complete -e "btlaunchmany"
complete -c "btlaunchmany" -f -a '(_carapace_completer "btlaunchmany")'
complete -e "btlaunchmanycurses"
complete -c "btlaunchmanycurses" -f -a '(_carapace_completer "btlaunchmanycurses")'
complete -e "btmakemetafile"
complete -c "btmakemetafile" -f -a '(_carapace_completer "btmakemetafile")'
complete -e "btop"
complete -c "btop" -f -a '(_carapace_completer "btop")'
complete -e "btreannounce"
complete -c "btreannounce" -f -a '(_carapace_completer "btreannounce")'
complete -e "btrename"
complete -c "btrename" -f -a '(_carapace_completer "btrename")'
complete -e "btrfs"
complete -c "btrfs" -f -a '(_carapace_completer "btrfs")'
complete -e "btshowmetainfo"
complete -c "btshowmetainfo" -f -a '(_carapace_completer "btshowmetainfo")'
complete -e "bttrack"
complete -c "bttrack" -f -a '(_carapace_completer "bttrack")'
complete -e "buildctl"
complete -c "buildctl" -f -a '(_carapace_completer "buildctl")'
complete -e "buildhash"
complete -c "buildhash" -f -a '(_carapace_completer "buildhash")'
complete -e "bun"
complete -c "bun" -f -a '(_carapace_completer "bun")'
complete -e "bundle"
complete -c "bundle" -f -a '(_carapace_completer "bundle")'
complete -e "bunx"
complete -c "bunx" -f -a '(_carapace_completer "bunx")'
complete -e "bunzip2"
complete -c "bunzip2" -f -a '(_carapace_completer "bunzip2")'
complete -e "burst"
complete -c "burst" -f -a '(_carapace_completer "burst")'
complete -e "busctl"
complete -c "busctl" -f -a '(_carapace_completer "busctl")'
complete -e "but"
complete -c "but" -f -a '(_carapace_completer "but")'
complete -e "bw"
complete -c "bw" -f -a '(_carapace_completer "bw")'
complete -e "bwrap"
complete -c "bwrap" -f -a '(_carapace_completer "bwrap")'
complete -e "bzegrep"
complete -c "bzegrep" -f -a '(_carapace_completer "bzegrep")'
complete -e "bzfgrep"
complete -c "bzfgrep" -f -a '(_carapace_completer "bzfgrep")'
complete -e "bzgrep"
complete -c "bzgrep" -f -a '(_carapace_completer "bzgrep")'
complete -e "bzip2"
complete -c "bzip2" -f -a '(_carapace_completer "bzip2")'
complete -e "bzip2recover"
complete -c "bzip2recover" -f -a '(_carapace_completer "bzip2recover")'
complete -e "bzr"
complete -c "bzr" -f -a '(_carapace_completer "bzr")'
complete -e "c++"
complete -c "c++" -f -a '(_carapace_completer "c++")'
complete -e "cabal"
complete -c "cabal" -f -a '(_carapace_completer "cabal")'
complete -e "cacaclock"
complete -c "cacaclock" -f -a '(_carapace_completer "cacaclock")'
complete -e "cal"
complete -c "cal" -f -a '(_carapace_completer "cal")'
complete -e "calendar"
complete -c "calendar" -f -a '(_carapace_completer "calendar")'
complete -e "calibre"
complete -c "calibre" -f -a '(_carapace_completer "calibre")'
complete -e "calibre-debug"
complete -c "calibre-debug" -f -a '(_carapace_completer "calibre-debug")'
complete -e "calibre-server"
complete -c "calibre-server" -f -a '(_carapace_completer "calibre-server")'
complete -e "calibre-smtp"
complete -c "calibre-smtp" -f -a '(_carapace_completer "calibre-smtp")'
complete -e "calibredb"
complete -c "calibredb" -f -a '(_carapace_completer "calibredb")'
complete -e "cap"
complete -c "cap" -f -a '(_carapace_completer "cap")'
complete -e "cap-audit"
complete -c "cap-audit" -f -a '(_carapace_completer "cap-audit")'
complete -e "capslock"
complete -c "capslock" -f -a '(_carapace_completer "capslock")'
complete -e "carapace"
complete -c "carapace" -f -a '(_carapace_completer "carapace")'
complete -e "cargo"
complete -c "cargo" -f -a '(_carapace_completer "cargo")'
complete -e "cargo-clippy"
complete -c "cargo-clippy" -f -a '(_carapace_completer "cargo-clippy")'
complete -e "cargo-fmt"
complete -c "cargo-fmt" -f -a '(_carapace_completer "cargo-fmt")'
complete -e "cargo-metadata"
complete -c "cargo-metadata" -f -a '(_carapace_completer "cargo-metadata")'
complete -e "cargo-rm"
complete -c "cargo-rm" -f -a '(_carapace_completer "cargo-rm")'
complete -e "cargo-set-version"
complete -c "cargo-set-version" -f -a '(_carapace_completer "cargo-set-version")'
complete -e "cargo-upgrade"
complete -c "cargo-upgrade" -f -a '(_carapace_completer "cargo-upgrade")'
complete -e "cargo-watch"
complete -c "cargo-watch" -f -a '(_carapace_completer "cargo-watch")'
complete -e "cask"
complete -c "cask" -f -a '(_carapace_completer "cask")'
complete -e "cat"
complete -c "cat" -f -a '(_carapace_completer "cat")'
complete -e "catchsegv"
complete -c "catchsegv" -f -a '(_carapace_completer "catchsegv")'
complete -e "cbonsai"
complete -c "cbonsai" -f -a '(_carapace_completer "cbonsai")'
complete -e "cc"
complete -c "cc" -f -a '(_carapace_completer "cc")'
complete -e "ccache"
complete -c "ccache" -f -a '(_carapace_completer "ccache")'
complete -e "ccal"
complete -c "ccal" -f -a '(_carapace_completer "ccal")'
complete -e "cdcd"
complete -c "cdcd" -f -a '(_carapace_completer "cdcd")'
complete -e "cdebug"
complete -c "cdebug" -f -a '(_carapace_completer "cdebug")'
complete -e "cdr"
complete -c "cdr" -f -a '(_carapace_completer "cdr")'
complete -e "cdrdao"
complete -c "cdrdao" -f -a '(_carapace_completer "cdrdao")'
complete -e "cdrecord"
complete -c "cdrecord" -f -a '(_carapace_completer "cdrecord")'
complete -e "ceilometer"
complete -c "ceilometer" -f -a '(_carapace_completer "ceilometer")'
complete -e "cekit"
complete -c "cekit" -f -a '(_carapace_completer "cekit")'
complete -e "certbot"
complete -c "certbot" -f -a '(_carapace_completer "certbot")'
complete -e "certtool"
complete -c "certtool" -f -a '(_carapace_completer "certtool")'
complete -e "cf"
complete -c "cf" -f -a '(_carapace_completer "cf")'
complete -e "cfdisk"
complete -c "cfdisk" -f -a '(_carapace_completer "cfdisk")'
complete -e "cftp"
complete -c "cftp" -f -a '(_carapace_completer "cftp")'
complete -e "chafa"
complete -c "chafa" -f -a '(_carapace_completer "chafa")'
complete -e "chage"
complete -c "chage" -f -a '(_carapace_completer "chage")'
complete -e "charm"
complete -c "charm" -f -a '(_carapace_completer "charm")'
complete -e "chatblade"
complete -c "chatblade" -f -a '(_carapace_completer "chatblade")'
complete -e "chattr"
complete -c "chattr" -f -a '(_carapace_completer "chattr")'
complete -e "chcon"
complete -c "chcon" -f -a '(_carapace_completer "chcon")'
complete -e "chcpu"
complete -c "chcpu" -f -a '(_carapace_completer "chcpu")'
complete -e "chdman"
complete -c "chdman" -f -a '(_carapace_completer "chdman")'
complete -e "checkmodule"
complete -c "checkmodule" -f -a '(_carapace_completer "checkmodule")'
complete -e "checkpolicy"
complete -c "checkpolicy" -f -a '(_carapace_completer "checkpolicy")'
complete -e "checkupdates"
complete -c "checkupdates" -f -a '(_carapace_completer "checkupdates")'
complete -e "cheese"
complete -c "cheese" -f -a '(_carapace_completer "cheese")'
complete -e "chezmoi"
complete -c "chezmoi" -f -a '(_carapace_completer "chezmoi")'
complete -e "chfn"
complete -c "chfn" -f -a '(_carapace_completer "chfn")'
complete -e "chgrp"
complete -c "chgrp" -f -a '(_carapace_completer "chgrp")'
complete -e "chimera"
complete -c "chimera" -f -a '(_carapace_completer "chimera")'
complete -e "chkconfig"
complete -c "chkconfig" -f -a '(_carapace_completer "chkconfig")'
complete -e "chkstow"
complete -c "chkstow" -f -a '(_carapace_completer "chkstow")'
complete -e "chmem"
complete -c "chmem" -f -a '(_carapace_completer "chmem")'
complete -e "chmod"
complete -c "chmod" -f -a '(_carapace_completer "chmod")'
complete -e "choc"
complete -c "choc" -f -a '(_carapace_completer "choc")'
complete -e "choom"
complete -c "choom" -f -a '(_carapace_completer "choom")'
complete -e "chown"
complete -c "chown" -f -a '(_carapace_completer "chown")'
complete -e "chpass"
complete -c "chpass" -f -a '(_carapace_completer "chpass")'
complete -e "chpasswd"
complete -c "chpasswd" -f -a '(_carapace_completer "chpasswd")'
complete -e "chroma"
complete -c "chroma" -f -a '(_carapace_completer "chroma")'
complete -e "chromium"
complete -c "chromium" -f -a '(_carapace_completer "chromium")'
complete -e "chroot"
complete -c "chroot" -f -a '(_carapace_completer "chroot")'
complete -e "chrt"
complete -c "chrt" -f -a '(_carapace_completer "chrt")'
complete -e "chsh"
complete -c "chsh" -f -a '(_carapace_completer "chsh")'
complete -e "ci"
complete -c "ci" -f -a '(_carapace_completer "ci")'
complete -e "cifsiostat"
complete -c "cifsiostat" -f -a '(_carapace_completer "cifsiostat")'
complete -e "cinder"
complete -c "cinder" -f -a '(_carapace_completer "cinder")'
complete -e "circleci"
complete -c "circleci" -f -a '(_carapace_completer "circleci")'
complete -e "ckeygen"
complete -c "ckeygen" -f -a '(_carapace_completer "ckeygen")'
complete -e "cksum"
complete -c "cksum" -f -a '(_carapace_completer "cksum")'
complete -e "clamav-config"
complete -c "clamav-config" -f -a '(_carapace_completer "clamav-config")'
complete -e "clamav-milter"
complete -c "clamav-milter" -f -a '(_carapace_completer "clamav-milter")'
complete -e "clambc"
complete -c "clambc" -f -a '(_carapace_completer "clambc")'
complete -e "clamconf"
complete -c "clamconf" -f -a '(_carapace_completer "clamconf")'
complete -e "clamd"
complete -c "clamd" -f -a '(_carapace_completer "clamd")'
complete -e "clamdscan"
complete -c "clamdscan" -f -a '(_carapace_completer "clamdscan")'
complete -e "clamdtop"
complete -c "clamdtop" -f -a '(_carapace_completer "clamdtop")'
complete -e "clamonacc"
complete -c "clamonacc" -f -a '(_carapace_completer "clamonacc")'
complete -e "clamscan"
complete -c "clamscan" -f -a '(_carapace_completer "clamscan")'
complete -e "clamsubmit"
complete -c "clamsubmit" -f -a '(_carapace_completer "clamsubmit")'
complete -e "clang"
complete -c "clang" -f -a '(_carapace_completer "clang")'
complete -e "clang++"
complete -c "clang++" -f -a '(_carapace_completer "clang++")'
complete -e "clang-check"
complete -c "clang-check" -f -a '(_carapace_completer "clang-check")'
complete -e "clang-format"
complete -c "clang-format" -f -a '(_carapace_completer "clang-format")'
complete -e "clang-tidy"
complete -c "clang-tidy" -f -a '(_carapace_completer "clang-tidy")'
complete -e "clay"
complete -c "clay" -f -a '(_carapace_completer "clay")'
complete -e "clear"
complete -c "clear" -f -a '(_carapace_completer "clear")'
complete -e "clion"
complete -c "clion" -f -a '(_carapace_completer "clion")'
complete -e "cloudkitty"
complete -c "cloudkitty" -f -a '(_carapace_completer "cloudkitty")'
complete -e "clusterdb"
complete -c "clusterdb" -f -a '(_carapace_completer "clusterdb")'
complete -e "cmake"
complete -c "cmake" -f -a '(_carapace_completer "cmake")'
complete -e "cmp"
complete -c "cmp" -f -a '(_carapace_completer "cmp")'
complete -e "cmus"
complete -c "cmus" -f -a '(_carapace_completer "cmus")'
complete -e "cmus-remote"
complete -c "cmus-remote" -f -a '(_carapace_completer "cmus-remote")'
complete -e "co"
complete -c "co" -f -a '(_carapace_completer "co")'
complete -e "code"
complete -c "code" -f -a '(_carapace_completer "code")'
complete -e "code-insiders"
complete -c "code-insiders" -f -a '(_carapace_completer "code-insiders")'
complete -e "codecov"
complete -c "codecov" -f -a '(_carapace_completer "codecov")'
complete -e "coffee"
complete -c "coffee" -f -a '(_carapace_completer "coffee")'
complete -e "col"
complete -c "col" -f -a '(_carapace_completer "col")'
complete -e "colcrt"
complete -c "colcrt" -f -a '(_carapace_completer "colcrt")'
complete -e "colima"
complete -c "colima" -f -a '(_carapace_completer "colima")'
complete -e "colrm"
complete -c "colrm" -f -a '(_carapace_completer "colrm")'
complete -e "column"
complete -c "column" -f -a '(_carapace_completer "column")'
complete -e "combine"
complete -c "combine" -f -a '(_carapace_completer "combine")'
complete -e "combinediff"
complete -c "combinediff" -f -a '(_carapace_completer "combinediff")'
complete -e "comm"
complete -c "comm" -f -a '(_carapace_completer "comm")'
complete -e "comp"
complete -c "comp" -f -a '(_carapace_completer "comp")'
complete -e "compare"
complete -c "compare" -f -a '(_carapace_completer "compare")'
complete -e "compinit"
complete -c "compinit" -f -a '(_carapace_completer "compinit")'
complete -e "composer"
complete -c "composer" -f -a '(_carapace_completer "composer")'
complete -e "composer.phar"
complete -c "composer.phar" -f -a '(_carapace_completer "composer.phar")'
complete -e "composite"
complete -c "composite" -f -a '(_carapace_completer "composite")'
complete -e "compress"
complete -c "compress" -f -a '(_carapace_completer "compress")'
complete -e "conan"
complete -c "conan" -f -a '(_carapace_completer "conan")'
complete -e "conch"
complete -c "conch" -f -a '(_carapace_completer "conch")'
complete -e "concourse"
complete -c "concourse" -f -a '(_carapace_completer "concourse")'
complete -e "conda"
complete -c "conda" -f -a '(_carapace_completer "conda")'
complete -e "conda-content-trust"
complete -c "conda-content-trust" -f -a '(_carapace_completer "conda-content-trust")'
complete -e "conda-env"
complete -c "conda-env" -f -a '(_carapace_completer "conda-env")'
complete -e "config.status"
complete -c "config.status" -f -a '(_carapace_completer "config.status")'
complete -e "configure"
complete -c "configure" -f -a '(_carapace_completer "configure")'
complete -e "conky"
complete -c "conky" -f -a '(_carapace_completer "conky")'
complete -e "consul"
complete -c "consul" -f -a '(_carapace_completer "consul")'
complete -e "conv"
complete -c "conv" -f -a '(_carapace_completer "conv")'
complete -e "convert"
complete -c "convert" -f -a '(_carapace_completer "convert")'
complete -e "copyfilerange"
complete -c "copyfilerange" -f -a '(_carapace_completer "copyfilerange")'
complete -e "copyq"
complete -c "copyq" -f -a '(_carapace_completer "copyq")'
complete -e "coredumpctl"
complete -c "coredumpctl" -f -a '(_carapace_completer "coredumpctl")'
complete -e "coresched"
complete -c "coresched" -f -a '(_carapace_completer "coresched")'
complete -e "cosign"
complete -c "cosign" -f -a '(_carapace_completer "cosign")'
complete -e "cowsay"
complete -c "cowsay" -f -a '(_carapace_completer "cowsay")'
complete -e "cowthink"
complete -c "cowthink" -f -a '(_carapace_completer "cowthink")'
complete -e "cp"
complete -c "cp" -f -a '(_carapace_completer "cp")'
complete -e "cpack"
complete -c "cpack" -f -a '(_carapace_completer "cpack")'
complete -e "cpio"
complete -c "cpio" -f -a '(_carapace_completer "cpio")'
complete -e "cplay"
complete -c "cplay" -f -a '(_carapace_completer "cplay")'
complete -e "cppcheck"
complete -c "cppcheck" -f -a '(_carapace_completer "cppcheck")'
complete -e "cpupower"
complete -c "cpupower" -f -a '(_carapace_completer "cpupower")'
complete -e "crc"
complete -c "crc" -f -a '(_carapace_completer "crc")'
complete -e "createdb"
complete -c "createdb" -f -a '(_carapace_completer "createdb")'
complete -e "createuser"
complete -c "createuser" -f -a '(_carapace_completer "createuser")'
complete -e "crontab"
complete -c "crontab" -f -a '(_carapace_completer "crontab")'
complete -e "crsh"
complete -c "crsh" -f -a '(_carapace_completer "crsh")'
complete -e "crush"
complete -c "crush" -f -a '(_carapace_completer "crush")'
complete -e "cryptsetup"
complete -c "cryptsetup" -f -a '(_carapace_completer "cryptsetup")'
complete -e "cscope"
complete -c "cscope" -f -a '(_carapace_completer "cscope")'
complete -e "csh"
complete -c "csh" -f -a '(_carapace_completer "csh")'
complete -e "csplit"
complete -c "csplit" -f -a '(_carapace_completer "csplit")'
complete -e "cssh"
complete -c "cssh" -f -a '(_carapace_completer "cssh")'
complete -e "csview"
complete -c "csview" -f -a '(_carapace_completer "csview")'
complete -e "ctags"
complete -c "ctags" -f -a '(_carapace_completer "ctags")'
complete -e "ctags-exuberant"
complete -c "ctags-exuberant" -f -a '(_carapace_completer "ctags-exuberant")'
complete -e "ctags-universal"
complete -c "ctags-universal" -f -a '(_carapace_completer "ctags-universal")'
complete -e "ctest"
complete -c "ctest" -f -a '(_carapace_completer "ctest")'
complete -e "ctr"
complete -c "ctr" -f -a '(_carapace_completer "ctr")'
complete -e "ctrlaltdel"
complete -c "ctrlaltdel" -f -a '(_carapace_completer "ctrlaltdel")'
complete -e "cue"
complete -c "cue" -f -a '(_carapace_completer "cue")'
complete -e "cura"
complete -c "cura" -f -a '(_carapace_completer "cura")'
complete -e "curl"
complete -c "curl" -f -a '(_carapace_completer "curl")'
complete -e "cut"
complete -c "cut" -f -a '(_carapace_completer "cut")'
complete -e "cvs"
complete -c "cvs" -f -a '(_carapace_completer "cvs")'
complete -e "cxl"
complete -c "cxl" -f -a '(_carapace_completer "cxl")'
complete -e "d2"
complete -c "d2" -f -a '(_carapace_completer "d2")'
complete -e "dad"
complete -c "dad" -f -a '(_carapace_completer "dad")'
complete -e "dagger"
complete -c "dagger" -f -a '(_carapace_completer "dagger")'
complete -e "darcs"
complete -c "darcs" -f -a '(_carapace_completer "darcs")'
complete -e "darktable"
complete -c "darktable" -f -a '(_carapace_completer "darktable")'
complete -e "darktable-cli"
complete -c "darktable-cli" -f -a '(_carapace_completer "darktable-cli")'
complete -e "dart"
complete -c "dart" -f -a '(_carapace_completer "dart")'
complete -e "dash"
complete -c "dash" -f -a '(_carapace_completer "dash")'
complete -e "datagrip"
complete -c "datagrip" -f -a '(_carapace_completer "datagrip")'
complete -e "dataspell"
complete -c "dataspell" -f -a '(_carapace_completer "dataspell")'
complete -e "date"
complete -c "date" -f -a '(_carapace_completer "date")'
complete -e "daxctl"
complete -c "daxctl" -f -a '(_carapace_completer "daxctl")'
complete -e "dbt"
complete -c "dbt" -f -a '(_carapace_completer "dbt")'
complete -e "dbus-launch"
complete -c "dbus-launch" -f -a '(_carapace_completer "dbus-launch")'
complete -e "dbus-monitor"
complete -c "dbus-monitor" -f -a '(_carapace_completer "dbus-monitor")'
complete -e "dbus-send"
complete -c "dbus-send" -f -a '(_carapace_completer "dbus-send")'
complete -e "dc"
complete -c "dc" -f -a '(_carapace_completer "dc")'
complete -e "dconf"
complete -c "dconf" -f -a '(_carapace_completer "dconf")'
complete -e "dcop"
complete -c "dcop" -f -a '(_carapace_completer "dcop")'
complete -e "dcopclient"
complete -c "dcopclient" -f -a '(_carapace_completer "dcopclient")'
complete -e "dcopfind"
complete -c "dcopfind" -f -a '(_carapace_completer "dcopfind")'
complete -e "dcopobject"
complete -c "dcopobject" -f -a '(_carapace_completer "dcopobject")'
complete -e "dcopref"
complete -c "dcopref" -f -a '(_carapace_completer "dcopref")'
complete -e "dcopstart"
complete -c "dcopstart" -f -a '(_carapace_completer "dcopstart")'
complete -e "dd"
complete -c "dd" -f -a '(_carapace_completer "dd")'
complete -e "deadcode"
complete -c "deadcode" -f -a '(_carapace_completer "deadcode")'
complete -e "debian-distro-info"
complete -c "debian-distro-info" -f -a '(_carapace_completer "debian-distro-info")'
complete -e "delpart"
complete -c "delpart" -f -a '(_carapace_completer "delpart")'
complete -e "delta"
complete -c "delta" -f -a '(_carapace_completer "delta")'
complete -e "deno"
complete -c "deno" -f -a '(_carapace_completer "deno")'
complete -e "designate"
complete -c "designate" -f -a '(_carapace_completer "designate")'
complete -e "devbox"
complete -c "devbox" -f -a '(_carapace_completer "devbox")'
complete -e "devcontainer"
complete -c "devcontainer" -f -a '(_carapace_completer "devcontainer")'
complete -e "devlink"
complete -c "devlink" -f -a '(_carapace_completer "devlink")'
complete -e "devpod"
complete -c "devpod" -f -a '(_carapace_completer "devpod")'
complete -e "devtodo"
complete -c "devtodo" -f -a '(_carapace_completer "devtodo")'
complete -e "df"
complete -c "df" -f -a '(_carapace_completer "df")'
complete -e "dfc"
complete -c "dfc" -f -a '(_carapace_completer "dfc")'
complete -e "dget"
complete -c "dget" -f -a '(_carapace_completer "dget")'
complete -e "dhclient"
complete -c "dhclient" -f -a '(_carapace_completer "dhclient")'
complete -e "dhclient3"
complete -c "dhclient3" -f -a '(_carapace_completer "dhclient3")'
complete -e "dhcpcd"
complete -c "dhcpcd" -f -a '(_carapace_completer "dhcpcd")'
complete -e "diana"
complete -c "diana" -f -a '(_carapace_completer "diana")'
complete -e "dict"
complete -c "dict" -f -a '(_carapace_completer "dict")'
complete -e "diff"
complete -c "diff" -f -a '(_carapace_completer "diff")'
complete -e "diff3"
complete -c "diff3" -f -a '(_carapace_completer "diff3")'
complete -e "diffstat"
complete -c "diffstat" -f -a '(_carapace_completer "diffstat")'
complete -e "dig"
complete -c "dig" -f -a '(_carapace_completer "dig")'
complete -e "dillo"
complete -c "dillo" -f -a '(_carapace_completer "dillo")'
complete -e "dir"
complete -c "dir" -f -a '(_carapace_completer "dir")'
complete -e "dircmp"
complete -c "dircmp" -f -a '(_carapace_completer "dircmp")'
complete -e "dircolors"
complete -c "dircolors" -f -a '(_carapace_completer "dircolors")'
complete -e "direnv"
complete -c "direnv" -f -a '(_carapace_completer "direnv")'
complete -e "dirname"
complete -c "dirname" -f -a '(_carapace_completer "dirname")'
complete -e "diskutil"
complete -c "diskutil" -f -a '(_carapace_completer "diskutil")'
complete -e "display"
complete -c "display" -f -a '(_carapace_completer "display")'
complete -e "dist"
complete -c "dist" -f -a '(_carapace_completer "dist")'
complete -e "distro-info"
complete -c "distro-info" -f -a '(_carapace_completer "distro-info")'
complete -e "dive"
complete -c "dive" -f -a '(_carapace_completer "dive")'
complete -e "django-admin"
complete -c "django-admin" -f -a '(_carapace_completer "django-admin")'
complete -e "django-admin.py"
complete -c "django-admin.py" -f -a '(_carapace_completer "django-admin.py")'
complete -e "dlv"
complete -c "dlv" -f -a '(_carapace_completer "dlv")'
complete -e "dm-tool"
complete -c "dm-tool" -f -a '(_carapace_completer "dm-tool")'
complete -e "dmake"
complete -c "dmake" -f -a '(_carapace_completer "dmake")'
complete -e "dmenu"
complete -c "dmenu" -f -a '(_carapace_completer "dmenu")'
complete -e "dmesg"
complete -c "dmesg" -f -a '(_carapace_completer "dmesg")'
complete -e "dmidecode"
complete -c "dmidecode" -f -a '(_carapace_completer "dmidecode")'
complete -e "dms"
complete -c "dms" -f -a '(_carapace_completer "dms")'
complete -e "dnf"
complete -c "dnf" -f -a '(_carapace_completer "dnf")'
complete -e "dngconverter"
complete -c "dngconverter" -f -a '(_carapace_completer "dngconverter")'
complete -e "dnsmasq"
complete -c "dnsmasq" -f -a '(_carapace_completer "dnsmasq")'
complete -e "do-release-upgrade"
complete -c "do-release-upgrade" -f -a '(_carapace_completer "do-release-upgrade")'
complete -e "doas"
complete -c "doas" -f -a '(_carapace_completer "doas")'
complete -e "docker"
complete -c "docker" -f -a '(_carapace_completer "docker")'
complete -e "docker-buildx"
complete -c "docker-buildx" -f -a '(_carapace_completer "docker-buildx")'
complete -e "docker-compose"
complete -c "docker-compose" -f -a '(_carapace_completer "docker-compose")'
complete -e "docker-scan"
complete -c "docker-scan" -f -a '(_carapace_completer "docker-scan")'
complete -e "dockerd"
complete -c "dockerd" -f -a '(_carapace_completer "dockerd")'
complete -e "docpad"
complete -c "docpad" -f -a '(_carapace_completer "docpad")'
complete -e "doctl"
complete -c "doctl" -f -a '(_carapace_completer "doctl")'
complete -e "dog"
complete -c "dog" -f -a '(_carapace_completer "dog")'
complete -e "doing"
complete -c "doing" -f -a '(_carapace_completer "doing")'
complete -e "domainname"
complete -c "domainname" -f -a '(_carapace_completer "domainname")'
complete -e "dos2unix"
complete -c "dos2unix" -f -a '(_carapace_completer "dos2unix")'
complete -e "downgrade"
complete -c "downgrade" -f -a '(_carapace_completer "downgrade")'
complete -e "dpkg"
complete -c "dpkg" -f -a '(_carapace_completer "dpkg")'
complete -e "dpll"
complete -c "dpll" -f -a '(_carapace_completer "dpll")'
complete -e "drill"
complete -c "drill" -f -a '(_carapace_completer "drill")'
complete -e "dropbox"
complete -c "dropbox" -f -a '(_carapace_completer "dropbox")'
complete -e "dropdb"
complete -c "dropdb" -f -a '(_carapace_completer "dropdb")'
complete -e "dropuser"
complete -c "dropuser" -f -a '(_carapace_completer "dropuser")'
complete -e "dsh"
complete -c "dsh" -f -a '(_carapace_completer "dsh")'
complete -e "dtruss"
complete -c "dtruss" -f -a '(_carapace_completer "dtruss")'
complete -e "du"
complete -c "du" -f -a '(_carapace_completer "du")'
complete -e "dunst"
complete -c "dunst" -f -a '(_carapace_completer "dunst")'
complete -e "dunstctl"
complete -c "dunstctl" -f -a '(_carapace_completer "dunstctl")'
complete -e "dunstify"
complete -c "dunstify" -f -a '(_carapace_completer "dunstify")'
complete -e "dust"
complete -c "dust" -f -a '(_carapace_completer "dust")'
complete -e "dvibook"
complete -c "dvibook" -f -a '(_carapace_completer "dvibook")'
complete -e "dviconcat"
complete -c "dviconcat" -f -a '(_carapace_completer "dviconcat")'
complete -e "dvicopy"
complete -c "dvicopy" -f -a '(_carapace_completer "dvicopy")'
complete -e "dvidvi"
complete -c "dvidvi" -f -a '(_carapace_completer "dvidvi")'
complete -e "dvipdf"
complete -c "dvipdf" -f -a '(_carapace_completer "dvipdf")'
complete -e "dvips"
complete -c "dvips" -f -a '(_carapace_completer "dvips")'
complete -e "dviselect"
complete -c "dviselect" -f -a '(_carapace_completer "dviselect")'
complete -e "dvitodvi"
complete -c "dvitodvi" -f -a '(_carapace_completer "dvitodvi")'
complete -e "dvitype"
complete -c "dvitype" -f -a '(_carapace_completer "dvitype")'
complete -e "dwb"
complete -c "dwb" -f -a '(_carapace_completer "dwb")'
complete -e "e2label"
complete -c "e2label" -f -a '(_carapace_completer "e2label")'
complete -e "eatmydata"
complete -c "eatmydata" -f -a '(_carapace_completer "eatmydata")'
complete -e "ebook-convert"
complete -c "ebook-convert" -f -a '(_carapace_completer "ebook-convert")'
complete -e "ebook-device"
complete -c "ebook-device" -f -a '(_carapace_completer "ebook-device")'
complete -e "ebook-edit"
complete -c "ebook-edit" -f -a '(_carapace_completer "ebook-edit")'
complete -e "ebook-meta"
complete -c "ebook-meta" -f -a '(_carapace_completer "ebook-meta")'
complete -e "ebook-polish"
complete -c "ebook-polish" -f -a '(_carapace_completer "ebook-polish")'
complete -e "ebook-viewer"
complete -c "ebook-viewer" -f -a '(_carapace_completer "ebook-viewer")'
complete -e "ebtables"
complete -c "ebtables" -f -a '(_carapace_completer "ebtables")'
complete -e "ecasound"
complete -c "ecasound" -f -a '(_carapace_completer "ecasound")'
complete -e "ecdsautil"
complete -c "ecdsautil" -f -a '(_carapace_completer "ecdsautil")'
complete -e "ed"
complete -c "ed" -f -a '(_carapace_completer "ed")'
complete -e "egrep"
complete -c "egrep" -f -a '(_carapace_completer "egrep")'
complete -e "eject"
complete -c "eject" -f -a '(_carapace_completer "eject")'
complete -e "electron"
complete -c "electron" -f -a '(_carapace_completer "electron")'
complete -e "elfdump"
complete -c "elfdump" -f -a '(_carapace_completer "elfdump")'
complete -e "elinks"
complete -c "elinks" -f -a '(_carapace_completer "elinks")'
complete -e "elvish"
complete -c "elvish" -f -a '(_carapace_completer "elvish")'
complete -e "emacs"
complete -c "emacs" -f -a '(_carapace_completer "emacs")'
complete -e "emacsclient"
complete -c "emacsclient" -f -a '(_carapace_completer "emacsclient")'
complete -e "emulator"
complete -c "emulator" -f -a '(_carapace_completer "emulator")'
complete -e "enosys"
complete -c "enosys" -f -a '(_carapace_completer "enosys")'
complete -e "enscript"
complete -c "enscript" -f -a '(_carapace_completer "enscript")'
complete -e "entr"
complete -c "entr" -f -a '(_carapace_completer "entr")'
complete -e "env"
complete -c "env" -f -a '(_carapace_completer "env")'
complete -e "envdir"
complete -c "envdir" -f -a '(_carapace_completer "envdir")'
complete -e "envsubst"
complete -c "envsubst" -f -a '(_carapace_completer "envsubst")'
complete -e "eog"
complete -c "eog" -f -a '(_carapace_completer "eog")'
complete -e "epdfview"
complete -c "epdfview" -f -a '(_carapace_completer "epdfview")'
complete -e "epsffit"
complete -c "epsffit" -f -a '(_carapace_completer "epsffit")'
complete -e "erb"
complete -c "erb" -f -a '(_carapace_completer "erb")'
complete -e "espeak"
complete -c "espeak" -f -a '(_carapace_completer "espeak")'
complete -e "etags"
complete -c "etags" -f -a '(_carapace_completer "etags")'
complete -e "ethtool"
complete -c "ethtool" -f -a '(_carapace_completer "ethtool")'
complete -e "eu-nm"
complete -c "eu-nm" -f -a '(_carapace_completer "eu-nm")'
complete -e "eu-objdump"
complete -c "eu-objdump" -f -a '(_carapace_completer "eu-objdump")'
complete -e "eu-readelf"
complete -c "eu-readelf" -f -a '(_carapace_completer "eu-readelf")'
complete -e "eu-strings"
complete -c "eu-strings" -f -a '(_carapace_completer "eu-strings")'
complete -e "eview"
complete -c "eview" -f -a '(_carapace_completer "eview")'
complete -e "evim"
complete -c "evim" -f -a '(_carapace_completer "evim")'
complete -e "evince"
complete -c "evince" -f -a '(_carapace_completer "evince")'
complete -e "ex"
complete -c "ex" -f -a '(_carapace_completer "ex")'
complete -e "exa"
complete -c "exa" -f -a '(_carapace_completer "exa")'
complete -e "exch"
complete -c "exch" -f -a '(_carapace_completer "exch")'
complete -e "exercism"
complete -c "exercism" -f -a '(_carapace_completer "exercism")'
complete -e "expand"
complete -c "expand" -f -a '(_carapace_completer "expand")'
complete -e "exportfs"
complete -c "exportfs" -f -a '(_carapace_completer "exportfs")'
complete -e "expr"
complete -c "expr" -f -a '(_carapace_completer "expr")'
complete -e "express"
complete -c "express" -f -a '(_carapace_completer "express")'
complete -e "extcheck"
complete -c "extcheck" -f -a '(_carapace_completer "extcheck")'
complete -e "extractres"
complete -c "extractres" -f -a '(_carapace_completer "extractres")'
complete -e "eza"
complete -c "eza" -f -a '(_carapace_completer "eza")'
complete -e "faas-cli"
complete -c "faas-cli" -f -a '(_carapace_completer "faas-cli")'
complete -e "fab"
complete -c "fab" -f -a '(_carapace_completer "fab")'
complete -e "factor"
complete -c "factor" -f -a '(_carapace_completer "factor")'
complete -e "fadvise"
complete -c "fadvise" -f -a '(_carapace_completer "fadvise")'
complete -e "fail2ban-client"
complete -c "fail2ban-client" -f -a '(_carapace_completer "fail2ban-client")'
complete -e "fail2ban-regex"
complete -c "fail2ban-regex" -f -a '(_carapace_completer "fail2ban-regex")'
complete -e "fakechroot"
complete -c "fakechroot" -f -a '(_carapace_completer "fakechroot")'
complete -e "fakeroot"
complete -c "fakeroot" -f -a '(_carapace_completer "fakeroot")'
complete -e "fallocate"
complete -c "fallocate" -f -a '(_carapace_completer "fallocate")'
complete -e "fastboot"
complete -c "fastboot" -f -a '(_carapace_completer "fastboot")'
complete -e "fastfetch"
complete -c "fastfetch" -f -a '(_carapace_completer "fastfetch")'
complete -e "fc-cache"
complete -c "fc-cache" -f -a '(_carapace_completer "fc-cache")'
complete -e "fc-cat"
complete -c "fc-cat" -f -a '(_carapace_completer "fc-cat")'
complete -e "fc-conflist"
complete -c "fc-conflist" -f -a '(_carapace_completer "fc-conflist")'
complete -e "fc-list"
complete -c "fc-list" -f -a '(_carapace_completer "fc-list")'
complete -e "fc-match"
complete -c "fc-match" -f -a '(_carapace_completer "fc-match")'
complete -e "fd"
complete -c "fd" -f -a '(_carapace_completer "fd")'
complete -e "fdisk"
complete -c "fdisk" -f -a '(_carapace_completer "fdisk")'
complete -e "feh"
complete -c "feh" -f -a '(_carapace_completer "feh")'
complete -e "fetch-ebook-metadata"
complete -c "fetch-ebook-metadata" -f -a '(_carapace_completer "fetch-ebook-metadata")'
complete -e "fetchmail"
complete -c "fetchmail" -f -a '(_carapace_completer "fetchmail")'
complete -e "ffind"
complete -c "ffind" -f -a '(_carapace_completer "ffind")'
complete -e "ffmpeg"
complete -c "ffmpeg" -f -a '(_carapace_completer "ffmpeg")'
complete -e "ffplay"
complete -c "ffplay" -f -a '(_carapace_completer "ffplay")'
complete -e "ffprobe"
complete -c "ffprobe" -f -a '(_carapace_completer "ffprobe")'
complete -e "fgrep"
complete -c "fgrep" -f -a '(_carapace_completer "fgrep")'
complete -e "figlet"
complete -c "figlet" -f -a '(_carapace_completer "figlet")'
complete -e "file"
complete -c "file" -f -a '(_carapace_completer "file")'
complete -e "filecap"
complete -c "filecap" -f -a '(_carapace_completer "filecap")'
complete -e "filterdiff"
complete -c "filterdiff" -f -a '(_carapace_completer "filterdiff")'
complete -e "fincore"
complete -c "fincore" -f -a '(_carapace_completer "fincore")'
complete -e "find"
complete -c "find" -f -a '(_carapace_completer "find")'
complete -e "findaffix"
complete -c "findaffix" -f -a '(_carapace_completer "findaffix")'
complete -e "findfs"
complete -c "findfs" -f -a '(_carapace_completer "findfs")'
complete -e "findmnt"
complete -c "findmnt" -f -a '(_carapace_completer "findmnt")'
complete -e "finger"
complete -c "finger" -f -a '(_carapace_completer "finger")'
complete -e "firefox"
complete -c "firefox" -f -a '(_carapace_completer "firefox")'
complete -e "fish"
complete -c "fish" -f -a '(_carapace_completer "fish")'
complete -e "fixdlsrps"
complete -c "fixdlsrps" -f -a '(_carapace_completer "fixdlsrps")'
complete -e "fixfiles"
complete -c "fixfiles" -f -a '(_carapace_completer "fixfiles")'
complete -e "fixfmps"
complete -c "fixfmps" -f -a '(_carapace_completer "fixfmps")'
complete -e "fixmacps"
complete -c "fixmacps" -f -a '(_carapace_completer "fixmacps")'
complete -e "fixpsditps"
complete -c "fixpsditps" -f -a '(_carapace_completer "fixpsditps")'
complete -e "fixpspps"
complete -c "fixpspps" -f -a '(_carapace_completer "fixpspps")'
complete -e "fixscribeps"
complete -c "fixscribeps" -f -a '(_carapace_completer "fixscribeps")'
complete -e "fixtpps"
complete -c "fixtpps" -f -a '(_carapace_completer "fixtpps")'
complete -e "fixwfwps"
complete -c "fixwfwps" -f -a '(_carapace_completer "fixwfwps")'
complete -e "fixwpps"
complete -c "fixwpps" -f -a '(_carapace_completer "fixwpps")'
complete -e "fixwwps"
complete -c "fixwwps" -f -a '(_carapace_completer "fixwwps")'
complete -e "flac"
complete -c "flac" -f -a '(_carapace_completer "flac")'
complete -e "flameshot"
complete -c "flameshot" -f -a '(_carapace_completer "flameshot")'
complete -e "flatpak"
complete -c "flatpak" -f -a '(_carapace_completer "flatpak")'
complete -e "flex"
complete -c "flex" -f -a '(_carapace_completer "flex")'
complete -e "flex++"
complete -c "flex++" -f -a '(_carapace_completer "flex++")'
complete -e "flipdiff"
complete -c "flipdiff" -f -a '(_carapace_completer "flipdiff")'
complete -e "flist"
complete -c "flist" -f -a '(_carapace_completer "flist")'
complete -e "flists"
complete -c "flists" -f -a '(_carapace_completer "flists")'
complete -e "flock"
complete -c "flock" -f -a '(_carapace_completer "flock")'
complete -e "flua"
complete -c "flua" -f -a '(_carapace_completer "flua")'
complete -e "flutter"
complete -c "flutter" -f -a '(_carapace_completer "flutter")'
complete -e "flyctl"
complete -c "flyctl" -f -a '(_carapace_completer "flyctl")'
complete -e "fmt"
complete -c "fmt" -f -a '(_carapace_completer "fmt")'
complete -e "fmttest"
complete -c "fmttest" -f -a '(_carapace_completer "fmttest")'
complete -e "fned"
complete -c "fned" -f -a '(_carapace_completer "fned")'
complete -e "fnext"
complete -c "fnext" -f -a '(_carapace_completer "fnext")'
complete -e "fnm"
complete -c "fnm" -f -a '(_carapace_completer "fnm")'
complete -e "fold"
complete -c "fold" -f -a '(_carapace_completer "fold")'
complete -e "folder"
complete -c "folder" -f -a '(_carapace_completer "folder")'
complete -e "folders"
complete -c "folders" -f -a '(_carapace_completer "folders")'
complete -e "foot"
complete -c "foot" -f -a '(_carapace_completer "foot")'
complete -e "fortune"
complete -c "fortune" -f -a '(_carapace_completer "fortune")'
complete -e "forw"
complete -c "forw" -f -a '(_carapace_completer "forw")'
complete -e "fprev"
complete -c "fprev" -f -a '(_carapace_completer "fprev")'
complete -e "free"
complete -c "free" -f -a '(_carapace_completer "free")'
complete -e "freebsd-make"
complete -c "freebsd-make" -f -a '(_carapace_completer "freebsd-make")'
complete -e "freeze"
complete -c "freeze" -f -a '(_carapace_completer "freeze")'
complete -e "freezer"
complete -c "freezer" -f -a '(_carapace_completer "freezer")'
complete -e "fsck"
complete -c "fsck" -f -a '(_carapace_completer "fsck")'
complete -e "fsck.cramfs"
complete -c "fsck.cramfs" -f -a '(_carapace_completer "fsck.cramfs")'
complete -e "fsck.minix"
complete -c "fsck.minix" -f -a '(_carapace_completer "fsck.minix")'
complete -e "fsfreeze"
complete -c "fsfreeze" -f -a '(_carapace_completer "fsfreeze")'
complete -e "fsh"
complete -c "fsh" -f -a '(_carapace_completer "fsh")'
complete -e "fstrim"
complete -c "fstrim" -f -a '(_carapace_completer "fstrim")'
complete -e "ftp"
complete -c "ftp" -f -a '(_carapace_completer "ftp")'
complete -e "ftpd"
complete -c "ftpd" -f -a '(_carapace_completer "ftpd")'
complete -e "fury"
complete -c "fury" -f -a '(_carapace_completer "fury")'
complete -e "fuser"
complete -c "fuser" -f -a '(_carapace_completer "fuser")'
complete -e "fusermount"
complete -c "fusermount" -f -a '(_carapace_completer "fusermount")'
complete -e "fusermount3"
complete -c "fusermount3" -f -a '(_carapace_completer "fusermount3")'
complete -e "fwhois"
complete -c "fwhois" -f -a '(_carapace_completer "fwhois")'
complete -e "fwupdmgr"
complete -c "fwupdmgr" -f -a '(_carapace_completer "fwupdmgr")'
complete -e "fzf"
complete -c "fzf" -f -a '(_carapace_completer "fzf")'
complete -e "g++"
complete -c "g++" -f -a '(_carapace_completer "g++")'
complete -e "galeon"
complete -c "galeon" -f -a '(_carapace_completer "galeon")'
complete -e "gapplication"
complete -c "gapplication" -f -a '(_carapace_completer "gapplication")'
complete -e "gas"
complete -c "gas" -f -a '(_carapace_completer "gas")'
complete -e "gatsby"
complete -c "gatsby" -f -a '(_carapace_completer "gatsby")'
complete -e "gawk"
complete -c "gawk" -f -a '(_carapace_completer "gawk")'
complete -e "gb2sum"
complete -c "gb2sum" -f -a '(_carapace_completer "gb2sum")'
complete -e "gbase32"
complete -c "gbase32" -f -a '(_carapace_completer "gbase32")'
complete -e "gbase64"
complete -c "gbase64" -f -a '(_carapace_completer "gbase64")'
complete -e "gbasename"
complete -c "gbasename" -f -a '(_carapace_completer "gbasename")'
complete -e "gcat"
complete -c "gcat" -f -a '(_carapace_completer "gcat")'
complete -e "gcc"
complete -c "gcc" -f -a '(_carapace_completer "gcc")'
complete -e "gccgo"
complete -c "gccgo" -f -a '(_carapace_completer "gccgo")'
complete -e "gchmod"
complete -c "gchmod" -f -a '(_carapace_completer "gchmod")'
complete -e "gchroot"
complete -c "gchroot" -f -a '(_carapace_completer "gchroot")'
complete -e "gcksum"
complete -c "gcksum" -f -a '(_carapace_completer "gcksum")'
complete -e "gcloud"
complete -c "gcloud" -f -a '(_carapace_completer "gcloud")'
complete -e "gcmp"
complete -c "gcmp" -f -a '(_carapace_completer "gcmp")'
complete -e "gcomm"
complete -c "gcomm" -f -a '(_carapace_completer "gcomm")'
complete -e "gcore"
complete -c "gcore" -f -a '(_carapace_completer "gcore")'
complete -e "gcp"
complete -c "gcp" -f -a '(_carapace_completer "gcp")'
complete -e "gcut"
complete -c "gcut" -f -a '(_carapace_completer "gcut")'
complete -e "gdate"
complete -c "gdate" -f -a '(_carapace_completer "gdate")'
complete -e "gdb"
complete -c "gdb" -f -a '(_carapace_completer "gdb")'
complete -e "gdbus"
complete -c "gdbus" -f -a '(_carapace_completer "gdbus")'
complete -e "gdd"
complete -c "gdd" -f -a '(_carapace_completer "gdd")'
complete -e "gdf"
complete -c "gdf" -f -a '(_carapace_completer "gdf")'
complete -e "gdiff"
complete -c "gdiff" -f -a '(_carapace_completer "gdiff")'
complete -e "gdown"
complete -c "gdown" -f -a '(_carapace_completer "gdown")'
complete -e "gdu"
complete -c "gdu" -f -a '(_carapace_completer "gdu")'
complete -e "geany"
complete -c "geany" -f -a '(_carapace_completer "geany")'
complete -e "gecho"
complete -c "gecho" -f -a '(_carapace_completer "gecho")'
complete -e "gegrep"
complete -c "gegrep" -f -a '(_carapace_completer "gegrep")'
complete -e "gem"
complete -c "gem" -f -a '(_carapace_completer "gem")'
complete -e "genisoimage"
complete -c "genisoimage" -f -a '(_carapace_completer "genisoimage")'
complete -e "genv"
complete -c "genv" -f -a '(_carapace_completer "genv")'
complete -e "get-env"
complete -c "get-env" -f -a '(_carapace_completer "get-env")'
complete -e "getafm"
complete -c "getafm" -f -a '(_carapace_completer "getafm")'
complete -e "getconf"
complete -c "getconf" -f -a '(_carapace_completer "getconf")'
complete -e "getent"
complete -c "getent" -f -a '(_carapace_completer "getent")'
complete -e "getfacl"
complete -c "getfacl" -f -a '(_carapace_completer "getfacl")'
complete -e "getfacl.exe"
complete -c "getfacl.exe" -f -a '(_carapace_completer "getfacl.exe")'
complete -e "getfattr"
complete -c "getfattr" -f -a '(_carapace_completer "getfattr")'
complete -e "getino"
complete -c "getino" -f -a '(_carapace_completer "getino")'
complete -e "getmail"
complete -c "getmail" -f -a '(_carapace_completer "getmail")'
complete -e "getopt"
complete -c "getopt" -f -a '(_carapace_completer "getopt")'
complete -e "getpidprevcon"
complete -c "getpidprevcon" -f -a '(_carapace_completer "getpidprevcon")'
complete -e "getsebool"
complete -c "getsebool" -f -a '(_carapace_completer "getsebool")'
complete -e "gex"
complete -c "gex" -f -a '(_carapace_completer "gex")'
complete -e "gexpand"
complete -c "gexpand" -f -a '(_carapace_completer "gexpand")'
complete -e "gfgrep"
complete -c "gfgrep" -f -a '(_carapace_completer "gfgrep")'
complete -e "gfind"
complete -c "gfind" -f -a '(_carapace_completer "gfind")'
complete -e "gfmt"
complete -c "gfmt" -f -a '(_carapace_completer "gfmt")'
complete -e "gfold"
complete -c "gfold" -f -a '(_carapace_completer "gfold")'
complete -e "gftp"
complete -c "gftp" -f -a '(_carapace_completer "gftp")'
complete -e "ggetopt"
complete -c "ggetopt" -f -a '(_carapace_completer "ggetopt")'
complete -e "ggrep"
complete -c "ggrep" -f -a '(_carapace_completer "ggrep")'
complete -e "ggv"
complete -c "ggv" -f -a '(_carapace_completer "ggv")'
complete -e "gh"
complete -c "gh" -f -a '(_carapace_completer "gh")'
complete -e "gh-copilot"
complete -c "gh-copilot" -f -a '(_carapace_completer "gh-copilot")'
complete -e "gh-dash"
complete -c "gh-dash" -f -a '(_carapace_completer "gh-dash")'
complete -e "gh-stack"
complete -c "gh-stack" -f -a '(_carapace_completer "gh-stack")'
complete -e "ghalint"
complete -c "ghalint" -f -a '(_carapace_completer "ghalint")'
complete -e "ghc"
complete -c "ghc" -f -a '(_carapace_completer "ghc")'
complete -e "ghc-pkg"
complete -c "ghc-pkg" -f -a '(_carapace_completer "ghc-pkg")'
complete -e "ghci"
complete -c "ghci" -f -a '(_carapace_completer "ghci")'
complete -e "ghead"
complete -c "ghead" -f -a '(_carapace_completer "ghead")'
complete -e "ghostscript"
complete -c "ghostscript" -f -a '(_carapace_completer "ghostscript")'
complete -e "ghostty"
complete -c "ghostty" -f -a '(_carapace_completer "ghostty")'
complete -e "ghostview"
complete -c "ghostview" -f -a '(_carapace_completer "ghostview")'
complete -e "gid"
complete -c "gid" -f -a '(_carapace_completer "gid")'
complete -e "gimp"
complete -c "gimp" -f -a '(_carapace_completer "gimp")'
complete -e "gimp-3.2"
complete -c "gimp-3.2" -f -a '(_carapace_completer "gimp-3.2")'
complete -e "ginstall"
complete -c "ginstall" -f -a '(_carapace_completer "ginstall")'
complete -e "gio"
complete -c "gio" -f -a '(_carapace_completer "gio")'
complete -e "gist"
complete -c "gist" -f -a '(_carapace_completer "gist")'
complete -e "git"
complete -c "git" -f -a '(_carapace_completer "git")'
complete -e "git-abort"
complete -c "git-abort" -f -a '(_carapace_completer "git-abort")'
complete -e "git-alias"
complete -c "git-alias" -f -a '(_carapace_completer "git-alias")'
complete -e "git-archive-file"
complete -c "git-archive-file" -f -a '(_carapace_completer "git-archive-file")'
complete -e "git-authors"
complete -c "git-authors" -f -a '(_carapace_completer "git-authors")'
complete -e "git-browse"
complete -c "git-browse" -f -a '(_carapace_completer "git-browse")'
complete -e "git-browse-ci"
complete -c "git-browse-ci" -f -a '(_carapace_completer "git-browse-ci")'
complete -e "git-clang-format"
complete -c "git-clang-format" -f -a '(_carapace_completer "git-clang-format")'
complete -e "git-clear"
complete -c "git-clear" -f -a '(_carapace_completer "git-clear")'
complete -e "git-clear-soft"
complete -c "git-clear-soft" -f -a '(_carapace_completer "git-clear-soft")'
complete -e "git-coauthor"
complete -c "git-coauthor" -f -a '(_carapace_completer "git-coauthor")'
complete -e "git-cvsserver"
complete -c "git-cvsserver" -f -a '(_carapace_completer "git-cvsserver")'
complete -e "git-extras"
complete -c "git-extras" -f -a '(_carapace_completer "git-extras")'
complete -e "git-flow"
complete -c "git-flow" -f -a '(_carapace_completer "git-flow")'
complete -e "git-info"
complete -c "git-info" -f -a '(_carapace_completer "git-info")'
complete -e "git-pulls"
complete -c "git-pulls" -f -a '(_carapace_completer "git-pulls")'
complete -e "git-receive-pack"
complete -c "git-receive-pack" -f -a '(_carapace_completer "git-receive-pack")'
complete -e "git-revise"
complete -c "git-revise" -f -a '(_carapace_completer "git-revise")'
complete -e "git-shell"
complete -c "git-shell" -f -a '(_carapace_completer "git-shell")'
complete -e "git-standup"
complete -c "git-standup" -f -a '(_carapace_completer "git-standup")'
complete -e "git-unlock"
complete -c "git-unlock" -f -a '(_carapace_completer "git-unlock")'
complete -e "git-upload-archive"
complete -c "git-upload-archive" -f -a '(_carapace_completer "git-upload-archive")'
complete -e "git-upload-pack"
complete -c "git-upload-pack" -f -a '(_carapace_completer "git-upload-pack")'
complete -e "git-utimes"
complete -c "git-utimes" -f -a '(_carapace_completer "git-utimes")'
complete -e "git-wtf"
complete -c "git-wtf" -f -a '(_carapace_completer "git-wtf")'
complete -e "gitk"
complete -c "gitk" -f -a '(_carapace_completer "gitk")'
complete -e "gitleaks"
complete -c "gitleaks" -f -a '(_carapace_completer "gitleaks")'
complete -e "gitlint"
complete -c "gitlint" -f -a '(_carapace_completer "gitlint")'
complete -e "gitsign"
complete -c "gitsign" -f -a '(_carapace_completer "gitsign")'
complete -e "gitui"
complete -c "gitui" -f -a '(_carapace_completer "gitui")'
complete -e "gjoin"
complete -c "gjoin" -f -a '(_carapace_completer "gjoin")'
complete -e "glab"
complete -c "glab" -f -a '(_carapace_completer "glab")'
complete -e "glance"
complete -c "glance" -f -a '(_carapace_completer "glance")'
complete -e "glances"
complete -c "glances" -f -a '(_carapace_completer "glances")'
complete -e "gln"
complete -c "gln" -f -a '(_carapace_completer "gln")'
complete -e "global"
complete -c "global" -f -a '(_carapace_completer "global")'
complete -e "glocate"
complete -c "glocate" -f -a '(_carapace_completer "glocate")'
complete -e "glow"
complete -c "glow" -f -a '(_carapace_completer "glow")'
complete -e "gls"
complete -c "gls" -f -a '(_carapace_completer "gls")'
complete -e "gm"
complete -c "gm" -f -a '(_carapace_completer "gm")'
complete -e "gmake"
complete -c "gmake" -f -a '(_carapace_completer "gmake")'
complete -e "gmd5sum"
complete -c "gmd5sum" -f -a '(_carapace_completer "gmd5sum")'
complete -e "gmkdir"
complete -c "gmkdir" -f -a '(_carapace_completer "gmkdir")'
complete -e "gmkfifo"
complete -c "gmkfifo" -f -a '(_carapace_completer "gmkfifo")'
complete -e "gmknod"
complete -c "gmknod" -f -a '(_carapace_completer "gmknod")'
complete -e "gmktemp"
complete -c "gmktemp" -f -a '(_carapace_completer "gmktemp")'
complete -e "gmplayer"
complete -c "gmplayer" -f -a '(_carapace_completer "gmplayer")'
complete -e "gmv"
complete -c "gmv" -f -a '(_carapace_completer "gmv")'
complete -e "gnl"
complete -c "gnl" -f -a '(_carapace_completer "gnl")'
complete -e "gnocchi"
complete -c "gnocchi" -f -a '(_carapace_completer "gnocchi")'
complete -e "gnome-gv"
complete -c "gnome-gv" -f -a '(_carapace_completer "gnome-gv")'
complete -e "gnome-keyring"
complete -c "gnome-keyring" -f -a '(_carapace_completer "gnome-keyring")'
complete -e "gnome-keyring-daemon"
complete -c "gnome-keyring-daemon" -f -a '(_carapace_completer "gnome-keyring-daemon")'
complete -e "gnome-maps"
complete -c "gnome-maps" -f -a '(_carapace_completer "gnome-maps")'
complete -e "gnome-terminal"
complete -c "gnome-terminal" -f -a '(_carapace_completer "gnome-terminal")'
complete -e "gnumake"
complete -c "gnumake" -f -a '(_carapace_completer "gnumake")'
complete -e "gnumfmt"
complete -c "gnumfmt" -f -a '(_carapace_completer "gnumfmt")'
complete -e "gnupod_INIT"
complete -c "gnupod_INIT" -f -a '(_carapace_completer "gnupod_INIT")'
complete -e "gnupod_addsong"
complete -c "gnupod_addsong" -f -a '(_carapace_completer "gnupod_addsong")'
complete -e "gnupod_check"
complete -c "gnupod_check" -f -a '(_carapace_completer "gnupod_check")'
complete -e "gnupod_search"
complete -c "gnupod_search" -f -a '(_carapace_completer "gnupod_search")'
complete -e "gnutls-cli"
complete -c "gnutls-cli" -f -a '(_carapace_completer "gnutls-cli")'
complete -e "gnutls-cli-debug"
complete -c "gnutls-cli-debug" -f -a '(_carapace_completer "gnutls-cli-debug")'
complete -e "gnutls-serv"
complete -c "gnutls-serv" -f -a '(_carapace_completer "gnutls-serv")'
complete -e "go"
complete -c "go" -f -a '(_carapace_completer "go")'
complete -e "go-carpet"
complete -c "go-carpet" -f -a '(_carapace_completer "go-carpet")'
complete -e "go-tool-asm"
complete -c "go-tool-asm" -f -a '(_carapace_completer "go-tool-asm")'
complete -e "go-tool-buildid"
complete -c "go-tool-buildid" -f -a '(_carapace_completer "go-tool-buildid")'
complete -e "go-tool-cgo"
complete -c "go-tool-cgo" -f -a '(_carapace_completer "go-tool-cgo")'
complete -e "go-tool-compile"
complete -c "go-tool-compile" -f -a '(_carapace_completer "go-tool-compile")'
complete -e "go-tool-covdata"
complete -c "go-tool-covdata" -f -a '(_carapace_completer "go-tool-covdata")'
complete -e "go-tool-cover"
complete -c "go-tool-cover" -f -a '(_carapace_completer "go-tool-cover")'
complete -e "go-tool-dist"
complete -c "go-tool-dist" -f -a '(_carapace_completer "go-tool-dist")'
complete -e "go-tool-doc"
complete -c "go-tool-doc" -f -a '(_carapace_completer "go-tool-doc")'
complete -e "go-tool-fix"
complete -c "go-tool-fix" -f -a '(_carapace_completer "go-tool-fix")'
complete -e "go-tool-link"
complete -c "go-tool-link" -f -a '(_carapace_completer "go-tool-link")'
complete -e "go-tool-mockgen"
complete -c "go-tool-mockgen" -f -a '(_carapace_completer "go-tool-mockgen")'
complete -e "go-tool-nm"
complete -c "go-tool-nm" -f -a '(_carapace_completer "go-tool-nm")'
complete -e "go-tool-objdump"
complete -c "go-tool-objdump" -f -a '(_carapace_completer "go-tool-objdump")'
complete -e "go-tool-pack"
complete -c "go-tool-pack" -f -a '(_carapace_completer "go-tool-pack")'
complete -e "gocryptfs"
complete -c "gocryptfs" -f -a '(_carapace_completer "gocryptfs")'
complete -e "gocyclo"
complete -c "gocyclo" -f -a '(_carapace_completer "gocyclo")'
complete -e "god"
complete -c "god" -f -a '(_carapace_completer "god")'
complete -e "gofmt"
complete -c "gofmt" -f -a '(_carapace_completer "gofmt")'
complete -e "goimports"
complete -c "goimports" -f -a '(_carapace_completer "goimports")'
complete -e "goland"
complete -c "goland" -f -a '(_carapace_completer "goland")'
complete -e "golangci-lint"
complete -c "golangci-lint" -f -a '(_carapace_completer "golangci-lint")'
complete -e "gomplate"
complete -c "gomplate" -f -a '(_carapace_completer "gomplate")'
complete -e "gonew"
complete -c "gonew" -f -a '(_carapace_completer "gonew")'
complete -e "google-chrome"
complete -c "google-chrome" -f -a '(_carapace_completer "google-chrome")'
complete -e "gopls"
complete -c "gopls" -f -a '(_carapace_completer "gopls")'
complete -e "goreleaser"
complete -c "goreleaser" -f -a '(_carapace_completer "goreleaser")'
complete -e "goweight"
complete -c "goweight" -f -a '(_carapace_completer "goweight")'
complete -e "gparted"
complete -c "gparted" -f -a '(_carapace_completer "gparted")'
complete -e "gpasswd"
complete -c "gpasswd" -f -a '(_carapace_completer "gpasswd")'
complete -e "gpaste"
complete -c "gpaste" -f -a '(_carapace_completer "gpaste")'
complete -e "gpatch"
complete -c "gpatch" -f -a '(_carapace_completer "gpatch")'
complete -e "gpg"
complete -c "gpg" -f -a '(_carapace_completer "gpg")'
complete -e "gpg-agent"
complete -c "gpg-agent" -f -a '(_carapace_completer "gpg-agent")'
complete -e "gpg-zip"
complete -c "gpg-zip" -f -a '(_carapace_completer "gpg-zip")'
complete -e "gpgconf"
complete -c "gpgconf" -f -a '(_carapace_completer "gpgconf")'
complete -e "gpgv"
complete -c "gpgv" -f -a '(_carapace_completer "gpgv")'
complete -e "gphoto2"
complete -c "gphoto2" -f -a '(_carapace_completer "gphoto2")'
complete -e "gprintenv"
complete -c "gprintenv" -f -a '(_carapace_completer "gprintenv")'
complete -e "gprof"
complete -c "gprof" -f -a '(_carapace_completer "gprof")'
complete -e "gqview"
complete -c "gqview" -f -a '(_carapace_completer "gqview")'
complete -e "gradle"
complete -c "gradle" -f -a '(_carapace_completer "gradle")'
complete -e "gradlew"
complete -c "gradlew" -f -a '(_carapace_completer "gradlew")'
complete -e "grail"
complete -c "grail" -f -a '(_carapace_completer "grail")'
complete -e "greadlink"
complete -c "greadlink" -f -a '(_carapace_completer "greadlink")'
complete -e "grep"
complete -c "grep" -f -a '(_carapace_completer "grep")'
complete -e "grepdiff"
complete -c "grepdiff" -f -a '(_carapace_completer "grepdiff")'
complete -e "grm"
complete -c "grm" -f -a '(_carapace_completer "grm")'
complete -e "grmdir"
complete -c "grmdir" -f -a '(_carapace_completer "grmdir")'
complete -e "groff"
complete -c "groff" -f -a '(_carapace_completer "groff")'
complete -e "groupadd"
complete -c "groupadd" -f -a '(_carapace_completer "groupadd")'
complete -e "groupdel"
complete -c "groupdel" -f -a '(_carapace_completer "groupdel")'
complete -e "groupmems"
complete -c "groupmems" -f -a '(_carapace_completer "groupmems")'
complete -e "groupmod"
complete -c "groupmod" -f -a '(_carapace_completer "groupmod")'
complete -e "groups"
complete -c "groups" -f -a '(_carapace_completer "groups")'
complete -e "growisofs"
complete -c "growisofs" -f -a '(_carapace_completer "growisofs")'
complete -e "grpcurl"
complete -c "grpcurl" -f -a '(_carapace_completer "grpcurl")'
complete -e "grype"
complete -c "grype" -f -a '(_carapace_completer "grype")'
complete -e "gs"
complete -c "gs" -f -a '(_carapace_completer "gs")'
complete -e "gsa"
complete -c "gsa" -f -a '(_carapace_completer "gsa")'
complete -e "gsbj"
complete -c "gsbj" -f -a '(_carapace_completer "gsbj")'
complete -e "gsdj"
complete -c "gsdj" -f -a '(_carapace_completer "gsdj")'
complete -e "gsdj500"
complete -c "gsdj500" -f -a '(_carapace_completer "gsdj500")'
complete -e "gsed"
complete -c "gsed" -f -a '(_carapace_completer "gsed")'
complete -e "gseq"
complete -c "gseq" -f -a '(_carapace_completer "gseq")'
complete -e "gsettings"
complete -c "gsettings" -f -a '(_carapace_completer "gsettings")'
complete -e "gsha1sum"
complete -c "gsha1sum" -f -a '(_carapace_completer "gsha1sum")'
complete -e "gsha224sum"
complete -c "gsha224sum" -f -a '(_carapace_completer "gsha224sum")'
complete -e "gsha256sum"
complete -c "gsha256sum" -f -a '(_carapace_completer "gsha256sum")'
complete -e "gsha384sum"
complete -c "gsha384sum" -f -a '(_carapace_completer "gsha384sum")'
complete -e "gsha512sum"
complete -c "gsha512sum" -f -a '(_carapace_completer "gsha512sum")'
complete -e "gshred"
complete -c "gshred" -f -a '(_carapace_completer "gshred")'
complete -e "gshuf"
complete -c "gshuf" -f -a '(_carapace_completer "gshuf")'
complete -e "gslj"
complete -c "gslj" -f -a '(_carapace_completer "gslj")'
complete -e "gslp"
complete -c "gslp" -f -a '(_carapace_completer "gslp")'
complete -e "gsnd"
complete -c "gsnd" -f -a '(_carapace_completer "gsnd")'
complete -e "gsort"
complete -c "gsort" -f -a '(_carapace_completer "gsort")'
complete -e "gsplit"
complete -c "gsplit" -f -a '(_carapace_completer "gsplit")'
complete -e "gst-inspect-1.0"
complete -c "gst-inspect-1.0" -f -a '(_carapace_completer "gst-inspect-1.0")'
complete -e "gst-launch-1.0"
complete -c "gst-launch-1.0" -f -a '(_carapace_completer "gst-launch-1.0")'
complete -e "gstat"
complete -c "gstat" -f -a '(_carapace_completer "gstat")'
complete -e "gstdbuf"
complete -c "gstdbuf" -f -a '(_carapace_completer "gstdbuf")'
complete -e "gstrings"
complete -c "gstrings" -f -a '(_carapace_completer "gstrings")'
complete -e "gstty"
complete -c "gstty" -f -a '(_carapace_completer "gstty")'
complete -e "gsum"
complete -c "gsum" -f -a '(_carapace_completer "gsum")'
complete -e "gtac"
complete -c "gtac" -f -a '(_carapace_completer "gtac")'
complete -e "gtail"
complete -c "gtail" -f -a '(_carapace_completer "gtail")'
complete -e "gtar"
complete -c "gtar" -f -a '(_carapace_completer "gtar")'
complete -e "gtee"
complete -c "gtee" -f -a '(_carapace_completer "gtee")'
complete -e "gtimeout"
complete -c "gtimeout" -f -a '(_carapace_completer "gtimeout")'
complete -e "gtk-launch"
complete -c "gtk-launch" -f -a '(_carapace_completer "gtk-launch")'
complete -e "gtk4-builder-tool"
complete -c "gtk4-builder-tool" -f -a '(_carapace_completer "gtk4-builder-tool")'
complete -e "gtk4-demo"
complete -c "gtk4-demo" -f -a '(_carapace_completer "gtk4-demo")'
complete -e "gtk4-image-tool"
complete -c "gtk4-image-tool" -f -a '(_carapace_completer "gtk4-image-tool")'
complete -e "gtk4-launch"
complete -c "gtk4-launch" -f -a '(_carapace_completer "gtk4-launch")'
complete -e "gtk4-node-editor"
complete -c "gtk4-node-editor" -f -a '(_carapace_completer "gtk4-node-editor")'
complete -e "gtk4-path-tool"
complete -c "gtk4-path-tool" -f -a '(_carapace_completer "gtk4-path-tool")'
complete -e "gtk4-print-editor"
complete -c "gtk4-print-editor" -f -a '(_carapace_completer "gtk4-print-editor")'
complete -e "gtk4-rendernode-tool"
complete -c "gtk4-rendernode-tool" -f -a '(_carapace_completer "gtk4-rendernode-tool")'
complete -e "gtk4-widget-factory"
complete -c "gtk4-widget-factory" -f -a '(_carapace_completer "gtk4-widget-factory")'
complete -e "gtouch"
complete -c "gtouch" -f -a '(_carapace_completer "gtouch")'
complete -e "gtr"
complete -c "gtr" -f -a '(_carapace_completer "gtr")'
complete -e "gtty"
complete -c "gtty" -f -a '(_carapace_completer "gtty")'
complete -e "guilt"
complete -c "guilt" -f -a '(_carapace_completer "guilt")'
complete -e "guilt-add"
complete -c "guilt-add" -f -a '(_carapace_completer "guilt-add")'
complete -e "guilt-applied"
complete -c "guilt-applied" -f -a '(_carapace_completer "guilt-applied")'
complete -e "guilt-delete"
complete -c "guilt-delete" -f -a '(_carapace_completer "guilt-delete")'
complete -e "guilt-files"
complete -c "guilt-files" -f -a '(_carapace_completer "guilt-files")'
complete -e "guilt-fold"
complete -c "guilt-fold" -f -a '(_carapace_completer "guilt-fold")'
complete -e "guilt-fork"
complete -c "guilt-fork" -f -a '(_carapace_completer "guilt-fork")'
complete -e "guilt-header"
complete -c "guilt-header" -f -a '(_carapace_completer "guilt-header")'
complete -e "guilt-help"
complete -c "guilt-help" -f -a '(_carapace_completer "guilt-help")'
complete -e "guilt-import"
complete -c "guilt-import" -f -a '(_carapace_completer "guilt-import")'
complete -e "guilt-import-commit"
complete -c "guilt-import-commit" -f -a '(_carapace_completer "guilt-import-commit")'
complete -e "guilt-init"
complete -c "guilt-init" -f -a '(_carapace_completer "guilt-init")'
complete -e "guilt-new"
complete -c "guilt-new" -f -a '(_carapace_completer "guilt-new")'
complete -e "guilt-next"
complete -c "guilt-next" -f -a '(_carapace_completer "guilt-next")'
complete -e "guilt-patchbomb"
complete -c "guilt-patchbomb" -f -a '(_carapace_completer "guilt-patchbomb")'
complete -e "guilt-pop"
complete -c "guilt-pop" -f -a '(_carapace_completer "guilt-pop")'
complete -e "guilt-prev"
complete -c "guilt-prev" -f -a '(_carapace_completer "guilt-prev")'
complete -e "guilt-push"
complete -c "guilt-push" -f -a '(_carapace_completer "guilt-push")'
complete -e "guilt-rebase"
complete -c "guilt-rebase" -f -a '(_carapace_completer "guilt-rebase")'
complete -e "guilt-refresh"
complete -c "guilt-refresh" -f -a '(_carapace_completer "guilt-refresh")'
complete -e "guilt-rm"
complete -c "guilt-rm" -f -a '(_carapace_completer "guilt-rm")'
complete -e "guilt-series"
complete -c "guilt-series" -f -a '(_carapace_completer "guilt-series")'
complete -e "guilt-status"
complete -c "guilt-status" -f -a '(_carapace_completer "guilt-status")'
complete -e "guilt-top"
complete -c "guilt-top" -f -a '(_carapace_completer "guilt-top")'
complete -e "guilt-unapplied"
complete -c "guilt-unapplied" -f -a '(_carapace_completer "guilt-unapplied")'
complete -e "gulp"
complete -c "gulp" -f -a '(_carapace_completer "gulp")'
complete -e "gum"
complete -c "gum" -f -a '(_carapace_completer "gum")'
complete -e "guname"
complete -c "guname" -f -a '(_carapace_completer "guname")'
complete -e "gunexpand"
complete -c "gunexpand" -f -a '(_carapace_completer "gunexpand")'
complete -e "guniq"
complete -c "guniq" -f -a '(_carapace_completer "guniq")'
complete -e "gunzip"
complete -c "gunzip" -f -a '(_carapace_completer "gunzip")'
complete -e "guptime"
complete -c "guptime" -f -a '(_carapace_completer "guptime")'
complete -e "gv"
complete -c "gv" -f -a '(_carapace_completer "gv")'
complete -e "gview"
complete -c "gview" -f -a '(_carapace_completer "gview")'
complete -e "gvim"
complete -c "gvim" -f -a '(_carapace_completer "gvim")'
complete -e "gvimdiff"
complete -c "gvimdiff" -f -a '(_carapace_completer "gvimdiff")'
complete -e "gwc"
complete -c "gwc" -f -a '(_carapace_completer "gwc")'
complete -e "gwho"
complete -c "gwho" -f -a '(_carapace_completer "gwho")'
complete -e "gxargs"
complete -c "gxargs" -f -a '(_carapace_completer "gxargs")'
complete -e "gzegrep"
complete -c "gzegrep" -f -a '(_carapace_completer "gzegrep")'
complete -e "gzfgrep"
complete -c "gzfgrep" -f -a '(_carapace_completer "gzfgrep")'
complete -e "gzgrep"
complete -c "gzgrep" -f -a '(_carapace_completer "gzgrep")'
complete -e "gzilla"
complete -c "gzilla" -f -a '(_carapace_completer "gzilla")'
complete -e "gzip"
complete -c "gzip" -f -a '(_carapace_completer "gzip")'
complete -e "halt"
complete -c "halt" -f -a '(_carapace_completer "halt")'
complete -e "hardlink"
complete -c "hardlink" -f -a '(_carapace_completer "hardlink")'
complete -e "hatch"
complete -c "hatch" -f -a '(_carapace_completer "hatch")'
complete -e "hcloud"
complete -c "hcloud" -f -a '(_carapace_completer "hcloud")'
complete -e "hd"
complete -c "hd" -f -a '(_carapace_completer "hd")'
complete -e "head"
complete -c "head" -f -a '(_carapace_completer "head")'
complete -e "heat"
complete -c "heat" -f -a '(_carapace_completer "heat")'
complete -e "helix"
complete -c "helix" -f -a '(_carapace_completer "helix")'
complete -e "hello"
complete -c "hello" -f -a '(_carapace_completer "hello")'
complete -e "helm"
complete -c "helm" -f -a '(_carapace_completer "helm")'
complete -e "helmfile"
complete -c "helmfile" -f -a '(_carapace_completer "helmfile")'
complete -e "helmsman"
complete -c "helmsman" -f -a '(_carapace_completer "helmsman")'
complete -e "hexchat"
complete -c "hexchat" -f -a '(_carapace_completer "hexchat")'
complete -e "hexdump"
complete -c "hexdump" -f -a '(_carapace_completer "hexdump")'
complete -e "hilite"
complete -c "hilite" -f -a '(_carapace_completer "hilite")'
complete -e "histed"
complete -c "histed" -f -a '(_carapace_completer "histed")'
complete -e "hledger"
complete -c "hledger" -f -a '(_carapace_completer "hledger")'
complete -e "homectl"
complete -c "homectl" -f -a '(_carapace_completer "homectl")'
complete -e "host"
complete -c "host" -f -a '(_carapace_completer "host")'
complete -e "hostid"
complete -c "hostid" -f -a '(_carapace_completer "hostid")'
complete -e "hostname"
complete -c "hostname" -f -a '(_carapace_completer "hostname")'
complete -e "hostnamectl"
complete -c "hostnamectl" -f -a '(_carapace_completer "hostnamectl")'
complete -e "hotjava"
complete -c "hotjava" -f -a '(_carapace_completer "hotjava")'
complete -e "htop"
complete -c "htop" -f -a '(_carapace_completer "htop")'
complete -e "http"
complete -c "http" -f -a '(_carapace_completer "http")'
complete -e "https"
complete -c "https" -f -a '(_carapace_completer "https")'
complete -e "hugetop"
complete -c "hugetop" -f -a '(_carapace_completer "hugetop")'
complete -e "hugo"
complete -c "hugo" -f -a '(_carapace_completer "hugo")'
complete -e "hurl"
complete -c "hurl" -f -a '(_carapace_completer "hurl")'
complete -e "hwclock"
complete -c "hwclock" -f -a '(_carapace_completer "hwclock")'
complete -e "hwinfo"
complete -c "hwinfo" -f -a '(_carapace_completer "hwinfo")'
complete -e "hwloc"
complete -c "hwloc" -f -a '(_carapace_completer "hwloc")'
complete -e "hx"
complete -c "hx" -f -a '(_carapace_completer "hx")'
complete -e "hyperfine"
complete -c "hyperfine" -f -a '(_carapace_completer "hyperfine")'
complete -e "i3"
complete -c "i3" -f -a '(_carapace_completer "i3")'
complete -e "i3-scrot"
complete -c "i3-scrot" -f -a '(_carapace_completer "i3-scrot")'
complete -e "i3blocks"
complete -c "i3blocks" -f -a '(_carapace_completer "i3blocks")'
complete -e "i3exit"
complete -c "i3exit" -f -a '(_carapace_completer "i3exit")'
complete -e "i3lock"
complete -c "i3lock" -f -a '(_carapace_completer "i3lock")'
complete -e "i3status"
complete -c "i3status" -f -a '(_carapace_completer "i3status")'
complete -e "i3status-rs"
complete -c "i3status-rs" -f -a '(_carapace_completer "i3status-rs")'
complete -e "ibus"
complete -c "ibus" -f -a '(_carapace_completer "ibus")'
complete -e "icombine"
complete -c "icombine" -f -a '(_carapace_completer "icombine")'
complete -e "iconv"
complete -c "iconv" -f -a '(_carapace_completer "iconv")'
complete -e "iconvconfig"
complete -c "iconvconfig" -f -a '(_carapace_completer "iconvconfig")'
complete -e "id"
complete -c "id" -f -a '(_carapace_completer "id")'
complete -e "idea"
complete -c "idea" -f -a '(_carapace_completer "idea")'
complete -e "identify"
complete -c "identify" -f -a '(_carapace_completer "identify")'
complete -e "ifconfig"
complete -c "ifconfig" -f -a '(_carapace_completer "ifconfig")'
complete -e "ifdown"
complete -c "ifdown" -f -a '(_carapace_completer "ifdown")'
complete -e "iftop"
complete -c "iftop" -f -a '(_carapace_completer "iftop")'
complete -e "ifup"
complete -c "ifup" -f -a '(_carapace_completer "ifup")'
complete -e "ijoin"
complete -c "ijoin" -f -a '(_carapace_completer "ijoin")'
complete -e "img2pdf"
complete -c "img2pdf" -f -a '(_carapace_completer "img2pdf")'
complete -e "img2sixel"
complete -c "img2sixel" -f -a '(_carapace_completer "img2sixel")'
complete -e "import"
complete -c "import" -f -a '(_carapace_completer "import")'
complete -e "importctl"
complete -c "importctl" -f -a '(_carapace_completer "importctl")'
complete -e "imv"
complete -c "imv" -f -a '(_carapace_completer "imv")'
complete -e "inc"
complete -c "inc" -f -a '(_carapace_completer "inc")'
complete -e "include-what-you-use"
complete -c "include-what-you-use" -f -a '(_carapace_completer "include-what-you-use")'
complete -e "includeres"
complete -c "includeres" -f -a '(_carapace_completer "includeres")'
complete -e "incus"
complete -c "incus" -f -a '(_carapace_completer "incus")'
complete -e "info"
complete -c "info" -f -a '(_carapace_completer "info")'
complete -e "infocmp"
complete -c "infocmp" -f -a '(_carapace_completer "infocmp")'
complete -e "initctl"
complete -c "initctl" -f -a '(_carapace_completer "initctl")'
complete -e "initdb"
complete -c "initdb" -f -a '(_carapace_completer "initdb")'
complete -e "inkscape"
complete -c "inkscape" -f -a '(_carapace_completer "inkscape")'
complete -e "inshellisense"
complete -c "inshellisense" -f -a '(_carapace_completer "inshellisense")'
complete -e "insmod"
complete -c "insmod" -f -a '(_carapace_completer "insmod")'
complete -e "install"
complete -c "install" -f -a '(_carapace_completer "install")'
complete -e "install-info"
complete -c "install-info" -f -a '(_carapace_completer "install-info")'
complete -e "interdiff"
complete -c "interdiff" -f -a '(_carapace_completer "interdiff")'
complete -e "inxi"
complete -c "inxi" -f -a '(_carapace_completer "inxi")'
complete -e "ion"
complete -c "ion" -f -a '(_carapace_completer "ion")'
complete -e "ionice"
complete -c "ionice" -f -a '(_carapace_completer "ionice")'
complete -e "iostat"
complete -c "iostat" -f -a '(_carapace_completer "iostat")'
complete -e "ip"
complete -c "ip" -f -a '(_carapace_completer "ip")'
complete -e "ip6tables"
complete -c "ip6tables" -f -a '(_carapace_completer "ip6tables")'
complete -e "ip6tables-restore"
complete -c "ip6tables-restore" -f -a '(_carapace_completer "ip6tables-restore")'
complete -e "ip6tables-save"
complete -c "ip6tables-save" -f -a '(_carapace_completer "ip6tables-save")'
complete -e "ipcmk"
complete -c "ipcmk" -f -a '(_carapace_completer "ipcmk")'
complete -e "ipcrm"
complete -c "ipcrm" -f -a '(_carapace_completer "ipcrm")'
complete -e "ipcs"
complete -c "ipcs" -f -a '(_carapace_completer "ipcs")'
complete -e "ipkg"
complete -c "ipkg" -f -a '(_carapace_completer "ipkg")'
complete -e "ipsec"
complete -c "ipsec" -f -a '(_carapace_completer "ipsec")'
complete -e "ipset"
complete -c "ipset" -f -a '(_carapace_completer "ipset")'
complete -e "iptables"
complete -c "iptables" -f -a '(_carapace_completer "iptables")'
complete -e "iptables-restore"
complete -c "iptables-restore" -f -a '(_carapace_completer "iptables-restore")'
complete -e "iptables-save"
complete -c "iptables-save" -f -a '(_carapace_completer "iptables-save")'
complete -e "irb"
complete -c "irb" -f -a '(_carapace_completer "irb")'
complete -e "iredis"
complete -c "iredis" -f -a '(_carapace_completer "iredis")'
complete -e "ironic"
complete -c "ironic" -f -a '(_carapace_completer "ironic")'
complete -e "irqtop"
complete -c "irqtop" -f -a '(_carapace_completer "irqtop")'
complete -e "irssi"
complete -c "irssi" -f -a '(_carapace_completer "irssi")'
complete -e "isag"
complete -c "isag" -f -a '(_carapace_completer "isag")'
complete -e "isosize"
complete -c "isosize" -f -a '(_carapace_completer "isosize")'
complete -e "ispell"
complete -c "ispell" -f -a '(_carapace_completer "ispell")'
complete -e "ivpn"
complete -c "ivpn" -f -a '(_carapace_completer "ivpn")'
complete -e "iwconfig"
complete -c "iwconfig" -f -a '(_carapace_completer "iwconfig")'
complete -e "iwyu"
complete -c "iwyu" -f -a '(_carapace_completer "iwyu")'
complete -e "jadetex"
complete -c "jadetex" -f -a '(_carapace_completer "jadetex")'
complete -e "jar"
complete -c "jar" -f -a '(_carapace_completer "jar")'
complete -e "jarsigner"
complete -c "jarsigner" -f -a '(_carapace_completer "jarsigner")'
complete -e "java"
complete -c "java" -f -a '(_carapace_completer "java")'
complete -e "javac"
complete -c "javac" -f -a '(_carapace_completer "javac")'
complete -e "javadoc"
complete -c "javadoc" -f -a '(_carapace_completer "javadoc")'
complete -e "javah"
complete -c "javah" -f -a '(_carapace_completer "javah")'
complete -e "javap"
complete -c "javap" -f -a '(_carapace_completer "javap")'
complete -e "jdb"
complete -c "jdb" -f -a '(_carapace_completer "jdb")'
complete -e "jest"
complete -c "jest" -f -a '(_carapace_completer "jest")'
complete -e "jest.js"
complete -c "jest.js" -f -a '(_carapace_completer "jest.js")'
complete -e "jj"
complete -c "jj" -f -a '(_carapace_completer "jj")'
complete -e "jmeter"
complete -c "jmeter" -f -a '(_carapace_completer "jmeter")'
complete -e "jmeter-plugins"
complete -c "jmeter-plugins" -f -a '(_carapace_completer "jmeter-plugins")'
complete -e "joe"
complete -c "joe" -f -a '(_carapace_completer "joe")'
complete -e "join"
complete -c "join" -f -a '(_carapace_completer "join")'
complete -e "jonas"
complete -c "jonas" -f -a '(_carapace_completer "jonas")'
complete -e "journalctl"
complete -c "journalctl" -f -a '(_carapace_completer "journalctl")'
complete -e "jp2a"
complete -c "jp2a" -f -a '(_carapace_completer "jp2a")'
complete -e "jq"
complete -c "jq" -f -a '(_carapace_completer "jq")'
complete -e "jrnl"
complete -c "jrnl" -f -a '(_carapace_completer "jrnl")'
complete -e "julia"
complete -c "julia" -f -a '(_carapace_completer "julia")'
complete -e "just"
complete -c "just" -f -a '(_carapace_completer "just")'
complete -e "k3sup"
complete -c "k3sup" -f -a '(_carapace_completer "k3sup")'
complete -e "k6"
complete -c "k6" -f -a '(_carapace_completer "k6")'
complete -e "k9s"
complete -c "k9s" -f -a '(_carapace_completer "k9s")'
complete -e "kak"
complete -c "kak" -f -a '(_carapace_completer "kak")'
complete -e "kak-lsp"
complete -c "kak-lsp" -f -a '(_carapace_completer "kak-lsp")'
complete -e "kcl"
complete -c "kcl" -f -a '(_carapace_completer "kcl")'
complete -e "kdeconnect-cli"
complete -c "kdeconnect-cli" -f -a '(_carapace_completer "kdeconnect-cli")'
complete -e "kernel-install"
complete -c "kernel-install" -f -a '(_carapace_completer "kernel-install")'
complete -e "keyring"
complete -c "keyring" -f -a '(_carapace_completer "keyring")'
complete -e "keystone"
complete -c "keystone" -f -a '(_carapace_completer "keystone")'
complete -e "keytool"
complete -c "keytool" -f -a '(_carapace_completer "keytool")'
complete -e "kfmclient"
complete -c "kfmclient" -f -a '(_carapace_completer "kfmclient")'
complete -e "khal"
complete -c "khal" -f -a '(_carapace_completer "khal")'
complete -e "kill"
complete -c "kill" -f -a '(_carapace_completer "kill")'
complete -e "killall"
complete -c "killall" -f -a '(_carapace_completer "killall")'
complete -e "killall5"
complete -c "killall5" -f -a '(_carapace_completer "killall5")'
complete -e "kioclient"
complete -c "kioclient" -f -a '(_carapace_completer "kioclient")'
complete -e "kitchen"
complete -c "kitchen" -f -a '(_carapace_completer "kitchen")'
complete -e "kitten"
complete -c "kitten" -f -a '(_carapace_completer "kitten")'
complete -e "kitty"
complete -c "kitty" -f -a '(_carapace_completer "kitty")'
complete -e "kmod"
complete -c "kmod" -f -a '(_carapace_completer "kmod")'
complete -e "kmonad"
complete -c "kmonad" -f -a '(_carapace_completer "kmonad")'
complete -e "knock"
complete -c "knock" -f -a '(_carapace_completer "knock")'
complete -e "kompose"
complete -c "kompose" -f -a '(_carapace_completer "kompose")'
complete -e "konqueror"
complete -c "konqueror" -f -a '(_carapace_completer "konqueror")'
complete -e "kotlin"
complete -c "kotlin" -f -a '(_carapace_completer "kotlin")'
complete -e "kotlinc"
complete -c "kotlinc" -f -a '(_carapace_completer "kotlinc")'
complete -e "kpartx"
complete -c "kpartx" -f -a '(_carapace_completer "kpartx")'
complete -e "kpdf"
complete -c "kpdf" -f -a '(_carapace_completer "kpdf")'
complete -e "ksh"
complete -c "ksh" -f -a '(_carapace_completer "ksh")'
complete -e "ksh88"
complete -c "ksh88" -f -a '(_carapace_completer "ksh88")'
complete -e "ksh93"
complete -c "ksh93" -f -a '(_carapace_completer "ksh93")'
complete -e "ktlint"
complete -c "ktlint" -f -a '(_carapace_completer "ktlint")'
complete -e "kubeadm"
complete -c "kubeadm" -f -a '(_carapace_completer "kubeadm")'
complete -e "kubebuilder"
complete -c "kubebuilder" -f -a '(_carapace_completer "kubebuilder")'
complete -e "kubectl"
complete -c "kubectl" -f -a '(_carapace_completer "kubectl")'
complete -e "kubeseal"
complete -c "kubeseal" -f -a '(_carapace_completer "kubeseal")'
complete -e "kustomize"
complete -c "kustomize" -f -a '(_carapace_completer "kustomize")'
complete -e "kvno"
complete -c "kvno" -f -a '(_carapace_completer "kvno")'
complete -e "l3build"
complete -c "l3build" -f -a '(_carapace_completer "l3build")'
complete -e "last"
complete -c "last" -f -a '(_carapace_completer "last")'
complete -e "lastb"
complete -c "lastb" -f -a '(_carapace_completer "lastb")'
complete -e "lastlog"
complete -c "lastlog" -f -a '(_carapace_completer "lastlog")'
complete -e "lastlog2"
complete -c "lastlog2" -f -a '(_carapace_completer "lastlog2")'
complete -e "latex"
complete -c "latex" -f -a '(_carapace_completer "latex")'
complete -e "latexmk"
complete -c "latexmk" -f -a '(_carapace_completer "latexmk")'
complete -e "lazygit"
complete -c "lazygit" -f -a '(_carapace_completer "lazygit")'
complete -e "ldapadd"
complete -c "ldapadd" -f -a '(_carapace_completer "ldapadd")'
complete -e "ldapcompare"
complete -c "ldapcompare" -f -a '(_carapace_completer "ldapcompare")'
complete -e "ldapdelete"
complete -c "ldapdelete" -f -a '(_carapace_completer "ldapdelete")'
complete -e "ldapexop"
complete -c "ldapexop" -f -a '(_carapace_completer "ldapexop")'
complete -e "ldapmodify"
complete -c "ldapmodify" -f -a '(_carapace_completer "ldapmodify")'
complete -e "ldapmodrdn"
complete -c "ldapmodrdn" -f -a '(_carapace_completer "ldapmodrdn")'
complete -e "ldappasswd"
complete -c "ldappasswd" -f -a '(_carapace_completer "ldappasswd")'
complete -e "ldapsearch"
complete -c "ldapsearch" -f -a '(_carapace_completer "ldapsearch")'
complete -e "ldapurl"
complete -c "ldapurl" -f -a '(_carapace_completer "ldapurl")'
complete -e "ldapwhoami"
complete -c "ldapwhoami" -f -a '(_carapace_completer "ldapwhoami")'
complete -e "ldattach"
complete -c "ldattach" -f -a '(_carapace_completer "ldattach")'
complete -e "ldconfig"
complete -c "ldconfig" -f -a '(_carapace_completer "ldconfig")'
complete -e "ldconfig.real"
complete -c "ldconfig.real" -f -a '(_carapace_completer "ldconfig.real")'
complete -e "ldd"
complete -c "ldd" -f -a '(_carapace_completer "ldd")'
complete -e "lefthook"
complete -c "lefthook" -f -a '(_carapace_completer "lefthook")'
complete -e "less"
complete -c "less" -f -a '(_carapace_completer "less")'
complete -e "lf"
complete -c "lf" -f -a '(_carapace_completer "lf")'
complete -e "lfcd"
complete -c "lfcd" -f -a '(_carapace_completer "lfcd")'
complete -e "lftp"
complete -c "lftp" -f -a '(_carapace_completer "lftp")'
complete -e "lha"
complete -c "lha" -f -a '(_carapace_completer "lha")'
complete -e "libcap-ng.bash_completion"
complete -c "libcap-ng.bash_completion" -f -a '(_carapace_completer "libcap-ng.bash_completion")'
complete -e "libreoffice.sh"
complete -c "libreoffice.sh" -f -a '(_carapace_completer "libreoffice.sh")'
complete -e "light"
complete -c "light" -f -a '(_carapace_completer "light")'
complete -e "lightdm"
complete -c "lightdm" -f -a '(_carapace_completer "lightdm")'
complete -e "lilypond"
complete -c "lilypond" -f -a '(_carapace_completer "lilypond")'
complete -e "limactl"
complete -c "limactl" -f -a '(_carapace_completer "limactl")'
complete -e "link"
complete -c "link" -f -a '(_carapace_completer "link")'
complete -e "links"
complete -c "links" -f -a '(_carapace_completer "links")'
complete -e "links2"
complete -c "links2" -f -a '(_carapace_completer "links2")'
complete -e "linux"
complete -c "linux" -f -a '(_carapace_completer "linux")'
complete -e "litecli"
complete -c "litecli" -f -a '(_carapace_completer "litecli")'
complete -e "lksh"
complete -c "lksh" -f -a '(_carapace_completer "lksh")'
complete -e "lldb"
complete -c "lldb" -f -a '(_carapace_completer "lldb")'
complete -e "llvm-g++"
complete -c "llvm-g++" -f -a '(_carapace_completer "llvm-g++")'
complete -e "llvm-gcc"
complete -c "llvm-gcc" -f -a '(_carapace_completer "llvm-gcc")'
complete -e "llvm-objdump"
complete -c "llvm-objdump" -f -a '(_carapace_completer "llvm-objdump")'
complete -e "ln"
complete -c "ln" -f -a '(_carapace_completer "ln")'
complete -e "lnav"
complete -c "lnav" -f -a '(_carapace_completer "lnav")'
complete -e "lncrawl"
complete -c "lncrawl" -f -a '(_carapace_completer "lncrawl")'
complete -e "loadkeys"
complete -c "loadkeys" -f -a '(_carapace_completer "loadkeys")'
complete -e "locale"
complete -c "locale" -f -a '(_carapace_completer "locale")'
complete -e "localectl"
complete -c "localectl" -f -a '(_carapace_completer "localectl")'
complete -e "localedef"
complete -c "localedef" -f -a '(_carapace_completer "localedef")'
complete -e "locate"
complete -c "locate" -f -a '(_carapace_completer "locate")'
complete -e "logger"
complete -c "logger" -f -a '(_carapace_completer "logger")'
complete -e "loginctl"
complete -c "loginctl" -f -a '(_carapace_completer "loginctl")'
complete -e "logname"
complete -c "logname" -f -a '(_carapace_completer "logname")'
complete -e "look"
complete -c "look" -f -a '(_carapace_completer "look")'
complete -e "losetup"
complete -c "losetup" -f -a '(_carapace_completer "losetup")'
complete -e "lp"
complete -c "lp" -f -a '(_carapace_completer "lp")'
complete -e "lpadmin"
complete -c "lpadmin" -f -a '(_carapace_completer "lpadmin")'
complete -e "lpinfo"
complete -c "lpinfo" -f -a '(_carapace_completer "lpinfo")'
complete -e "lpoptions"
complete -c "lpoptions" -f -a '(_carapace_completer "lpoptions")'
complete -e "lpq"
complete -c "lpq" -f -a '(_carapace_completer "lpq")'
complete -e "lpr"
complete -c "lpr" -f -a '(_carapace_completer "lpr")'
complete -e "lprm"
complete -c "lprm" -f -a '(_carapace_completer "lprm")'
complete -e "lpstat"
complete -c "lpstat" -f -a '(_carapace_completer "lpstat")'
complete -e "lrf2lrs"
complete -c "lrf2lrs" -f -a '(_carapace_completer "lrf2lrs")'
complete -e "lrfviewer"
complete -c "lrfviewer" -f -a '(_carapace_completer "lrfviewer")'
complete -e "ls"
complete -c "ls" -f -a '(_carapace_completer "ls")'
complete -e "lsattr"
complete -c "lsattr" -f -a '(_carapace_completer "lsattr")'
complete -e "lsb_release"
complete -c "lsb_release" -f -a '(_carapace_completer "lsb_release")'
complete -e "lsblk"
complete -c "lsblk" -f -a '(_carapace_completer "lsblk")'
complete -e "lsclocks"
complete -c "lsclocks" -f -a '(_carapace_completer "lsclocks")'
complete -e "lscpu"
complete -c "lscpu" -f -a '(_carapace_completer "lscpu")'
complete -e "lsdiff"
complete -c "lsdiff" -f -a '(_carapace_completer "lsdiff")'
complete -e "lsfd"
complete -c "lsfd" -f -a '(_carapace_completer "lsfd")'
complete -e "lsinitcpio"
complete -c "lsinitcpio" -f -a '(_carapace_completer "lsinitcpio")'
complete -e "lsipc"
complete -c "lsipc" -f -a '(_carapace_completer "lsipc")'
complete -e "lsirq"
complete -c "lsirq" -f -a '(_carapace_completer "lsirq")'
complete -e "lslocks"
complete -c "lslocks" -f -a '(_carapace_completer "lslocks")'
complete -e "lslogins"
complete -c "lslogins" -f -a '(_carapace_completer "lslogins")'
complete -e "lsmem"
complete -c "lsmem" -f -a '(_carapace_completer "lsmem")'
complete -e "lsmod"
complete -c "lsmod" -f -a '(_carapace_completer "lsmod")'
complete -e "lsns"
complete -c "lsns" -f -a '(_carapace_completer "lsns")'
complete -e "lsof"
complete -c "lsof" -f -a '(_carapace_completer "lsof")'
complete -e "lsusb"
complete -c "lsusb" -f -a '(_carapace_completer "lsusb")'
complete -e "ltrace"
complete -c "ltrace" -f -a '(_carapace_completer "ltrace")'
complete -e "lua"
complete -c "lua" -f -a '(_carapace_completer "lua")'
complete -e "lualatex"
complete -c "lualatex" -f -a '(_carapace_completer "lualatex")'
complete -e "luarocks"
complete -c "luarocks" -f -a '(_carapace_completer "luarocks")'
complete -e "lunchy"
complete -c "lunchy" -f -a '(_carapace_completer "lunchy")'
complete -e "lvchange"
complete -c "lvchange" -f -a '(_carapace_completer "lvchange")'
complete -e "lvconvert"
complete -c "lvconvert" -f -a '(_carapace_completer "lvconvert")'
complete -e "lvcreate"
complete -c "lvcreate" -f -a '(_carapace_completer "lvcreate")'
complete -e "lvdisplay"
complete -c "lvdisplay" -f -a '(_carapace_completer "lvdisplay")'
complete -e "lvextend"
complete -c "lvextend" -f -a '(_carapace_completer "lvextend")'
complete -e "lvm"
complete -c "lvm" -f -a '(_carapace_completer "lvm")'
complete -e "lvmconfig"
complete -c "lvmconfig" -f -a '(_carapace_completer "lvmconfig")'
complete -e "lvmdiskscan"
complete -c "lvmdiskscan" -f -a '(_carapace_completer "lvmdiskscan")'
complete -e "lvmdump"
complete -c "lvmdump" -f -a '(_carapace_completer "lvmdump")'
complete -e "lvreduce"
complete -c "lvreduce" -f -a '(_carapace_completer "lvreduce")'
complete -e "lvremove"
complete -c "lvremove" -f -a '(_carapace_completer "lvremove")'
complete -e "lvrename"
complete -c "lvrename" -f -a '(_carapace_completer "lvrename")'
complete -e "lvresize"
complete -c "lvresize" -f -a '(_carapace_completer "lvresize")'
complete -e "lvs"
complete -c "lvs" -f -a '(_carapace_completer "lvs")'
complete -e "lvscan"
complete -c "lvscan" -f -a '(_carapace_completer "lvscan")'
complete -e "lynx"
complete -c "lynx" -f -a '(_carapace_completer "lynx")'
complete -e "lz4"
complete -c "lz4" -f -a '(_carapace_completer "lz4")'
complete -e "lz4c"
complete -c "lz4c" -f -a '(_carapace_completer "lz4c")'
complete -e "lz4c32"
complete -c "lz4c32" -f -a '(_carapace_completer "lz4c32")'
complete -e "lz4cat"
complete -c "lz4cat" -f -a '(_carapace_completer "lz4cat")'
complete -e "lzcat"
complete -c "lzcat" -f -a '(_carapace_completer "lzcat")'
complete -e "lzma"
complete -c "lzma" -f -a '(_carapace_completer "lzma")'
complete -e "lzop"
complete -c "lzop" -f -a '(_carapace_completer "lzop")'
complete -e "mac2unix"
complete -c "mac2unix" -f -a '(_carapace_completer "mac2unix")'
complete -e "machinectl"
complete -c "machinectl" -f -a '(_carapace_completer "machinectl")'
complete -e "magick"
complete -c "magick" -f -a '(_carapace_completer "magick")'
complete -e "magnum"
complete -c "magnum" -f -a '(_carapace_completer "magnum")'
complete -e "mail"
complete -c "mail" -f -a '(_carapace_completer "mail")'
complete -e "make"
complete -c "make" -f -a '(_carapace_completer "make")'
complete -e "makeinfo"
complete -c "makeinfo" -f -a '(_carapace_completer "makeinfo")'
complete -e "makepkg"
complete -c "makepkg" -f -a '(_carapace_completer "makepkg")'
complete -e "man"
complete -c "man" -f -a '(_carapace_completer "man")'
complete -e "manage.py"
complete -c "manage.py" -f -a '(_carapace_completer "manage.py")'
complete -e "manila"
complete -c "manila" -f -a '(_carapace_completer "manila")'
complete -e "mark"
complete -c "mark" -f -a '(_carapace_completer "mark")'
complete -e "marp"
complete -c "marp" -f -a '(_carapace_completer "marp")'
complete -e "mat"
complete -c "mat" -f -a '(_carapace_completer "mat")'
complete -e "mat2"
complete -c "mat2" -f -a '(_carapace_completer "mat2")'
complete -e "matchpathcon"
complete -c "matchpathcon" -f -a '(_carapace_completer "matchpathcon")'
complete -e "matlab"
complete -c "matlab" -f -a '(_carapace_completer "matlab")'
complete -e "mattrib"
complete -c "mattrib" -f -a '(_carapace_completer "mattrib")'
complete -e "maturin"
complete -c "maturin" -f -a '(_carapace_completer "maturin")'
complete -e "maxima"
complete -c "maxima" -f -a '(_carapace_completer "maxima")'
complete -e "mbimcli"
complete -c "mbimcli" -f -a '(_carapace_completer "mbimcli")'
complete -e "mc"
complete -c "mc" -f -a '(_carapace_completer "mc")'
complete -e "mcd"
complete -c "mcd" -f -a '(_carapace_completer "mcd")'
complete -e "mcomix"
complete -c "mcomix" -f -a '(_carapace_completer "mcomix")'
complete -e "mcookie"
complete -c "mcookie" -f -a '(_carapace_completer "mcookie")'
complete -e "mcopy"
complete -c "mcopy" -f -a '(_carapace_completer "mcopy")'
complete -e "md2"
complete -c "md2" -f -a '(_carapace_completer "md2")'
complete -e "md4"
complete -c "md4" -f -a '(_carapace_completer "md4")'
complete -e "md5"
complete -c "md5" -f -a '(_carapace_completer "md5")'
complete -e "md5sum"
complete -c "md5sum" -f -a '(_carapace_completer "md5sum")'
complete -e "mdadm"
complete -c "mdadm" -f -a '(_carapace_completer "mdadm")'
complete -e "mdbook"
complete -c "mdbook" -f -a '(_carapace_completer "mdbook")'
complete -e "mdel"
complete -c "mdel" -f -a '(_carapace_completer "mdel")'
complete -e "mdeltree"
complete -c "mdeltree" -f -a '(_carapace_completer "mdeltree")'
complete -e "mdir"
complete -c "mdir" -f -a '(_carapace_completer "mdir")'
complete -e "mdu"
complete -c "mdu" -f -a '(_carapace_completer "mdu")'
complete -e "meld"
complete -c "meld" -f -a '(_carapace_completer "meld")'
complete -e "melt"
complete -c "melt" -f -a '(_carapace_completer "melt")'
complete -e "mencal"
complete -c "mencal" -f -a '(_carapace_completer "mencal")'
complete -e "mere"
complete -c "mere" -f -a '(_carapace_completer "mere")'
complete -e "merge"
complete -c "merge" -f -a '(_carapace_completer "merge")'
complete -e "mesg"
complete -c "mesg" -f -a '(_carapace_completer "mesg")'
complete -e "metaflac"
complete -c "metaflac" -f -a '(_carapace_completer "metaflac")'
complete -e "mformat"
complete -c "mformat" -f -a '(_carapace_completer "mformat")'
complete -e "mgv"
complete -c "mgv" -f -a '(_carapace_completer "mgv")'
complete -e "mhfixmsg"
complete -c "mhfixmsg" -f -a '(_carapace_completer "mhfixmsg")'
complete -e "mhlist"
complete -c "mhlist" -f -a '(_carapace_completer "mhlist")'
complete -e "mhmail"
complete -c "mhmail" -f -a '(_carapace_completer "mhmail")'
complete -e "mhn"
complete -c "mhn" -f -a '(_carapace_completer "mhn")'
complete -e "mhparam"
complete -c "mhparam" -f -a '(_carapace_completer "mhparam")'
complete -e "mhpath"
complete -c "mhpath" -f -a '(_carapace_completer "mhpath")'
complete -e "mhshow"
complete -c "mhshow" -f -a '(_carapace_completer "mhshow")'
complete -e "mhstore"
complete -c "mhstore" -f -a '(_carapace_completer "mhstore")'
complete -e "micro"
complete -c "micro" -f -a '(_carapace_completer "micro")'
complete -e "middleman"
complete -c "middleman" -f -a '(_carapace_completer "middleman")'
complete -e "mii-tool"
complete -c "mii-tool" -f -a '(_carapace_completer "mii-tool")'
complete -e "mina"
complete -c "mina" -f -a '(_carapace_completer "mina")'
complete -e "minikube"
complete -c "minikube" -f -a '(_carapace_completer "minikube")'
complete -e "mise"
complete -c "mise" -f -a '(_carapace_completer "mise")'
complete -e "mistral"
complete -c "mistral" -f -a '(_carapace_completer "mistral")'
complete -e "mitmproxy"
complete -c "mitmproxy" -f -a '(_carapace_completer "mitmproxy")'
complete -e "mix"
complete -c "mix" -f -a '(_carapace_completer "mix")'
complete -e "mkcert"
complete -c "mkcert" -f -a '(_carapace_completer "mkcert")'
complete -e "mkdir"
complete -c "mkdir" -f -a '(_carapace_completer "mkdir")'
complete -e "mkfifo"
complete -c "mkfifo" -f -a '(_carapace_completer "mkfifo")'
complete -e "mkfs"
complete -c "mkfs" -f -a '(_carapace_completer "mkfs")'
complete -e "mkfs.bfs"
complete -c "mkfs.bfs" -f -a '(_carapace_completer "mkfs.bfs")'
complete -e "mkfs.cramfs"
complete -c "mkfs.cramfs" -f -a '(_carapace_completer "mkfs.cramfs")'
complete -e "mkfs.minix"
complete -c "mkfs.minix" -f -a '(_carapace_completer "mkfs.minix")'
complete -e "mkinitcpio"
complete -c "mkinitcpio" -f -a '(_carapace_completer "mkinitcpio")'
complete -e "mkisofs"
complete -c "mkisofs" -f -a '(_carapace_completer "mkisofs")'
complete -e "mknod"
complete -c "mknod" -f -a '(_carapace_completer "mknod")'
complete -e "mksh"
complete -c "mksh" -f -a '(_carapace_completer "mksh")'
complete -e "mkswap"
complete -c "mkswap" -f -a '(_carapace_completer "mkswap")'
complete -e "mktemp"
complete -c "mktemp" -f -a '(_carapace_completer "mktemp")'
complete -e "mktunes"
complete -c "mktunes" -f -a '(_carapace_completer "mktunes")'
complete -e "mlabel"
complete -c "mlabel" -f -a '(_carapace_completer "mlabel")'
complete -e "mlocate"
complete -c "mlocate" -f -a '(_carapace_completer "mlocate")'
complete -e "mmcli"
complete -c "mmcli" -f -a '(_carapace_completer "mmcli")'
complete -e "mmd"
complete -c "mmd" -f -a '(_carapace_completer "mmd")'
complete -e "mmm"
complete -c "mmm" -f -a '(_carapace_completer "mmm")'
complete -e "mmount"
complete -c "mmount" -f -a '(_carapace_completer "mmount")'
complete -e "mmove"
complete -c "mmove" -f -a '(_carapace_completer "mmove")'
complete -e "modinfo"
complete -c "modinfo" -f -a '(_carapace_completer "modinfo")'
complete -e "modprobe"
complete -c "modprobe" -f -a '(_carapace_completer "modprobe")'
complete -e "module"
complete -c "module" -f -a '(_carapace_completer "module")'
complete -e "mogrify"
complete -c "mogrify" -f -a '(_carapace_completer "mogrify")'
complete -e "molecule"
complete -c "molecule" -f -a '(_carapace_completer "molecule")'
complete -e "monasca"
complete -c "monasca" -f -a '(_carapace_completer "monasca")'
complete -e "mondoarchive"
complete -c "mondoarchive" -f -a '(_carapace_completer "mondoarchive")'
complete -e "montage"
complete -c "montage" -f -a '(_carapace_completer "montage")'
complete -e "moosic"
complete -c "moosic" -f -a '(_carapace_completer "moosic")'
complete -e "more"
complete -c "more" -f -a '(_carapace_completer "more")'
complete -e "mosh"
complete -c "mosh" -f -a '(_carapace_completer "mosh")'
complete -e "mount"
complete -c "mount" -f -a '(_carapace_completer "mount")'
complete -e "mountpoint"
complete -c "mountpoint" -f -a '(_carapace_completer "mountpoint")'
complete -e "mousepad"
complete -c "mousepad" -f -a '(_carapace_completer "mousepad")'
complete -e "mozilla"
complete -c "mozilla" -f -a '(_carapace_completer "mozilla")'
complete -e "mozilla-firefox"
complete -c "mozilla-firefox" -f -a '(_carapace_completer "mozilla-firefox")'
complete -e "mozilla-xremote-client"
complete -c "mozilla-xremote-client" -f -a '(_carapace_completer "mozilla-xremote-client")'
complete -e "mp42aac"
complete -c "mp42aac" -f -a '(_carapace_completer "mp42aac")'
complete -e "mp42avc"
complete -c "mp42avc" -f -a '(_carapace_completer "mp42avc")'
complete -e "mp42hevc"
complete -c "mp42hevc" -f -a '(_carapace_completer "mp42hevc")'
complete -e "mp42hls"
complete -c "mp42hls" -f -a '(_carapace_completer "mp42hls")'
complete -e "mp42ts"
complete -c "mp42ts" -f -a '(_carapace_completer "mp42ts")'
complete -e "mp4compact"
complete -c "mp4compact" -f -a '(_carapace_completer "mp4compact")'
complete -e "mp4dash"
complete -c "mp4dash" -f -a '(_carapace_completer "mp4dash")'
complete -e "mp4dashclone"
complete -c "mp4dashclone" -f -a '(_carapace_completer "mp4dashclone")'
complete -e "mp4dcfpackager"
complete -c "mp4dcfpackager" -f -a '(_carapace_completer "mp4dcfpackager")'
complete -e "mp4decrypt"
complete -c "mp4decrypt" -f -a '(_carapace_completer "mp4decrypt")'
complete -e "mp4dump"
complete -c "mp4dump" -f -a '(_carapace_completer "mp4dump")'
complete -e "mp4edit"
complete -c "mp4edit" -f -a '(_carapace_completer "mp4edit")'
complete -e "mp4encrypt"
complete -c "mp4encrypt" -f -a '(_carapace_completer "mp4encrypt")'
complete -e "mp4extract"
complete -c "mp4extract" -f -a '(_carapace_completer "mp4extract")'
complete -e "mp4fragment"
complete -c "mp4fragment" -f -a '(_carapace_completer "mp4fragment")'
complete -e "mp4hls"
complete -c "mp4hls" -f -a '(_carapace_completer "mp4hls")'
complete -e "mp4iframeindex"
complete -c "mp4iframeindex" -f -a '(_carapace_completer "mp4iframeindex")'
complete -e "mp4info"
complete -c "mp4info" -f -a '(_carapace_completer "mp4info")'
complete -e "mp4mux"
complete -c "mp4mux" -f -a '(_carapace_completer "mp4mux")'
complete -e "mp4rtphintinfo"
complete -c "mp4rtphintinfo" -f -a '(_carapace_completer "mp4rtphintinfo")'
complete -e "mp4split"
complete -c "mp4split" -f -a '(_carapace_completer "mp4split")'
complete -e "mp4tag"
complete -c "mp4tag" -f -a '(_carapace_completer "mp4tag")'
complete -e "mpc"
complete -c "mpc" -f -a '(_carapace_completer "mpc")'
complete -e "mplayer"
complete -c "mplayer" -f -a '(_carapace_completer "mplayer")'
complete -e "mpstat"
complete -c "mpstat" -f -a '(_carapace_completer "mpstat")'
complete -e "mpv"
complete -c "mpv" -f -a '(_carapace_completer "mpv")'
complete -e "mr"
complete -c "mr" -f -a '(_carapace_completer "mr")'
complete -e "mrd"
complete -c "mrd" -f -a '(_carapace_completer "mrd")'
complete -e "mread"
complete -c "mread" -f -a '(_carapace_completer "mread")'
complete -e "mren"
complete -c "mren" -f -a '(_carapace_completer "mren")'
complete -e "msgchk"
complete -c "msgchk" -f -a '(_carapace_completer "msgchk")'
complete -e "mssh"
complete -c "mssh" -f -a '(_carapace_completer "mssh")'
complete -e "mt"
complete -c "mt" -f -a '(_carapace_completer "mt")'
complete -e "mtn"
complete -c "mtn" -f -a '(_carapace_completer "mtn")'
complete -e "mtoolstest"
complete -c "mtoolstest" -f -a '(_carapace_completer "mtoolstest")'
complete -e "mtr"
complete -c "mtr" -f -a '(_carapace_completer "mtr")'
complete -e "mtype"
complete -c "mtype" -f -a '(_carapace_completer "mtype")'
complete -e "munchlist"
complete -c "munchlist" -f -a '(_carapace_completer "munchlist")'
complete -e "mupdf"
complete -c "mupdf" -f -a '(_carapace_completer "mupdf")'
complete -e "murano"
complete -c "murano" -f -a '(_carapace_completer "murano")'
complete -e "mush"
complete -c "mush" -f -a '(_carapace_completer "mush")'
complete -e "mussh"
complete -c "mussh" -f -a '(_carapace_completer "mussh")'
complete -e "mutt"
complete -c "mutt" -f -a '(_carapace_completer "mutt")'
complete -e "mux"
complete -c "mux" -f -a '(_carapace_completer "mux")'
complete -e "mv"
complete -c "mv" -f -a '(_carapace_completer "mv")'
complete -e "mvim"
complete -c "mvim" -f -a '(_carapace_completer "mvim")'
complete -e "mvn"
complete -c "mvn" -f -a '(_carapace_completer "mvn")'
complete -e "mvnDebug"
complete -c "mvnDebug" -f -a '(_carapace_completer "mvnDebug")'
complete -e "mx"
complete -c "mx" -f -a '(_carapace_completer "mx")'
complete -e "mycli"
complete -c "mycli" -f -a '(_carapace_completer "mycli")'
complete -e "mysql"
complete -c "mysql" -f -a '(_carapace_completer "mysql")'
complete -e "mysqladmin"
complete -c "mysqladmin" -f -a '(_carapace_completer "mysqladmin")'
complete -e "mysqldiff"
complete -c "mysqldiff" -f -a '(_carapace_completer "mysqldiff")'
complete -e "mysqldump"
complete -c "mysqldump" -f -a '(_carapace_completer "mysqldump")'
complete -e "mysqlimport"
complete -c "mysqlimport" -f -a '(_carapace_completer "mysqlimport")'
complete -e "mysqlshow"
complete -c "mysqlshow" -f -a '(_carapace_completer "mysqlshow")'
complete -e "n-m3u8dl-re"
complete -c "n-m3u8dl-re" -f -a '(_carapace_completer "n-m3u8dl-re")'
complete -e "namei"
complete -c "namei" -f -a '(_carapace_completer "namei")'
complete -e "nano"
complete -c "nano" -f -a '(_carapace_completer "nano")'
complete -e "nanoc"
complete -c "nanoc" -f -a '(_carapace_completer "nanoc")'
complete -e "native2ascii"
complete -c "native2ascii" -f -a '(_carapace_completer "native2ascii")'
complete -e "nautilus"
complete -c "nautilus" -f -a '(_carapace_completer "nautilus")'
complete -e "navi"
complete -c "navi" -f -a '(_carapace_completer "navi")'
complete -e "nawk"
complete -c "nawk" -f -a '(_carapace_completer "nawk")'
complete -e "nc"
complete -c "nc" -f -a '(_carapace_completer "nc")'
complete -e "ncal"
complete -c "ncal" -f -a '(_carapace_completer "ncal")'
complete -e "ncdu"
complete -c "ncdu" -f -a '(_carapace_completer "ncdu")'
complete -e "ncftp"
complete -c "ncftp" -f -a '(_carapace_completer "ncftp")'
complete -e "ndctl"
complete -c "ndctl" -f -a '(_carapace_completer "ndctl")'
complete -e "nedit"
complete -c "nedit" -f -a '(_carapace_completer "nedit")'
complete -e "neo"
complete -c "neo" -f -a '(_carapace_completer "neo")'
complete -e "neofetch"
complete -c "neofetch" -f -a '(_carapace_completer "neofetch")'
complete -e "neomutt"
complete -c "neomutt" -f -a '(_carapace_completer "neomutt")'
complete -e "nerdctl"
complete -c "nerdctl" -f -a '(_carapace_completer "nerdctl")'
complete -e "netcap"
complete -c "netcap" -f -a '(_carapace_completer "netcap")'
complete -e "netcat"
complete -c "netcat" -f -a '(_carapace_completer "netcat")'
complete -e "netrik"
complete -c "netrik" -f -a '(_carapace_completer "netrik")'
complete -e "netscape"
complete -c "netscape" -f -a '(_carapace_completer "netscape")'
complete -e "netstat"
complete -c "netstat" -f -a '(_carapace_completer "netstat")'
complete -e "networkQuality"
complete -c "networkQuality" -f -a '(_carapace_completer "networkQuality")'
complete -e "networkctl"
complete -c "networkctl" -f -a '(_carapace_completer "networkctl")'
complete -e "neutron"
complete -c "neutron" -f -a '(_carapace_completer "neutron")'
complete -e "new"
complete -c "new" -f -a '(_carapace_completer "new")'
complete -e "newgrp"
complete -c "newgrp" -f -a '(_carapace_completer "newgrp")'
complete -e "newman"
complete -c "newman" -f -a '(_carapace_completer "newman")'
complete -e "newrelic"
complete -c "newrelic" -f -a '(_carapace_completer "newrelic")'
complete -e "newrole"
complete -c "newrole" -f -a '(_carapace_completer "newrole")'
complete -e "next"
complete -c "next" -f -a '(_carapace_completer "next")'
complete -e "nfpm"
complete -c "nfpm" -f -a '(_carapace_completer "nfpm")'
complete -e "nft"
complete -c "nft" -f -a '(_carapace_completer "nft")'
complete -e "ng"
complete -c "ng" -f -a '(_carapace_completer "ng")'
complete -e "nginx"
complete -c "nginx" -f -a '(_carapace_completer "nginx")'
complete -e "ngrep"
complete -c "ngrep" -f -a '(_carapace_completer "ngrep")'
complete -e "nh"
complete -c "nh" -f -a '(_carapace_completer "nh")'
complete -e "nice"
complete -c "nice" -f -a '(_carapace_completer "nice")'
complete -e "nilaway"
complete -c "nilaway" -f -a '(_carapace_completer "nilaway")'
complete -e "ninja"
complete -c "ninja" -f -a '(_carapace_completer "ninja")'
complete -e "nix"
complete -c "nix" -f -a '(_carapace_completer "nix")'
complete -e "nix-build"
complete -c "nix-build" -f -a '(_carapace_completer "nix-build")'
complete -e "nix-channel"
complete -c "nix-channel" -f -a '(_carapace_completer "nix-channel")'
complete -e "nix-instantiate"
complete -c "nix-instantiate" -f -a '(_carapace_completer "nix-instantiate")'
complete -e "nix-shell"
complete -c "nix-shell" -f -a '(_carapace_completer "nix-shell")'
complete -e "nixos-rebuild"
complete -c "nixos-rebuild" -f -a '(_carapace_completer "nixos-rebuild")'
complete -e "nkf"
complete -c "nkf" -f -a '(_carapace_completer "nkf")'
complete -e "nl"
complete -c "nl" -f -a '(_carapace_completer "nl")'
complete -e "nm"
complete -c "nm" -f -a '(_carapace_completer "nm")'
complete -e "nmap"
complete -c "nmap" -f -a '(_carapace_completer "nmap")'
complete -e "nmblookup"
complete -c "nmblookup" -f -a '(_carapace_completer "nmblookup")'
complete -e "nmcli"
complete -c "nmcli" -f -a '(_carapace_completer "nmcli")'
complete -e "nocorrect"
complete -c "nocorrect" -f -a '(_carapace_completer "nocorrect")'
complete -e "node"
complete -c "node" -f -a '(_carapace_completer "node")'
complete -e "nohup"
complete -c "nohup" -f -a '(_carapace_completer "nohup")'
complete -e "nomad"
complete -c "nomad" -f -a '(_carapace_completer "nomad")'
complete -e "nova"
complete -c "nova" -f -a '(_carapace_completer "nova")'
complete -e "nox"
complete -c "nox" -f -a '(_carapace_completer "nox")'
complete -e "npm"
complete -c "npm" -f -a '(_carapace_completer "npm")'
complete -e "nproc"
complete -c "nproc" -f -a '(_carapace_completer "nproc")'
complete -e "ns"
complete -c "ns" -f -a '(_carapace_completer "ns")'
complete -e "nsenter"
complete -c "nsenter" -f -a '(_carapace_completer "nsenter")'
complete -e "nslookup"
complete -c "nslookup" -f -a '(_carapace_completer "nslookup")'
complete -e "ntalk"
complete -c "ntalk" -f -a '(_carapace_completer "ntalk")'
complete -e "ntpd"
complete -c "ntpd" -f -a '(_carapace_completer "ntpd")'
complete -e "nu"
complete -c "nu" -f -a '(_carapace_completer "nu")'
complete -e "numfmt"
complete -c "numfmt" -f -a '(_carapace_completer "numfmt")'
complete -e "nvim"
complete -c "nvim" -f -a '(_carapace_completer "nvim")'
complete -e "nvm"
complete -c "nvm" -f -a '(_carapace_completer "nvm")'
complete -e "objdump"
complete -c "objdump" -f -a '(_carapace_completer "objdump")'
complete -e "od"
complete -c "od" -f -a '(_carapace_completer "od")'
complete -e "ogg123"
complete -c "ogg123" -f -a '(_carapace_completer "ogg123")'
complete -e "oggdec"
complete -c "oggdec" -f -a '(_carapace_completer "oggdec")'
complete -e "oggenc"
complete -c "oggenc" -f -a '(_carapace_completer "oggenc")'
complete -e "ogginfo"
complete -c "ogginfo" -f -a '(_carapace_completer "ogginfo")'
complete -e "oh-my-posh"
complete -c "oh-my-posh" -f -a '(_carapace_completer "oh-my-posh")'
complete -e "oksh"
complete -c "oksh" -f -a '(_carapace_completer "oksh")'
complete -e "okular"
complete -c "okular" -f -a '(_carapace_completer "okular")'
complete -e "ollama"
complete -c "ollama" -f -a '(_carapace_completer "ollama")'
complete -e "oomctl"
complete -c "oomctl" -f -a '(_carapace_completer "oomctl")'
complete -e "op"
complete -c "op" -f -a '(_carapace_completer "op")'
complete -e "openscad"
complete -c "openscad" -f -a '(_carapace_completer "openscad")'
complete -e "openssl"
complete -c "openssl" -f -a '(_carapace_completer "openssl")'
complete -e "openstack"
complete -c "openstack" -f -a '(_carapace_completer "openstack")'
complete -e "openvpn3"
complete -c "openvpn3" -f -a '(_carapace_completer "openvpn3")'
complete -e "opera"
complete -c "opera" -f -a '(_carapace_completer "opera")'
complete -e "opera-next"
complete -c "opera-next" -f -a '(_carapace_completer "opera-next")'
complete -e "opkg"
complete -c "opkg" -f -a '(_carapace_completer "opkg")'
complete -e "optipng"
complete -c "optipng" -f -a '(_carapace_completer "optipng")'
complete -e "optirun"
complete -c "optirun" -f -a '(_carapace_completer "optirun")'
complete -e "opusdec"
complete -c "opusdec" -f -a '(_carapace_completer "opusdec")'
complete -e "opusenc"
complete -c "opusenc" -f -a '(_carapace_completer "opusenc")'
complete -e "opusinfo"
complete -c "opusinfo" -f -a '(_carapace_completer "opusinfo")'
complete -e "orbctl"
complete -c "orbctl" -f -a '(_carapace_completer "orbctl")'
complete -e "osh"
complete -c "osh" -f -a '(_carapace_completer "osh")'
complete -e "ouch"
complete -c "ouch" -f -a '(_carapace_completer "ouch")'
complete -e "p11-kit"
complete -c "p11-kit" -f -a '(_carapace_completer "p11-kit")'
complete -e "p4"
complete -c "p4" -f -a '(_carapace_completer "p4")'
complete -e "p4d"
complete -c "p4d" -f -a '(_carapace_completer "p4d")'
complete -e "pacat"
complete -c "pacat" -f -a '(_carapace_completer "pacat")'
complete -e "paccache"
complete -c "paccache" -f -a '(_carapace_completer "paccache")'
complete -e "pacdiff"
complete -c "pacdiff" -f -a '(_carapace_completer "pacdiff")'
complete -e "pacignore"
complete -c "pacignore" -f -a '(_carapace_completer "pacignore")'
complete -e "pack"
complete -c "pack" -f -a '(_carapace_completer "pack")'
complete -e "packer"
complete -c "packer" -f -a '(_carapace_completer "packer")'
complete -e "packf"
complete -c "packf" -f -a '(_carapace_completer "packf")'
complete -e "paclist"
complete -c "paclist" -f -a '(_carapace_completer "paclist")'
complete -e "paclog-pkglist"
complete -c "paclog-pkglist" -f -a '(_carapace_completer "paclog-pkglist")'
complete -e "pacman"
complete -c "pacman" -f -a '(_carapace_completer "pacman")'
complete -e "pacman-conf"
complete -c "pacman-conf" -f -a '(_carapace_completer "pacman-conf")'
complete -e "pacman-db-upgrade"
complete -c "pacman-db-upgrade" -f -a '(_carapace_completer "pacman-db-upgrade")'
complete -e "pacman-key"
complete -c "pacman-key" -f -a '(_carapace_completer "pacman-key")'
complete -e "pacman-mirrors"
complete -c "pacman-mirrors" -f -a '(_carapace_completer "pacman-mirrors")'
complete -e "pacmd"
complete -c "pacmd" -f -a '(_carapace_completer "pacmd")'
complete -e "pacscripts"
complete -c "pacscripts" -f -a '(_carapace_completer "pacscripts")'
complete -e "pacsearch"
complete -c "pacsearch" -f -a '(_carapace_completer "pacsearch")'
complete -e "pacsort"
complete -c "pacsort" -f -a '(_carapace_completer "pacsort")'
complete -e "pactl"
complete -c "pactl" -f -a '(_carapace_completer "pactl")'
complete -e "pactree"
complete -c "pactree" -f -a '(_carapace_completer "pactree")'
complete -e "padsp"
complete -c "padsp" -f -a '(_carapace_completer "padsp")'
complete -e "palemoon"
complete -c "palemoon" -f -a '(_carapace_completer "palemoon")'
complete -e "pamac"
complete -c "pamac" -f -a '(_carapace_completer "pamac")'
complete -e "pandoc"
complete -c "pandoc" -f -a '(_carapace_completer "pandoc")'
complete -e "papers"
complete -c "papers" -f -a '(_carapace_completer "papers")'
complete -e "papirus-folders"
complete -c "papirus-folders" -f -a '(_carapace_completer "papirus-folders")'
complete -e "paplay"
complete -c "paplay" -f -a '(_carapace_completer "paplay")'
complete -e "parec"
complete -c "parec" -f -a '(_carapace_completer "parec")'
complete -e "parecord"
complete -c "parecord" -f -a '(_carapace_completer "parecord")'
complete -e "partx"
complete -c "partx" -f -a '(_carapace_completer "partx")'
complete -e "paru"
complete -c "paru" -f -a '(_carapace_completer "paru")'
complete -e "pass"
complete -c "pass" -f -a '(_carapace_completer "pass")'
complete -e "passwd"
complete -c "passwd" -f -a '(_carapace_completer "passwd")'
complete -e "paste"
complete -c "paste" -f -a '(_carapace_completer "paste")'
complete -e "pasuspender"
complete -c "pasuspender" -f -a '(_carapace_completer "pasuspender")'
complete -e "patch"
complete -c "patch" -f -a '(_carapace_completer "patch")'
complete -e "patchelf"
complete -c "patchelf" -f -a '(_carapace_completer "patchelf")'
complete -e "pathchk"
complete -c "pathchk" -f -a '(_carapace_completer "pathchk")'
complete -e "patool"
complete -c "patool" -f -a '(_carapace_completer "patool")'
complete -e "pax"
complete -c "pax" -f -a '(_carapace_completer "pax")'
complete -e "pcmanfm"
complete -c "pcmanfm" -f -a '(_carapace_completer "pcmanfm")'
complete -e "pcp-htop"
complete -c "pcp-htop" -f -a '(_carapace_completer "pcp-htop")'
complete -e "pcred"
complete -c "pcred" -f -a '(_carapace_completer "pcred")'
complete -e "pdf2dsc"
complete -c "pdf2dsc" -f -a '(_carapace_completer "pdf2dsc")'
complete -e "pdf2ps"
complete -c "pdf2ps" -f -a '(_carapace_completer "pdf2ps")'
complete -e "pdfattach"
complete -c "pdfattach" -f -a '(_carapace_completer "pdfattach")'
complete -e "pdfdetach"
complete -c "pdfdetach" -f -a '(_carapace_completer "pdfdetach")'
complete -e "pdffonts"
complete -c "pdffonts" -f -a '(_carapace_completer "pdffonts")'
complete -e "pdfimages"
complete -c "pdfimages" -f -a '(_carapace_completer "pdfimages")'
complete -e "pdfinfo"
complete -c "pdfinfo" -f -a '(_carapace_completer "pdfinfo")'
complete -e "pdfjadetex"
complete -c "pdfjadetex" -f -a '(_carapace_completer "pdfjadetex")'
complete -e "pdflatex"
complete -c "pdflatex" -f -a '(_carapace_completer "pdflatex")'
complete -e "pdfopt"
complete -c "pdfopt" -f -a '(_carapace_completer "pdfopt")'
complete -e "pdfseparate"
complete -c "pdfseparate" -f -a '(_carapace_completer "pdfseparate")'
complete -e "pdfsig"
complete -c "pdfsig" -f -a '(_carapace_completer "pdfsig")'
complete -e "pdftex"
complete -c "pdftex" -f -a '(_carapace_completer "pdftex")'
complete -e "pdftexi2dvi"
complete -c "pdftexi2dvi" -f -a '(_carapace_completer "pdftexi2dvi")'
complete -e "pdftk"
complete -c "pdftk" -f -a '(_carapace_completer "pdftk")'
complete -e "pdftocairo"
complete -c "pdftocairo" -f -a '(_carapace_completer "pdftocairo")'
complete -e "pdftohtml"
complete -c "pdftohtml" -f -a '(_carapace_completer "pdftohtml")'
complete -e "pdftopbm"
complete -c "pdftopbm" -f -a '(_carapace_completer "pdftopbm")'
complete -e "pdftoppm"
complete -c "pdftoppm" -f -a '(_carapace_completer "pdftoppm")'
complete -e "pdftops"
complete -c "pdftops" -f -a '(_carapace_completer "pdftops")'
complete -e "pdftotext"
complete -c "pdftotext" -f -a '(_carapace_completer "pdftotext")'
complete -e "pdfunite"
complete -c "pdfunite" -f -a '(_carapace_completer "pdfunite")'
complete -e "pdksh"
complete -c "pdksh" -f -a '(_carapace_completer "pdksh")'
complete -e "perf"
complete -c "perf" -f -a '(_carapace_completer "perf")'
complete -e "periscope"
complete -c "periscope" -f -a '(_carapace_completer "periscope")'
complete -e "perl"
complete -c "perl" -f -a '(_carapace_completer "perl")'
complete -e "perlbrew"
complete -c "perlbrew" -f -a '(_carapace_completer "perlbrew")'
complete -e "perldoc"
complete -c "perldoc" -f -a '(_carapace_completer "perldoc")'
complete -e "pfiles"
complete -c "pfiles" -f -a '(_carapace_completer "pfiles")'
complete -e "pflags"
complete -c "pflags" -f -a '(_carapace_completer "pflags")'
complete -e "pg"
complete -c "pg" -f -a '(_carapace_completer "pg")'
complete -e "pg_config"
complete -c "pg_config" -f -a '(_carapace_completer "pg_config")'
complete -e "pg_ctl"
complete -c "pg_ctl" -f -a '(_carapace_completer "pg_ctl")'
complete -e "pg_dump"
complete -c "pg_dump" -f -a '(_carapace_completer "pg_dump")'
complete -e "pg_dumpall"
complete -c "pg_dumpall" -f -a '(_carapace_completer "pg_dumpall")'
complete -e "pg_isready"
complete -c "pg_isready" -f -a '(_carapace_completer "pg_isready")'
complete -e "pg_restore"
complete -c "pg_restore" -f -a '(_carapace_completer "pg_restore")'
complete -e "pg_upgrade"
complete -c "pg_upgrade" -f -a '(_carapace_completer "pg_upgrade")'
complete -e "pgcli"
complete -c "pgcli" -f -a '(_carapace_completer "pgcli")'
complete -e "pgrep"
complete -c "pgrep" -f -a '(_carapace_completer "pgrep")'
complete -e "phing"
complete -c "phing" -f -a '(_carapace_completer "phing")'
complete -e "php"
complete -c "php" -f -a '(_carapace_completer "php")'
complete -e "phpstorm"
complete -c "phpstorm" -f -a '(_carapace_completer "phpstorm")'
complete -e "picard"
complete -c "picard" -f -a '(_carapace_completer "picard")'
complete -e "pick"
complete -c "pick" -f -a '(_carapace_completer "pick")'
complete -e "picocom"
complete -c "picocom" -f -a '(_carapace_completer "picocom")'
complete -e "pidof"
complete -c "pidof" -f -a '(_carapace_completer "pidof")'
complete -e "pidproxy"
complete -c "pidproxy" -f -a '(_carapace_completer "pidproxy")'
complete -e "pidstat"
complete -c "pidstat" -f -a '(_carapace_completer "pidstat")'
complete -e "pidwait"
complete -c "pidwait" -f -a '(_carapace_completer "pidwait")'
complete -e "pigz"
complete -c "pigz" -f -a '(_carapace_completer "pigz")'
complete -e "pine"
complete -c "pine" -f -a '(_carapace_completer "pine")'
complete -e "pinef"
complete -c "pinef" -f -a '(_carapace_completer "pinef")'
complete -e "pinfo"
complete -c "pinfo" -f -a '(_carapace_completer "pinfo")'
complete -e "ping"
complete -c "ping" -f -a '(_carapace_completer "ping")'
complete -e "ping6"
complete -c "ping6" -f -a '(_carapace_completer "ping6")'
complete -e "pinky"
complete -c "pinky" -f -a '(_carapace_completer "pinky")'
complete -e "pip"
complete -c "pip" -f -a '(_carapace_completer "pip")'
complete -e "pipenv"
complete -c "pipenv" -f -a '(_carapace_completer "pipenv")'
complete -e "pipesz"
complete -c "pipesz" -f -a '(_carapace_completer "pipesz")'
complete -e "pipx"
complete -c "pipx" -f -a '(_carapace_completer "pipx")'
complete -e "pivot_root"
complete -c "pivot_root" -f -a '(_carapace_completer "pivot_root")'
complete -e "pixi"
complete -c "pixi" -f -a '(_carapace_completer "pixi")'
complete -e "pixz"
complete -c "pixz" -f -a '(_carapace_completer "pixz")'
complete -e "pkcon"
complete -c "pkcon" -f -a '(_carapace_completer "pkcon")'
complete -e "pkg-config"
complete -c "pkg-config" -f -a '(_carapace_completer "pkg-config")'
complete -e "pkgadd"
complete -c "pkgadd" -f -a '(_carapace_completer "pkgadd")'
complete -e "pkginfo"
complete -c "pkginfo" -f -a '(_carapace_completer "pkginfo")'
complete -e "pkgrm"
complete -c "pkgrm" -f -a '(_carapace_completer "pkgrm")'
complete -e "pkgsite"
complete -c "pkgsite" -f -a '(_carapace_completer "pkgsite")'
complete -e "pkill"
complete -c "pkill" -f -a '(_carapace_completer "pkill")'
complete -e "play"
complete -c "play" -f -a '(_carapace_completer "play")'
complete -e "play_ng"
complete -c "play_ng" -f -a '(_carapace_completer "play_ng")'
complete -e "playerctl"
complete -c "playerctl" -f -a '(_carapace_completer "playerctl")'
complete -e "pldd"
complete -c "pldd" -f -a '(_carapace_completer "pldd")'
complete -e "pm2"
complete -c "pm2" -f -a '(_carapace_completer "pm2")'
complete -e "pmake"
complete -c "pmake" -f -a '(_carapace_completer "pmake")'
complete -e "pman"
complete -c "pman" -f -a '(_carapace_completer "pman")'
complete -e "pmap"
complete -c "pmap" -f -a '(_carapace_completer "pmap")'
complete -e "pmcat"
complete -c "pmcat" -f -a '(_carapace_completer "pmcat")'
complete -e "pmdesc"
complete -c "pmdesc" -f -a '(_carapace_completer "pmdesc")'
complete -e "pmeth"
complete -c "pmeth" -f -a '(_carapace_completer "pmeth")'
complete -e "pmexp"
complete -c "pmexp" -f -a '(_carapace_completer "pmexp")'
complete -e "pmfunc"
complete -c "pmfunc" -f -a '(_carapace_completer "pmfunc")'
complete -e "pmload"
complete -c "pmload" -f -a '(_carapace_completer "pmload")'
complete -e "pmls"
complete -c "pmls" -f -a '(_carapace_completer "pmls")'
complete -e "pmpath"
complete -c "pmpath" -f -a '(_carapace_completer "pmpath")'
complete -e "pmvers"
complete -c "pmvers" -f -a '(_carapace_completer "pmvers")'
complete -e "pngcheck"
complete -c "pngcheck" -f -a '(_carapace_completer "pngcheck")'
complete -e "pnpm"
complete -c "pnpm" -f -a '(_carapace_completer "pnpm")'
complete -e "podgrep"
complete -c "podgrep" -f -a '(_carapace_completer "podgrep")'
complete -e "podman"
complete -c "podman" -f -a '(_carapace_completer "podman")'
complete -e "podpath"
complete -c "podpath" -f -a '(_carapace_completer "podpath")'
complete -e "podtoc"
complete -c "podtoc" -f -a '(_carapace_completer "podtoc")'
complete -e "poff"
complete -c "poff" -f -a '(_carapace_completer "poff")'
complete -e "policytool"
complete -c "policytool" -f -a '(_carapace_completer "policytool")'
complete -e "polybar"
complete -c "polybar" -f -a '(_carapace_completer "polybar")'
complete -e "polybar-msg"
complete -c "polybar-msg" -f -a '(_carapace_completer "polybar-msg")'
complete -e "pon"
complete -c "pon" -f -a '(_carapace_completer "pon")'
complete -e "port"
complete -c "port" -f -a '(_carapace_completer "port")'
complete -e "portablectl"
complete -c "portablectl" -f -a '(_carapace_completer "portablectl")'
complete -e "posh"
complete -c "posh" -f -a '(_carapace_completer "posh")'
complete -e "postconf"
complete -c "postconf" -f -a '(_carapace_completer "postconf")'
complete -e "postgres"
complete -c "postgres" -f -a '(_carapace_completer "postgres")'
complete -e "postmaster"
complete -c "postmaster" -f -a '(_carapace_completer "postmaster")'
complete -e "postqueue"
complete -c "postqueue" -f -a '(_carapace_completer "postqueue")'
complete -e "postsuper"
complete -c "postsuper" -f -a '(_carapace_completer "postsuper")'
complete -e "poweroff"
complete -c "poweroff" -f -a '(_carapace_completer "poweroff")'
complete -e "powertop"
complete -c "powertop" -f -a '(_carapace_completer "powertop")'
complete -e "pprof"
complete -c "pprof" -f -a '(_carapace_completer "pprof")'
complete -e "pr"
complete -c "pr" -f -a '(_carapace_completer "pr")'
complete -e "pre-commit"
complete -c "pre-commit" -f -a '(_carapace_completer "pre-commit")'
complete -e "present"
complete -c "present" -f -a '(_carapace_completer "present")'
complete -e "prettybat"
complete -c "prettybat" -f -a '(_carapace_completer "prettybat")'
complete -e "prettyping"
complete -c "prettyping" -f -a '(_carapace_completer "prettyping")'
complete -e "prev"
complete -c "prev" -f -a '(_carapace_completer "prev")'
complete -e "printenv"
complete -c "printenv" -f -a '(_carapace_completer "printenv")'
complete -e "prlimit"
complete -c "prlimit" -f -a '(_carapace_completer "prlimit")'
complete -e "procs"
complete -c "procs" -f -a '(_carapace_completer "procs")'
complete -e "prompt"
complete -c "prompt" -f -a '(_carapace_completer "prompt")'
complete -e "protoc"
complete -c "protoc" -f -a '(_carapace_completer "protoc")'
complete -e "prove"
complete -c "prove" -f -a '(_carapace_completer "prove")'
complete -e "prun"
complete -c "prun" -f -a '(_carapace_completer "prun")'
complete -e "ps"
complete -c "ps" -f -a '(_carapace_completer "ps")'
complete -e "ps2ascii"
complete -c "ps2ascii" -f -a '(_carapace_completer "ps2ascii")'
complete -e "ps2epsi"
complete -c "ps2epsi" -f -a '(_carapace_completer "ps2epsi")'
complete -e "ps2pdf"
complete -c "ps2pdf" -f -a '(_carapace_completer "ps2pdf")'
complete -e "ps2pdf12"
complete -c "ps2pdf12" -f -a '(_carapace_completer "ps2pdf12")'
complete -e "ps2pdf13"
complete -c "ps2pdf13" -f -a '(_carapace_completer "ps2pdf13")'
complete -e "ps2pdf14"
complete -c "ps2pdf14" -f -a '(_carapace_completer "ps2pdf14")'
complete -e "ps2pdfwr"
complete -c "ps2pdfwr" -f -a '(_carapace_completer "ps2pdfwr")'
complete -e "ps2ps"
complete -c "ps2ps" -f -a '(_carapace_completer "ps2ps")'
complete -e "psbook"
complete -c "psbook" -f -a '(_carapace_completer "psbook")'
complete -e "pscale"
complete -c "pscale" -f -a '(_carapace_completer "pscale")'
complete -e "pscap"
complete -c "pscap" -f -a '(_carapace_completer "pscap")'
complete -e "psed"
complete -c "psed" -f -a '(_carapace_completer "psed")'
complete -e "psig"
complete -c "psig" -f -a '(_carapace_completer "psig")'
complete -e "psmerge"
complete -c "psmerge" -f -a '(_carapace_completer "psmerge")'
complete -e "psmulti"
complete -c "psmulti" -f -a '(_carapace_completer "psmulti")'
complete -e "psnup"
complete -c "psnup" -f -a '(_carapace_completer "psnup")'
complete -e "psql"
complete -c "psql" -f -a '(_carapace_completer "psql")'
complete -e "psresize"
complete -c "psresize" -f -a '(_carapace_completer "psresize")'
complete -e "psselect"
complete -c "psselect" -f -a '(_carapace_completer "psselect")'
complete -e "pstack"
complete -c "pstack" -f -a '(_carapace_completer "pstack")'
complete -e "pstoedit"
complete -c "pstoedit" -f -a '(_carapace_completer "pstoedit")'
complete -e "pstop"
complete -c "pstop" -f -a '(_carapace_completer "pstop")'
complete -e "pstops"
complete -c "pstops" -f -a '(_carapace_completer "pstops")'
complete -e "pstotgif"
complete -c "pstotgif" -f -a '(_carapace_completer "pstotgif")'
complete -e "pswrap"
complete -c "pswrap" -f -a '(_carapace_completer "pswrap")'
complete -e "ptx"
complete -c "ptx" -f -a '(_carapace_completer "ptx")'
complete -e "pulseaudio"
complete -c "pulseaudio" -f -a '(_carapace_completer "pulseaudio")'
complete -e "pulumi"
complete -c "pulumi" -f -a '(_carapace_completer "pulumi")'
complete -e "pump"
complete -c "pump" -f -a '(_carapace_completer "pump")'
complete -e "pv"
complete -c "pv" -f -a '(_carapace_completer "pv")'
complete -e "pvchange"
complete -c "pvchange" -f -a '(_carapace_completer "pvchange")'
complete -e "pvck"
complete -c "pvck" -f -a '(_carapace_completer "pvck")'
complete -e "pvcreate"
complete -c "pvcreate" -f -a '(_carapace_completer "pvcreate")'
complete -e "pvdisplay"
complete -c "pvdisplay" -f -a '(_carapace_completer "pvdisplay")'
complete -e "pvmove"
complete -c "pvmove" -f -a '(_carapace_completer "pvmove")'
complete -e "pvremove"
complete -c "pvremove" -f -a '(_carapace_completer "pvremove")'
complete -e "pvresize"
complete -c "pvresize" -f -a '(_carapace_completer "pvresize")'
complete -e "pvs"
complete -c "pvs" -f -a '(_carapace_completer "pvs")'
complete -e "pvscan"
complete -c "pvscan" -f -a '(_carapace_completer "pvscan")'
complete -e "pwait"
complete -c "pwait" -f -a '(_carapace_completer "pwait")'
complete -e "pwd"
complete -c "pwd" -f -a '(_carapace_completer "pwd")'
complete -e "pwdx"
complete -c "pwdx" -f -a '(_carapace_completer "pwdx")'
complete -e "pwgen"
complete -c "pwgen" -f -a '(_carapace_completer "pwgen")'
complete -e "pycharm"
complete -c "pycharm" -f -a '(_carapace_completer "pycharm")'
complete -e "pygmentize"
complete -c "pygmentize" -f -a '(_carapace_completer "pygmentize")'
complete -e "pyhtmlizer"
complete -c "pyhtmlizer" -f -a '(_carapace_completer "pyhtmlizer")'
complete -e "pytest"
complete -c "pytest" -f -a '(_carapace_completer "pytest")'
complete -e "python"
complete -c "python" -f -a '(_carapace_completer "python")'
complete -e "qdbus"
complete -c "qdbus" -f -a '(_carapace_completer "qdbus")'
complete -e "qiv"
complete -c "qiv" -f -a '(_carapace_completer "qiv")'
complete -e "qmicli"
complete -c "qmicli" -f -a '(_carapace_completer "qmicli")'
complete -e "qmk"
complete -c "qmk" -f -a '(_carapace_completer "qmk")'
complete -e "qpdf"
complete -c "qpdf" -f -a '(_carapace_completer "qpdf")'
complete -e "qrencode"
complete -c "qrencode" -f -a '(_carapace_completer "qrencode")'
complete -e "quilt"
complete -c "quilt" -f -a '(_carapace_completer "quilt")'
complete -e "qutebrowser"
complete -c "qutebrowser" -f -a '(_carapace_completer "qutebrowser")'
complete -e "rails"
complete -c "rails" -f -a '(_carapace_completer "rails")'
complete -e "rake"
complete -c "rake" -f -a '(_carapace_completer "rake")'
complete -e "ralio"
complete -c "ralio" -f -a '(_carapace_completer "ralio")'
complete -e "ramalama"
complete -c "ramalama" -f -a '(_carapace_completer "ramalama")'
complete -e "ranger"
complete -c "ranger" -f -a '(_carapace_completer "ranger")'
complete -e "rankmirrors"
complete -c "rankmirrors" -f -a '(_carapace_completer "rankmirrors")'
complete -e "ranlib"
complete -c "ranlib" -f -a '(_carapace_completer "ranlib")'
complete -e "rar"
complete -c "rar" -f -a '(_carapace_completer "rar")'
complete -e "rbw"
complete -c "rbw" -f -a '(_carapace_completer "rbw")'
complete -e "rc"
complete -c "rc" -f -a '(_carapace_completer "rc")'
complete -e "rclone"
complete -c "rclone" -f -a '(_carapace_completer "rclone")'
complete -e "rcp"
complete -c "rcp" -f -a '(_carapace_completer "rcp")'
complete -e "rcs"
complete -c "rcs" -f -a '(_carapace_completer "rcs")'
complete -e "rcsdiff"
complete -c "rcsdiff" -f -a '(_carapace_completer "rcsdiff")'
complete -e "rdesktop"
complete -c "rdesktop" -f -a '(_carapace_completer "rdesktop")'
complete -e "rdfind"
complete -c "rdfind" -f -a '(_carapace_completer "rdfind")'
complete -e "readelf"
complete -c "readelf" -f -a '(_carapace_completer "readelf")'
complete -e "readlink"
complete -c "readlink" -f -a '(_carapace_completer "readlink")'
complete -e "readprofile"
complete -c "readprofile" -f -a '(_carapace_completer "readprofile")'
complete -e "reboot"
complete -c "reboot" -f -a '(_carapace_completer "reboot")'
complete -e "rec"
complete -c "rec" -f -a '(_carapace_completer "rec")'
complete -e "rec_ng"
complete -c "rec_ng" -f -a '(_carapace_completer "rec_ng")'
complete -e "redis-cli"
complete -c "redis-cli" -f -a '(_carapace_completer "redis-cli")'
complete -e "refile"
complete -c "refile" -f -a '(_carapace_completer "refile")'
complete -e "reindexdb"
complete -c "reindexdb" -f -a '(_carapace_completer "reindexdb")'
complete -e "reload"
complete -c "reload" -f -a '(_carapace_completer "reload")'
complete -e "rename"
complete -c "rename" -f -a '(_carapace_completer "rename")'
complete -e "renice"
complete -c "renice" -f -a '(_carapace_completer "renice")'
complete -e "repl"
complete -c "repl" -f -a '(_carapace_completer "repl")'
complete -e "resizepart"
complete -c "resizepart" -f -a '(_carapace_completer "resizepart")'
complete -e "resolvectl"
complete -c "resolvectl" -f -a '(_carapace_completer "resolvectl")'
complete -e "restart"
complete -c "restart" -f -a '(_carapace_completer "restart")'
complete -e "restic"
complete -c "restic" -f -a '(_carapace_completer "restic")'
complete -e "restorecon"
complete -c "restorecon" -f -a '(_carapace_completer "restorecon")'
complete -e "resume-cli"
complete -c "resume-cli" -f -a '(_carapace_completer "resume-cli")'
complete -e "retawq"
complete -c "retawq" -f -a '(_carapace_completer "retawq")'
complete -e "reuse"
complete -c "reuse" -f -a '(_carapace_completer "reuse")'
complete -e "rev"
complete -c "rev" -f -a '(_carapace_completer "rev")'
complete -e "rfkill"
complete -c "rfkill" -f -a '(_carapace_completer "rfkill")'
complete -e "rg"
complete -c "rg" -f -a '(_carapace_completer "rg")'
complete -e "rgrep"
complete -c "rgrep" -f -a '(_carapace_completer "rgrep")'
complete -e "rgview"
complete -c "rgview" -f -a '(_carapace_completer "rgview")'
complete -e "rgvim"
complete -c "rgvim" -f -a '(_carapace_completer "rgvim")'
complete -e "ri"
complete -c "ri" -f -a '(_carapace_completer "ri")'
complete -e "rider"
complete -c "rider" -f -a '(_carapace_completer "rider")'
complete -e "rifle"
complete -c "rifle" -f -a '(_carapace_completer "rifle")'
complete -e "ripsecrets"
complete -c "ripsecrets" -f -a '(_carapace_completer "ripsecrets")'
complete -e "rksh"
complete -c "rksh" -f -a '(_carapace_completer "rksh")'
complete -e "rksh93"
complete -c "rksh93" -f -a '(_carapace_completer "rksh93")'
complete -e "rlogin"
complete -c "rlogin" -f -a '(_carapace_completer "rlogin")'
complete -e "rm"
complete -c "rm" -f -a '(_carapace_completer "rm")'
complete -e "rmaxima"
complete -c "rmaxima" -f -a '(_carapace_completer "rmaxima")'
complete -e "rmd160"
complete -c "rmd160" -f -a '(_carapace_completer "rmd160")'
complete -e "rmdir"
complete -c "rmdir" -f -a '(_carapace_completer "rmdir")'
complete -e "rmf"
complete -c "rmf" -f -a '(_carapace_completer "rmf")'
complete -e "rmic"
complete -c "rmic" -f -a '(_carapace_completer "rmic")'
complete -e "rmid"
complete -c "rmid" -f -a '(_carapace_completer "rmid")'
complete -e "rmiregistry"
complete -c "rmiregistry" -f -a '(_carapace_completer "rmiregistry")'
complete -e "rmlint"
complete -c "rmlint" -f -a '(_carapace_completer "rmlint")'
complete -e "rmlint.sh"
complete -c "rmlint.sh" -f -a '(_carapace_completer "rmlint.sh")'
complete -e "rmm"
complete -c "rmm" -f -a '(_carapace_completer "rmm")'
complete -e "rmmod"
complete -c "rmmod" -f -a '(_carapace_completer "rmmod")'
complete -e "rnano"
complete -c "rnano" -f -a '(_carapace_completer "rnano")'
complete -e "route"
complete -c "route" -f -a '(_carapace_completer "route")'
complete -e "rrdtool"
complete -c "rrdtool" -f -a '(_carapace_completer "rrdtool")'
complete -e "rsh"
complete -c "rsh" -f -a '(_carapace_completer "rsh")'
complete -e "rslsync"
complete -c "rslsync" -f -a '(_carapace_completer "rslsync")'
complete -e "rspec"
complete -c "rspec" -f -a '(_carapace_completer "rspec")'
complete -e "rsync"
complete -c "rsync" -f -a '(_carapace_completer "rsync")'
complete -e "rtcwake"
complete -c "rtcwake" -f -a '(_carapace_completer "rtcwake")'
complete -e "rtin"
complete -c "rtin" -f -a '(_carapace_completer "rtin")'
complete -e "rubber"
complete -c "rubber" -f -a '(_carapace_completer "rubber")'
complete -e "rubber-info"
complete -c "rubber-info" -f -a '(_carapace_completer "rubber-info")'
complete -e "rubber-pipe"
complete -c "rubber-pipe" -f -a '(_carapace_completer "rubber-pipe")'
complete -e "rubocop"
complete -c "rubocop" -f -a '(_carapace_completer "rubocop")'
complete -e "ruby"
complete -c "ruby" -f -a '(_carapace_completer "ruby")'
complete -e "ruby-mri"
complete -c "ruby-mri" -f -a '(_carapace_completer "ruby-mri")'
complete -e "rubymine"
complete -c "rubymine" -f -a '(_carapace_completer "rubymine")'
complete -e "run-help"
complete -c "run-help" -f -a '(_carapace_completer "run-help")'
complete -e "run0"
complete -c "run0" -f -a '(_carapace_completer "run0")'
complete -e "runc"
complete -c "runc" -f -a '(_carapace_completer "runc")'
complete -e "runcon"
complete -c "runcon" -f -a '(_carapace_completer "runcon")'
complete -e "runuser"
complete -c "runuser" -f -a '(_carapace_completer "runuser")'
complete -e "rup"
complete -c "rup" -f -a '(_carapace_completer "rup")'
complete -e "rusage"
complete -c "rusage" -f -a '(_carapace_completer "rusage")'
complete -e "rust-analyzer"
complete -c "rust-analyzer" -f -a '(_carapace_completer "rust-analyzer")'
complete -e "rustc"
complete -c "rustc" -f -a '(_carapace_completer "rustc")'
complete -e "rustdoc"
complete -c "rustdoc" -f -a '(_carapace_completer "rustdoc")'
complete -e "rustrover"
complete -c "rustrover" -f -a '(_carapace_completer "rustrover")'
complete -e "rustup"
complete -c "rustup" -f -a '(_carapace_completer "rustup")'
complete -e "rview"
complete -c "rview" -f -a '(_carapace_completer "rview")'
complete -e "rvim"
complete -c "rvim" -f -a '(_carapace_completer "rvim")'
complete -e "rwho"
complete -c "rwho" -f -a '(_carapace_completer "rwho")'
complete -e "rxvt"
complete -c "rxvt" -f -a '(_carapace_completer "rxvt")'
complete -e "s2p"
complete -c "s2p" -f -a '(_carapace_completer "s2p")'
complete -e "sadf"
complete -c "sadf" -f -a '(_carapace_completer "sadf")'
complete -e "sahara"
complete -c "sahara" -f -a '(_carapace_completer "sahara")'
complete -e "sar"
complete -c "sar" -f -a '(_carapace_completer "sar")'
complete -e "saw"
complete -c "saw" -f -a '(_carapace_completer "saw")'
complete -e "sbt"
complete -c "sbt" -f -a '(_carapace_completer "sbt")'
complete -e "scala"
complete -c "scala" -f -a '(_carapace_completer "scala")'
complete -e "scalac"
complete -c "scalac" -f -a '(_carapace_completer "scalac")'
complete -e "scan"
complete -c "scan" -f -a '(_carapace_completer "scan")'
complete -e "scc"
complete -c "scc" -f -a '(_carapace_completer "scc")'
complete -e "sccs"
complete -c "sccs" -f -a '(_carapace_completer "sccs")'
complete -e "sccsdiff"
complete -c "sccsdiff" -f -a '(_carapace_completer "sccsdiff")'
complete -e "schedtool"
complete -c "schedtool" -f -a '(_carapace_completer "schedtool")'
complete -e "scons"
complete -c "scons" -f -a '(_carapace_completer "scons")'
complete -e "scp"
complete -c "scp" -f -a '(_carapace_completer "scp")'
complete -e "scrcpy"
complete -c "scrcpy" -f -a '(_carapace_completer "scrcpy")'
complete -e "scrcpy.exe"
complete -c "scrcpy.exe" -f -a '(_carapace_completer "scrcpy.exe")'
complete -e "screen"
complete -c "screen" -f -a '(_carapace_completer "screen")'
complete -e "screencapture"
complete -c "screencapture" -f -a '(_carapace_completer "screencapture")'
complete -e "script"
complete -c "script" -f -a '(_carapace_completer "script")'
complete -e "scriptlive"
complete -c "scriptlive" -f -a '(_carapace_completer "scriptlive")'
complete -e "scriptreplay"
complete -c "scriptreplay" -f -a '(_carapace_completer "scriptreplay")'
complete -e "scrot"
complete -c "scrot" -f -a '(_carapace_completer "scrot")'
complete -e "scrub"
complete -c "scrub" -f -a '(_carapace_completer "scrub")'
complete -e "sd"
complete -c "sd" -f -a '(_carapace_completer "sd")'
complete -e "sdd"
complete -c "sdd" -f -a '(_carapace_completer "sdd")'
complete -e "sdkmanager"
complete -c "sdkmanager" -f -a '(_carapace_completer "sdkmanager")'
complete -e "seaf-cli"
complete -c "seaf-cli" -f -a '(_carapace_completer "seaf-cli")'
complete -e "sealert"
complete -c "sealert" -f -a '(_carapace_completer "sealert")'
complete -e "secon"
complete -c "secon" -f -a '(_carapace_completer "secon")'
complete -e "secret-tool"
complete -c "secret-tool" -f -a '(_carapace_completer "secret-tool")'
complete -e "sed"
complete -c "sed" -f -a '(_carapace_completer "sed")'
complete -e "sedismod"
complete -c "sedismod" -f -a '(_carapace_completer "sedismod")'
complete -e "sedta"
complete -c "sedta" -f -a '(_carapace_completer "sedta")'
complete -e "seinfo"
complete -c "seinfo" -f -a '(_carapace_completer "seinfo")'
complete -e "selinuxconlist"
complete -c "selinuxconlist" -f -a '(_carapace_completer "selinuxconlist")'
complete -e "selinuxdefcon"
complete -c "selinuxdefcon" -f -a '(_carapace_completer "selinuxdefcon")'
complete -e "selinuxexeccon"
complete -c "selinuxexeccon" -f -a '(_carapace_completer "selinuxexeccon")'
complete -e "semanage"
complete -c "semanage" -f -a '(_carapace_completer "semanage")'
complete -e "semodule"
complete -c "semodule" -f -a '(_carapace_completer "semodule")'
complete -e "semodule_unpackage"
complete -c "semodule_unpackage" -f -a '(_carapace_completer "semodule_unpackage")'
complete -e "semver"
complete -c "semver" -f -a '(_carapace_completer "semver")'
complete -e "senlin"
complete -c "senlin" -f -a '(_carapace_completer "senlin")'
complete -e "sensors"
complete -c "sensors" -f -a '(_carapace_completer "sensors")'
complete -e "sensors-detect"
complete -c "sensors-detect" -f -a '(_carapace_completer "sensors-detect")'
complete -e "sepolgen"
complete -c "sepolgen" -f -a '(_carapace_completer "sepolgen")'
complete -e "sepolicy"
complete -c "sepolicy" -f -a '(_carapace_completer "sepolicy")'
complete -e "seq"
complete -c "seq" -f -a '(_carapace_completer "seq")'
complete -e "serialver"
complete -c "serialver" -f -a '(_carapace_completer "serialver")'
complete -e "serie"
complete -c "serie" -f -a '(_carapace_completer "serie")'
complete -e "service"
complete -c "service" -f -a '(_carapace_completer "service")'
complete -e "sesearch"
complete -c "sesearch" -f -a '(_carapace_completer "sesearch")'
complete -e "sestatus"
complete -c "sestatus" -f -a '(_carapace_completer "sestatus")'
complete -e "set-env"
complete -c "set-env" -f -a '(_carapace_completer "set-env")'
complete -e "setarch"
complete -c "setarch" -f -a '(_carapace_completer "setarch")'
complete -e "setcap"
complete -c "setcap" -f -a '(_carapace_completer "setcap")'
complete -e "setenforce"
complete -c "setenforce" -f -a '(_carapace_completer "setenforce")'
complete -e "setfacl"
complete -c "setfacl" -f -a '(_carapace_completer "setfacl")'
complete -e "setfacl.exe"
complete -c "setfacl.exe" -f -a '(_carapace_completer "setfacl.exe")'
complete -e "setfattr"
complete -c "setfattr" -f -a '(_carapace_completer "setfattr")'
complete -e "setpgid"
complete -c "setpgid" -f -a '(_carapace_completer "setpgid")'
complete -e "setpriv"
complete -c "setpriv" -f -a '(_carapace_completer "setpriv")'
complete -e "setsebool"
complete -c "setsebool" -f -a '(_carapace_completer "setsebool")'
complete -e "setsid"
complete -c "setsid" -f -a '(_carapace_completer "setsid")'
complete -e "setterm"
complete -c "setterm" -f -a '(_carapace_completer "setterm")'
complete -e "setup.py"
complete -c "setup.py" -f -a '(_carapace_completer "setup.py")'
complete -e "setxkbmap"
complete -c "setxkbmap" -f -a '(_carapace_completer "setxkbmap")'
complete -e "sfdisk"
complete -c "sfdisk" -f -a '(_carapace_completer "sfdisk")'
complete -e "sftp"
complete -c "sftp" -f -a '(_carapace_completer "sftp")'
complete -e "sh"
complete -c "sh" -f -a '(_carapace_completer "sh")'
complete -e "sha1"
complete -c "sha1" -f -a '(_carapace_completer "sha1")'
complete -e "sha1sum"
complete -c "sha1sum" -f -a '(_carapace_completer "sha1sum")'
complete -e "sha224sum"
complete -c "sha224sum" -f -a '(_carapace_completer "sha224sum")'
complete -e "sha256"
complete -c "sha256" -f -a '(_carapace_completer "sha256")'
complete -e "sha256sum"
complete -c "sha256sum" -f -a '(_carapace_completer "sha256sum")'
complete -e "sha384"
complete -c "sha384" -f -a '(_carapace_completer "sha384")'
complete -e "sha384sum"
complete -c "sha384sum" -f -a '(_carapace_completer "sha384sum")'
complete -e "sha512"
complete -c "sha512" -f -a '(_carapace_completer "sha512")'
complete -e "sha512sum"
complete -c "sha512sum" -f -a '(_carapace_completer "sha512sum")'
complete -e "sha512t256"
complete -c "sha512t256" -f -a '(_carapace_completer "sha512t256")'
complete -e "shallow-backup"
complete -c "shallow-backup" -f -a '(_carapace_completer "shallow-backup")'
complete -e "shasum"
complete -c "shasum" -f -a '(_carapace_completer "shasum")'
complete -e "shellcheck"
complete -c "shellcheck" -f -a '(_carapace_completer "shellcheck")'
complete -e "show"
complete -c "show" -f -a '(_carapace_completer "show")'
complete -e "showchar"
complete -c "showchar" -f -a '(_carapace_completer "showchar")'
complete -e "showkey"
complete -c "showkey" -f -a '(_carapace_completer "showkey")'
complete -e "showmount"
complete -c "showmount" -f -a '(_carapace_completer "showmount")'
complete -e "showoff"
complete -c "showoff" -f -a '(_carapace_completer "showoff")'
complete -e "shred"
complete -c "shred" -f -a '(_carapace_completer "shred")'
complete -e "shtab"
complete -c "shtab" -f -a '(_carapace_completer "shtab")'
complete -e "shuf"
complete -c "shuf" -f -a '(_carapace_completer "shuf")'
complete -e "shutdown"
complete -c "shutdown" -f -a '(_carapace_completer "shutdown")'
complete -e "singularity"
complete -c "singularity" -f -a '(_carapace_completer "singularity")'
complete -e "sioyek"
complete -c "sioyek" -f -a '(_carapace_completer "sioyek")'
complete -e "sisu"
complete -c "sisu" -f -a '(_carapace_completer "sisu")'
complete -e "skein1024"
complete -c "skein1024" -f -a '(_carapace_completer "skein1024")'
complete -e "skein256"
complete -c "skein256" -f -a '(_carapace_completer "skein256")'
complete -e "skein512"
complete -c "skein512" -f -a '(_carapace_completer "skein512")'
complete -e "skipstone"
complete -c "skipstone" -f -a '(_carapace_completer "skipstone")'
complete -e "slabtop"
complete -c "slabtop" -f -a '(_carapace_completer "slabtop")'
complete -e "sleep"
complete -c "sleep" -f -a '(_carapace_completer "sleep")'
complete -e "slides"
complete -c "slides" -f -a '(_carapace_completer "slides")'
complete -e "slitex"
complete -c "slitex" -f -a '(_carapace_completer "slitex")'
complete -e "slocate"
complete -c "slocate" -f -a '(_carapace_completer "slocate")'
complete -e "slrn"
complete -c "slrn" -f -a '(_carapace_completer "slrn")'
complete -e "slsa-verifier"
complete -c "slsa-verifier" -f -a '(_carapace_completer "slsa-verifier")'
complete -e "smartctl"
complete -c "smartctl" -f -a '(_carapace_completer "smartctl")'
complete -e "smbclient"
complete -c "smbclient" -f -a '(_carapace_completer "smbclient")'
complete -e "smbcontrol"
complete -c "smbcontrol" -f -a '(_carapace_completer "smbcontrol")'
complete -e "smbstatus"
complete -c "smbstatus" -f -a '(_carapace_completer "smbstatus")'
complete -e "soa"
complete -c "soa" -f -a '(_carapace_completer "soa")'
complete -e "socket"
complete -c "socket" -f -a '(_carapace_completer "socket")'
complete -e "soft"
complete -c "soft" -f -a '(_carapace_completer "soft")'
complete -e "sort"
complete -c "sort" -f -a '(_carapace_completer "sort")'
complete -e "sortm"
complete -c "sortm" -f -a '(_carapace_completer "sortm")'
complete -e "source-highlight"
complete -c "source-highlight" -f -a '(_carapace_completer "source-highlight")'
complete -e "sox"
complete -c "sox" -f -a '(_carapace_completer "sox")'
complete -e "sox_ng"
complete -c "sox_ng" -f -a '(_carapace_completer "sox_ng")'
complete -e "soxi"
complete -c "soxi" -f -a '(_carapace_completer "soxi")'
complete -e "soxi_ng"
complete -c "soxi_ng" -f -a '(_carapace_completer "soxi_ng")'
complete -e "spamassassin"
complete -c "spamassassin" -f -a '(_carapace_completer "spamassassin")'
complete -e "speedtest-cli"
complete -c "speedtest-cli" -f -a '(_carapace_completer "speedtest-cli")'
complete -e "split"
complete -c "split" -f -a '(_carapace_completer "split")'
complete -e "splitdiff"
complete -c "splitdiff" -f -a '(_carapace_completer "splitdiff")'
complete -e "spring"
complete -c "spring" -f -a '(_carapace_completer "spring")'
complete -e "sqlite"
complete -c "sqlite" -f -a '(_carapace_completer "sqlite")'
complete -e "sqlite3"
complete -c "sqlite3" -f -a '(_carapace_completer "sqlite3")'
complete -e "sqsh"
complete -c "sqsh" -f -a '(_carapace_completer "sqsh")'
complete -e "sr"
complete -c "sr" -f -a '(_carapace_completer "sr")'
complete -e "srm"
complete -c "srm" -f -a '(_carapace_completer "srm")'
complete -e "srptool"
complete -c "srptool" -f -a '(_carapace_completer "srptool")'
complete -e "ss"
complete -c "ss" -f -a '(_carapace_completer "ss")'
complete -e "ssh"
complete -c "ssh" -f -a '(_carapace_completer "ssh")'
complete -e "ssh-add"
complete -c "ssh-add" -f -a '(_carapace_completer "ssh-add")'
complete -e "ssh-agent"
complete -c "ssh-agent" -f -a '(_carapace_completer "ssh-agent")'
complete -e "ssh-copy-id"
complete -c "ssh-copy-id" -f -a '(_carapace_completer "ssh-copy-id")'
complete -e "ssh-keygen"
complete -c "ssh-keygen" -f -a '(_carapace_completer "ssh-keygen")'
complete -e "ssh-keyscan"
complete -c "ssh-keyscan" -f -a '(_carapace_completer "ssh-keyscan")'
complete -e "sshfs"
complete -c "sshfs" -f -a '(_carapace_completer "sshfs")'
complete -e "sslscan"
complete -c "sslscan" -f -a '(_carapace_completer "sslscan")'
complete -e "st"
complete -c "st" -f -a '(_carapace_completer "st")'
complete -e "star"
complete -c "star" -f -a '(_carapace_completer "star")'
complete -e "starship"
complete -c "starship" -f -a '(_carapace_completer "starship")'
complete -e "start"
complete -c "start" -f -a '(_carapace_completer "start")'
complete -e "stat"
complete -c "stat" -f -a '(_carapace_completer "stat")'
complete -e "staticcheck"
complete -c "staticcheck" -f -a '(_carapace_completer "staticcheck")'
complete -e "status"
complete -c "status" -f -a '(_carapace_completer "status")'
complete -e "stdbuf"
complete -c "stdbuf" -f -a '(_carapace_completer "stdbuf")'
complete -e "stop"
complete -c "stop" -f -a '(_carapace_completer "stop")'
complete -e "storagectl"
complete -c "storagectl" -f -a '(_carapace_completer "storagectl")'
complete -e "stow"
complete -c "stow" -f -a '(_carapace_completer "stow")'
complete -e "strace"
complete -c "strace" -f -a '(_carapace_completer "strace")'
complete -e "strace64"
complete -c "strace64" -f -a '(_carapace_completer "strace64")'
complete -e "strings"
complete -c "strings" -f -a '(_carapace_completer "strings")'
complete -e "strip"
complete -c "strip" -f -a '(_carapace_completer "strip")'
complete -e "strongswan"
complete -c "strongswan" -f -a '(_carapace_completer "strongswan")'
complete -e "stty"
complete -c "stty" -f -a '(_carapace_completer "stty")'
complete -e "su"
complete -c "su" -f -a '(_carapace_completer "su")'
complete -e "subl"
complete -c "subl" -f -a '(_carapace_completer "subl")'
complete -e "subliminal"
complete -c "subliminal" -f -a '(_carapace_completer "subliminal")'
complete -e "sudo"
complete -c "sudo" -f -a '(_carapace_completer "sudo")'
complete -e "sudoedit"
complete -c "sudoedit" -f -a '(_carapace_completer "sudoedit")'
complete -e "sudoreplay"
complete -c "sudoreplay" -f -a '(_carapace_completer "sudoreplay")'
complete -e "sulogin"
complete -c "sulogin" -f -a '(_carapace_completer "sulogin")'
complete -e "sum"
complete -c "sum" -f -a '(_carapace_completer "sum")'
complete -e "supervisorctl"
complete -c "supervisorctl" -f -a '(_carapace_completer "supervisorctl")'
complete -e "supervisord"
complete -c "supervisord" -f -a '(_carapace_completer "supervisord")'
complete -e "surfraw"
complete -c "surfraw" -f -a '(_carapace_completer "surfraw")'
complete -e "sv"
complete -c "sv" -f -a '(_carapace_completer "sv")'
complete -e "svg-term"
complete -c "svg-term" -f -a '(_carapace_completer "svg-term")'
complete -e "svgcleaner"
complete -c "svgcleaner" -f -a '(_carapace_completer "svgcleaner")'
complete -e "svm"
complete -c "svm" -f -a '(_carapace_completer "svm")'
complete -e "svn"
complete -c "svn" -f -a '(_carapace_completer "svn")'
complete -e "svnadmin"
complete -c "svnadmin" -f -a '(_carapace_completer "svnadmin")'
complete -e "swaks"
complete -c "swaks" -f -a '(_carapace_completer "swaks")'
complete -e "swanctl"
complete -c "swanctl" -f -a '(_carapace_completer "swanctl")'
complete -e "swaplabel"
complete -c "swaplabel" -f -a '(_carapace_completer "swaplabel")'
complete -e "swapoff"
complete -c "swapoff" -f -a '(_carapace_completer "swapoff")'
complete -e "swapon"
complete -c "swapon" -f -a '(_carapace_completer "swapon")'
complete -e "sway"
complete -c "sway" -f -a '(_carapace_completer "sway")'
complete -e "swaybar"
complete -c "swaybar" -f -a '(_carapace_completer "swaybar")'
complete -e "swaybg"
complete -c "swaybg" -f -a '(_carapace_completer "swaybg")'
complete -e "swayidle"
complete -c "swayidle" -f -a '(_carapace_completer "swayidle")'
complete -e "swaylock"
complete -c "swaylock" -f -a '(_carapace_completer "swaylock")'
complete -e "swaymsg"
complete -c "swaymsg" -f -a '(_carapace_completer "swaymsg")'
complete -e "swaynag"
complete -c "swaynag" -f -a '(_carapace_completer "swaynag")'
complete -e "swift"
complete -c "swift" -f -a '(_carapace_completer "swift")'
complete -e "swiftc"
complete -c "swiftc" -f -a '(_carapace_completer "swiftc")'
complete -e "syft"
complete -c "syft" -f -a '(_carapace_completer "syft")'
complete -e "sync"
complete -c "sync" -f -a '(_carapace_completer "sync")'
complete -e "sysctl"
complete -c "sysctl" -f -a '(_carapace_completer "sysctl")'
complete -e "systemctl"
complete -c "systemctl" -f -a '(_carapace_completer "systemctl")'
complete -e "systemd-analyze"
complete -c "systemd-analyze" -f -a '(_carapace_completer "systemd-analyze")'
complete -e "systemd-ask-password"
complete -c "systemd-ask-password" -f -a '(_carapace_completer "systemd-ask-password")'
complete -e "systemd-cat"
complete -c "systemd-cat" -f -a '(_carapace_completer "systemd-cat")'
complete -e "systemd-cgls"
complete -c "systemd-cgls" -f -a '(_carapace_completer "systemd-cgls")'
complete -e "systemd-cgtop"
complete -c "systemd-cgtop" -f -a '(_carapace_completer "systemd-cgtop")'
complete -e "systemd-confext"
complete -c "systemd-confext" -f -a '(_carapace_completer "systemd-confext")'
complete -e "systemd-creds"
complete -c "systemd-creds" -f -a '(_carapace_completer "systemd-creds")'
complete -e "systemd-cryptenroll"
complete -c "systemd-cryptenroll" -f -a '(_carapace_completer "systemd-cryptenroll")'
complete -e "systemd-delta"
complete -c "systemd-delta" -f -a '(_carapace_completer "systemd-delta")'
complete -e "systemd-detect-virt"
complete -c "systemd-detect-virt" -f -a '(_carapace_completer "systemd-detect-virt")'
complete -e "systemd-dissect"
complete -c "systemd-dissect" -f -a '(_carapace_completer "systemd-dissect")'
complete -e "systemd-hwdb"
complete -c "systemd-hwdb" -f -a '(_carapace_completer "systemd-hwdb")'
complete -e "systemd-id128"
complete -c "systemd-id128" -f -a '(_carapace_completer "systemd-id128")'
complete -e "systemd-inhibit"
complete -c "systemd-inhibit" -f -a '(_carapace_completer "systemd-inhibit")'
complete -e "systemd-machine-id-setup"
complete -c "systemd-machine-id-setup" -f -a '(_carapace_completer "systemd-machine-id-setup")'
complete -e "systemd-notify"
complete -c "systemd-notify" -f -a '(_carapace_completer "systemd-notify")'
complete -e "systemd-nspawn"
complete -c "systemd-nspawn" -f -a '(_carapace_completer "systemd-nspawn")'
complete -e "systemd-path"
complete -c "systemd-path" -f -a '(_carapace_completer "systemd-path")'
complete -e "systemd-resolve"
complete -c "systemd-resolve" -f -a '(_carapace_completer "systemd-resolve")'
complete -e "systemd-run"
complete -c "systemd-run" -f -a '(_carapace_completer "systemd-run")'
complete -e "systemd-sysext"
complete -c "systemd-sysext" -f -a '(_carapace_completer "systemd-sysext")'
complete -e "systemd-sysinstall"
complete -c "systemd-sysinstall" -f -a '(_carapace_completer "systemd-sysinstall")'
complete -e "systemd-tmpfiles"
complete -c "systemd-tmpfiles" -f -a '(_carapace_completer "systemd-tmpfiles")'
complete -e "systemd-tty-ask-password-agent"
complete -c "systemd-tty-ask-password-agent" -f -a '(_carapace_completer "systemd-tty-ask-password-agent")'
complete -e "systemd-vmspawn"
complete -c "systemd-vmspawn" -f -a '(_carapace_completer "systemd-vmspawn")'
complete -e "systemd-vpick"
complete -c "systemd-vpick" -f -a '(_carapace_completer "systemd-vpick")'
complete -e "tac"
complete -c "tac" -f -a '(_carapace_completer "tac")'
complete -e "tacker"
complete -c "tacker" -f -a '(_carapace_completer "tacker")'
complete -e "tail"
complete -c "tail" -f -a '(_carapace_completer "tail")'
complete -e "talk"
complete -c "talk" -f -a '(_carapace_completer "talk")'
complete -e "talosctl"
complete -c "talosctl" -f -a '(_carapace_completer "talosctl")'
complete -e "taplo"
complete -c "taplo" -f -a '(_carapace_completer "taplo")'
complete -e "tar"
complete -c "tar" -f -a '(_carapace_completer "tar")'
complete -e "tardy"
complete -c "tardy" -f -a '(_carapace_completer "tardy")'
complete -e "task"
complete -c "task" -f -a '(_carapace_completer "task")'
complete -e "taskset"
complete -c "taskset" -f -a '(_carapace_completer "taskset")'
complete -e "tc"
complete -c "tc" -f -a '(_carapace_completer "tc")'
complete -e "tcp_open"
complete -c "tcp_open" -f -a '(_carapace_completer "tcp_open")'
complete -e "tcpdump"
complete -c "tcpdump" -f -a '(_carapace_completer "tcpdump")'
complete -e "tcptraceroute"
complete -c "tcptraceroute" -f -a '(_carapace_completer "tcptraceroute")'
complete -e "tcsh"
complete -c "tcsh" -f -a '(_carapace_completer "tcsh")'
complete -e "tda"
complete -c "tda" -f -a '(_carapace_completer "tda")'
complete -e "tdd"
complete -c "tdd" -f -a '(_carapace_completer "tdd")'
complete -e "tde"
complete -c "tde" -f -a '(_carapace_completer "tde")'
complete -e "tdr"
complete -c "tdr" -f -a '(_carapace_completer "tdr")'
complete -e "tea"
complete -c "tea" -f -a '(_carapace_completer "tea")'
complete -e "teamocil"
complete -c "teamocil" -f -a '(_carapace_completer "teamocil")'
complete -e "tee"
complete -c "tee" -f -a '(_carapace_completer "tee")'
complete -e "telnet"
complete -c "telnet" -f -a '(_carapace_completer "telnet")'
complete -e "templ"
complete -c "templ" -f -a '(_carapace_completer "templ")'
complete -e "termux-apt-repo"
complete -c "termux-apt-repo" -f -a '(_carapace_completer "termux-apt-repo")'
complete -e "terraform"
complete -c "terraform" -f -a '(_carapace_completer "terraform")'
complete -e "terraform-ls"
complete -c "terraform-ls" -f -a '(_carapace_completer "terraform-ls")'
complete -e "terragrunt"
complete -c "terragrunt" -f -a '(_carapace_completer "terragrunt")'
complete -e "terramate"
complete -c "terramate" -f -a '(_carapace_completer "terramate")'
complete -e "tesseract"
complete -c "tesseract" -f -a '(_carapace_completer "tesseract")'
complete -e "tex"
complete -c "tex" -f -a '(_carapace_completer "tex")'
complete -e "texdoc"
complete -c "texdoc" -f -a '(_carapace_completer "texdoc")'
complete -e "texi2any"
complete -c "texi2any" -f -a '(_carapace_completer "texi2any")'
complete -e "texi2dvi"
complete -c "texi2dvi" -f -a '(_carapace_completer "texi2dvi")'
complete -e "texi2pdf"
complete -c "texi2pdf" -f -a '(_carapace_completer "texi2pdf")'
complete -e "texindex"
complete -c "texindex" -f -a '(_carapace_completer "texindex")'
complete -e "textutil"
complete -c "textutil" -f -a '(_carapace_completer "textutil")'
complete -e "tg"
complete -c "tg" -f -a '(_carapace_completer "tg")'
complete -e "thor"
complete -c "thor" -f -a '(_carapace_completer "thor")'
complete -e "tidy"
complete -c "tidy" -f -a '(_carapace_completer "tidy")'
complete -e "tig"
complete -c "tig" -f -a '(_carapace_completer "tig")'
complete -e "time"
complete -c "time" -f -a '(_carapace_completer "time")'
complete -e "timedatectl"
complete -c "timedatectl" -f -a '(_carapace_completer "timedatectl")'
complete -e "timeout"
complete -c "timeout" -f -a '(_carapace_completer "timeout")'
complete -e "timew"
complete -c "timew" -f -a '(_carapace_completer "timew")'
complete -e "tin"
complete -c "tin" -f -a '(_carapace_completer "tin")'
complete -e "tinygo"
complete -c "tinygo" -f -a '(_carapace_completer "tinygo")'
complete -e "tinysparql"
complete -c "tinysparql" -f -a '(_carapace_completer "tinysparql")'
complete -e "tkconch"
complete -c "tkconch" -f -a '(_carapace_completer "tkconch")'
complete -e "tkinfo"
complete -c "tkinfo" -f -a '(_carapace_completer "tkinfo")'
complete -e "tla"
complete -c "tla" -f -a '(_carapace_completer "tla")'
complete -e "tldr"
complete -c "tldr" -f -a '(_carapace_completer "tldr")'
complete -e "tload"
complete -c "tload" -f -a '(_carapace_completer "tload")'
complete -e "tmate"
complete -c "tmate" -f -a '(_carapace_completer "tmate")'
complete -e "tmux"
complete -c "tmux" -f -a '(_carapace_completer "tmux")'
complete -e "tmuxinator"
complete -c "tmuxinator" -f -a '(_carapace_completer "tmuxinator")'
complete -e "todo"
complete -c "todo" -f -a '(_carapace_completer "todo")'
complete -e "todo.sh"
complete -c "todo.sh" -f -a '(_carapace_completer "todo.sh")'
complete -e "tofu"
complete -c "tofu" -f -a '(_carapace_completer "tofu")'
complete -e "toilet"
complete -c "toilet" -f -a '(_carapace_completer "toilet")'
complete -e "toit.lsp"
complete -c "toit.lsp" -f -a '(_carapace_completer "toit.lsp")'
complete -e "toit.pkg"
complete -c "toit.pkg" -f -a '(_carapace_completer "toit.pkg")'
complete -e "toolbox"
complete -c "toolbox" -f -a '(_carapace_completer "toolbox")'
complete -e "top"
complete -c "top" -f -a '(_carapace_completer "top")'
complete -e "tor-browser"
complete -c "tor-browser" -f -a '(_carapace_completer "tor-browser")'
complete -e "tor-gencert"
complete -c "tor-gencert" -f -a '(_carapace_completer "tor-gencert")'
complete -e "tor-print-ed-signing-cert"
complete -c "tor-print-ed-signing-cert" -f -a '(_carapace_completer "tor-print-ed-signing-cert")'
complete -e "tor-resolve"
complete -c "tor-resolve" -f -a '(_carapace_completer "tor-resolve")'
complete -e "torsocks"
complete -c "torsocks" -f -a '(_carapace_completer "torsocks")'
complete -e "totdconfig"
complete -c "totdconfig" -f -a '(_carapace_completer "totdconfig")'
complete -e "touch"
complete -c "touch" -f -a '(_carapace_completer "touch")'
complete -e "tox"
complete -c "tox" -f -a '(_carapace_completer "tox")'
complete -e "tpb"
complete -c "tpb" -f -a '(_carapace_completer "tpb")'
complete -e "tput"
complete -c "tput" -f -a '(_carapace_completer "tput")'
complete -e "tr"
complete -c "tr" -f -a '(_carapace_completer "tr")'
complete -e "tracefs_sql"
complete -c "tracefs_sql" -f -a '(_carapace_completer "tracefs_sql")'
complete -e "tracepath"
complete -c "tracepath" -f -a '(_carapace_completer "tracepath")'
complete -e "tracepath6"
complete -c "tracepath6" -f -a '(_carapace_completer "tracepath6")'
complete -e "traceroute"
complete -c "traceroute" -f -a '(_carapace_completer "traceroute")'
complete -e "traefik"
complete -c "traefik" -f -a '(_carapace_completer "traefik")'
complete -e "transmission-cli"
complete -c "transmission-cli" -f -a '(_carapace_completer "transmission-cli")'
complete -e "transmission-create"
complete -c "transmission-create" -f -a '(_carapace_completer "transmission-create")'
complete -e "transmission-daemon"
complete -c "transmission-daemon" -f -a '(_carapace_completer "transmission-daemon")'
complete -e "transmission-edit"
complete -c "transmission-edit" -f -a '(_carapace_completer "transmission-edit")'
complete -e "transmission-remote"
complete -c "transmission-remote" -f -a '(_carapace_completer "transmission-remote")'
complete -e "transmission-show"
complete -c "transmission-show" -f -a '(_carapace_completer "transmission-show")'
complete -e "trash"
complete -c "trash" -f -a '(_carapace_completer "trash")'
complete -e "trash-empty"
complete -c "trash-empty" -f -a '(_carapace_completer "trash-empty")'
complete -e "trash-list"
complete -c "trash-list" -f -a '(_carapace_completer "trash-list")'
complete -e "trash-put"
complete -c "trash-put" -f -a '(_carapace_completer "trash-put")'
complete -e "trash-restore"
complete -c "trash-restore" -f -a '(_carapace_completer "trash-restore")'
complete -e "tree"
complete -c "tree" -f -a '(_carapace_completer "tree")'
complete -e "trial"
complete -c "trial" -f -a '(_carapace_completer "trial")'
complete -e "trip"
complete -c "trip" -f -a '(_carapace_completer "trip")'
complete -e "trippy"
complete -c "trippy" -f -a '(_carapace_completer "trippy")'
complete -e "trivy"
complete -c "trivy" -f -a '(_carapace_completer "trivy")'
complete -e "trove"
complete -c "trove" -f -a '(_carapace_completer "trove")'
complete -e "truncate"
complete -c "truncate" -f -a '(_carapace_completer "truncate")'
complete -e "truss"
complete -c "truss" -f -a '(_carapace_completer "truss")'
complete -e "trust"
complete -c "trust" -f -a '(_carapace_completer "trust")'
complete -e "tryaffix"
complete -c "tryaffix" -f -a '(_carapace_completer "tryaffix")'
complete -e "ts"
complete -c "ts" -f -a '(_carapace_completer "ts")'
complete -e "ts-node"
complete -c "ts-node" -f -a '(_carapace_completer "ts-node")'
complete -e "tsc"
complete -c "tsc" -f -a '(_carapace_completer "tsc")'
complete -e "tsh"
complete -c "tsh" -f -a '(_carapace_completer "tsh")'
complete -e "tshark"
complete -c "tshark" -f -a '(_carapace_completer "tshark")'
complete -e "tsort"
complete -c "tsort" -f -a '(_carapace_completer "tsort")'
complete -e "tsx"
complete -c "tsx" -f -a '(_carapace_completer "tsx")'
complete -e "tty"
complete -c "tty" -f -a '(_carapace_completer "tty")'
complete -e "ttyd"
complete -c "ttyd" -f -a '(_carapace_completer "ttyd")'
complete -e "tunctl"
complete -c "tunctl" -f -a '(_carapace_completer "tunctl")'
complete -e "tune2fs"
complete -c "tune2fs" -f -a '(_carapace_completer "tune2fs")'
complete -e "tunelp"
complete -c "tunelp" -f -a '(_carapace_completer "tunelp")'
complete -e "tunes2pod"
complete -c "tunes2pod" -f -a '(_carapace_completer "tunes2pod")'
complete -e "turbo"
complete -c "turbo" -f -a '(_carapace_completer "turbo")'
complete -e "twidge"
complete -c "twidge" -f -a '(_carapace_completer "twidge")'
complete -e "twist"
complete -c "twist" -f -a '(_carapace_completer "twist")'
complete -e "twistd"
complete -c "twistd" -f -a '(_carapace_completer "twistd")'
complete -e "txt"
complete -c "txt" -f -a '(_carapace_completer "txt")'
complete -e "typst"
complete -c "typst" -f -a '(_carapace_completer "typst")'
complete -e "ubuntu-distro-info"
complete -c "ubuntu-distro-info" -f -a '(_carapace_completer "ubuntu-distro-info")'
complete -e "uclampset"
complete -c "uclampset" -f -a '(_carapace_completer "uclampset")'
complete -e "udevadm"
complete -c "udevadm" -f -a '(_carapace_completer "udevadm")'
complete -e "udisksctl"
complete -c "udisksctl" -f -a '(_carapace_completer "udisksctl")'
complete -e "ufw"
complete -c "ufw" -f -a '(_carapace_completer "ufw")'
complete -e "ul"
complete -c "ul" -f -a '(_carapace_completer "ul")'
complete -e "uml_mconsole"
complete -c "uml_mconsole" -f -a '(_carapace_completer "uml_mconsole")'
complete -e "uml_moo"
complete -c "uml_moo" -f -a '(_carapace_completer "uml_moo")'
complete -e "uml_switch"
complete -c "uml_switch" -f -a '(_carapace_completer "uml_switch")'
complete -e "umount"
complete -c "umount" -f -a '(_carapace_completer "umount")'
complete -e "unace"
complete -c "unace" -f -a '(_carapace_completer "unace")'
complete -e "uname"
complete -c "uname" -f -a '(_carapace_completer "uname")'
complete -e "unbrotli"
complete -c "unbrotli" -f -a '(_carapace_completer "unbrotli")'
complete -e "uncompress"
complete -c "uncompress" -f -a '(_carapace_completer "uncompress")'
complete -e "unexpand"
complete -c "unexpand" -f -a '(_carapace_completer "unexpand")'
complete -e "uniq"
complete -c "uniq" -f -a '(_carapace_completer "uniq")'
complete -e "unison"
complete -c "unison" -f -a '(_carapace_completer "unison")'
complete -e "units"
complete -c "units" -f -a '(_carapace_completer "units")'
complete -e "unix2dos"
complete -c "unix2dos" -f -a '(_carapace_completer "unix2dos")'
complete -e "unix2mac"
complete -c "unix2mac" -f -a '(_carapace_completer "unix2mac")'
complete -e "unlink"
complete -c "unlink" -f -a '(_carapace_completer "unlink")'
complete -e "unlz4"
complete -c "unlz4" -f -a '(_carapace_completer "unlz4")'
complete -e "unlzma"
complete -c "unlzma" -f -a '(_carapace_completer "unlzma")'
complete -e "unpack"
complete -c "unpack" -f -a '(_carapace_completer "unpack")'
complete -e "unpigz"
complete -c "unpigz" -f -a '(_carapace_completer "unpigz")'
complete -e "unrar"
complete -c "unrar" -f -a '(_carapace_completer "unrar")'
complete -e "unset-env"
complete -c "unset-env" -f -a '(_carapace_completer "unset-env")'
complete -e "unshare"
complete -c "unshare" -f -a '(_carapace_completer "unshare")'
complete -e "unwrapdiff"
complete -c "unwrapdiff" -f -a '(_carapace_completer "unwrapdiff")'
complete -e "unxz"
complete -c "unxz" -f -a '(_carapace_completer "unxz")'
complete -e "unzip"
complete -c "unzip" -f -a '(_carapace_completer "unzip")'
complete -e "unzstd"
complete -c "unzstd" -f -a '(_carapace_completer "unzstd")'
complete -e "updpkgsums"
complete -c "updpkgsums" -f -a '(_carapace_completer "updpkgsums")'
complete -e "upower"
complete -c "upower" -f -a '(_carapace_completer "upower")'
complete -e "uptime"
complete -c "uptime" -f -a '(_carapace_completer "uptime")'
complete -e "upx"
complete -c "upx" -f -a '(_carapace_completer "upx")'
complete -e "urxvt"
complete -c "urxvt" -f -a '(_carapace_completer "urxvt")'
complete -e "urxvt256c"
complete -c "urxvt256c" -f -a '(_carapace_completer "urxvt256c")'
complete -e "urxvt256c-ml"
complete -c "urxvt256c-ml" -f -a '(_carapace_completer "urxvt256c-ml")'
complete -e "urxvt256c-mlc"
complete -c "urxvt256c-mlc" -f -a '(_carapace_completer "urxvt256c-mlc")'
complete -e "urxvt256cc"
complete -c "urxvt256cc" -f -a '(_carapace_completer "urxvt256cc")'
complete -e "urxvtc"
complete -c "urxvtc" -f -a '(_carapace_completer "urxvtc")'
complete -e "useradd"
complete -c "useradd" -f -a '(_carapace_completer "useradd")'
complete -e "userdbctl"
complete -c "userdbctl" -f -a '(_carapace_completer "userdbctl")'
complete -e "userdel"
complete -c "userdel" -f -a '(_carapace_completer "userdel")'
complete -e "usermod"
complete -c "usermod" -f -a '(_carapace_completer "usermod")'
complete -e "users"
complete -c "users" -f -a '(_carapace_completer "users")'
complete -e "utmpdump"
complete -c "utmpdump" -f -a '(_carapace_completer "utmpdump")'
complete -e "uuidd"
complete -c "uuidd" -f -a '(_carapace_completer "uuidd")'
complete -e "uuidgen"
complete -c "uuidgen" -f -a '(_carapace_completer "uuidgen")'
complete -e "uuidparse"
complete -c "uuidparse" -f -a '(_carapace_completer "uuidparse")'
complete -e "uv"
complete -c "uv" -f -a '(_carapace_completer "uv")'
complete -e "vacuumdb"
complete -c "vacuumdb" -f -a '(_carapace_completer "vacuumdb")'
complete -e "vagrant"
complete -c "vagrant" -f -a '(_carapace_completer "vagrant")'
complete -e "valgrind"
complete -c "valgrind" -f -a '(_carapace_completer "valgrind")'
complete -e "validatetrans"
complete -c "validatetrans" -f -a '(_carapace_completer "validatetrans")'
complete -e "varlinkctl"
complete -c "varlinkctl" -f -a '(_carapace_completer "varlinkctl")'
complete -e "vault"
complete -c "vault" -f -a '(_carapace_completer "vault")'
complete -e "vcs_info_hookadd"
complete -c "vcs_info_hookadd" -f -a '(_carapace_completer "vcs_info_hookadd")'
complete -e "vcs_info_hookdel"
complete -c "vcs_info_hookdel" -f -a '(_carapace_completer "vcs_info_hookdel")'
complete -e "vd"
complete -c "vd" -f -a '(_carapace_completer "vd")'
complete -e "vdir"
complete -c "vdir" -f -a '(_carapace_completer "vdir")'
complete -e "vercel"
complete -c "vercel" -f -a '(_carapace_completer "vercel")'
complete -e "vgcfgbackup"
complete -c "vgcfgbackup" -f -a '(_carapace_completer "vgcfgbackup")'
complete -e "vgcfgrestore"
complete -c "vgcfgrestore" -f -a '(_carapace_completer "vgcfgrestore")'
complete -e "vgchange"
complete -c "vgchange" -f -a '(_carapace_completer "vgchange")'
complete -e "vgck"
complete -c "vgck" -f -a '(_carapace_completer "vgck")'
complete -e "vgconvert"
complete -c "vgconvert" -f -a '(_carapace_completer "vgconvert")'
complete -e "vgcreate"
complete -c "vgcreate" -f -a '(_carapace_completer "vgcreate")'
complete -e "vgdisplay"
complete -c "vgdisplay" -f -a '(_carapace_completer "vgdisplay")'
complete -e "vgexport"
complete -c "vgexport" -f -a '(_carapace_completer "vgexport")'
complete -e "vgextend"
complete -c "vgextend" -f -a '(_carapace_completer "vgextend")'
complete -e "vgimport"
complete -c "vgimport" -f -a '(_carapace_completer "vgimport")'
complete -e "vgimportclone"
complete -c "vgimportclone" -f -a '(_carapace_completer "vgimportclone")'
complete -e "vgmerge"
complete -c "vgmerge" -f -a '(_carapace_completer "vgmerge")'
complete -e "vgmknodes"
complete -c "vgmknodes" -f -a '(_carapace_completer "vgmknodes")'
complete -e "vgreduce"
complete -c "vgreduce" -f -a '(_carapace_completer "vgreduce")'
complete -e "vgremove"
complete -c "vgremove" -f -a '(_carapace_completer "vgremove")'
complete -e "vgrename"
complete -c "vgrename" -f -a '(_carapace_completer "vgrename")'
complete -e "vgs"
complete -c "vgs" -f -a '(_carapace_completer "vgs")'
complete -e "vgscan"
complete -c "vgscan" -f -a '(_carapace_completer "vgscan")'
complete -e "vgsplit"
complete -c "vgsplit" -f -a '(_carapace_completer "vgsplit")'
complete -e "vhs"
complete -c "vhs" -f -a '(_carapace_completer "vhs")'
complete -e "vi"
complete -c "vi" -f -a '(_carapace_completer "vi")'
complete -e "view"
complete -c "view" -f -a '(_carapace_completer "view")'
complete -e "viewnior"
complete -c "viewnior" -f -a '(_carapace_completer "viewnior")'
complete -e "vim"
complete -c "vim" -f -a '(_carapace_completer "vim")'
complete -e "vimdiff"
complete -c "vimdiff" -f -a '(_carapace_completer "vimdiff")'
complete -e "vipw"
complete -c "vipw" -f -a '(_carapace_completer "vipw")'
complete -e "virsh"
complete -c "virsh" -f -a '(_carapace_completer "virsh")'
complete -e "virt-admin"
complete -c "virt-admin" -f -a '(_carapace_completer "virt-admin")'
complete -e "virt-host-validate"
complete -c "virt-host-validate" -f -a '(_carapace_completer "virt-host-validate")'
complete -e "virt-pki-validate"
complete -c "virt-pki-validate" -f -a '(_carapace_completer "virt-pki-validate")'
complete -e "virt-xml-validate"
complete -c "virt-xml-validate" -f -a '(_carapace_completer "virt-xml-validate")'
complete -e "visidata"
complete -c "visidata" -f -a '(_carapace_completer "visidata")'
complete -e "visudo"
complete -c "visudo" -f -a '(_carapace_completer "visudo")'
complete -e "vitrage"
complete -c "vitrage" -f -a '(_carapace_completer "vitrage")'
complete -e "viu"
complete -c "viu" -f -a '(_carapace_completer "viu")'
complete -e "vivid"
complete -c "vivid" -f -a '(_carapace_completer "vivid")'
complete -e "vlc"
complete -c "vlc" -f -a '(_carapace_completer "vlc")'
complete -e "vmstat"
complete -c "vmstat" -f -a '(_carapace_completer "vmstat")'
complete -e "vncserver"
complete -c "vncserver" -f -a '(_carapace_completer "vncserver")'
complete -e "vncviewer"
complete -c "vncviewer" -f -a '(_carapace_completer "vncviewer")'
complete -e "vnstat"
complete -c "vnstat" -f -a '(_carapace_completer "vnstat")'
complete -e "volta"
complete -c "volta" -f -a '(_carapace_completer "volta")'
complete -e "vorbiscomment"
complete -c "vorbiscomment" -f -a '(_carapace_completer "vorbiscomment")'
complete -e "vpnc"
complete -c "vpnc" -f -a '(_carapace_completer "vpnc")'
complete -e "vpnc-connect"
complete -c "vpnc-connect" -f -a '(_carapace_completer "vpnc-connect")'
complete -e "vserver"
complete -c "vserver" -f -a '(_carapace_completer "vserver")'
complete -e "vunnel"
complete -c "vunnel" -f -a '(_carapace_completer "vunnel")'
complete -e "w"
complete -c "w" -f -a '(_carapace_completer "w")'
complete -e "w3m"
complete -c "w3m" -f -a '(_carapace_completer "w3m")'
complete -e "waitpid"
complete -c "waitpid" -f -a '(_carapace_completer "waitpid")'
complete -e "wall"
complete -c "wall" -f -a '(_carapace_completer "wall")'
complete -e "watch"
complete -c "watch" -f -a '(_carapace_completer "watch")'
complete -e "watcher"
complete -c "watcher" -f -a '(_carapace_completer "watcher")'
complete -e "watchexec"
complete -c "watchexec" -f -a '(_carapace_completer "watchexec")'
complete -e "watchgnupg"
complete -c "watchgnupg" -f -a '(_carapace_completer "watchgnupg")'
complete -e "waypoint"
complete -c "waypoint" -f -a '(_carapace_completer "waypoint")'
complete -e "wc"
complete -c "wc" -f -a '(_carapace_completer "wc")'
complete -e "wdctl"
complete -c "wdctl" -f -a '(_carapace_completer "wdctl")'
complete -e "webstorm"
complete -c "webstorm" -f -a '(_carapace_completer "webstorm")'
complete -e "wemux"
complete -c "wemux" -f -a '(_carapace_completer "wemux")'
complete -e "wezterm"
complete -c "wezterm" -f -a '(_carapace_completer "wezterm")'
complete -e "wg"
complete -c "wg" -f -a '(_carapace_completer "wg")'
complete -e "wg-quick"
complete -c "wg-quick" -f -a '(_carapace_completer "wg-quick")'
complete -e "wget"
complete -c "wget" -f -a '(_carapace_completer "wget")'
complete -e "whatis"
complete -c "whatis" -f -a '(_carapace_completer "whatis")'
complete -e "whereis"
complete -c "whereis" -f -a '(_carapace_completer "whereis")'
complete -e "which"
complete -c "which" -f -a '(_carapace_completer "which")'
complete -e "who"
complete -c "who" -f -a '(_carapace_completer "who")'
complete -e "whoami"
complete -c "whoami" -f -a '(_carapace_completer "whoami")'
complete -e "whois"
complete -c "whois" -f -a '(_carapace_completer "whois")'
complete -e "whom"
complete -c "whom" -f -a '(_carapace_completer "whom")'
complete -e "wiggle"
complete -c "wiggle" -f -a '(_carapace_completer "wiggle")'
complete -e "wine"
complete -c "wine" -f -a '(_carapace_completer "wine")'
complete -e "wineboot"
complete -c "wineboot" -f -a '(_carapace_completer "wineboot")'
complete -e "winepath"
complete -c "winepath" -f -a '(_carapace_completer "winepath")'
complete -e "wineserver"
complete -c "wineserver" -f -a '(_carapace_completer "wineserver")'
complete -e "winetricks"
complete -c "winetricks" -f -a '(_carapace_completer "winetricks")'
complete -e "wipefs"
complete -c "wipefs" -f -a '(_carapace_completer "wipefs")'
complete -e "wire"
complete -c "wire" -f -a '(_carapace_completer "wire")'
complete -e "wireshark"
complete -c "wireshark" -f -a '(_carapace_completer "wireshark")'
complete -e "wishlist"
complete -c "wishlist" -f -a '(_carapace_completer "wishlist")'
complete -e "wl-mirror"
complete -c "wl-mirror" -f -a '(_carapace_completer "wl-mirror")'
complete -e "wodim"
complete -c "wodim" -f -a '(_carapace_completer "wodim")'
complete -e "woeusb"
complete -c "woeusb" -f -a '(_carapace_completer "woeusb")'
complete -e "wpa_cli"
complete -c "wpa_cli" -f -a '(_carapace_completer "wpa_cli")'
complete -e "wpctl"
complete -c "wpctl" -f -a '(_carapace_completer "wpctl")'
complete -e "write"
complete -c "write" -f -a '(_carapace_completer "write")'
complete -e "wt"
complete -c "wt" -f -a '(_carapace_completer "wt")'
complete -e "www"
complete -c "www" -f -a '(_carapace_completer "www")'
complete -e "x264"
complete -c "x264" -f -a '(_carapace_completer "x264")'
complete -e "xargs"
complete -c "xargs" -f -a '(_carapace_completer "xargs")'
complete -e "xattr"
complete -c "xattr" -f -a '(_carapace_completer "xattr")'
complete -e "xauth"
complete -c "xauth" -f -a '(_carapace_completer "xauth")'
complete -e "xautolock"
complete -c "xautolock" -f -a '(_carapace_completer "xautolock")'
complete -e "xbacklight"
complete -c "xbacklight" -f -a '(_carapace_completer "xbacklight")'
complete -e "xbps-alternatives"
complete -c "xbps-alternatives" -f -a '(_carapace_completer "xbps-alternatives")'
complete -e "xbps-checkvers"
complete -c "xbps-checkvers" -f -a '(_carapace_completer "xbps-checkvers")'
complete -e "xbps-create"
complete -c "xbps-create" -f -a '(_carapace_completer "xbps-create")'
complete -e "xbps-dgraph"
complete -c "xbps-dgraph" -f -a '(_carapace_completer "xbps-dgraph")'
complete -e "xbps-digest"
complete -c "xbps-digest" -f -a '(_carapace_completer "xbps-digest")'
complete -e "xbps-fbulk"
complete -c "xbps-fbulk" -f -a '(_carapace_completer "xbps-fbulk")'
complete -e "xbps-fetch"
complete -c "xbps-fetch" -f -a '(_carapace_completer "xbps-fetch")'
complete -e "xbps-install"
complete -c "xbps-install" -f -a '(_carapace_completer "xbps-install")'
complete -e "xbps-pkgdb"
complete -c "xbps-pkgdb" -f -a '(_carapace_completer "xbps-pkgdb")'
complete -e "xbps-query"
complete -c "xbps-query" -f -a '(_carapace_completer "xbps-query")'
complete -e "xbps-reconfigure"
complete -c "xbps-reconfigure" -f -a '(_carapace_completer "xbps-reconfigure")'
complete -e "xbps-remove"
complete -c "xbps-remove" -f -a '(_carapace_completer "xbps-remove")'
complete -e "xbps-rindex"
complete -c "xbps-rindex" -f -a '(_carapace_completer "xbps-rindex")'
complete -e "xbps-uchroot"
complete -c "xbps-uchroot" -f -a '(_carapace_completer "xbps-uchroot")'
complete -e "xbps-uhelper"
complete -c "xbps-uhelper" -f -a '(_carapace_completer "xbps-uhelper")'
complete -e "xbps-uunshare"
complete -c "xbps-uunshare" -f -a '(_carapace_completer "xbps-uunshare")'
complete -e "xclip"
complete -c "xclip" -f -a '(_carapace_completer "xclip")'
complete -e "xdg-mime"
complete -c "xdg-mime" -f -a '(_carapace_completer "xdg-mime")'
complete -e "xdotool"
complete -c "xdotool" -f -a '(_carapace_completer "xdotool")'
complete -e "xdpyinfo"
complete -c "xdpyinfo" -f -a '(_carapace_completer "xdpyinfo")'
complete -e "xdvi"
complete -c "xdvi" -f -a '(_carapace_completer "xdvi")'
complete -e "xev"
complete -c "xev" -f -a '(_carapace_completer "xev")'
complete -e "xfconf-query"
complete -c "xfconf-query" -f -a '(_carapace_completer "xfconf-query")'
complete -e "xfd"
complete -c "xfd" -f -a '(_carapace_completer "xfd")'
complete -e "xfig"
complete -c "xfig" -f -a '(_carapace_completer "xfig")'
complete -e "xfontsel"
complete -c "xfontsel" -f -a '(_carapace_completer "xfontsel")'
complete -e "xfreerdp"
complete -c "xfreerdp" -f -a '(_carapace_completer "xfreerdp")'
complete -e "xh"
complete -c "xh" -f -a '(_carapace_completer "xh")'
complete -e "xhost"
complete -c "xhost" -f -a '(_carapace_completer "xhost")'
complete -e "xinput"
complete -c "xinput" -f -a '(_carapace_completer "xinput")'
complete -e "xkbcli"
complete -c "xkbcli" -f -a '(_carapace_completer "xkbcli")'
complete -e "xkill"
complete -c "xkill" -f -a '(_carapace_completer "xkill")'
complete -e "xli"
complete -c "xli" -f -a '(_carapace_completer "xli")'
complete -e "xloadimage"
complete -c "xloadimage" -f -a '(_carapace_completer "xloadimage")'
complete -e "xlsatoms"
complete -c "xlsatoms" -f -a '(_carapace_completer "xlsatoms")'
complete -e "xlsclients"
complete -c "xlsclients" -f -a '(_carapace_completer "xlsclients")'
complete -e "xmaxima"
complete -c "xmaxima" -f -a '(_carapace_completer "xmaxima")'
complete -e "xml"
complete -c "xml" -f -a '(_carapace_completer "xml")'
complete -e "xmllint"
complete -c "xmllint" -f -a '(_carapace_completer "xmllint")'
complete -e "xmlstarlet"
complete -c "xmlstarlet" -f -a '(_carapace_completer "xmlstarlet")'
complete -e "xmms2"
complete -c "xmms2" -f -a '(_carapace_completer "xmms2")'
complete -e "xmodmap"
complete -c "xmodmap" -f -a '(_carapace_completer "xmodmap")'
complete -e "xmosaic"
complete -c "xmosaic" -f -a '(_carapace_completer "xmosaic")'
complete -e "xon"
complete -c "xon" -f -a '(_carapace_completer "xon")'
complete -e "xonsh"
complete -c "xonsh" -f -a '(_carapace_completer "xonsh")'
complete -e "xournal"
complete -c "xournal" -f -a '(_carapace_completer "xournal")'
complete -e "xpdf"
complete -c "xpdf" -f -a '(_carapace_completer "xpdf")'
complete -e "xping"
complete -c "xping" -f -a '(_carapace_completer "xping")'
complete -e "xprop"
complete -c "xprop" -f -a '(_carapace_completer "xprop")'
complete -e "xrandr"
complete -c "xrandr" -f -a '(_carapace_completer "xrandr")'
complete -e "xrdb"
complete -c "xrdb" -f -a '(_carapace_completer "xrdb")'
complete -e "xscreensaver-command"
complete -c "xscreensaver-command" -f -a '(_carapace_completer "xscreensaver-command")'
complete -e "xsel"
complete -c "xsel" -f -a '(_carapace_completer "xsel")'
complete -e "xset"
complete -c "xset" -f -a '(_carapace_completer "xset")'
complete -e "xsetbg"
complete -c "xsetbg" -f -a '(_carapace_completer "xsetbg")'
complete -e "xsetroot"
complete -c "xsetroot" -f -a '(_carapace_completer "xsetroot")'
complete -e "xsltproc"
complete -c "xsltproc" -f -a '(_carapace_completer "xsltproc")'
complete -e "xss-lock"
complete -c "xss-lock" -f -a '(_carapace_completer "xss-lock")'
complete -e "xterm"
complete -c "xterm" -f -a '(_carapace_completer "xterm")'
complete -e "xtightvncviewer"
complete -c "xtightvncviewer" -f -a '(_carapace_completer "xtightvncviewer")'
complete -e "xtp"
complete -c "xtp" -f -a '(_carapace_completer "xtp")'
complete -e "xv"
complete -c "xv" -f -a '(_carapace_completer "xv")'
complete -e "xview"
complete -c "xview" -f -a '(_carapace_completer "xview")'
complete -e "xvnc4viewer"
complete -c "xvnc4viewer" -f -a '(_carapace_completer "xvnc4viewer")'
complete -e "xvncviewer"
complete -c "xvncviewer" -f -a '(_carapace_completer "xvncviewer")'
complete -e "xwd"
complete -c "xwd" -f -a '(_carapace_completer "xwd")'
complete -e "xwininfo"
complete -c "xwininfo" -f -a '(_carapace_completer "xwininfo")'
complete -e "xwit"
complete -c "xwit" -f -a '(_carapace_completer "xwit")'
complete -e "xwud"
complete -c "xwud" -f -a '(_carapace_completer "xwud")'
complete -e "xxd"
complete -c "xxd" -f -a '(_carapace_completer "xxd")'
complete -e "xxhsum"
complete -c "xxhsum" -f -a '(_carapace_completer "xxhsum")'
complete -e "xz"
complete -c "xz" -f -a '(_carapace_completer "xz")'
complete -e "xzcat"
complete -c "xzcat" -f -a '(_carapace_completer "xzcat")'
complete -e "ya"
complete -c "ya" -f -a '(_carapace_completer "ya")'
complete -e "yafc"
complete -c "yafc" -f -a '(_carapace_completer "yafc")'
complete -e "yamllint"
complete -c "yamllint" -f -a '(_carapace_completer "yamllint")'
complete -e "yarn"
complete -c "yarn" -f -a '(_carapace_completer "yarn")'
complete -e "yash"
complete -c "yash" -f -a '(_carapace_completer "yash")'
complete -e "yay"
complete -c "yay" -f -a '(_carapace_completer "yay")'
complete -e "yazi"
complete -c "yazi" -f -a '(_carapace_completer "yazi")'
complete -e "yes"
complete -c "yes" -f -a '(_carapace_completer "yes")'
complete -e "yj"
complete -c "yj" -f -a '(_carapace_completer "yj")'
complete -e "ykman"
complete -c "ykman" -f -a '(_carapace_completer "ykman")'
complete -e "youtube-dl"
complete -c "youtube-dl" -f -a '(_carapace_completer "youtube-dl")'
complete -e "ypbind"
complete -c "ypbind" -f -a '(_carapace_completer "ypbind")'
complete -e "ypcat"
complete -c "ypcat" -f -a '(_carapace_completer "ypcat")'
complete -e "ypmatch"
complete -c "ypmatch" -f -a '(_carapace_completer "ypmatch")'
complete -e "yppasswd"
complete -c "yppasswd" -f -a '(_carapace_completer "yppasswd")'
complete -e "yppoll"
complete -c "yppoll" -f -a '(_carapace_completer "yppoll")'
complete -e "yppush"
complete -c "yppush" -f -a '(_carapace_completer "yppush")'
complete -e "ypserv"
complete -c "ypserv" -f -a '(_carapace_completer "ypserv")'
complete -e "ypset"
complete -c "ypset" -f -a '(_carapace_completer "ypset")'
complete -e "ypwhich"
complete -c "ypwhich" -f -a '(_carapace_completer "ypwhich")'
complete -e "ypxfr"
complete -c "ypxfr" -f -a '(_carapace_completer "ypxfr")'
complete -e "ysh"
complete -c "ysh" -f -a '(_carapace_completer "ysh")'
complete -e "yt-dlp"
complete -c "yt-dlp" -f -a '(_carapace_completer "yt-dlp")'
complete -e "ytalk"
complete -c "ytalk" -f -a '(_carapace_completer "ytalk")'
complete -e "zargs"
complete -c "zargs" -f -a '(_carapace_completer "zargs")'
complete -e "zathura"
complete -c "zathura" -f -a '(_carapace_completer "zathura")'
complete -e "zcalc"
complete -c "zcalc" -f -a '(_carapace_completer "zcalc")'
complete -e "zcash-cli"
complete -c "zcash-cli" -f -a '(_carapace_completer "zcash-cli")'
complete -e "zcat"
complete -c "zcat" -f -a '(_carapace_completer "zcat")'
complete -e "zcp"
complete -c "zcp" -f -a '(_carapace_completer "zcp")'
complete -e "zdb"
complete -c "zdb" -f -a '(_carapace_completer "zdb")'
complete -e "zdelattr"
complete -c "zdelattr" -f -a '(_carapace_completer "zdelattr")'
complete -e "zdump"
complete -c "zdump" -f -a '(_carapace_completer "zdump")'
complete -e "zeal"
complete -c "zeal" -f -a '(_carapace_completer "zeal")'
complete -e "zed"
complete -c "zed" -f -a '(_carapace_completer "zed")'
complete -e "zegrep"
complete -c "zegrep" -f -a '(_carapace_completer "zegrep")'
complete -e "zellij"
complete -c "zellij" -f -a '(_carapace_completer "zellij")'
complete -e "zen"
complete -c "zen" -f -a '(_carapace_completer "zen")'
complete -e "zf_chmod"
complete -c "zf_chmod" -f -a '(_carapace_completer "zf_chmod")'
complete -e "zf_ln"
complete -c "zf_ln" -f -a '(_carapace_completer "zf_ln")'
complete -e "zf_mkdir"
complete -c "zf_mkdir" -f -a '(_carapace_completer "zf_mkdir")'
complete -e "zf_mv"
complete -c "zf_mv" -f -a '(_carapace_completer "zf_mv")'
complete -e "zf_rm"
complete -c "zf_rm" -f -a '(_carapace_completer "zf_rm")'
complete -e "zf_rmdir"
complete -c "zf_rmdir" -f -a '(_carapace_completer "zf_rmdir")'
complete -e "zfgrep"
complete -c "zfgrep" -f -a '(_carapace_completer "zfgrep")'
complete -e "zfs"
complete -c "zfs" -f -a '(_carapace_completer "zfs")'
complete -e "zgetattr"
complete -c "zgetattr" -f -a '(_carapace_completer "zgetattr")'
complete -e "zgrep"
complete -c "zgrep" -f -a '(_carapace_completer "zgrep")'
complete -e "zig"
complete -c "zig" -f -a '(_carapace_completer "zig")'
complete -e "zip"
complete -c "zip" -f -a '(_carapace_completer "zip")'
complete -e "zipinfo"
complete -c "zipinfo" -f -a '(_carapace_completer "zipinfo")'
complete -e "zlistattr"
complete -c "zlistattr" -f -a '(_carapace_completer "zlistattr")'
complete -e "zln"
complete -c "zln" -f -a '(_carapace_completer "zln")'
complete -e "zmail"
complete -c "zmail" -f -a '(_carapace_completer "zmail")'
complete -e "zmv"
complete -c "zmv" -f -a '(_carapace_completer "zmv")'
complete -e "zone"
complete -c "zone" -f -a '(_carapace_completer "zone")'
complete -e "zoxide"
complete -c "zoxide" -f -a '(_carapace_completer "zoxide")'
complete -e "zpool"
complete -c "zpool" -f -a '(_carapace_completer "zpool")'
complete -e "zpty"
complete -c "zpty" -f -a '(_carapace_completer "zpty")'
complete -e "zramctl"
complete -c "zramctl" -f -a '(_carapace_completer "zramctl")'
complete -e "zsetattr"
complete -c "zsetattr" -f -a '(_carapace_completer "zsetattr")'
complete -e "zsh"
complete -c "zsh" -f -a '(_carapace_completer "zsh")'
complete -e "zsh-mime-handler"
complete -c "zsh-mime-handler" -f -a '(_carapace_completer "zsh-mime-handler")'
complete -e "zsocket"
complete -c "zsocket" -f -a '(_carapace_completer "zsocket")'
complete -e "zstd"
complete -c "zstd" -f -a '(_carapace_completer "zstd")'
complete -e "zstdcat"
complete -c "zstdcat" -f -a '(_carapace_completer "zstdcat")'
complete -e "zstdmt"
complete -c "zstdmt" -f -a '(_carapace_completer "zstdmt")'
complete -e "zstream"
complete -c "zstream" -f -a '(_carapace_completer "zstream")'
complete -e "ztodo"
complete -c "ztodo" -f -a '(_carapace_completer "ztodo")'
complete -e "zun"
complete -c "zun" -f -a '(_carapace_completer "zun")'
complete -e "zxpdf"
complete -c "zxpdf" -f -a '(_carapace_completer "zxpdf")'


# ── Custom completions via carapace ──────────────────────────────────────
for __tool in instagram-cli gallery-dl spotdl instaloader aider
  complete -e "$__tool"
  complete -c "$__tool" -f -a '(_carapace_completer "'$__tool'")'
end
