#!/usr/bin/env python3
"""Wallpaper catalogue, bounded thumbnail cache and Hyprpaper integration."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent
HOME = Path.home()
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "hyprquickpaper"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "hyprquickpaper"
FORMATS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif"}
TEMPLATE_ROOT = HOME / ".config/templates"


def read_json(path, default):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return default


def atomic_json(path, data):
    import tempfile
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        temporary = f.name
    os.replace(temporary, path)


def expanded(value):
    return Path(os.path.expandvars(os.path.expanduser(value))).absolute()


def thumbnail(path):
    from PIL import Image, ImageOps
    stat = path.stat()
    key = hashlib.sha256(f"{path}:{stat.st_mtime_ns}:{stat.st_size}".encode()).hexdigest()
    output = CACHE / "thumbs" / (key + ".jpg")
    if not output.exists():
        output.parent.mkdir(parents=True, exist_ok=True)
        with Image.open(path) as image:
            image.seek(0)
            image = ImageOps.exif_transpose(image).convert("RGB")
            image.thumbnail((900, 600))
            image.save(output, quality=85)
    return output


def catalogue(mode="themes"):
    config = read_json(ROOT / "config.json", {})
    directory = expanded(config.get("wallpaper_path" ))
    templates = []
    for path in sorted((ROOT / "templates").glob("*.json")):
        data = read_json(path, {})
        if data.get("layout") not in {"carousel", "gallery"}:
            continue
        data["id"] = path.stem
        templates.append(data)
    packs = []
    if TEMPLATE_ROOT.is_dir():
        for folder in sorted((p for p in TEMPLATE_ROOT.iterdir() if p.is_dir()), key=lambda p: p.name.casefold()):
            manifest = read_json(folder / "template.json", {})
            image_name = manifest.get("image", "")
            image = (folder / image_name) if image_name else next(
                (p for p in sorted(folder.iterdir()) if p.is_file() and p.suffix.lower() in FORMATS), None)
            config_dir = folder / "quickshell"
            if not image or not image.is_file() or not config_dir.is_dir():
                continue
            packs.append({"id": folder.name, "name": manifest.get("name", folder.name),
                          "image": str(image), "preview": image.as_uri(),
                          "wallpaper": str((folder / manifest.get("wallpaper", image.name)).resolve())})
    wallpapers = []
    errors = []
    paths = directory.rglob("*") if config.get("recursive", True) else directory.glob("*")
    import importlib.util
    spec = importlib.util.spec_from_file_location("desktop_themes", ROOT.parent / "SettingsHub/hub-helper.py")
    hub = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(hub)
    for path in sorted(paths, key=lambda p: str(p).casefold()):
        if path.is_file() and path.suffix.lower() in FORMATS:
            try:
                hub.theme_for_wallpaper(path)
            except (OSError, ValueError) as error:
                errors.append(f"{path.name}: {error}")
    candidates = [(expanded(theme["wallpaper"]), theme) for theme in hub.list_themes()]
    for path, theme in candidates:
        if path.is_file() and path.suffix.lower() in FORMATS:
            try:
                wallpapers.append({"path": str(path), "name": theme["name"] if theme else path.stem,
                                   "preview": thumbnail(path).as_uri(),
                                   "url": path.as_uri(), "gif": path.suffix.lower() == ".gif",
                                   "theme": theme["id"] if theme else ""})
            except (OSError, ValueError) as error:
                errors.append(f"{path.name}: {error}")
    saved = read_json(STATE / "current.json", {})
    return {"wallpapers": wallpapers, "templates": templates, "packs": packs, "directory": str(directory),
            "template": read_json(STATE / "menu.json", {}).get("template", config.get("template", "carousel")),
            "current": saved.get("path", ""), "warnings": errors}


def command(args):
    return subprocess.run(args, capture_output=True, text=True, timeout=8)


def start_transition(new_path):
    config = read_json(ROOT / "config.json", {})
    if not config.get("transitions", True):
        return
    old_value = read_json(STATE / "current.json", {}).get("path", "")
    old_path = expanded(old_value) if old_value else None
    if old_path is None or not old_path.is_file() or old_path == new_path:
        return
    environment = dict(os.environ, HYPRQUICKPAPER_OLD_IMAGE=old_path.as_uri(),
                       HYPRQUICKPAPER_NEW_IMAGE=new_path.as_uri())
    try:
        subprocess.run(["quickshell", "--daemonize", "--path", str(ROOT / "Transition.qml")],
                       env=environment, capture_output=True, timeout=3)
    except (OSError, subprocess.TimeoutExpired):
        pass  # Wallpaper switching remains available if the effect cannot start.


def apply_wallpaper(value, persist=True):
    path = expanded(value)
    if not path.is_file() or path.suffix.lower() not in FORMATS:
        raise ValueError("Bitte eine vorhandene Bilddatei auswählen.")
    # Hyprpaper displays still images. Use a full-resolution first frame for GIFs.
    actual = path
    if path.suffix.lower() == ".gif":
        from PIL import Image
        CACHE.mkdir(parents=True, exist_ok=True)
        actual = CACHE / "gif-background.png"
        with Image.open(path) as image:
            image.convert("RGBA").save(actual)
    probe = command(["hyprctl", "hyprpaper", "listactive"])
    if probe.returncode:
        if command(["pgrep", "-x", "hyprpaper"]).returncode:
            STATE.mkdir(parents=True, exist_ok=True)
            initial = STATE / "hyprpaper.conf"
            initial.write_text("wallpaper {\n    monitor =\n    path = " + str(actual) + "\n}\n")
            with (STATE / "hyprpaper.log").open("a") as log:
                subprocess.Popen(["hyprpaper", "-c", str(initial)], stdout=log, stderr=log,
                                 start_new_session=True)
        for _ in range(30):
            if command(["hyprctl", "hyprpaper", "listactive"]).returncode == 0:
                break
            time.sleep(0.1)
        else:
            raise RuntimeError("Hyprpaper ist nicht erreichbar. Bitte in deiner Hyprland-Sitzung öffnen.")
    monitors = command(["hyprctl", "monitors", "-j"])
    if monitors.returncode:
        raise RuntimeError(monitors.stderr.strip() or "Monitore konnten nicht gelesen werden.")
    names = [monitor["name"] for monitor in json.loads(monitors.stdout)]
    if not names:
        raise RuntimeError("Keine aktiven Monitore gefunden.")
    start_transition(actual)
    for monitor in names:
        result = command(["hyprctl", "hyprpaper", "wallpaper", f"{monitor},{actual}"])
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Wallpaper-Wechsel fehlgeschlagen.")
    if persist:
        atomic_json(STATE / "current.json", {"path": str(path)})
    return {"ok": True}


def apply_pack(identifier):
    folder = (TEMPLATE_ROOT / identifier).resolve()
    if folder.parent != TEMPLATE_ROOT.resolve() or not folder.is_dir():
        raise ValueError("Unbekanntes Design-Paket.")
    manifest = read_json(folder / "template.json", {})
    image_name = manifest.get("image", "")
    image = (folder / image_name) if image_name else next(
        (p for p in sorted(folder.iterdir()) if p.is_file() and p.suffix.lower() in FORMATS), None)
    wallpaper = folder / manifest.get("wallpaper", image.name if image else "")
    if image and (image.resolve() == folder or folder not in image.resolve().parents):
        raise ValueError("Das Paketbild muss innerhalb des Paketordners liegen.")
    if folder not in wallpaper.resolve().parents:
        raise ValueError("Das Wallpaper muss innerhalb des Paketordners liegen.")
    source = folder / "quickshell"
    if not image or not image.is_file() or image.suffix.lower() not in FORMATS:
        raise ValueError("Im Design-Paket fehlt ein gültiges Bild.")
    if not wallpaper.is_file() or wallpaper.suffix.lower() not in FORMATS:
        raise ValueError("Das Wallpaper aus template.json wurde nicht gefunden.")
    if not source.is_dir() or source.is_symlink():
        raise ValueError("Im Design-Paket fehlt der Ordner quickshell/.")
    target = HOME / ".config/quickshell"
    backup = STATE / "template-backups" / (time.strftime("%Y%m%d-%H%M%S") + "-" + identifier)
    copied = []
    for path in source.rglob("*"):
        if path.is_symlink():
            raise ValueError("Symlinks sind in Design-Paketen nicht erlaubt.")
        if path.is_file():
            relative = path.relative_to(source)
            if relative.parts[0] == "hyprquickpaper":
                raise ValueError("Ein Paket darf den hyprquickpaper-Ordner nicht überschreiben.")
            copied.append((path, relative))
    if not copied:
        raise ValueError("Der Ordner quickshell/ enthält keine Dateien.")
    changed = []
    created = []
    try:
        for path, relative in copied:
            destination = target / relative
            if destination.exists() and destination.is_file():
                saved = backup / relative
                saved.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(destination, saved)
                changed.append((destination, saved))
            else:
                created.append(destination)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, destination)
        apply_wallpaper(str(wallpaper))
    except Exception:
        for destination, saved in reversed(changed):
            shutil.copy2(saved, destination)
        for destination in created:
            destination.unlink(missing_ok=True)
        raise
    # Restart only instances using the main quickshell config, leaving this picker alive.
    listed = command(["quickshell", "list", "-a", "-j"])
    if listed.returncode == 0:
        try:
            instances = json.loads(listed.stdout)
            main_config = str((target / "shell.qml").resolve())
            for instance in instances:
                if Path(instance.get("config_path", "")).resolve() == Path(main_config):
                    command(["quickshell", "kill", "--pid", str(instance["pid"])])
            subprocess.Popen(["quickshell", "--daemonize", "--path", main_config],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
        except (ValueError, KeyError, OSError):
            pass
    atomic_json(STATE / "menu.json", {"template": read_json(STATE / "menu.json", {}).get("template", "carousel"),
                                      "pack": identifier})
    return {"ok": True, "backup": str(backup), "name": manifest.get("name", identifier)}


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "list"
    if action == "list":
        result = catalogue(sys.argv[2] if len(sys.argv) > 2 else os.environ.get("HYPRQUICKPAPER_MODE", "wallpapers"))
    elif action == "apply":
        result = apply_wallpaper(sys.argv[2])
    elif action == "restore":
        selected = read_json(STATE / "current.json", {}).get("path", "")
        if not selected or not Path(selected).is_file():
            selected = str(HOME / ".config/hypr/scripts/walpaper-red.png")
        result = apply_wallpaper(selected)
    elif action == "template":
        identifier = sys.argv[2]
        if identifier not in {p.stem for p in (ROOT / "templates").glob("*.json")}:
            raise ValueError("Unbekannte Vorlage.")
        atomic_json(STATE / "menu.json", {"template": identifier})
        result = {"ok": True}
    elif action == "pack":
        result = apply_pack(sys.argv[2])
    else:
        raise ValueError("Unbekannte Aktion.")
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(json.dumps({"ok": False, "error": str(error)}, ensure_ascii=False))
        sys.exit(1)
