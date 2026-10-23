#!/usr/bin/env bash
# Slim, read-only snapshot of a finished project repo into the Denote library's
# works/ folder, so one search root covers it. The original repo is never
# modified; the copy is a new local git repo with one commit and no remote
# (the original keeps its GitHub backup).
#
# Usage: snapshot-relic.sh SOURCE_REPO [SLUG] [--max-mb N] [--execute]
#   Without --execute it prints the plan and writes nothing.
#   Copies every tracked file of SOURCE_REPO as it is on disk, plus untracked
#   (not ignored) text-like files (org md txt tex bib py R qmd Rmd ipynb yml
#   yaml toml cfg sh el json csv), except files over N MB (default 2) and
#   anything under a dot-directory. Skipped files are listed in SKIPPED.tsv.
#   Writes README.org (origin path, remote, commit, date, dirty count), a
#   .project marker, and commits everything.
#
# Written for macOS's stock /bin/bash 3.2.
set -uo pipefail

LIB=${DENOTE_LIB:-$HOME/acropolis/denote-library}
max_mb=2
execute=0
src=
slug=
while (( $# > 0 )); do
    case $1 in
        --max-mb) shift; max_mb=${1:?}; ;;
        --execute) execute=1 ;;
        -h|--help) sed -n '2,/^set -uo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) if [[ -z $src ]]; then src=$1; elif [[ -z $slug ]]; then slug=$1; else echo "unexpected: $1" >&2; exit 2; fi ;;
    esac
    shift
done
[[ -n $src ]] || { echo "usage: snapshot-relic.sh SOURCE_REPO [SLUG] [--max-mb N] [--execute]" >&2; exit 2; }
src=$(cd "$src" && pwd -P) || exit 2
[[ $(git -C "$src" rev-parse --show-toplevel) == "$src" ]] || { echo "$src is not the top of a git repo" >&2; exit 2; }
slug=${slug:-$(basename "$src")}
dest=$LIB/works/$slug
[[ -e $dest ]] && { echo "$dest exists; refusing to overwrite" >&2; exit 1; }

limit=$((max_mb * 1048576))

is_text() {
    case ${1##*.} in
        org|md|txt|tex|bib|py|R|r|qmd|Rmd|ipynb|yml|yaml|toml|cfg|sh|el|json|csv) return 0 ;;
        *) return 1 ;;
    esac
}

candidates() {
    local u
    git -C "$src" ls-files -z
    git -C "$src" ls-files -o --exclude-standard -z | while IFS= read -r -d '' u; do
        if is_text "$u"; then printf '%s\0' "$u"; fi
    done
}
keep=0; keepb=0; skip=0; skipb=0
list=$(mktemp); skipped=$(mktemp)
trap 'rm -f "$list" "$skipped"' EXIT
while IFS= read -r -d '' f; do
    case $f in .*|*/.*) continue ;; esac
    [[ -f $src/$f ]] || continue
    size=$(stat -f %z "$src/$f")
    if (( size > limit )); then
        skip=$((skip + 1)); skipb=$((skipb + size)); printf '%s\t%s\n' "$size" "$f" >> "$skipped"
    else
        keep=$((keep + 1)); keepb=$((keepb + size)); printf '%s\n' "$f" >> "$list"
    fi
done < <(candidates)

dirty=$(git -C "$src" status --porcelain | wc -l | tr -d ' ')
commit=$(git -C "$src" rev-parse --short HEAD)
remote=$(git -C "$src" remote get-url origin 2>/dev/null || echo none)
echo "$src -> $dest"
printf 'copy %d files (%d KB); skip %d files over %d MB (%d KB); source commit %s, %s uncommitted change(s), remote %s\n' \
    "$keep" $((keepb / 1024)) "$skip" "$max_mb" $((skipb / 1024)) "$commit" "$dirty" "$remote"
(( execute )) || exit 0

mkdir -p "$dest"
while IFS= read -r f; do
    mkdir -p "$dest/$(dirname "$f")"
    cp -p "$src/$f" "$dest/$f"
done < "$list"
{ printf 'bytes\tpath\n'; sort -rn "$skipped"; } > "$dest/SKIPPED.tsv"
: > "$dest/.project"
cat > "$dest/README.org" <<EOF
#+title: $slug (relic snapshot)
#+snapshot_of: $src
#+snapshot_remote: $remote
#+snapshot_commit: $commit
#+snapshot_on: [$(date +%F)]

A slim read-only copy for searching alongside the Denote library. The original
repository is the working copy of record and keeps its own GitHub backup. Not
copied: files over $max_mb MB ($skip files, see =SKIPPED.tsv=) and dot-directories.
The original had $dirty uncommitted change(s) at the time; this copy holds the
files as they were on disk, not as committed.
EOF
git -C "$dest" init -q -b main
git -C "$dest" add -A
git -C "$dest" commit -q -m "Relic snapshot of $slug at $commit" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
echo "written: $dest ($(git -C "$dest" ls-files | wc -l | tr -d ' ') files committed)"
