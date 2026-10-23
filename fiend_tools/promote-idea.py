#!/usr/bin/env python3
"""promote-idea.py: copy an idea note and everything it touches into a
self-contained project directory.

    promote-idea.py NOTE SLUG [--lib DIR] [--dest-parent DIR] [--bib FILE]
                    [--deny kw,kw,...] [--no-git] [--execute]
    promote-idea.py --check PROJECT_DIR

NOTE is a Denote file path or identifier. Without --execute nothing is
written; the plan and the link checks are printed. The origin is never
modified. Exit status 2 means something does not resolve in the copy.

The project goes to LIB/works/SLUG. With --execute it also gets its own git
repository (git init, a .gitignore for library/ and *.pdf, no commit, no
remote). Skip that with --no-git.
"""
from __future__ import annotations

import argparse
import datetime
import hashlib
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

DENOTE = re.compile(r"^(?P<id>\d{8}T\d{6})(?:==[^-]+)?--(?P<title>.*?)(?:__(?P<kw>[^.]*))?\.(?:org|md|txt)$")
DENOTE_LINK = re.compile(r"\[\[denote:(\d{8}T\d{6})")
CITE = re.compile(r"\[cite(?:/[^:\]]*)?:([^\]]*)\]")
CITE_KEY = re.compile(r"@([\w:.#$%&+?<>~/-]+)")
REFERENCE = re.compile(r"^#\+reference:\s*(.+)$", re.M)
FILE_LINK = re.compile(r"\[\[file:([^\]]+?)(?:::[^\]]*)?\]")
BIB_START = re.compile(r"^@(\w+)\{([^,\s]+),", re.M)
FILE_FIELD = re.compile(r"^(\s*)file\s*=\s*\{(.*?)\}(,?)[ \t]*$", re.M)
DENY = "hub,life,journal,security,pw,codes,finances,health"


def index_library(lib: Path) -> dict[str, tuple[Path, list[str]]]:
    notes = {}
    for sub in ("pkb", "bib_notes", "notes"):
        if not (lib / sub).is_dir():
            continue
        for p in sorted((lib / sub).iterdir()):
            if p.is_symlink() or not p.is_file() or p.name[0] in ".#":
                continue
            m = DENOTE.match(p.name)
            if m:
                notes[m["id"]] = (p, (m["kw"] or "").split("_"))
    return notes


def split_bib(text: str) -> dict[str, str]:
    starts = list(BIB_START.finditer(text))
    entries = {}
    for i, m in enumerate(starts):
        if m[1].lower() in ("comment", "string", "preamble"):
            continue
        end = starts[i + 1].start() if i + 1 < len(starts) else len(text)
        entries[m[2]] = text[m.start():end].rstrip() + "\n"
    return entries


def keys_in(text: str) -> set[str]:
    return {k.rstrip(".:") for blk in CITE.findall(text) for k in CITE_KEY.findall(blk)}


def refs_in(text: str) -> set[str]:
    return {k.strip() for line in REFERENCE.findall(text) for k in line.split(";") if k.strip()}


def report(texts: dict[str, str], ids: set[str], keys: set[str], rel_files: set[str]) -> list[str]:
    """Unresolved references, given what the copy contains."""
    bad = []
    for name, text in texts.items():
        bad += [f"{name}: denote:{i} not in copy" for i in sorted(set(DENOTE_LINK.findall(text)) - ids)]
        bad += [f"{name}: cite key @{k} not in refs.bib" for k in sorted(keys_in(text) - keys)]
        for link in sorted(set(FILE_LINK.findall(text))):
            if link.startswith(("~", "/", "http")):
                bad.append(f"{name}: absolute or external file link {link}")
            elif link not in rel_files:
                bad.append(f"{name}: file:{link} not in copy")
    return bad


