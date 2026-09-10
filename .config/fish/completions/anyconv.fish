# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_anyconv_global_optspecs
    string join \n o/output-dir= j/jobs= d/dry-run f/force k/keep-going l/list h/help V/version
end

function __fish_anyconv_needs_command
    # Figure out if the current invocation already has a command.
    set -l cmd (commandline -opc)
    set -e cmd[1]
    argparse -s (__fish_anyconv_global_optspecs) -- $cmd 2>/dev/null
    or return
    if set -q argv[1]
        # Also print the command, so this can be used to figure out what it is.
        echo $argv[1]
        return 1
    end
    return 0
end

function __fish_anyconv_using_subcommand
    set -l cmd (__fish_anyconv_needs_command)
    test -z "$cmd"
    and return 1
    contains -- $cmd[1] $argv
end

complete -c anyconv -n "__fish_anyconv_needs_command" -s o -l output-dir -d 'Directory to place anyconverted files in' -r -F
complete -c anyconv -n "__fish_anyconv_needs_command" -s j -l jobs -d 'Maximum parallel anyconversion jobs (default: min(4, CPU cores))' -r
complete -c anyconv -n "__fish_anyconv_needs_command" -s d -l dry-run -d 'Show planned backend and command per file without executing'
complete -c anyconv -n "__fish_anyconv_needs_command" -s f -l force -d 'Overwrite existing output files without prompting'
complete -c anyconv -n "__fish_anyconv_needs_command" -s k -l keep-going -d 'Continue processing remaining files when a batch item fails'
complete -c anyconv -n "__fish_anyconv_needs_command" -s l -l list -d 'List all supported file formats, engines, and anyconversion matrix'
complete -c anyconv -n "__fish_anyconv_needs_command" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c anyconv -n "__fish_anyconv_needs_command" -s V -l version -d 'Print version'
complete -c anyconv -n "__fish_anyconv_needs_command" -a "completions" -d 'Generate shell completions for bash, zsh, fish, etc.'
complete -c anyconv -n "__fish_anyconv_needs_command" -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c anyconv -n "__fish_anyconv_using_subcommand completions" -s h -l help -d 'Print help'
complete -c anyconv -n "__fish_anyconv_using_subcommand help; and not __fish_seen_subcommand_from completions help" -f -a "completions" -d 'Generate shell completions for bash, zsh, fish, etc.'
complete -c anyconv -n "__fish_anyconv_using_subcommand help; and not __fish_seen_subcommand_from completions help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
