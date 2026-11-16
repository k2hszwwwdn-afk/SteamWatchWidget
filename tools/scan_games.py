#!/usr/bin/env python3

import json
import os
from pathlib import Path
import re
import sys


FIELD_PATTERN = re.compile(r'^\s*"([^"]+)"\s+"((?:\\.|[^"\\])*)"\s*$', re.MULTILINE)
EXCLUDED_NAMES = (
    "steam linux runtime",
    "proton",
    "steamworks common redistributables",
)


def unescape_vdf(value: str) -> str:
    return value.replace(r"\\", "\\").replace(r"\"", '"')


def read_field(text: str, field: str) -> str | None:
    for key, value in FIELD_PATTERN.findall(text):
        if key == field:
            return unescape_vdf(value)
    return None


def steam_roots(home: Path) -> list[Path]:
    candidates = [
        Path(os.environ["STEAM_DIR"]).expanduser() if os.environ.get("STEAM_DIR") else None,
        home / ".local/share/Steam",
        home / ".steam/steam",
        home / ".steam/root",
        home / ".var/app/com.valvesoftware.Steam/.local/share/Steam",
    ]
    roots: list[Path] = []
    seen: set[Path] = set()

    for candidate in candidates:
        if candidate is None or not candidate.is_dir():
            continue
        resolved = candidate.resolve()
        if resolved not in seen and (resolved / "steamapps").is_dir():
            seen.add(resolved)
            roots.append(resolved)
    return roots


def library_paths(roots: list[Path]) -> list[Path]:
    libraries: list[Path] = []
    seen: set[Path] = set()

    for root in roots:
        config = root / "steamapps/libraryfolders.vdf"
        candidates = [root]
        try:
            text = config.read_text(encoding="utf-8", errors="replace")
        except OSError:
            text = ""
        candidates.extend(
            Path(unescape_vdf(path)).expanduser()
            for key, path in FIELD_PATTERN.findall(text)
            if key == "path"
        )

        for candidate in candidates:
            resolved = candidate.resolve()
            if resolved not in seen and (resolved / "steamapps").is_dir():
                seen.add(resolved)
                libraries.append(resolved)
    return libraries


def installed_games(libraries: list[Path]) -> list[dict[str, str]]:
    games: dict[str, dict[str, str]] = {}

    for library in libraries:
        steamapps = library / "steamapps"
        for manifest in steamapps.glob("appmanifest_*.acf"):
            try:
                text = manifest.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue

            app_id = read_field(text, "appid")
            name = read_field(text, "name")
            install_dir = read_field(text, "installdir")
            state_flags = read_field(text, "StateFlags")
            if not app_id or not app_id.isdecimal() or not name or not install_dir:
                continue
            try:
                if int(state_flags or "0") & 4 == 0:
                    continue
            except ValueError:
                continue
            if name.casefold().startswith(EXCLUDED_NAMES):
                continue
            if not (steamapps / "common" / install_dir).is_dir():
                continue

            cache_dir = library / "appcache/librarycache" / app_id
            artwork = next(
                (
                    cache_dir / filename
                    for filename in ("library_600x900.jpg", "header.jpg", "logo.png")
                    if (cache_dir / filename).is_file()
                ),
                None,
            )
            games[app_id] = {
                "appid": app_id,
                "name": name,
                "artworkPath": str(artwork) if artwork else "",
            }

    return sorted(games.values(), key=lambda game: game["name"].casefold())


def scan() -> dict[str, object]:
    roots = steam_roots(Path.home())
    libraries = library_paths(roots)
    if not libraries:
        return {
            "games": [],
            "error": "No Steam library was found. Install Steam and a game, then refresh.",
        }

    return {"games": installed_games(libraries), "error": ""}


def main() -> int:
    try:
        result = scan()
    except OSError as error:
        result = {"games": [], "error": f"Could not read Steam libraries: {error}"}
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
