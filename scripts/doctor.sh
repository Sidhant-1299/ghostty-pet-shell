#!/usr/bin/env bash

set -u

CONFIG="${GHOSTTY_PET_CONFIG:-$HOME/.config/ghostty-pet/config}"

echo "Ghostty Terminal Pet Doctor"
echo

if [ -f "$CONFIG" ]; then
  echo "Config: $CONFIG"
  # shellcheck disable=SC1090
  source "$CONFIG"
else
  echo "Config missing: $CONFIG"
  exit 1
fi

echo "GHOSTTY_PET_HOME=${GHOSTTY_PET_HOME:-unset}"
echo "PET_IMAGE=${PET_IMAGE:-unset}"
echo "PYTHON_BIN=${PYTHON_BIN:-unset}"
echo "SHELL_BIN=${SHELL_BIN:-unset}"
echo

if [ -n "${PYTHON_BIN:-}" ] && [ -x "$PYTHON_BIN" ]; then
  echo "Python executable:"
  "$PYTHON_BIN" -c "import sys; print(sys.executable)"

  echo
  echo "Python version:"
  "$PYTHON_BIN" --version

  echo
  echo "Pillow check:"
  if "$PYTHON_BIN" -c "from PIL import Image; import PIL; print(PIL.__version__); print(PIL.__file__)" 2>/tmp/ghostty-pet-pil-error.log; then
    echo "Pillow OK"
  else
    echo "Pillow FAILED"
    cat /tmp/ghostty-pet-pil-error.log
  fi
else
  echo "PYTHON_BIN is invalid."
fi

echo

if [ -f "${PET_IMAGE:-}" ]; then
  echo "Pet image exists: $PET_IMAGE"
else
  echo "Pet image missing: ${PET_IMAGE:-unset}"
fi

RENDERER="${GHOSTTY_PET_HOME:-$HOME/.local/share/ghostty-pet}/ghostty_pet/renderer.py"

if [ -f "$RENDERER" ]; then
  echo "Renderer exists: $RENDERER"
else
  echo "Renderer missing: $RENDERER"
fi

echo
echo "PATH python3:"
command -v python3 || true

echo
echo "Done."