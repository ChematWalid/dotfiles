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

    # Use NUL separators so empty fields, tabs, and embedded newlines do not
    # shift notification metadata while Bash parses it.
    local -a parsed_fields=()
    mapfile -d '' -t parsed_fields < <(
        printf '%s' "$raw_history" | jq -j '
            .data[0] // [] |
            .[] |
            ((.id.data // 0) | tostring), "\u0000",
            ((.appname.data // "System") | gsub("[\u0000-\u001f\u007f]"; " ")), "\u0000",
            ((.summary.data // "") | gsub("[\u0000-\u001f\u007f]"; " ")), "\u0000",
            ((.body.data // "") | gsub("[\u0000-\u001f\u007f]"; " ") | if length > 60 then .[0:57] + "..." else . end), "\u0000"
        '
    )

    if [[ ${#parsed_fields[@]} -lt 4 ]]; then
        show_empty
    fi

    # Build Rofi display entries and corresponding action metadata arrays
    local rofi_lines=()
    local actions=()
    local nids=()
    local appnames=()
    local summaries=()
    local bodies=()

    # Fixed top actions
    rofi_lines+=("󰎟  Redisplay Latest Notification")
    actions+=("pop_latest")
    nids+=("0")
    appnames+=("")
    summaries+=("")
    bodies+=("")

    rofi_lines+=("󰎟  Clear All Notification History")
    actions+=("clear_all")
    nids+=("0")
    appnames+=("")
    summaries+=("")
    bodies+=("")

    local field_index id app summary body
    for ((field_index = 0; field_index + 3 < ${#parsed_fields[@]}; field_index += 4)); do
        id="${parsed_fields[field_index]}"
        app="${parsed_fields[field_index + 1]}"
        summary="${parsed_fields[field_index + 2]}"
        body="${parsed_fields[field_index + 3]}"

        local line="󰂚 [${app}] ${summary}"
        if [[ -n "$body" && "$body" != "$summary" ]]; then
            line+=" — ${body}"
        fi

        rofi_lines+=("$line")
        actions+=("open")
        nids+=("$id")
        appnames+=("$app")
        summaries+=("$summary")
        bodies+=("$body")
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
            local sum="${summaries[$idx]}"
            local bdy="${bodies[$idx]}"
            local full="$sum"
            [[ -n "$bdy" ]] && full+=$'\n'"$bdy"
            if command -v xclip >/dev/null 2>&1; then
                printf "%s" "$full" | xclip -selection clipboard 2>/dev/null || true
            fi
            if command -v copyq >/dev/null 2>&1; then
                copyq add "$full" 2>/dev/null || true
            fi
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
