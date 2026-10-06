#!/usr/bin/env python3
"""Refresh source formulae from each project's latest stable GitHub release."""

import hashlib
import io
import json
import os
from pathlib import Path
import re
import tarfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
PROJECTS = {
    "timeclock": ("timeclock-v", "cmd/timeclock/main.go"),
    "understudy": ("v", "cmd/understudy/main.go"),
    "ingot": ("v", "cmd/ingot/main.go"),
}


def get(url, *, api=False):
    headers = {"User-Agent": "giraffesyo-homebrew-tap"}
    if api:
        headers["Accept"] = "application/vnd.github+json"
        if token := os.environ.get("GH_TOKEN"):
            headers["Authorization"] = f"Bearer {token}"
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=60) as response:
        return response.read()


def release_version(release, prefix):
    if release.get("draft") or release.get("prerelease"):
        raise ValueError("Only published stable releases can update formulae")
    tag = release["tag_name"]
    if not re.fullmatch(re.escape(prefix) + r"\d+\.\d+\.\d+", tag):
        raise ValueError(f"Unexpected release tag: {tag!r}")
    return tag.removeprefix(prefix)


def source_checksum(archive, required):
    # Inspect the archive without extracting untrusted paths onto the runner.
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as source:
        paths = {member.name.partition("/")[2] for member in source if member.isfile()}
    if not {"go.mod", required}.issubset(paths):
        raise ValueError(f"Release archive does not contain {required} and go.mod")
    return hashlib.sha256(archive).hexdigest()


def updated_formula(content, url, version, checksum):
    for key, value in (("url", url), ("sha256", checksum)):
        content, count = re.subn(rf'^  {key} "[^"]+"$', f'  {key} "{value}"', content, count=1, flags=re.M)
        if count != 1:
            raise ValueError(f"Expected one {key} in formula")
    # Keep an explicit version in sync if a formula needs one.
    content = re.sub(r'^  version "[^"]+"$', f'  version "{version}"', content, count=1, flags=re.M)
    return content


def main():
    for name, (prefix, required) in PROJECTS.items():
        path = ROOT / "Formula" / f"{name}.rb"
        if not path.exists():
            print(f"{name}: no formula yet; skipping")
            continue
        release = json.loads(get(f"https://api.github.com/repos/giraffesyo/{name}/releases/latest", api=True))
        version = release_version(release, prefix)
        url = f"https://github.com/giraffesyo/{name}/archive/refs/tags/{prefix}{version}.tar.gz"
        original = path.read_text()
        current = re.search(r'/archive/refs/tags/' + re.escape(prefix) + r'(\d+)\.(\d+)\.(\d+)\.tar.gz', original)
        if not current:
            raise ValueError(f"Cannot read current version for {name}")
        current_version = tuple(map(int, current.groups()))
        next_version = tuple(map(int, version.split(".")))
        if next_version <= current_version:
            print(f"{name}: already at {'.'.join(current.groups())}; no update")
            continue
        checksum = source_checksum(get(url), required)
        path.write_text(updated_formula(original, url, version, checksum))
        print(f"{name}: updated to {version}")


if __name__ == "__main__":
    main()
