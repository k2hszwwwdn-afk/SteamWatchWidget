# Steam Watch Widget

Steam Watch is a KDE Plasma 6 widget for Bazzite and other Linux desktops. It scans local Steam libraries for installed games, lets you filter the list, and launches a selected game through Steam.

## Features

- Scrollable list of installed Steam games
- Search by game title
- Launch with the Steam `rungameid` URI
- Optional Steam library artwork
- Finds native and Flatpak Steam libraries, including additional libraries registered in `libraryfolders.vdf`
- Refreshes automatically and has a manual refresh button
- Does not use a network service or modify Steam files

## Requirements

- KDE Plasma 6
- Steam (native or Flatpak)
- Python 3
- `kpackagetool6` and the Plasma 5 Support executable data engine (`plasma5support`)

## Install

From this repository:

```sh
./install.sh
```

Then open Plasma's **Add Widgets** menu, search for **Steam Watch**, and add it to the desktop or a panel. Expand it to browse the games, type in the search field to filter, and choose **Play** to launch a game. The list refreshes every 30 seconds; use the refresh button to scan immediately.

To uninstall:

```sh
./uninstall.sh
```

## How it works

The widget invokes a small local Python scanner through Plasma's executable data engine. The scanner reads Steam's library folders and installed app manifests, then returns game IDs, titles, and any cached local artwork. Launching a game opens `steam://rungameid/<appid>` through the desktop's registered Steam handler.

The scanner only reads Steam metadata and artwork paths. It does not access account credentials, change game files, or make network requests.

## Development

Run the scanner directly to inspect its JSON response:

```sh
python3 tools/scan_games.py
```

Run the focused scanner tests:

```sh
python3 -m unittest discover -s tests
```

## License

MIT. See [LICENSE](./LICENSE).
