#!/usr/bin/env bash
# Change volume / brightness / mic mute and show feedback through mako.
# The synchronous hint makes each notification replace the previous one instead of stacking.
# Usage: osd.sh volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down

notify() { # key, title, text, [value]
    local args=(-a osd -t 1500
        -h "string:x-canonical-private-synchronous:$1")
    [ -n "$4" ] && args+=(-h "int:value:$4")
    notify-send "${args[@]}" "$2" "$3"
}

volume_pct() {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]\+%' | head -1 | tr -d '%'
}

case "$1" in
    volume-up|volume-down|volume-mute)
        case "$1" in
            volume-up)   pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
            volume-down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
            volume-mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
        esac
        vol=$(volume_pct)
        if pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes; then
            notify osd-volume "Hangerő" "Némítva" 0
        else
            notify osd-volume "Hangerő" "${vol}%" "$vol"
        fi
        ;;
    mic-mute)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        if pactl get-source-mute @DEFAULT_SOURCE@ | grep -q yes; then
            notify osd-mic "Mikrofon" "Némítva"
        else
            notify osd-mic "Mikrofon" "Bekapcsolva"
        fi
        ;;
    brightness-up|brightness-down)
        [ "$1" = brightness-up ] && step='5%+' || step='5%-'
        pct=$(brightnessctl -m set "$step" | cut -d, -f4 | tr -d '%')
        notify osd-brightness "Fényerő" "${pct}%" "$pct"
        ;;
esac
