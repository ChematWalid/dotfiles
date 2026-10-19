#!/usr/bin/env bash
# Polybar invokes this stable script path; the native helper handles timer and
# state-file events without forking date/cat/sleep every second.
set -euo pipefail
exec "${HOME}/.local/bin/polybar-datetime"
