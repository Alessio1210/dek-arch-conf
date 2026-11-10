#!/usr/bin/env python3
"""NUL-safe, streaming home-wide pickers for Yazi. No extra packages needed."""
import os
from pathlib import Path
import subprocess
import sys

HOME = str(Path.home())
COLORS = (
    "bg:#2e3440,bg+:#434c5e,fg:#d8dee9,fg+:#eceff4,"
    "hl:#88c0d0,hl+:#8fbcbb,pointer:#88c0d0,marker:#a3be8c,"
    "prompt:#88c0d0,header:#81a1c1,border:#4c566a,info:#b48ead"
)


def preview(path):
    p = Path(path)
    if p.is_dir():
        try:
            for entry in sorted(p.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower()))[:100]:
                print(("📁 " if entry.is_dir() else "   ") + entry.name)
        except OSError as exc:
            print(exc)
    else:
        try:
            with p.open("rb") as source:
                data = source.read(32768)
            if b"\0" in data:
                print("Binary file — press Enter to reveal in Yazi")
            else:
                for number, line in enumerate(data.decode("utf-8", "replace").splitlines()[:160], 1):
                    # Strip terminal controls from file contents.
                    line = "".join(c for c in line if c == "\t" or c.isprintable())
                    print(f"{number:4}  {line}")
        except OSError as exc:
            print(exc)


def main(mode):
    if mode == "grep":
        with open("/dev/tty", "r+") as tty:
            tty.write("Search file contents across home (ripgrep regex; smart case)\nGrep › ")
            tty.flush()
            query = tty.readline().rstrip("\n")
        if not query:
            return
        command = ["rg", "--hidden", "--no-ignore", "--smart-case", "--files-with-matches", "--null", "--", query, HOME]
        title = " CONTENT SEARCH "
    elif mode == "folders":
        command = ["find", HOME, "-type", "d", "-print0"]
        title = " FIND FOLDER "
    else:
        command = ["rg", "--files", "--hidden", "--no-ignore", "--null", HOME]
        title = " FIND FILE "

    # Empty fzf environment prevents user defaults from changing output format.
    env = dict(os.environ, FZF_DEFAULT_OPTS="", FZF_DEFAULT_OPTS_FILE="")
    import shlex
    preview_cmd = f"python3 {shlex.quote(str(Path(__file__).resolve()))} preview {{}}"
    options = [
        "fzf", "--read0", "--print0", "--layout=reverse", "--border=rounded",
        "--height=100%", "--info=inline", f"--border-label={title}",
        "--prompt=❯ ", f"--color={COLORS}",
        "--header=All of ~ · includes hidden/ignored paths · Enter: reveal · Esc: cancel · Ctrl-/: preview",
        f"--preview={preview_cmd}", "--preview-window=right,55%,border-left",
        "--bind=ctrl-/:toggle-preview", "--no-multi",
    ]
    with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as source:
        try:
            picked = subprocess.run(options, stdin=source.stdout, stdout=subprocess.PIPE, env=env)
        finally:
            source.stdout.close()
            if source.poll() is None:
                source.terminate()
        if picked.returncode != 0:
            return
        selected = os.fsdecode(picked.stdout.rstrip(b"\0"))
        if selected:
            subprocess.run(["ya", "emit", "cd" if mode == "folders" else "reveal", selected], check=True)


if __name__ == "__main__":
    try:
        if sys.argv[1] == "preview":
            preview(sys.argv[2])
        else:
            main(sys.argv[1])
    except (KeyboardInterrupt, BrokenPipeError):
        pass
