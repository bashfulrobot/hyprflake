# modules/desktop/dank/capture/tests/test_diff.py
import importlib.util
import json
import os
import subprocess

_spec = importlib.util.spec_from_file_location(
    "diff", os.path.join(os.path.dirname(__file__), "..", "diff.py")
)
diff = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(diff)


def test_canonical_is_order_independent():
    a = {"b": 1, "a": [3, 2]}
    b = {"a": [3, 2], "b": 1}
    assert diff.canonical(a) == diff.canonical(b)


def test_canonical_list_order_is_significant():
    assert diff.canonical([1, 2]) != diff.canonical([2, 1])


def test_canonical_treats_integer_floats_as_ints():
    # DMS writes whole-number settings as ints; Nix renders the stylix value as
    # a float. They must compare equal (else a perpetual phantom diff).
    assert diff.canonical({"dockTransparency": 1.0}) == diff.canonical({"dockTransparency": 1})
    assert diff.canonical([1.0, 2.0]) == diff.canonical([1, 2])
    assert diff.canonical({"a": {"b": 3.0}}) == diff.canonical({"a": {"b": 3}})


def test_canonical_preserves_non_integer_floats():
    assert diff.canonical({"fontScale": 1.15}) != diff.canonical({"fontScale": 1})
    assert "1.15" in diff.canonical({"fontScale": 1.15})


def test_equal_subcommand_ignores_int_float_spelling(tmp_path):
    same = _run(tmp_path, "equal", files={"a.json": {"x": 1.0}, "b.json": {"x": 1}})
    assert same.returncode == 0


def test_hash_subcommand_ignores_int_float_spelling(tmp_path):
    r1 = _run(tmp_path, "hash", files={"a.json": {"x": 1.0}})
    r2 = _run(tmp_path, "hash", files={"b.json": {"x": 1}})
    assert r1.stdout.strip() == r2.stdout.strip()


def test_deep_merge_recurses_dicts():
    base = {"a": {"x": 1, "y": 2}, "b": 9}
    over = {"a": {"y": 3}}
    assert diff.deep_merge(base, over) == {"a": {"x": 1, "y": 3}, "b": 9}


def test_deep_merge_replaces_lists_wholesale():
    base = {"bars": [{"id": "a"}, {"id": "b"}]}
    over = {"bars": [{"id": "c"}]}
    assert diff.deep_merge(base, over) == {"bars": [{"id": "c"}]}


def test_deep_merge_adds_new_keys():
    assert diff.deep_merge({"a": 1}, {"b": 2}) == {"a": 1, "b": 2}


def test_deep_diff_minimal_and_nested():
    base = {"a": {"x": 1, "y": 2}, "b": 9}
    live = {"a": {"x": 1, "y": 5}, "b": 9}
    assert diff.deep_diff(base, live) == {"a": {"y": 5}}


def test_deep_diff_new_key_and_changed_list():
    base = {"bars": [1, 2]}
    live = {"bars": [1, 2, 3], "extra": True}
    assert diff.deep_diff(base, live) == {"bars": [1, 2, 3], "extra": True}


def test_deep_diff_identical_is_empty():
    base = {"a": {"x": 1}}
    assert diff.deep_diff(base, {"a": {"x": 1}}) == {}


def test_without_removes_top_level_keys_present_in_keys():
    full = {"a": 1, "b": 2, "currentThemeName": "x", "fontFamily": "y"}
    keys = {"currentThemeName": "custom", "fontFamily": "z", "monoFontFamily": "m"}
    assert diff.without(full, keys) == {"a": 1, "b": 2}


def test_without_empty_keys_is_identity():
    full = {"a": 1, "b": {"c": 2}}
    assert diff.without(full, {}) == full


def test_roundtrip_merge_of_diff_equals_live():
    base = {"a": {"x": 1, "y": 2}, "bars": [1, 2], "b": 9}
    live = {"a": {"x": 1, "y": 5}, "bars": [9], "b": 9, "new": "z"}
    delta = diff.deep_diff(base, live)
    assert diff.canonical(diff.deep_merge(base, delta)) == diff.canonical(live)


def _run(tmp_path, *args, files=None):
    files = files or {}
    paths = []
    for name, obj in files.items():
        p = tmp_path / name
        p.write_text(json.dumps(obj))
        paths.append(str(p))
    cmd = ["python3", os.path.join(os.path.dirname(__file__), "..", "diff.py"), *args, *paths]
    return subprocess.run(cmd, capture_output=True, text=True)


def test_cli_hash_is_canonical(tmp_path):
    r1 = _run(tmp_path, "hash", files={"a.json": {"a": 1, "b": 2}})
    r2 = _run(tmp_path, "hash", files={"b.json": {"b": 2, "a": 1}})
    assert r1.returncode == 0
    assert r1.stdout.strip() == r2.stdout.strip()


def test_cli_equal_exit_codes(tmp_path):
    same = _run(tmp_path, "equal", files={"a.json": {"x": 1}, "b.json": {"x": 1}})
    diff_ = _run(tmp_path, "equal", files={"a.json": {"x": 1}, "b.json": {"x": 2}})
    assert same.returncode == 0
    assert diff_.returncode == 1
