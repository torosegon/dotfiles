#!/usr/bin/env bash
# Swaybar status: keyboard layout | battery (percent + time left) | month-day time

BAT=/sys/class/power_supply/BAT0
KBD="1:1:AT_Translated_Set_2_keyboard"

layout() {
    swaymsg -t get_inputs -r \
        | jq -r --arg id "$KBD" \
            '.[] | select(.identifier==$id) | .xkb_active_layout_name' 2>/dev/null \
        | case "$(cat)" in
            Hungarian*)  echo HU ;;
            English*)    echo US ;;
            *)           echo "?" ;;
        esac
}

battery() {
    [ -r "$BAT/capacity" ] || return
    local cap status en pn secs h m rem=""
    cap=$(<"$BAT/capacity")
    status=$(<"$BAT/status")
    en=$(<"$BAT/energy_now")
    pn=$(<"$BAT/power_now")

    if [ "${pn:-0}" -gt 0 ]; then
        case "$status" in
            Discharging) secs=$(( en * 3600 / pn )) ;;
            Charging)
                local ef; ef=$(<"$BAT/energy_full")
                secs=$(( (ef - en) * 3600 / pn )) ;;
        esac
        if [ -n "$secs" ]; then
            h=$(( secs / 3600 )); m=$(( secs % 3600 / 60 ))
            rem=$(printf ' %d:%02d' "$h" "$m")
        fi
    fi

    local icon
    case "$status" in
        Charging)    icon="CHG" ;;
        Discharging) icon="BAT" ;;
        *)           icon="AC" ;;
    esac
    echo "$icon ${cap}%${rem}"
}

while true; do
    echo "$(layout) | $(battery) | $(date +'%m-%d %H:%M')"
    sleep 1
done
