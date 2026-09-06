#!/usr/bin/env bash
# ── rofi-notification-center.sh ───────────────────────────────────────────────
# Interactive Notification Center for Dunst & Rofi (Catppuccin Mocha themed)
# Production-grade, zero-dependency Bash implementation using dunstctl + jq + rofi.

set -euo pipefail
IFS=$'\n\t'

readonly CONFIG_RASI="${HOME}/.config/rofi/config.rasi"
readonly FOCUS_SCRIPT="${HOME}/.config/dunst/focus-app.sh"

show_empty() {
    rofi -e "No notification history found." \
         -theme "$CONFIG_RASI" 2>/dev/null || true
    exit 0
}

main() {
    local raw_history
    raw_history=$(dunstctl history 2>/dev/null || echo '{"data":[[]]}')

    # Parse notifications into tab-separated lines: ID \t APP \t SUMMARY \t BODY
    local parsed_items=()
    mapfile -t parsed_items < <(
        echo "$raw_history" | jq -r '
            .data[0] // [] |
            .[] |
            "\(.id.data)\t\(.appname.data // "System")\t\(.summary.data // "")\t\((.body.data // "") | gsub("\n"; " ") | if length > 60 then .[0:57] + "..." else . end)"
        '
    )

    if [[ ${#parsed_items[@]} -eq 0 ]]; then
        show_empty
    fi

    # Build Rofi display entries and corresponding action metadata arrays
    local rofi_lines=()
    local actions=()
    local nids=()
    local appnames=()

    # Fixed top actions
    rofi_lines+=("󰎟  Redisplay Latest Notification")
    actions+=("pop_latest")
    nids+=("0")
    appnames+=("")

    rofi_lines+=("󰎟  Clear All Notification History")
    actions+=("clear_all")
    nids+=("0")
    appnames+=("")

    for item in "${parsed_items[@]}"; do
        [[ -z "$item" ]] && continue
        local id app summary body
        IFS=$'\t' read -r id app summary body <<< "$item"

        local line="󰂚 [${app}] ${summary}"
        if [[ -n "$body" && "$body" != "$summary" ]]; then
            line+=" — ${body}"
        fi

        rofi_lines+=("$line")
        actions+=("open")
        nids+=("$id")
        appnames+=("$app")
    done

    # Run Rofi in dmenu mode
    local selected_idx
    selected_idx=$(
        printf '%s\n' "${rofi_lines[@]}" | \
        rofi -dmenu -i \
             -p "󰂚 Notifications" \
             -format "i" \
             -theme "$CONFIG_RASI" 2>/dev/null || true
    )

    # If cancelled or invalid, exit gracefully
    if [[ -z "$selected_idx" || ! "$selected_idx" =~ ^[0-9]+$ ]]; then
        exit 0
    fi

    local idx=$((selected_idx))
    if [[ $idx -lt 0 || $idx -ge ${#actions[@]} ]]; then
        exit 0
    fi

    local action="${actions[$idx]}"
    case "$action" in
        pop_latest)
            dunstctl history-pop >/dev/null 2>&1 || true
            ;;
        clear_all)
            dunstctl history-clear >/dev/null 2>&1 || true
            ;;
        open)
            local nid="${nids[$idx]}"
            local app="${appnames[$idx]}"
            if [[ -n "$nid" && "$nid" != "0" ]]; then
                dunstctl history-pop "$nid" >/dev/null 2>&1 || true
            fi
            if [[ -n "$app" && -x "$FOCUS_SCRIPT" ]]; then
                "$FOCUS_SCRIPT" "$app" >/dev/null 2>&1 || true
            fi
            ;;
    esac
}

main "$@"
