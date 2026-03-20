#!/bin/bash

DATA=$(cat)

MODEL=$(echo "$DATA" | grep -oP '"display_name"\s*:\s*"\K[^"]+' 2>/dev/null)
REM_PCT=$(echo "$DATA" | grep -oP '"remaining_percentage"\s*:\s*\K\d+' 2>/dev/null | head -1)

BRANCH=$(git branch --show-current 2>/dev/null)
DIRTY=$(git status --porcelain 2>/dev/null | wc -l)
DIFF_STAT=$(git diff --shortstat 2>/dev/null)
ADDED=$(echo "$DIFF_STAT" | grep -oP '\d+(?= insertion)' || echo "0")
REMOVED=$(echo "$DIFF_STAT" | grep -oP '\d+(?= deletion)' || echo "0")

# Gruvbox colors
YELLOW='\033[38;2;215;153;33m'
GREEN='\033[38;2;0;215;95m'
BLUE='\033[38;2;131;165;152m'
ORANGE='\033[38;2;254;128;25m'
RED='\033[38;2;251;73;52m'
GRAY='\033[38;2;146;131;116m'
RESET='\033[0m'

if [ "${REM_PCT}" -le 20 ] 2>/dev/null; then
    CTX_COLOR=$RED
elif [ "${REM_PCT}" -le 40 ] 2>/dev/null; then
    CTX_COLOR=$ORANGE
else
    CTX_COLOR=$GREEN
fi

OUT="${BLUE}${MODEL}${RESET}"
OUT+=" ${GRAY}│${RESET} ctx: ${CTX_COLOR}${REM_PCT}%${RESET}"
OUT+=" ${GRAY}│${RESET} "

if [ -n "$BRANCH" ]; then
    if [ "$DIRTY" -gt 0 ]; then
        OUT+="${YELLOW}${BRANCH} ●${RESET}"
    else
        OUT+="${GREEN}${BRANCH}${RESET}"
    fi
    if [ -n "$DIFF_STAT" ]; then
        OUT+=" ${GREEN}+${ADDED}${RESET} ${RED}-${REMOVED}${RESET}"
    fi
else
    OUT+="${GRAY}no git${RESET}"
fi

echo -e "$OUT"
