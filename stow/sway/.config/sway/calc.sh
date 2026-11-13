#!/usr/bin/env bash
# Calculator and currency converter in fuzzel, powered by Qalculate (qalc).
# Usage: calc.sh calc | calc.sh exchange
#
# calc:     expression -> result; Enter on the result copies it to the clipboard,
#           typing a new expression continues ("ans" = previous result).
# exchange: "100 eur" -> list of HUF/EUR/USD/GBP conversions, or
#           "100 eur to chf" for a specific target. Enter copies the line.

FZ=(fuzzel --config "$HOME/.config/fuzzel/sway.ini")
CURRENCIES=(HUF EUR USD GBP)          # default targets in exchange mode
RATES_MAX_AGE=$((24 * 3600))          # refresh rates after this many seconds
STAMP="$HOME/.cache/calc-rates.stamp"

err() { notify-send -a osd -u critical "Számológép" "$1"; exit 1; }
command -v qalc >/dev/null || err "A qalc nincs telepítve (sudo dnf install qalculate)"

mkdir -p "$(dirname "$STAMP")"

refresh_rates() {
    qalc -e -t 1 >/dev/null 2>&1 && touch "$STAMP"
}

if [ ! -e "$STAMP" ]; then
    refresh_rates                                   # first run: wait for the download
elif [ $(( $(date +%s) - $(stat -c %Y "$STAMP") )) -gt "$RATES_MAX_AGE" ]; then
    refresh_rates &                                 # refresh in the background
fi

# Generic qalc call; the leading space keeps the expression from being parsed as an option.
# conv 0: no automatic (mixed) unit conversion, zeroes off: no trailing zeros,
# uni 0: ASCII output (plain minus, EUR/GBP instead of the € / £ symbols).
# Extra qalc settings go into QALC_EXTRA (e.g. 2 decimals in exchange mode).
QALC_EXTRA=()
calc() {
    local e=${1//%[[:space:]]of[[:space:]]/% * }       # "15% of 8400" -> "15% * 8400"
    qalc -t -set "conv 0" -set "zeroes off" -set "uni 0" "${QALC_EXTRA[@]}" " $e" 2>&1 \
        | sed -E -e '/^$/d' -e 's/^\$/USD /'              # uniform currency notation
}

copy() {
    printf '%s' "$1" | wl-copy
    notify-send -a osd -t 1500 -h string:x-canonical-private-synchronous:calc "Vágólapra másolva" "$1"
}

mode_calc() {
    local expr res pick ans=""
    expr=$("${FZ[@]}" --dmenu --prompt-only "= ") || exit 0
    while [ -n "$expr" ]; do
        [ -n "$ans" ] && expr=${expr//ans/($ans)}
        res=$(calc "$expr" | tail -n 1)
        [ -z "$res" ] && res="Hiba"
        pick=$(printf '%s\n' "$res" | "${FZ[@]}" --dmenu --lines 1 --prompt "$expr = ") || exit 0
        if [ "$pick" = "$res" ]; then
            [ "$res" != "Hiba" ] && copy "$res"
            exit 0
        fi
        ans=$res
        expr=$pick                                  # new expression from the typed text
    done
}

mode_exchange() {
    local input lines pick
    QALC_EXTRA=(-set "maxdeci 2")
    input=$("${FZ[@]}" --dmenu --prompt-only "Váltás (pl. 100 eur): ") || exit 0
    [ -z "$input" ] && exit 0

    if [[ "${input,,}" =~ (^|[[:space:]])(to|in)[[:space:]] ]]; then
        lines=$(calc "$input")                      # explicit target: "100 eur to chf"
    else
        lines=""
        for c in "${CURRENCIES[@]}"; do
            lines+=$(calc "$input to $c")$'\n'
        done
    fi
    lines=$(printf '%s' "$lines" | sed '/^$/d')
    [ -z "$lines" ] && err "Nem sikerült átváltani: $input"

    pick=$(printf '%s\n' "$lines" \
        | "${FZ[@]}" --dmenu --lines "$(printf '%s\n' "$lines" | wc -l)" --prompt "$input → ") || exit 0
    [ -n "$pick" ] && copy "$pick"
}

case "$1" in
    calc)     mode_calc ;;
    exchange) mode_exchange ;;
    *) echo "Használat: $0 calc|exchange" >&2; exit 2 ;;
esac
