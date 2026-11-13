#!/usr/bin/env bash
# Automatic dark/light mode: dark after sunset, light after sunrise.
# Switches GTK/libadwaita apps and browsers (color-scheme via the portal)
# and the foot terminal (running instances via SIGUSR1/2, new windows via theme.ini).
#
# Usage: darkmode.sh [tick|dark|light|toggle|auto|status]
#   tick    (default) called by a timer: set the mode matching the time of day
#   dark    manual dark, valid until the next sunrise/sunset
#   light   manual light, same as above
#   toggle  switch to the other mode (manual)
#   auto    clear the manual override, back to automatic
#   status  today's sunrise/sunset and the current mode

LAT=47.4979     # Budapest
LON=19.0402

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/darkmode"
STATE="$CACHE/state"     # last applied mode (dark|light)
HOLD="$CACHE/hold"       # on manual switch: the period (day|night) it is valid for
mkdir -p "$CACHE"

# period + today's sunrise/sunset in local time: "day|night HH:MM HH:MM"
solar() {
    python3 -I - "$LAT" "$LON" <<'PY'
import sys, math, datetime as dt
lat, lon = float(sys.argv[1]), float(sys.argv[2])
utc = dt.timezone.utc
now = dt.datetime.now(utc)
n = now.timetuple().tm_yday
g = 2 * math.pi / 365 * (n - 1)
eq = 229.18 * (0.000075 + 0.001868*math.cos(g) - 0.032077*math.sin(g)
               - 0.014615*math.cos(2*g) - 0.040849*math.sin(2*g))
d = (0.006918 - 0.399912*math.cos(g) + 0.070257*math.sin(g) - 0.006758*math.cos(2*g)
     + 0.000907*math.sin(2*g) - 0.002697*math.cos(3*g) + 0.00148*math.sin(3*g))
la = math.radians(lat)
c = math.cos(math.radians(90.833)) / (math.cos(la) * math.cos(d)) - math.tan(la) * math.tan(d)
ha = math.degrees(math.acos(max(-1.0, min(1.0, c))))
base = dt.datetime(now.year, now.month, now.day, tzinfo=utc)
rise = base + dt.timedelta(minutes=720 - 4*(lon + ha) - eq)
sett = base + dt.timedelta(minutes=720 - 4*(lon - ha) - eq)
period = "day" if rise <= now < sett else "night"
loc = lambda t: t.astimezone().strftime("%H:%M")
print(period, loc(rise), loc(sett))
PY
}

apply() {  # dark|light
    local mode=$1 scheme sig
    if [ "$mode" = dark ]; then scheme=prefer-dark; sig=USR1; else scheme=default; sig=USR2; fi
    gsettings set org.gnome.desktop.interface color-scheme "$scheme"
    # foot: new windows start from theme.ini, running ones get a signal
    mkdir -p "$HOME/.config/foot"
    printf '[main]\ninitial-color-theme=%s\n' "$mode" > "$HOME/.config/foot/theme.ini"
    pkill -"$sig" -x foot 2>/dev/null
    echo "$mode" > "$STATE"
}

current() { cat "$STATE" 2>/dev/null; }

case "${1:-tick}" in
    tick)
        read -r period _ <<<"$(solar)"
        if [ -f "$HOLD" ] && [ "$(cat "$HOLD")" = "$period" ]; then exit 0; fi   # manual override active
        rm -f "$HOLD"
        want=$([ "$period" = day ] && echo light || echo dark)
        [ "$(current)" = "$want" ] || apply "$want"
        ;;
    dark|light)
        read -r period _ <<<"$(solar)"; echo "$period" > "$HOLD"; apply "$1" ;;
    toggle)
        read -r period _ <<<"$(solar)"; echo "$period" > "$HOLD"
        [ "$(current)" = dark ] && apply light || apply dark ;;
    auto)
        rm -f "$HOLD"; exec "$0" tick ;;
    status)
        read -r period rise sett <<<"$(solar)"
        echo "mód: $(current || true)  napszak: $period  napkelte: $rise  napnyugta: $sett  $([ -f "$HOLD" ] && echo '(kézi felülírással)')" ;;
    *)  echo "Használat: $0 [tick|dark|light|toggle|auto|status]" >&2; exit 2 ;;
esac
