If you use ghostty(like me) and love your pets(like me) then this project gives you a tiny animated pixel pet that appears when Ghostty starts.

# Ghostty Terminal Pet

`ghostty-terminal-pet` is a small Ghostty startup companion.

It plays an animated pixel-art pet inside Ghostty for a few seconds, or until you press a key, then drops you into your normal shell.

It is designed for people who want a Codex-like or VS Code Pets-like terminal companion, but inside Ghostty.

## What this does

When Ghostty opens, it runs a small shell launcher.

That launcher:

1. Loads your Ghostty Pet config from:

```bash
~/.config/ghostty-pet/config
```

2. Finds the Python interpreter that can import Pillow.

3. Starts the pet renderer.

4. The renderer loads your sprite sheet PNG.

5. The pet moves around the terminal for a few seconds.

6. When the splash ends, your normal shell opens.

The flow looks like this:

```text
Ghostty starts
        |
        v
~/.local/bin/ghostty-pet-shell
        |
        v
~/.config/ghostty-pet/config
        |
        v
ghostty_pet/renderer.py
        |
        v
animated pet splash
        |
        v
your normal shell
```

## Why this exists

Ghostty does not have a built-in pet overlay system like VS Code Pets.

But Ghostty can render inline images in the terminal, so this project uses a PNG sprite sheet and animates it directly in the terminal.

This is not a fake Tamagotchi app.

It is a small animated startup companion.

The goal is:

- keep it lightweight
- keep it hackable
- let anyone use their own pet sprite sheet
- avoid venv complexity
- make Python and Pillow issues easy to debug
- make Ghostty startup feel personal

## Repo structure

```text
.
├── assets
│   └── pet.png
├── bin
│   └── ghostty-pet-shell
├── examples
│   ├── ghostty-pet.config
│   └── ghostty.config.snippet
├── ghostty_pet
│   ├── __init__.py
│   └── renderer.py
├── LICENSE
├── README.md
└── scripts
    ├── doctor.sh
    ├── install.sh
    └── setup-ghostty.sh
```

## What each file does

### `assets/pet.png`

Default pet sprite sheet.

Replace this with your own pet if you want.

The default expected layout is:

```text
4 columns x 2 rows = 8 animation frames
```

Example:

```text
frame 1 | frame 2 | frame 3 | frame 4
frame 5 | frame 6 | frame 7 | frame 8
```

### `ghostty_pet/renderer.py`

The actual animation engine.

It:

- opens the sprite sheet
- splits it into frames
- removes the light background
- scales the frames
- sends PNG frames to Ghostty
- moves the pet around
- exits after a timeout or keypress

### `bin/ghostty-pet-shell`

The startup launcher.

Ghostty runs this file before opening your normal shell.

It:

- loads config
- runs the renderer
- then executes your shell with `exec "$SHELL_BIN" -l`

### `examples/ghostty-pet.config`

Template config file.

The installer copies this to:

```bash
~/.config/ghostty-pet/config
```

### `examples/ghostty.config.snippet`

Example Ghostty config block.

Use this when manually wiring the launcher into Ghostty.

### `scripts/install.sh`

Installs the project locally.

It:

- copies the repo into `~/.local/share/ghostty-pet`
- creates `~/.config/ghostty-pet/config`
- copies the default pet image to `~/.config/ghostty-pet/pet.png`
- detects the current Python interpreter
- installs Pillow globally for that Python
- creates `~/.local/bin/ghostty-pet-shell`

### `scripts/setup-ghostty.sh`

Adds the Ghostty startup command to your Ghostty config.

### `scripts/doctor.sh`

Debug script.

Use this when the pet does not start or Pillow cannot be imported.

It prints:

- config path
- Python path
- Pillow version
- Pillow location
- pet image path
- renderer path
- current `python3` path

## Requirements

You need:

- macOS or Linux
- Ghostty
- Python 3
- Pillow

This project intentionally does not use a virtual environment by default.

Pillow is installed for the selected Python interpreter using:

```bash
python3 -m pip install --upgrade pillow
```

The important detail is that Pillow must be installed for the exact Python that Ghostty runs.

On macOS, this matters because the `python3` in your normal terminal may not be the same `python3` used by apps launched from the Dock.

That is why the installer pins the exact Python path in config.

## Quick install

Clone the repo:

```bash
git clone https://github.com/YOUR_USERNAME/ghostty-terminal-pet.git
cd ghostty-terminal-pet
```

