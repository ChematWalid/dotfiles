#!/usr/bin/env bash

if [ "$(copyq eval 'visible()')" = "true" ]; then
    copyq hide
else
    copyq show
    # Force i3 to bring CopyQ to the current active workspace, center it, and focus it
    i3-msg '[class="[cC]opy[qQ]"] move to workspace current, focus, move position center' >/dev/null 2>&1
fi
