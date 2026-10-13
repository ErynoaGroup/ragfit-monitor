#!/usr/bin/env python3
"""Checks the OAuth role mapping in ragfit/deploy/grafana.ini: only full team claims, deny by default."""
import configparser
import sys

import jmespath

cfg = configparser.ConfigParser(interpolation=None)
cfg.read("ragfit/deploy/grafana.ini")
o = cfg["auth.generic_oauth"]
path = o["role_attribute_path"]
allowed = set(o["allowed_groups"].split())
assert o["role_attribute_strict"] == "true", "role_attribute_strict must be true"
assert cfg["auth"]["disable_login_form"] == "true" and cfg["auth"]["disable_login"] == "true"
assert cfg["auth.basic"]["enabled"] == "false" and cfg["auth.anonymous"]["enabled"] == "false"
assert o["allow_assign_grafana_admin"] == "false"
assert all(g.startswith("ErynoaGroup:") and len(g) > len("ErynoaGroup:") for g in allowed)


def decide(claims):
    groups = claims.get("groups") or []
    if not allowed.intersection(groups):
        return None
    try:
        role = jmespath.search(path, claims)
    except jmespath.exceptions.JMESPathError:
        role = None
    return role or None


cases = [
    ({"groups": ["ErynoaGroup:platform-admin"]}, "Admin"),
    ({"groups": ["ErynoaGroup:monitor-editor"]}, "Editor"),
    ({"groups": ["ErynoaGroup:monitor-viewer"]}, "Viewer"),
    ({"groups": ["ErynoaGroup:monitor-viewer", "ErynoaGroup:monitor-editor"]}, "Editor"),
    ({"groups": ["ErynoaGroup:monitor-viewer", "ErynoaGroup:platform-admin"]}, "Admin"),
    ({"groups": ["ErynoaGroup"]}, None),
    ({"groups": ["ErynoaGroup:other-team"]}, None),
    ({"groups": ["OtherOrg:monitor-editor"]}, None),
    ({"groups": ["erynoagroup:monitor-editor"]}, None),
    ({"groups": ["ErynoaGroup:monitor-editor-x"]}, None),
    ({"groups": []}, None),
    ({}, None),
]
bad = 0
for claims, want in cases:
    got = decide(claims)
    ok = got == want
    bad += not ok
    print(f"{'ok  ' if ok else 'FAIL'} {claims} -> {got} (want {want})")
sys.exit(1 if bad else 0)
