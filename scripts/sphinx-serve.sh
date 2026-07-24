#!/usr/bin/env bash
# sphinx-serve.sh — live-preview a Sphinx project in the browser.
# Creates/reuses a central (virtualenvwrapper-compatible) venv named after the
# project, installs the project's requirements (+ sphinx-autobuild), then serves
# with live reload. The venv lives in $WORKON_HOME, so `workon <project>` works.
#
# Usage: sphinx-serve.sh [SOURCEDIR]
#   SOURCEDIR defaults to the dir containing conf.py (., docs/, or source/).
set -euo pipefail

srcdir="${1:-}"
if [[ -z "$srcdir" ]]; then
    for d in . docs source; do
        [[ -f "$d/conf.py" ]] && { srcdir="$d"; break; }
    done
fi
[[ -n "${srcdir:-}" && -f "$srcdir/conf.py" ]] || {
    echo "sphinx-serve: no conf.py found (pass SOURCEDIR)" >&2; exit 1
}

name="$(basename "$PWD")"
WORKON_HOME="${WORKON_HOME:-$HOME/.virtualenvs}"
venv="$WORKON_HOME/$name"
mkdir -p "$WORKON_HOME"
[[ -d "$venv" ]] || { echo "[sphinx-serve] creating venv: $venv"; python3 -m venv "$venv"; }
"$venv/bin/pip" install --quiet --upgrade pip

req=""
for r in requirements.txt docs/requirements.txt "$srcdir/requirements.txt"; do
    [[ -f "$r" ]] && { req="$r"; break; }
done
if [[ -n "$req" ]]; then
    echo "[sphinx-serve] installing $req"
    "$venv/bin/pip" install --quiet -r "$req"
else
    echo "[sphinx-serve] no requirements.txt; installing sphinx + myst-parser"
    "$venv/bin/pip" install --quiet sphinx myst-parser
fi
"$venv/bin/pip" install --quiet sphinx-autobuild   # dev tool, rarely in requirements

echo "[sphinx-serve] serving $srcdir -> _build/html (workon $name; live reload)"
exec "$venv/bin/sphinx-autobuild" "$srcdir" _build/html --open-browser
