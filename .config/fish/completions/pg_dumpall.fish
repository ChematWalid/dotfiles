complete -e "pg_dumpall"
complete -c "pg_dumpall" -f -a '(_carapace_completer "pg_dumpall")'