Run install:

```bash
./scripts/install.sh
```

Check the install:

```bash
./scripts/doctor.sh
```

Wire it into Ghostty:

```bash
./scripts/setup-ghostty.sh --all-surfaces
```

Restart Ghostty.

## Ghostty setup modes

There are two ways to run the pet.

### Run pet for every new terminal

```bash
./scripts/setup-ghostty.sh --all-surfaces
```

This writes:

```ini
command = /Users/YOUR_USERNAME/.local/bin/ghostty-pet-shell
shell-integration = zsh
```

Use this if you want the pet every time a new Ghostty surface opens.

### Run pet only on initial Ghostty startup

```bash
./scripts/setup-ghostty.sh --initial
```

This writes:

```ini
initial-command = /Users/YOUR_USERNAME/.local/bin/ghostty-pet-shell
shell-integration = zsh
```

Use this if you only want the pet once when Ghostty first opens.

## Manual Ghostty config

Open your Ghostty config:

```bash
nano ~/.config/ghostty/config
```

Add this block:

```ini
# >>> ghostty-terminal-pet
command = /Users/YOUR_USERNAME/.local/bin/ghostty-pet-shell
shell-integration = zsh
# <<< ghostty-terminal-pet
```

Replace `YOUR_USERNAME` with your actual macOS username.

For example:

```ini
command = /Users/sidhant/.local/bin/ghostty-pet-shell
shell-integration = zsh
```

For fish:

```ini
shell-integration = fish
```

For bash:

```ini
shell-integration = bash
```

## Config file

The main config lives here:

```bash
~/.config/ghostty-pet/config
```

Example:

```bash
GHOSTTY_PET_HOME="$HOME/.local/share/ghostty-pet"

PET_IMAGE="$HOME/.config/ghostty-pet/pet.png"

PYTHON_BIN="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3"

SHELL_BIN="${SHELL:-/bin/zsh}"

SPLASH_SECONDS="5"
EXIT_ANY_KEY="1"

SHEET_COLS="4"
SHEET_ROWS="2"

FPS="7"

CELL_COLS="12"
CELL_ROWS="8"

PIXEL_WIDTH="150"

TRANSPARENT_THRESHOLD="245"

DEBUG="0"
```

## Config options

### `GHOSTTY_PET_HOME`

Where the installed project lives.

Default:

```bash
GHOSTTY_PET_HOME="$HOME/.local/share/ghostty-pet"
```

### `PET_IMAGE`

Path to your sprite sheet.

Default:

```bash
PET_IMAGE="$HOME/.config/ghostty-pet/pet.png"
```

### `PYTHON_BIN`

Exact Python interpreter used to run the pet.

Example:

```bash
PYTHON_BIN="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3"
```

This Python must be able to run:

```python
from PIL import Image
```

### `SHELL_BIN`

Your normal shell.

Default:

```bash
SHELL_BIN="${SHELL:-/bin/zsh}"
```

### `SPLASH_SECONDS`

How long the pet runs before your shell opens.

Example:

```bash
SPLASH_SECONDS="5"
```

### `EXIT_ANY_KEY`

Whether pressing any key skips the pet.

```bash
EXIT_ANY_KEY="1"
```

Use `0` to disable keypress skipping.

### `SHEET_COLS` and `SHEET_ROWS`

The sprite sheet layout.

For a 4 by 2 sheet:

```bash
SHEET_COLS="4"
SHEET_ROWS="2"
```

For a 6 frame horizontal sheet:

```bash
SHEET_COLS="6"
SHEET_ROWS="1"
```

### `FPS`

Animation speed.

```bash
FPS="7"
```

Higher means faster animation.

### `CELL_COLS` and `CELL_ROWS`

How much terminal space the pet occupies.

```bash
CELL_COLS="12"
CELL_ROWS="8"
```

Increase these if the pet is clipped.

Decrease these if the pet takes too much terminal space.

### `PIXEL_WIDTH`

Pixel width used when scaling each frame.

```bash
PIXEL_WIDTH="150"
```

Make the pet smaller:

```bash
PIXEL_WIDTH="110"
```

Make the pet bigger:

```bash
PIXEL_WIDTH="180"
```

### `TRANSPARENT_THRESHOLD`

Removes white or off-white backgrounds from sprite sheets.

```bash
TRANSPARENT_THRESHOLD="245"
```

Higher means more aggressive background removal.

