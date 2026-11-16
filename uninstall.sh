#!/usr/bin/env bash
set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
plugin_id="io.github.k2hszwwwdn.steamwatchwidget"

if command -v kpackagetool6 >/dev/null 2>&1 &&
  kpackagetool6 --type Plasma/Applet --show "$plugin_id" >/dev/null 2>&1; then
  kpackagetool6 --type Plasma/Applet --remove "$plugin_id"
fi

rm -f "$data_home/steamwatch-widget/scan_games.py"
rmdir "$data_home/steamwatch-widget" 2>/dev/null || true
printf '%s\n' "Uninstalled Steam Watch."
