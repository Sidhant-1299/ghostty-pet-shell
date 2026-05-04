#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${GHOSTTY_PET_HOME:-$HOME/.local/share/ghostty-pet}"
CONFIG_DIR="$HOME/.config/ghostty-pet"
CONFIG_FILE="$CONFIG_DIR/config"
LOCAL_BIN="$HOME/.local/bin"
LAUNCHER="$LOCAL_BIN/ghostty-pet-shell"

mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOCAL_BIN"

echo "Installing Ghostty Terminal Pet..."
echo "Repo: $REPO_ROOT"
echo "Install dir: $INSTALL_DIR"

rsync -a \
  --exclude ".git" \
  --exclude "__pycache__" \
  "$REPO_ROOT/" "$INSTALL_DIR/"

find_python() {
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
    return 0
  fi

  if command -v python >/dev/null 2>&1; then
    command -v python
    return 0
  fi

  return 1
}

PYTHON_BIN="$(find_python)"

if [ -z "$PYTHON_BIN" ]; then
  echo "Could not find python3." >&2
  exit 1
fi

PYTHON_BIN="$("$PYTHON_BIN" -c 'import sys; print(sys.executable)')"

echo "Using Python: $PYTHON_BIN"

if "$PYTHON_BIN" -c "from PIL import Image" >/dev/null 2>&1; then
  echo "Pillow already installed for this Python."
else
  echo "Installing Pillow for this Python..."
  if ! "$PYTHON_BIN" -m pip install --upgrade pillow; then
    echo "Normal install failed. Trying user install..."
    "$PYTHON_BIN" -m pip install --user --upgrade pillow
  fi
fi

if "$PYTHON_BIN" -c "from PIL import Image; import PIL; print(PIL.__version__)" >/dev/null; then
  echo "Pillow import check passed."
else
  echo "Pillow still cannot be imported by $PYTHON_BIN" >&2
  exit 1
fi

cp "$INSTALL_DIR/bin/ghostty-pet-shell" "$LAUNCHER"
chmod +x "$LAUNCHER"

if [ ! -f "$CONFIG_FILE" ]; then
  cp "$INSTALL_DIR/examples/ghostty-pet.config" "$CONFIG_FILE"

  PYTHON_ESCAPED="${PYTHON_BIN//\//\\/}"
  INSTALL_ESCAPED="${INSTALL_DIR//\//\\/}"

  sed -i.bak "s|^PYTHON_BIN=.*|PYTHON_BIN=\"$PYTHON_BIN\"|" "$CONFIG_FILE"
  sed -i.bak "s|^GHOSTTY_PET_HOME=.*|GHOSTTY_PET_HOME=\"$INSTALL_DIR\"|" "$CONFIG_FILE"

  rm -f "$CONFIG_FILE.bak"

  echo "Created config: $CONFIG_FILE"
else
  echo "Config already exists: $CONFIG_FILE"
  echo "Not overwriting it."
fi

if [ ! -f "$CONFIG_DIR/pet.png" ]; then
  cp "$INSTALL_DIR/assets/pet.png" "$CONFIG_DIR/pet.png"
  echo "Copied default pet to: $CONFIG_DIR/pet.png"
fi

echo
echo "Installed launcher:"
echo "$LAUNCHER"
echo
echo "Next:"
echo "./scripts/setup-ghostty.sh --all-surfaces"