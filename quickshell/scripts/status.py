#!/usr/bin/env python3
"""One shared, read-only sampler. Emits JSON lines; no third-party packages."""
import glob
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from datetime import datetime
from zoneinfo import ZoneInfo


def read(path, default=""):
    try:
        return Path(path).read_text().strip()
    except (OSError, ValueError):
        return default


def number(path):
    try:
        return int(read(path))
    except ValueError:
        return None


def run(args):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=2).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def cpu_times():
    values = list(map(int, read('/proc/stat').splitlines()[0].split()[1:9]))
    return sum(values), values[3] + values[4]


def temperature():
    # Prefer the CPU package sensor over arbitrary ACPI / GPU / NVMe sensors.
    for chip in glob.glob('/sys/class/hwmon/hwmon*'):
        if read(chip + '/name') in ('coretemp', 'k10temp', 'zenpower', 'cpu_thermal'):
            for sensor in sorted(glob.glob(chip + '/temp*_input')):
                value = number(sensor)
                if value is not None:
                    return round(value / 1000)
    for sensor in sorted(glob.glob('/sys/class/thermal/thermal_zone*/temp')):
        value = number(sensor)
        if value is not None and 0 < value < 150000:
            return round(value / 1000)
    return None


def network():
    routes = read('/proc/net/route').splitlines()[1:]
    iface = next((p[0] for line in routes if len(p := line.split()) > 3
                  and p[1] == '00000000' and int(p[3], 16) & 1), '')
    if not iface:
        try:
            routes6 = json.loads(run(['ip', '-j', '-6', 'route', 'show', 'default']) or '[]')
            iface = next((route['dev'] for route in routes6 if 'dev' in route), '')
        except (ValueError, KeyError):
            pass
    if not iface:
        return {'name': 'Offline', 'device': '', 'wifi': False, 'signal': None}
    wifi = Path('/sys/class/net', iface, 'wireless').exists()
    signal = None
    if wifi:
        for line in read('/proc/net/wireless').splitlines()[2:]:
            parts = line.split()
            if parts[0].rstrip(':') == iface:
                signal = min(100, round(float(parts[2].rstrip('.')) / 70 * 100))
    ssid = ''
    if wifi:
        scan = run(['nmcli', '-t', '--escape', 'no', '-f', 'IN-USE,SSID,SIGNAL',
                    'device', 'wifi', 'list', 'ifname', iface, '--rescan', 'no'])
        for line in scan.splitlines():
            if line.startswith('*:'):
                ssid, strength = line[2:].rsplit(':', 1)
                try:
                    signal = int(strength)
                except ValueError:
                    pass
                break
    return {'name': ssid or iface, 'device': iface, 'wifi': wifi, 'signal': signal}


def sample(previous):
    current = cpu_times()
    elapsed = current[0] - previous[0]
    cpu = max(0, min(100, round(100 * (1 - (current[1] - previous[1]) / elapsed)))) if elapsed else 0
    mem = {p[0].rstrip(':'): int(p[1]) for line in read('/proc/meminfo').splitlines()
           if len(p := line.split()) > 1}
    total = mem.get('MemTotal', 1)
    used = total - mem.get('MemAvailable', total)
    battery = None
    for device in sorted(glob.glob('/sys/class/power_supply/*')):
        if read(device + '/type') == 'Battery' and read(device + '/present', '1') != '0':
            capacity = number(device + '/capacity')
            if capacity is not None:
                battery = {'capacity': capacity, 'status': read(device + '/status')}
                break
    brightness = None
    for device in sorted(glob.glob('/sys/class/backlight/*')):
        maximum, value = number(device + '/max_brightness'), number(device + '/brightness')
        if maximum and value is not None:
            brightness = round(value / maximum * 100)
            break
    return current, dict(cpu=cpu, memory=round(used / total * 100),
                        memoryDetail=f'{used / 1048576:.1f} / {total / 1048576:.1f} GiB',
                        temperature=temperature(), battery=battery, brightness=brightness,
                        network=network(), newYork=datetime.now(ZoneInfo('America/New_York')).strftime('%H:%M'))


def main():
    previous = cpu_times()
    while True:
        previous, data = sample(previous)
        print(json.dumps(data, ensure_ascii=False), flush=True)
        if '--once' in sys.argv:
            return
        time.sleep(3)


if __name__ == '__main__':
    try:
        main()
    except (BrokenPipeError, KeyboardInterrupt):
        pass
