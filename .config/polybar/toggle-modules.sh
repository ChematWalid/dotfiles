#!/bin/bash

CONFIG="$HOME/.config/polybar/config.ini"
ALL_MODULES=("date" "prayer" "pulseaudio" "memory" "cpu" "temperature" "battery" "filesystem" "backlight" "wlan" "eth" "tray" "powermenu")

CURRENT_LINE=$(grep "^modules-right" "$CONFIG")
CURRENT_MODULES=${CURRENT_LINE#*=}

OPTIONS=""
for mod in "${ALL_MODULES[@]}"; do
    if [[ " $CURRENT_MODULES " =~ " $mod " ]]; then
        OPTIONS+="[x] $mod\n"
    else
        OPTIONS+="[ ] $mod\n"
    fi
done

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "󰒓  Toggle Module" -theme ~/.config/rofi/config.rasi -theme-str 'window {width: 320px; height: 420px;} listview {lines: 12;}' 2> /tmp/rofi_err.log)

if [ -n "$CHOICE" ]; then
    SELECTED_MOD=$(echo "$CHOICE" | sed 's/\[x\] //g' | sed 's/\[ \] //g')
    
    if [[ " $CURRENT_MODULES " =~ " $SELECTED_MOD " ]]; then
        NEW_MODULES=$(echo " $CURRENT_MODULES " | sed "s/ $SELECTED_MOD / /g" | xargs)
    else
        NEW_MODULES=""
        for mod in "${ALL_MODULES[@]}"; do
            if [[ " $CURRENT_MODULES " =~ " $mod " ]] || [ "$mod" == "$SELECTED_MOD" ]; then
                NEW_MODULES+="$mod "
            fi
        done
        NEW_MODULES=$(echo "$NEW_MODULES" | xargs)
    fi

    sed -i "s/^modules-right.*/modules-right = $NEW_MODULES/g" "$CONFIG"
    ~/.config/polybar/launch.sh
fi
