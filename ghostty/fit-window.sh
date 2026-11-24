#!/usr/bin/env bash
# Author : Dr. Denys Dutykh (Mathematics Department, Khalifa University of Science and Technology, Abu Dhabi, UAE)
# License: MIT, see LICENSE at the repository root
#
# fit-window.sh [--write] COLUMNS ROWS
#
# Finds the two numbers, window-width and window-height, that make a new Ghostty window open with
# exactly COLUMNS columns and ROWS rows on this machine, and prints them as lines for
# ~/.config/ghostty/local. With --write it puts them into that file in place of the old ones, after
# keeping the old file as local.before-fit.
#
# Why it is needed. On GNOME with the text scaled (gsettings get org.gnome.desktop.interface
# text-scaling-factor above 1) Ghostty draws the letters at that scale but sizes a new window from
# letters that are not scaled, so the grid comes out smaller than window-width by window-height: 62
# by 14 for the shared 78 by 20 at the scale 1.25. The error depends on the size of the letters and
# on the title bar, and the grid moves in uneven steps (77 columns, then 79), so the numbers are
# measured, not computed: each trial opens a window, waits until it has settled and reads its grid
# with stty. Run it again after every change of font-size or of the scale of the text.
#
# What it does to the desktop. It opens between three and twelve small Ghostty windows, one after
# the other, each for about three seconds, and each takes the keyboard focus while it is open. It
# needs a graphical session. It reads config.ghostty and local from ~/.config/ghostty, leaves out
# their window-width and window-height, and gives its own trial file to Ghostty, which a running
# Ghostty never sees. It changes nothing but the file named above, and only with --write.
#
# A line of a file read through config-file beats an option of the command line, so the trials
# cannot be made with options on top of the real files: the trial file is a copy without those lines.

set -u

usage() {
    echo "usage: fit-window.sh [--write] COLUMNS ROWS" >&2
    exit 2
}

write=0
if [ "${1:-}" = "--write" ]; then
    write=1
    shift
fi
cols=${1:-}
rows=${2:-}
[[ $cols =~ ^[0-9]+$ && $rows =~ ^[0-9]+$ ]] || usage
command -v ghostty > /dev/null || { echo "fit-window: ghostty is not installed" >&2; exit 1; }
[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] || { echo "fit-window: no graphical session" >&2; exit 1; }

dir=${XDG_CONFIG_HOME:-$HOME/.config}/ghostty
local_file=$dir/local
scratch=$(mktemp -d) || exit 1
trap 'rm -rf "$scratch"' EXIT

# The configuration without the window size and without the line that reads the local file.
for f in "$dir/config.ghostty" "$local_file"; do
    [ -r "$f" ] && grep -v -E '^[[:space:]]*(config-file|window-width|window-height)[[:space:]]*=' "$f"
done > "$scratch/base.conf"

scale=$(gsettings get org.gnome.desktop.interface text-scaling-factor 2> /dev/null)
scale=${scale##* }
[[ $scale =~ ^[0-9]+(\.[0-9]+)?$ ]] || scale=1

# One trial: a window with the requested width and height; sets c and r to the grid that it ends with.
trial() {
    local conf=$scratch/trial.conf out=$scratch/grid.txt
    { cat "$scratch/base.conf"; printf 'window-width = %s\nwindow-height = %s\n' "$1" "$2"; } > "$conf"
    rm -f "$out"
    timeout 30 ghostty --config-default-files=false --config-file="$conf" --gtk-single-instance=false \
        -e bash -c "sleep 2; stty size > '$out'; sleep 0.2" > /dev/null 2>&1
    c=""
    r=""
    [ -s "$out" ] && read -r r c < "$out"
    [ -n "$c" ]
}

# The next request along one axis. Arguments: the wanted value, the factor between a step of the
# request and a step of the result, then the measured pairs "request:result" separated by spaces.
# It prints the request to try, or nothing when the wanted value lies between two neighbours.
next_request() {
    local want=$1 factor=$2 pairs=$3 lo="" hi="" lo_r="" hi_r="" p q res
    for p in $pairs; do
        q=${p%%:*}
        res=${p##*:}
        if [ "$res" -lt "$want" ] && { [ -z "$lo" ] || [ "$q" -gt "$lo" ]; }; then lo=$q; lo_r=$res; fi
        if [ "$res" -gt "$want" ] && { [ -z "$hi" ] || [ "$q" -lt "$hi" ]; }; then hi=$q; hi_r=$res; fi
    done
    if [ -n "$lo" ] && [ -n "$hi" ]; then
        [ $((hi - lo)) -le 1 ] && return 0
        echo $(((lo + hi) / 2))
    elif [ -n "$lo" ]; then
        awk -v q="$lo" -v d="$((want - lo_r))" -v f="$factor" 'BEGIN { s = int(d * f + 0.999); if (s < 1) s = 1; print q + s }'
    elif [ -n "$hi" ]; then
        awk -v q="$hi" -v d="$((hi_r - want))" -v f="$factor" 'BEGIN { s = int(d * f + 0.999); if (s < 1) s = 1; print q - s }'
    fi
}

width=$(awk -v n="$cols" -v s="$scale" 'BEGIN { printf "%d", n * s + 0.5 }')
height=$((rows + 7))
width_pairs=""
height_pairs=""
found_w=""
found_h=""

for _ in $(seq 1 14); do
    trial "$width" "$height" || { echo "fit-window: Ghostty gave no answer" >&2; exit 1; }
    printf 'request %sx%s gives %s columns and %s rows\n' "$width" "$height" "$c" "$r"
    width_pairs="$width_pairs $width:$c"
    height_pairs="$height_pairs $height:$r"
    [ "$c" -eq "$cols" ] && found_w=$width
    [ "$r" -eq "$rows" ] && found_h=$height
    if [ -n "$found_w" ] && [ -n "$found_h" ]; then
        break
    fi
    if [ -z "$found_w" ]; then
        next=$(next_request "$cols" "$scale" "$width_pairs")
        if [ -n "$next" ]; then width=$next; else break; fi
    else
        width=$found_w
    fi
    if [ -z "$found_h" ]; then
        next=$(next_request "$rows" 1 "$height_pairs")
        if [ -n "$next" ]; then height=$next; else break; fi
    else
        height=$found_h
    fi
done

if [ -z "$found_w" ] || [ -z "$found_h" ]; then
    echo "fit-window: no request gives exactly $cols columns and $rows rows at this size of the letters." >&2
    echo "The grid skips the wanted value: change font-size by half a point in $local_file and run it again." >&2
    exit 1
fi

# The two numbers found separately must give the grid together.
trial "$found_w" "$found_h" && [ "$c" -eq "$cols" ] && [ "$r" -eq "$rows" ] || {
    echo "fit-window: the pair $found_w by $found_h gives ${c:-nothing} columns and ${r:-nothing} rows; run it again" >&2
    exit 1
}
printf 'checked: %s by %s gives %s columns and %s rows\n\n' "$found_w" "$found_h" "$c" "$r"

if [ "$write" -eq 1 ]; then
    [ -f "$local_file" ] && cp -p "$local_file" "$local_file.before-fit"
    {
        [ -f "$local_file" ] && grep -v -E '^[[:space:]]*(window-width|window-height)[[:space:]]*=' "$local_file"
        printf 'window-width = %s\nwindow-height = %s\n' "$found_w" "$found_h"
    } > "$scratch/local.new"
    cat "$scratch/local.new" > "$local_file"
    echo "written to $local_file (the earlier file is local.before-fit)"
else
    printf 'window-width = %s\nwindow-height = %s\n' "$found_w" "$found_h"
fi