def check_tree(dest: Path) -> list[str]:
    notes_dir = dest / "notes"
    texts = {p.name: p.read_text(encoding="utf-8") for p in notes_dir.glob("*.org")}
    ids = {DENOTE.match(n)["id"] for n in texts if DENOTE.match(n)}
    bib = split_bib((dest / "refs.bib").read_text(encoding="utf-8")) if (dest / "refs.bib").exists() else {}
    rel = {str(p.relative_to(notes_dir)) for p in notes_dir.rglob("*") if p.is_file()}
    bad = report(texts, ids, set(bib), rel)
    for key, entry in bib.items():
        for m in FILE_FIELD.finditer(entry):
            bad += [f"refs.bib @{key}: {f} missing" for f in m[2].split(";") if not (dest / f).exists()]
    return bad


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("note", nargs="?")
    ap.add_argument("slug", nargs="?")
    ap.add_argument("--lib", default=os.environ.get("DENOTE_LIB", "~/acropolis/denote-library"))
    ap.add_argument("--bib", help="master .bib (default: LIB/full_lib.bib)")
    ap.add_argument("--dest-parent", help="default: LIB/works")
    ap.add_argument("--no-git", action="store_true", help="do not git init the new project")
    ap.add_argument("--deny", default=DENY, help="Denote keywords whose notes are never copied")
    ap.add_argument("--execute", action="store_true")
    ap.add_argument("--check", metavar="PROJECT_DIR")
    a = ap.parse_args()

    if a.check:
        bad = check_tree(Path(a.check).expanduser())
        print("\n".join(bad) or "all references resolve")
        return 2 if bad else 0
    if not (a.note and a.slug):
        ap.error("NOTE and SLUG are required")

    lib = Path(a.lib).expanduser()
    bib_path = Path(a.bib).expanduser() if a.bib else lib / "full_lib.bib"
    dest = (Path(a.dest_parent).expanduser() if a.dest_parent else lib / "works") / a.slug
    deny = set(a.deny.split(","))
    notes = index_library(lib)
    m = DENOTE.match(Path(a.note).name) or re.match(r"(?P<id>\d{8}T\d{6})$", a.note)
    if not m or m["id"] not in notes:
        sys.exit("NOTE must be the file name or identifier of a note in LIB/pkb or LIB/bib_notes")
    seed_id = m["id"]
    seed = notes[seed_id][0]
    texts = {i: p.read_text(encoding="utf-8") for i, (p, _) in notes.items()}

    # closure: the seed, the notes it links, and the bib notes for the keys it cites
    copy_ids, warn = {seed_id}, []
    for i in sorted(set(DENOTE_LINK.findall(texts[seed_id]))):
        if i not in notes:
            warn.append(f"denote:{i} does not exist in the library")
        elif deny & set(notes[i][1]):
            warn.append(f"denote:{i} not copied (deny-list: {','.join(sorted(deny & set(notes[i][1])))})")
        else:
            copy_ids.add(i)
    by_reference = {}
    for i, t in texts.items():
        for k in refs_in(t):
            by_reference.setdefault(k, []).append(i)
    for k in keys_in(texts[seed_id]) | refs_in(texts[seed_id]):
        copy_ids.update(by_reference.get(k, []))

    # bibliography subset; PDFs move to library/ and the file field is rewritten
    master = split_bib(bib_path.read_text(encoding="utf-8"))
    wanted = set().union(*(keys_in(texts[i]) | refs_in(texts[i]) for i in copy_ids))
    bib_out, copies, names = [], {}, {}
    for k in sorted(wanted):
        if k not in master:
            warn.append(f"@{k} is not in {bib_path.name}")
            continue

        def localize(fm: re.Match) -> str:
            indent, value, comma = fm.groups()
            new = []
            for raw in value.split(";"):
                src = Path(raw).expanduser()
                if src.suffix.lower() != ".pdf":
                    continue
                if not src.exists():
                    warn.append(f"@{k}: attachment not found: {raw}")
                    continue
                name = src.name if names.setdefault(src.name, src) == src else f"{k}-{src.name}"
                copies[dest / "library" / name] = (src, "pdf")
                new.append(f"library/{name}")
            if not new:
                return fm.group(0)
            return f"{indent}file = {{{';'.join(new)}}},\n{indent}x-origin-file = {{{value}}}{comma}"

        bib_out.append(FILE_FIELD.sub(localize, master[k]))

    # attachments linked relatively keep their relative path under notes/
    rel_files = set()
    for i in copy_ids:
        p = notes[i][0]
        copies[dest / "notes" / p.name] = (p, "note")
        rel_files.add(p.name)
        for link in set(FILE_LINK.findall(texts[i])):
            src = (p.parent / link).resolve()
            if link.startswith(("~", "/", "http", "..")) or not src.is_file():
                continue
            if copies.get(dest / "notes" / link, (src,))[0] != src:
                warn.append(f"two different attachments want notes/{link}")
            copies[dest / "notes" / link] = (src, "attachment")
            rel_files.add(link)

    bad = report({notes[i][0].name: texts[i] for i in copy_ids}, copy_ids,
                 set(split_bib("\n".join(bib_out))), rel_files)

    print(f"{'EXECUTE' if a.execute else 'PLAN'}: {seed.name}\n  -> {dest}")
    for dst, (src, role) in sorted(copies.items(), key=lambda c: (c[1][1], str(c[0]))):
        print(f"  {role:10} {dst.relative_to(dest)}  ({src.stat().st_size // 1024} KB)")
    print(f"  {'bib':10} refs.bib  ({len(bib_out)} of {len(wanted)} keys)")
    for line in warn + bad:
        print(f"  WARN {line}")

    if not a.execute:
        return 2 if (warn or bad) else 0
    if dest.exists():
        sys.exit(f"{dest} exists; refusing to overwrite")
    manifest = ["role\tsource\tcopy\tsha256_16\tbytes"]
    for dst, (src, role) in copies.items():
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        digest = hashlib.sha256(dst.read_bytes()).hexdigest()[:16]
        manifest.append(f"{role}\t{src}\t{dst.relative_to(dest)}\t{digest}\t{dst.stat().st_size}")
    (dest / "refs.bib").write_text("\n".join(bib_out), encoding="utf-8")
    (dest / "manifest.tsv").write_text("\n".join(manifest) + "\n", encoding="utf-8")
    (dest / ".dir-locals.el").write_text(
        ";; Written by promote-idea.py. If this folder moves, update the path.\n"
        f'((nil . ((denote-directory . "{dest / "notes"}/"))))\n', encoding="utf-8")
    (dest / "README.org").write_text(
        f"#+title: {a.slug}\n#+promoted_from: denote:{seed_id}\n"
        f"#+promoted_on: [{datetime.date.today():%Y-%m-%d}]\n\n"
        "* Ownership\n"
        "- Idea, outline and drafts: owned by this project from the promotion date; the origin note is a frozen seed.\n"
        "- Bib notes, PDFs and bib entries: owned by the library and Zotero; copies here are read-only snapshots.\n"
        "- Data, code, figures and exports: owned here.\n\n"
        "* Layout\n"
        "- =notes/= Denote silo (=.dir-locals.el= sets =denote-directory=); =notes/refs/= attachments.\n"
        "- =refs.bib= subset of the master bibliography; =library/= PDFs; =manifest.tsv= what came from where.\n",
        encoding="utf-8")
    if not a.no_git:
        (dest / ".gitignore").write_text("library/\n*.pdf\n.DS_Store\n", encoding="utf-8")
        done = subprocess.run(["git", "init", "-q", "-b", "main", str(dest)], capture_output=True, text=True)
        print("  GIT:", "initialized (nothing committed, no remote)" if done.returncode == 0 else done.stderr.strip())
    print("  REMINDER: set denote-excluded-directories-regexp to include works/ so Denote ignores these copies")
    after = check_tree(dest)
    print("  CHECK (written tree):", "; ".join(after) or "all references resolve")
    return 2 if after else 0


if __name__ == "__main__":
    sys.exit(main())
