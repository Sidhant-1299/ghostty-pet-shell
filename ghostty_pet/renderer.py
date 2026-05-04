#!/usr/bin/env python3

import argparse
import base64
import io
import random
import select
import shutil
import sys
import termios
import time
import tty
from pathlib import Path

from PIL import Image

ESC = "\x1b"
ST = ESC + "\\"


def remove_light_background(image: Image.Image, threshold: int) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()

    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]

            if a == 0:
                continue

            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (255, 255, 255, 0)

    bbox = image.getbbox()
    return image.crop(bbox) if bbox else image


def extract_frames(
    sheet_path: Path,
    cols: int,
    rows: int,
    pixel_width: int,
    transparent_threshold: int,
) -> list[Image.Image]:
    sheet = Image.open(sheet_path).convert("RGBA")
    frames: list[Image.Image] = []

    for row in range(rows):
        for col in range(cols):
            left = round(col * sheet.width / cols)
            right = round((col + 1) * sheet.width / cols)
            top = round(row * sheet.height / rows)
            bottom = round((row + 1) * sheet.height / rows)

            frame = sheet.crop((left, top, right, bottom))
            frame = remove_light_background(frame, transparent_threshold)

            if frame.width == 0 or frame.height == 0:
                continue

            scale = pixel_width / frame.width
            new_height = max(1, int(frame.height * scale))

            frame = frame.resize(
                (pixel_width, new_height),
                Image.Resampling.NEAREST,
            )

            frames.append(frame)

    if not frames:
        raise RuntimeError("No frames extracted from sprite sheet.")

    return frames


def send_png(image: Image.Image, cell_cols: int, cell_rows: int) -> None:
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")

    payload = base64.standard_b64encode(buffer.getvalue()).decode("ascii")
    chunks = [payload[i : i + 4096] for i in range(0, len(payload), 4096)]

    for index, chunk in enumerate(chunks):
        more = 1 if index < len(chunks) - 1 else 0

        if index == 0:
            metadata = f"a=T,f=100,q=2,c={cell_cols},r={cell_rows},"
        else:
            metadata = ""

        sys.stdout.write(f"{ESC}_G{metadata}m={more};{chunk}{ST}")

    sys.stdout.flush()


def move_cursor(row: int, col: int) -> None:
    sys.stdout.write(f"{ESC}[{row};{col}H")


def clear_screen() -> None:
    sys.stdout.write(f"{ESC}[2J{ESC}[H")


def set_terminal_title(title: str) -> None:
    sys.stdout.write(f"{ESC}]0;{title}\a")


def key_pressed() -> str | None:
    readable, _, _ = select.select([sys.stdin], [], [], 0)

    if readable:
        return sys.stdin.read(1)

    return None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ghostty-pet",
        description="Animated pixel pet splash renderer for Ghostty.",
    )

    parser.add_argument(
        "sheet",
        type=Path,
        help="Path to a PNG sprite sheet.",
    )

    parser.add_argument("--cols", type=int, default=4)
    parser.add_argument("--rows", type=int, default=2)

    parser.add_argument("--fps", type=float, default=7)
    parser.add_argument("--cell-cols", type=int, default=12)
    parser.add_argument("--cell-rows", type=int, default=8)
    parser.add_argument("--pixel-width", type=int, default=150)
    parser.add_argument("--transparent-threshold", type=int, default=245)

    parser.add_argument("--splash-seconds", type=float, default=None)
    parser.add_argument("--exit-any-key", action="store_true")

    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not args.sheet.exists():
        print(f"ghostty-pet: sprite sheet not found: {args.sheet}", file=sys.stderr)
        return 2

    frames = extract_frames(
        sheet_path=args.sheet,
        cols=args.cols,
        rows=args.rows,
        pixel_width=args.pixel_width,
        transparent_threshold=args.transparent_threshold,
    )

    old_terminal = termios.tcgetattr(sys.stdin)

    x = 2
    y = 2
    dx = 1
    dy = 0
    frame_index = 0
    started_at = time.time()

    try:
        tty.setcbreak(sys.stdin)

        sys.stdout.write(f"{ESC}[?1049h")
        sys.stdout.write(f"{ESC}[?25l")
        set_terminal_title("Ghostty Pet")
        sys.stdout.flush()

        while True:
            key = key_pressed()

            if key in ("q", "\x03"):
                break

            if args.exit_any_key and key is not None:
                break

            if args.splash_seconds is not None:
                if time.time() - started_at >= args.splash_seconds:
                    break

            term_cols, term_rows = shutil.get_terminal_size((80, 24))

            max_x = max(1, term_cols - args.cell_cols)
            max_y = max(1, term_rows - args.cell_rows - 1)

            if random.random() < 0.08:
                dx = random.choice([-1, 0, 1])
                dy = random.choice([-1, 0, 1])

            x += dx
            y += dy

            if x <= 1 or x >= max_x:
                dx *= -1
                x = max(1, min(max_x, x))

            if y <= 1 or y >= max_y:
                dy *= -1
                y = max(1, min(max_y, y))

            sys.stdout.write(f"{ESC}[?2026h")
            clear_screen()
            move_cursor(y, x)

            send_png(
                frames[frame_index % len(frames)],
                cell_cols=args.cell_cols,
                cell_rows=args.cell_rows,
            )

            move_cursor(term_rows, 1)
            sys.stdout.write("press any key to skip | q to quit")
            sys.stdout.write(f"{ESC}[?2026l")
            sys.stdout.flush()

            frame_index += 1
            time.sleep(1 / args.fps)

    finally:
        sys.stdout.write(f"{ESC}[?25h")
        sys.stdout.write(f"{ESC}[?1049l")
        sys.stdout.flush()
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_terminal)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())