Lower means less aggressive background removal.

### `DEBUG`

Enable debug logs.

```bash
DEBUG="1"
```

Logs go here:

```bash
~/.config/ghostty-pet/debug.log
```

## Using your own pet

Replace the pet image:

```bash
cp /path/to/your/sprite-sheet.png ~/.config/ghostty-pet/pet.png
```

Then edit config:

```bash
nano ~/.config/ghostty-pet/config
```

Set the correct sprite sheet layout:

```bash
SHEET_COLS="4"
SHEET_ROWS="2"
```

Test it:

```bash
~/.local/bin/ghostty-pet-shell
```

## Testing without Ghostty startup

Run the renderer directly:

```bash
python3 ~/.local/share/ghostty-pet/ghostty_pet/renderer.py \
  ~/.config/ghostty-pet/pet.png \
  --cols 4 \
  --rows 2 \
  --splash-seconds 5 \
  --exit-any-key
```

Run the launcher directly:

```bash
~/.local/bin/ghostty-pet-shell
```

Run the doctor:

```bash
~/.local/share/ghostty-pet/scripts/doctor.sh
```

## Common problems

### `ModuleNotFoundError: No module named 'PIL'`

This means the Python running the pet does not have Pillow installed.

Check your configured Python:

```bash
grep PYTHON_BIN ~/.config/ghostty-pet/config
```

Test it:

```bash
/path/to/python3 -c "from PIL import Image; import PIL; print(PIL.__version__); print(PIL.__file__)"
```

Install Pillow for that Python:

```bash
/path/to/python3 -m pip install --upgrade pillow
```

Then run:

```bash
~/.local/share/ghostty-pet/scripts/doctor.sh
```

### My normal terminal imports Pillow, but Ghostty startup does not

This usually means Ghostty is using a different `python3`.

Do not rely on bare `python3`.

Set the absolute Python path in:

```bash
~/.config/ghostty-pet/config
```

Example:

```bash
PYTHON_BIN="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3"
```

### Pet image not found

Check:

```bash
ls ~/.config/ghostty-pet/pet.png
```

If missing:

```bash
cp ~/.local/share/ghostty-pet/assets/pet.png ~/.config/ghostty-pet/pet.png
```

### Renderer not found

Check:

```bash
ls ~/.local/share/ghostty-pet/ghostty_pet/renderer.py
```

If missing, reinstall:

```bash
./scripts/install.sh
```

### Pet is too big

Edit:

```bash
nano ~/.config/ghostty-pet/config
```

Lower:

```bash
PIXEL_WIDTH="110"
CELL_COLS="10"
CELL_ROWS="7"
```

### Pet is too small

Raise:

```bash
PIXEL_WIDTH="180"
CELL_COLS="14"
CELL_ROWS="10"
```

### Pet background is still visible

Raise:

```bash
TRANSPARENT_THRESHOLD="250"
```

### Parts of the pet disappear

Lower:

```bash
TRANSPARENT_THRESHOLD="235"
```

Or increase:

```bash
CELL_COLS="14"
CELL_ROWS="10"
```

## Uninstall

Remove the installed files:

```bash
rm -rf ~/.local/share/ghostty-pet
rm -rf ~/.config/ghostty-pet
rm -f ~/.local/bin/ghostty-pet-shell
```

Then remove the managed block from your Ghostty config:

```ini
# >>> ghostty-terminal-pet
command = /Users/YOUR_USERNAME/.local/bin/ghostty-pet-shell
shell-integration = zsh
# <<< ghostty-terminal-pet
```

## Design notes

This project uses a startup splash instead of a permanent overlay.

A permanent overlay inside a terminal is fragile because terminal applications redraw their own screen constantly.

The startup splash is reliable:

- it does not fight your shell prompt
- it does not interfere with full-screen apps
- it exits cleanly into your shell
- it works well as a Ghostty startup effect

The pet engine is intentionally simple.

Your pet is just a PNG sprite sheet.

The config controls how that sprite sheet is interpreted.

## Development

Run from repo root:

```bash
python3 ghostty_pet/renderer.py assets/pet.png \
  --cols 4 \
  --rows 2 \
  --splash-seconds 5 \
  --exit-any-key
```

Run install:

```bash
./scripts/install.sh
```

Run diagnostics:

```bash
./scripts/doctor.sh
```

Update Ghostty config:

```bash
./scripts/setup-ghostty.sh --all-surfaces
```

## License

MIT
