#!/usr/bin/env bash
# Lock the session with gtklock over a blurred copy of the current wallpaper.
# No `set -e`: a failed blur must never stop the screen from actually locking.
set -u

CACHE="$HOME/.cache/lock-bg.png"
CONFIG="$HOME/.config/gtklock/config.ini"
LAYOUT="$HOME/.config/gtklock/layout.xml"

# Same wallpaper sway picks (see the sway config exec_always).
WALLPAPER=""
for f in "$HOME"/wallpaper.jpg "$HOME"/wallpaper.jpeg "$HOME"/wallpaper.png; do
	[ -f "$f" ] && WALLPAPER="$f" && break
done

# Background for gtklock: a blurred copy of the wallpaper when ImageMagick is
# available, otherwise the raw wallpaper so the screen is never blank.
BG=""
if [ -n "$WALLPAPER" ]; then
	if command -v convert >/dev/null 2>&1; then
		[ "$WALLPAPER" -nt "$CACHE" ] && mkdir -p "$(dirname "$CACHE")" &&
			convert "$WALLPAPER" -blur 0x8 -modulate 60 "$CACHE"
		BG="$CACHE"
	else
		BG="$WALLPAPER"
	fi
fi

ARGS=()
[ -f "$CONFIG" ] && ARGS+=(-c "$CONFIG")
[ -f "$LAYOUT" ] && ARGS+=(-x "$LAYOUT")
[ -n "$BG" ] && [ -f "$BG" ] && ARGS+=(-b "$BG")

exec gtklock "${ARGS[@]}"
