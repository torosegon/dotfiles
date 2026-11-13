#!/usr/bin/env bash
# Screenshots with grim + slurp. Every capture is saved to a folder AND copied to the clipboard.
# A notification with a thumbnail appears; clicking it (or "edit") opens an annotator
# (satty if installed, otherwise swappy) that overwrites the original file and refreshes the clipboard.
#
# Usage: screenshot.sh full|window|region|edit [file]|menu
#   full    focused output
#   window  click a window
#   region  drag an area
#   edit    annotate a screenshot (pick from the latest ones, or give a file)
#   menu    fuzzel menu with all of the above

DIR="${SCREENSHOT_DIR:-$(xdg-user-dir PICTURES)/Screenshots}"
FZ=(fuzzel --config "$HOME/.config/fuzzel/sway.ini")
SLURP_STYLE=(-b '#00000066' -c '#4c7899ff' -s '#28557733' -w 2)
mkdir -p "$DIR"

note() { notify-send -a screenshot -t 3000 -h string:x-canonical-private-synchronous:screenshot "$@"; }

# Wait for the launcher fuzzel (app list) that started us to exit.
wait_launcher() { for _ in {1..20}; do pgrep -x fuzzel >/dev/null || break; sleep 0.05; done; }

# Notification with thumbnail; clicking it triggers the "default" action = edit.
announce() { # file
    (
        action=$(notify-send -a screenshot -i "$1" -t 8000 -A default=Edit \
            -h string:x-canonical-private-synchronous:screenshot \
            "Képernyőkép mentve" "$(basename "$1")"$'\n'"Vágólapra másolva · kattints a szerkesztéshez")
        [ "$action" = default ] && edit "$1"
    ) >/dev/null 2>&1 &
}

capture() { # mode
    local mode=$1 file geo out
    file="$DIR/$(date +'%Y-%m-%d_%H-%M-%S')_$mode.png"
    case $mode in
        full)
            out=$(swaymsg -t get_outputs -r | jq -r '.[] | select(.focused) | .name')
            grim -o "$out" "$file" ;;
        region)
            geo=$(slurp -d "${SLURP_STYLE[@]}") || return 0      # Esc = cancelled
            grim -g "$geo" "$file" ;;
        window)
            # visible windows as boxes; slurp -r restricts the selection to them
            geo=$(swaymsg -t get_tree \
                    | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' \
                    | slurp -r "${SLURP_STYLE[@]}") || return 0
            grim -g "$geo" "$file" ;;
    esac
    [ -s "$file" ] || { note "Képernyőkép" "Sikertelen mentés"; return 1; }
    wl-copy --type image/png < "$file"
    announce "$file"
}

edit() { # [file]
    local f=${1:-} files idx before after
    if [ -z "$f" ]; then
        wait_launcher
        mapfile -t files < <(ls -1t "$DIR"/*.png 2>/dev/null | head -20)
        [ ${#files[@]} -gt 0 ] || { note "Képernyőkép" "Még nincs mentett képernyőkép"; return 1; }
        idx=$(printf '%s\n' "${files[@]##*/}" \
            | "${FZ[@]}" --dmenu --index --minimal-lines --lines 12 --width 50 --prompt "Szerkesztés: ") || return 0
        f=${files[$idx]}
    fi
    before=$(stat -c %y "$f")
    if command -v satty >/dev/null; then
        satty --filename "$f" --output-filename "$f" --copy-command wl-copy --early-exit
    elif command -v swappy >/dev/null; then
        swappy -f "$f" -o "$f"
    else
        note "Képernyőkép" "Nincs annotáló: sudo dnf install swappy"; return 1
    fi
    after=$(stat -c %y "$f")
    # Saved changes land in the original file; keep the clipboard in sync with it.
    if [ "$before" != "$after" ]; then
        wl-copy --type image/png < "$f"
        note "Képernyőkép frissítve" "$(basename "$f")"
    fi
}

menu() {
    wait_launcher
    local idx
    idx=$(printf '%s\n' "  Terület" "  Ablak" "  Teljes képernyő" "  Szerkesztés…" "  Mappa megnyitása" \
        | "${FZ[@]}" --dmenu --index --minimal-lines --lines 8 --width 40 --prompt "Képernyőkép: ") || return 0
    case $idx in
        0) sleep 0.3; capture region ;;    # short delay so the menu is gone from the capture
        1) sleep 0.3; capture window ;;
        2) sleep 0.3; capture full ;;
        3) edit ;;
        4) foot -e yazi "$DIR" >/dev/null 2>&1 & ;;
    esac
}

case "${1:-menu}" in
    full|window|region) capture "$1" ;;
    edit)               shift; edit "${1:-}" ;;
    menu)               menu ;;
    *) echo "Használat: $0 full|window|region|edit [file]|menu" >&2; exit 2 ;;
esac
