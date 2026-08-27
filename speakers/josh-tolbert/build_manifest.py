#!/usr/bin/env python3
"""[manifest] Parse every downloaded .info.json into a TSV of video metadata + speaker(s).

The Jackson Heights channel credits preachers inconsistently:
    "Speaker: Josh Tolbert"          "Speakers: Matt Bassford and Clay Gentry"
    "Speakers; Matthew Bassford ..." "Clay Gentry"          (bare name, no label)
plus channel boilerplate ("Join us for Bible Study...", "59:34 - Closing Prayer") that a
naive last-line heuristic mistakes for a name. So: learn the roster from the labelled
videos first, then use that roster to resolve the unlabelled ones.
"""
import json, glob, os, re, sys, time
from collections import Counter

AUDIO_DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.cache/swiftbible-speakers/jackson-heights")
OUT       = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "manifest.tsv")

ALIASES = {"matthew bassford": "Matt Bassford", "matt bassford": "Matt Bassford"}
LABEL_RE = re.compile(r"^\s*speakers?\s*[:;]\s*(.+?)\s*$", re.I)
NAME_RE  = re.compile(r"^[A-Z][a-zA-Z'\-]+(?: [A-Z][a-zA-Z'\-]+){1,2}\.?$")
SPLIT_RE = re.compile(r"\s+and\s+|\s*&\s*|\s*,\s*", re.I)

def norm(name):
    n = name.strip().rstrip(".").strip()
    return ALIASES.get(n.lower(), n)

def names_from_label(val):
    out = []
    for part in SPLIT_RE.split(val):
        part = norm(part)
        if part and NAME_RE.match(part.rstrip(".") + ("" if part.endswith(".") else "")):
            out.append(part)
        elif part and 1 < len(part.split()) <= 3 and part[0].isupper():
            out.append(part)
    return out

t0 = time.time()
files = sorted(glob.glob(os.path.join(AUDIO_DIR, "*.info.json")))
vids = []
for f in files:
    if os.path.basename(f).startswith("NA-UC"):      # channel-level info.json, not a video
        continue
    try:
        d = json.load(open(f, encoding="utf-8"))
    except Exception as e:
        print(f"[manifest] skip {os.path.basename(f)}: {e}", file=sys.stderr); continue
    if not d.get("id"):
        continue
    vids.append(d)

# --- pass 1: roster from explicitly labelled videos ------------------------
roster = Counter()
labelled = {}
for d in vids:
    for line in (d.get("description") or "").splitlines():
        m = LABEL_RE.match(line)
        if m:
            ns = names_from_label(m.group(1))
            if ns:
                labelled[d["id"]] = ns
                roster.update(ns)
            break
known = {n.lower(): n for n in roster}
print(f"[manifest] roster learned from {len(labelled)} labelled videos: {len(known)} names", file=sys.stderr)

# --- pass 2: resolve the rest against the roster --------------------------
def resolve(d):
    if d["id"] in labelled:
        return labelled[d["id"]], "label"
    desc = d.get("description") or ""
    for line in desc.splitlines():                     # bare name on its own line
        s = norm(line.strip())
        if s.lower() in known:
            return [known[s.lower()]], "bare"
    hits = [v for k, v in known.items() if re.search(r"\b" + re.escape(k) + r"\b", desc, re.I)]
    if hits:
        return sorted(set(hits)), "fuzzy"
    return [], "unknown"

audio = {}
for p in glob.glob(os.path.join(AUDIO_DIR, "*.m4a")):
    audio[os.path.basename(p).rsplit("-", 1)[-1][:-4]] = p

rows, how = [], Counter()
for d in vids:
    ns, src = resolve(d)
    how[src] += 1
    rows.append([d["id"], d.get("upload_date") or "NA", str(d.get("duration") or 0),
                 ",".join(ns), "yes" if d["id"] in audio else "no",
                 (d.get("title") or "").replace("\t", " ")])

rows.sort(key=lambda r: r[1], reverse=True)
with open(OUT, "w", encoding="utf-8") as fh:
    fh.write("id\tupload_date\tduration_s\tspeakers\thas_audio\ttitle\n")
    for r in rows:
        fh.write("\t".join(r) + "\n")

tally = Counter()
secs  = Counter()
for r in rows:
    for n in (r[3].split(",") if r[3] else ["(unknown)"]):
        tally[n] += 1
        secs[n]  += int(r[2] or 0)
print(f"[manifest] {len(rows)} videos in {time.time()-t0:.1f}s -> {OUT}", file=sys.stderr)
print(f"[manifest] resolved via: {dict(how)}", file=sys.stderr)
print(f"[manifest] {'speaker':<22} {'videos':>6} {'hours':>7}", file=sys.stderr)
for n, c in tally.most_common(30):
    print(f"[manifest] {n:<22} {c:>6} {secs[n]/3600:>7.1f}", file=sys.stderr)
