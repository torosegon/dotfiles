#!/usr/bin/env bash
# Wi-Fi menu in fuzzel (NetworkManager / nmcli).
# Picking a network connects to known ones and asks for a password for new ones.

FZ=(fuzzel --config "$HOME/.config/fuzzel/sway.ini")

# Wait for the launcher fuzzel (app list) that started us to exit.
for _ in {1..20}; do pgrep -x fuzzel >/dev/null || break; sleep 0.05; done

note() {
    notify-send -a osd -t 3000 -h string:x-canonical-private-synchronous:wifi "Wi-Fi" "$1"
}

wifi_dev() { nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}'; }

known_profile() {
    nmcli -t -f NAME,TYPE connection show \
        | awk -F: -v n="$1" '$2=="802-11-wireless" && $1==n {f=1} END{exit !f}'
}

# Last meaningful line of an nmcli error message.
last_line() { printf '%s\n' "$1" | sed '/^$/d' | tail -n 1; }

connect_net() { # ssid, security
    local ssid=$1 sec=$2 out pw rc
    note "Csatlakozás: $ssid…"
    if known_profile "$ssid"; then
        out=$(nmcli connection up id "$ssid" 2>&1); rc=$?
    elif [ -z "$sec" ] || [ "$sec" = "--" ]; then
        out=$(nmcli device wifi connect "$ssid" 2>&1); rc=$?
    elif [[ $sec == *802.1X* ]]; then
        note "Vállalati (802.1X) hálózat: a haladó beállításokban add meg az adatokat."
        nm-connection-editor >/dev/null 2>&1 &
        return 0
    else
        pw=$("${FZ[@]}" --dmenu --prompt-only --password "Jelszó ($ssid): ") || return 0
        [ -z "$pw" ] && return 0
        out=$(nmcli device wifi connect "$ssid" password "$pw" 2>&1); rc=$?
        # A wrong password leaves a half-created profile behind in nmcli.
        [ $rc -ne 0 ] && nmcli connection delete id "$ssid" >/dev/null 2>&1
    fi
    if [ $rc -eq 0 ]; then note "Csatlakozva: $ssid"; return 0; fi
    note "Sikertelen: $(last_line "$out")"
    return 1
}

while true; do
    entries=(); act=(); ssids=(); secs=()
    add() { entries+=("$1"); act+=("$2"); ssids+=("$3"); secs+=("$4"); }

    if [ "$(nmcli radio wifi)" = enabled ]; then
        unset seen; declare -A seen
        # Active SSID (marks correctly even with several access points sharing a name)
        active=$(nmcli -t -f IN-USE,SSID device wifi list | sed -n 's/^\*://p' | head -n 1)
        active=${active//\\:/:}; active=${active//\\\\/\\}
        while IFS= read -r line; do
            use=${line%%:*};  rest=${line#*:}
            sig=${rest%%:*};  rest=${rest#*:}
            sec=${rest%%:*};  ssid=${rest#*:}
            ssid=${ssid//\\:/:}; ssid=${ssid//\\\\/\\}
            [ -z "$ssid" ] && continue
            [ -n "${seen[$ssid]}" ] && continue
            seen[$ssid]=1
            mark="  "; [ "$ssid" = "$active" ] && mark="* "
            [ -z "$sec" ] && sec="--"
            label=$sec; [ "$sec" = "--" ] && label="nyílt"
            add "$(printf '%s%-32s %3s%%  %s' "$mark" "$ssid" "$sig" "$label")" net "$ssid" "$sec"
        done < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list | sort -t: -k2 -nr)
        unset seen

        [ -n "$active" ] && add "  Szétkapcsolás: $active" disconnect
        add "  Újrakeresés" rescan
        add "  Wi-Fi kikapcsolása" off
    else
        add "  Wi-Fi bekapcsolása" on
    fi
    add "  Haladó beállítások…" editor

    idx=$(printf '%s\n' "${entries[@]}" \
        | "${FZ[@]}" --dmenu --index --minimal-lines --lines 14 --width 60 --prompt "Wi-Fi: ") || exit 0
    [ -z "$idx" ] && exit 0

    case "${act[$idx]}" in
        net)        connect_net "${ssids[$idx]}" "${secs[$idx]}"; exit 0 ;;
        disconnect) nmcli device disconnect "$(wifi_dev)" >/dev/null 2>&1 && note "Szétkapcsolva"; exit 0 ;;
        rescan)     note "Keresés…"; nmcli device wifi rescan >/dev/null 2>&1; sleep 3 ;;
        off)        nmcli radio wifi off; note "Wi-Fi kikapcsolva"; exit 0 ;;
        on)         rfkill unblock wifi 2>/dev/null; nmcli radio wifi on; note "Wi-Fi bekapcsolva"; sleep 3 ;;
        editor)     nm-connection-editor >/dev/null 2>&1 & exit 0 ;;
    esac
done
