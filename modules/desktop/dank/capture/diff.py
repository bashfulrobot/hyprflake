#!/usr/bin/env python3
"""DMS settings delta/merge/canonicalisation tool.

Subcommands:
  canonical <file>    print canonical JSON (sorted keys, compact)
  hash <file>         print sha256 of canonical JSON
  diff <base> <live>    print minimal delta D with merge(base, D) == live
  merge <base> <over>   print recursiveUpdate(base, over)
  without <full> <keys> print <full> with every top-level key of <keys> removed
  equal <a> <b>         exit 0 if canonical(a) == canonical(b) else 1
"""
import hashlib
import json
import sys


def load(path):
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def canonical(obj):
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def deep_merge(base, over):
    if isinstance(base, dict) and isinstance(over, dict):
        out = dict(base)
        for k, v in over.items():
            out[k] = deep_merge(base[k], v) if k in base else v
        return out
    return over


_UNCHANGED = object()


def _diff(base, live):
    """Return delta value, or _UNCHANGED sentinel when nothing changed."""
    if isinstance(base, dict) and isinstance(live, dict):
        delta = {}
        # NOTE: keys present in base but absent in live are NOT included in the
        # delta. Key removal cannot be expressed as a recursiveUpdate delta
        # (removed keys reappear from defaults on merge). Documented v1 limitation.
        for k, v in live.items():
            if k not in base:
                delta[k] = v
            else:
                d = _diff(base[k], v)
                if d is not _UNCHANGED:
                    delta[k] = d
        return delta if delta else _UNCHANGED
    return live if canonical(base) != canonical(live) else _UNCHANGED


def deep_diff(base, live):
    d = _diff(base, live)
    return {} if d is _UNCHANGED else d


def without(full, keys):
    """Return `full` with every top-level key that appears in `keys` removed."""
    drop = set(keys) if isinstance(keys, dict) else set()
    if not isinstance(full, dict):
        return full
    return {k: v for k, v in full.items() if k not in drop}


def main(argv):
    cmd = argv[1] if len(argv) > 1 else ""
    try:
        if cmd == "canonical":
            print(canonical(load(argv[2])))
            return 0
        if cmd == "hash":
            print(hashlib.sha256(canonical(load(argv[2])).encode("utf-8")).hexdigest())
            return 0
        if cmd == "diff":
            print(json.dumps(deep_diff(load(argv[2]), load(argv[3])), indent=2, sort_keys=True))
            return 0
        if cmd == "merge":
            print(json.dumps(deep_merge(load(argv[2]), load(argv[3])), indent=2, sort_keys=True))
            return 0
        if cmd == "without":
            print(json.dumps(without(load(argv[2]), load(argv[3])), indent=2, sort_keys=True))
            return 0
        if cmd == "equal":
            return 0 if canonical(load(argv[2])) == canonical(load(argv[3])) else 1
    except IndexError:
        sys.stderr.write("error: too few arguments for '" + cmd + "'\n")
        sys.stderr.write(__doc__)
        return 2
    sys.stderr.write(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
