#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
helper_dir="$data_home/steamwatch-widget"
helper_path="$helper_dir/scan_games.py"
package_dir="$source_dir/plasma/steamwatch-widget"
plugin_id="io.github.k2hszwwwdn.steamwatchwidget"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
  printf '%s\n' "kpackagetool6 is required to install the Plasma 6 widget." >&2
  exit 1
fi

install -d "$helper_dir"
install -m 0755 "$source_dir/tools/scan_games.py" "$helper_path"

if kpackagetool6 --type Plasma/Applet --show "$plugin_id" >/dev/null 2>&1; then
  kpackagetool6 --type Plasma/Applet --upgrade "$package_dir"
else
  kpackagetool6 --type Plasma/Applet --install "$package_dir"
fi

printf 'Installed Steam Watch. Add it from Plasma’s Add Widgets menu.\n'
