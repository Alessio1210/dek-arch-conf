"""Check sampler edge cases without requiring laptop hardware or a network."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('sampler', Path(__file__).parents[1] / 'scripts/status.py')
sampler = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sampler)


class SamplerTests(unittest.TestCase):
    def sample_with(self, files, paths):
        with patch.object(sampler, 'read', side_effect=lambda p, default='': files.get(p, default)), \
             patch.object(sampler.glob, 'glob', side_effect=lambda p: paths.get(p, [])), \
             patch.object(sampler, 'cpu_times', return_value=(200, 90)), \
             patch.object(sampler, 'network', return_value={'name': 'Offline'}):
            return sampler.sample((100, 40))[1]

    def test_cpu_and_available_memory(self):
        data = self.sample_with({'/proc/meminfo': 'MemTotal: 1000 kB\nMemAvailable: 250 kB'}, {})
        self.assertEqual(data['cpu'], 50)
        self.assertEqual(data['memory'], 75)
        self.assertIsNone(data['battery'])
        self.assertIsNone(data['brightness'])
        self.assertIsNone(data['temperature'])

    def test_discovers_nonstandard_laptop_devices(self):
        files = {'/sys/class/power_supply/BAT1/type': 'Battery',
                 '/sys/class/power_supply/BAT1/capacity': '72',
                 '/sys/class/power_supply/BAT1/status': 'Charging',
                 '/sys/class/backlight/intel_backlight/max_brightness': '1000',
                 '/sys/class/backlight/intel_backlight/brightness': '350'}
        paths = {'/sys/class/power_supply/*': ['/sys/class/power_supply/BAT1'],
                 '/sys/class/backlight/*': ['/sys/class/backlight/intel_backlight']}
        data = self.sample_with(files, paths)
        self.assertEqual(data['battery'], {'capacity': 72, 'status': 'Charging'})
        self.assertEqual(data['brightness'], 35)

    def test_zero_brightness_max_and_absent_battery(self):
        files = {'/sys/class/backlight/test/max_brightness': '0',
                 '/sys/class/backlight/test/brightness': '0',
                 '/sys/class/power_supply/BAT0/type': 'Battery',
                 '/sys/class/power_supply/BAT0/present': '0'}
        data = self.sample_with(files, {'/sys/class/backlight/*': ['/sys/class/backlight/test'],
                                       '/sys/class/power_supply/*': ['/sys/class/power_supply/BAT0']})
        self.assertIsNone(data['brightness'])
        self.assertIsNone(data['battery'])

    def test_offline_without_routes(self):
        with patch.object(sampler, 'read', return_value=''), patch.object(sampler, 'run', return_value='[]'):
            self.assertEqual(sampler.network()['name'], 'Offline')

    def test_wifi_ssid_with_colon(self):
        route = 'Iface Destination Gateway Flags\nwlan0 00000000 0100000A 0003'
        with patch.object(sampler, 'read', side_effect=lambda p, default='': route if p == '/proc/net/route' else ''), \
             patch.object(sampler.Path, 'exists', return_value=True), \
             patch.object(sampler, 'run', return_value='*:My:Network:91'):
            self.assertEqual(sampler.network(), {'name': 'My:Network', 'device': 'wlan0', 'wifi': True, 'signal': 91})


if __name__ == '__main__':
    unittest.main()
