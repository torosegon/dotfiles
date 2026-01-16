#!/usr/bin/env bash

SEP="::"

DATE=$(date +'%m. %d., %H:%M')

VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk -F'/' '{print $2}' | tr -d ' ')
pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes && VOL="MTD"

BAT_STAT=""

if [ -f "/sys/class/power_supply/BAT0" ]; then
	BAT="/sys/class/power_supply/BAT0"
	if [[ -d $BAT ]]; then
	    BAT_P=$(<"$BAT/capacity")
	    BAT_S=$(<"$BAT/status")
	else
	    BAT_P="?"
	    BAT_S="Unknown"
	fi

	case $BAT_S in
	  Charging)    BAT_SYM="+" ;;
	  Discharging) BAT_SYM="-" ;;
	  *)           BAT_SYM="~" ;;
	esac

	BAT_STAT = " ${SEP} [BAT ${BAT_SYM}${BAT_P}%]"
fi

KB_LAYOUT=$(swaymsg -t get_inputs \
  | jq -r '.[] | select(.type == "keyboard") | .xkb_active_layout_name' \
  | head -n1 \
  | awk '{ print ($2 ? $2 : $1) }' \
  | sed 's/[()]//g' \
  | tr '[:lower:]' '[:upper:]')

[[ $KB_LAYOUT == HUNGARIAN ]] && KB_LAYOUT=HU

echo "[${KB_LAYOUT}] ${SEP} [VOL ${VOL}]${BAT_STAT} ${SEP} $DATE"
