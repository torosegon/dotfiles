#!/usr/bin/env bash
# Bluetooth menu in fuzzel (BlueZ / bluetoothctl).
# Picking a device: connected -> disconnect, paired -> connect,
# new -> pair + trust + connect.

FZ=(fuzzel --config "$HOME/.config/fuzzel/sway.ini")
SCAN_SECS=8

# Wait for the launcher fuzzel (app list) that started us to exit.
for _ in {1..20}; do pgrep -x fuzzel >/dev/null || break; sleep 0.05; done

note() {
    notify-send -a osd -t 3000 -h string:x-canonical-private-synchronous:bluetooth "Bluetooth" "$1"
}

# MACs / names from "Device MAC Name..." lines
dev_list() { bluetoothctl devices "$@" 2>/dev/null | sed -n 's/^Device \([0-9A-F:]\{17\}\) \(.*\)$/\1\t\2/p'; }

# An unpaired device is only interesting if it has a real name (not just a MAC).
unnamed() { [[ $1 =~ ^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$ ]]; }

run_bt() { # description, command...  (with timeout, reports failures)
    local what=$1; shift
    local out
    out=$(timeout 25 "$@" 2>&1)
    if [ $? -eq 0 ] && ! grep -qiE 'fail|error|not available' <<<"$out"; then
        note "$what: kész"; return 0
    fi
    note "$what: sikertelen ($(printf '%s\n' "$out" | sed '/^$/d' | tail -n 1))"
    return 1
}

while true; do
    entries=(); act=(); macs=(); names=()
    add() { entries+=("$1"); act+=("$2"); macs+=("$3"); names+=("$4"); }

    powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')
    if [ "$powered" = yes ]; then
        declare -A conn=() pair=() nm=()
        while IFS=$'\t' read -r m n; do conn[$m]=1; done < <(dev_list Connected)
        while IFS=$'\t' read -r m n; do pair[$m]=1; done < <(dev_list Paired)
        order=()
        while IFS=$'\t' read -r m n; do nm[$m]=$n; order+=("$m"); done < <(dev_list)

        # order: connected, paired, new
        for pass in conn pair new; do
            for m in "${order[@]}"; do
                n=${nm[$m]}
                case $pass in
                    conn) [ -n "${conn[$m]}" ] || continue
                          add "$(printf '* %-34s csatlakozva' "$n")" dev "$m" "$n" ;;
                    pair) [ -z "${conn[$m]}" ] && [ -n "${pair[$m]}" ] || continue
                          add "$(printf '  %-34s párosítva' "$n")" dev "$m" "$n" ;;
                    new)  [ -z "${pair[$m]}" ] || continue
                          unnamed "$n" && continue
                          add "$(printf '  %-34s új' "$n")" dev "$m" "$n" ;;
                esac
            done
        done
        unset conn pair nm
        add "  Keresés (${SCAN_SECS} mp)" scan
        add "  Bluetooth kikapcsolása" off
    else
        add "  Bluetooth bekapcsolása" on
    fi
    add "  Terminál (bluetoothctl)…" term

    idx=$(printf '%s\n' "${entries[@]}" \
        | "${FZ[@]}" --dmenu --index --minimal-lines --lines 14 --width 60 --prompt "Bluetooth: ") || exit 0
    [ -z "$idx" ] && exit 0

    m=${macs[$idx]}; n=${names[$idx]}
    case "${act[$idx]}" in
        dev)
            if bluetoothctl devices Connected 2>/dev/null | grep -q "$m"; then
                run_bt "Szétkapcsolás: $n" bluetoothctl disconnect "$m"
            elif bluetoothctl devices Paired 2>/dev/null | grep -q "$m"; then
                note "Csatlakozás: $n…"
                run_bt "Csatlakozás: $n" bluetoothctl connect "$m"
            else
                note "Párosítás: $n…"
                if run_bt "Párosítás: $n" bluetoothctl --agent NoInputNoOutput pair "$m"; then
                    bluetoothctl trust "$m" >/dev/null 2>&1
                    run_bt "Csatlakozás: $n" bluetoothctl connect "$m"
                fi
            fi
            exit 0 ;;
        scan) note "Keresés… (${SCAN_SECS} mp)"; bluetoothctl --timeout "$SCAN_SECS" scan on >/dev/null 2>&1 ;;
        off)  bluetoothctl power off >/dev/null 2>&1; note "Bluetooth kikapcsolva"; exit 0 ;;
        on)   rfkill unblock bluetooth 2>/dev/null; bluetoothctl power on >/dev/null 2>&1; note "Bluetooth bekapcsolva"; sleep 1 ;;
        term) foot -e bluetoothctl >/dev/null 2>&1 & exit 0 ;;
    esac
done
