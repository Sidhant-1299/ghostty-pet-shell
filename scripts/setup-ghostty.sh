#!/usr/bin/env bash

set -euo pipefail

MODE="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --all-surfaces)
      MODE="all"
      shift
      ;;
    --initial)
      MODE="initial"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage: $0 [--all-surfaces|--initial]" >&2
      exit 1
      ;;
  esac
done

find_ghostty_config() {
  if [ -n "${GHOSTTY_CONFIG:-}" ]; then
    echo "$GHOSTTY_CONFIG"
    return 0
  fi

  if [ -f "$HOME/.config/ghostty/config" ]; then
    echo "$HOME/.config/ghostty/config"
    return 0
  fi

  if [ -f "$HOME/.config/ghostty/config.ghostty" ]; then
    echo "$HOME/.config/ghostty/config.ghostty"
    return 0
  fi

  if [ -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config" ]; then
    echo "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    return 0
  fi

  mkdir -p "$HOME/.config/ghostty"
  echo "$HOME/.config/ghostty/config"
}

CONFIG_FILE="$(find_ghostty_config)"
LAUNCHER="$HOME/.local/bin/ghostty-pet-shell"

if [ ! -x "$LAUNCHER" ]; then
  echo "Launcher not found or not executable: $LAUNCHER" >&2
  echo "Run ./scripts/install.sh first." >&2
  exit 1
fi

mkdir -p "$(dirname "$CONFIG_FILE")"
touch "$CONFIG_FILE"

TMP_FILE="$(mktemp)"

awk '
  /# >>> ghostty-terminal-pet/ { skip=1; next }
  /# <<< ghostty-terminal-pet/ { skip=0; next }
  skip != 1 { print }
' "$CONFIG_FILE" > "$TMP_FILE"

if [ "$MODE" = "initial" ]; then
  COMMAND_LINE="initial-command = $LAUNCHER"
else
  COMMAND_LINE="command = $LAUNCHER"
fi

cat >> "$TMP_FILE" <<EOF

# >>> ghostty-terminal-pet
$COMMAND_LINE
shell-integration = zsh
# <<< ghostty-terminal-pet
EOF

mv "$TMP_FILE" "$CONFIG_FILE"

echo "Updated Ghostty config:"
echo "$CONFIG_FILE"
echo
echo "Mode: $MODE"
echo "Launcher: $LAUNCHER"
echo
echo "Restart Ghostty or reload config."