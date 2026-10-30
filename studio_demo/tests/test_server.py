import json
import subprocess
import sys
import time
import unittest
from urllib.request import urlopen
from urllib.error import URLError
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
class ServerTests(unittest.TestCase):
    def test_http_api_and_assets(self):
        # Use an ephemeral loopback port reported on stdout.
        p=subprocess.Popen([sys.executable,'-u','-m','app.server','--data',
             str(ROOT/'examples/demo'),'--port','0','--no-browser'],cwd=ROOT,
             stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        try:
            lines=[p.stdout.readline().strip() for _ in range(3)]
            self.assertTrue(lines[0].startswith('LMM RR'))
            self.assertTrue(lines[2].startswith('URL:'))
            url=lines[2].split('URL:',1)[1].strip()
            with urlopen(url+'api/data',timeout=4) as r:
                self.assertEqual(r.status,200)
                obj=json.loads(r.read())
                self.assertTrue(obj['demo'])
            for name in ['','app.js','style.css','report.html']:
                with urlopen(url+name,timeout=5) as r:
                    self.assertEqual(r.status,200)
                    self.assertTrue(r.read())
        finally:
            p.terminate()
            try:p.wait(timeout=4)
            except subprocess.TimeoutExpired:p.kill()
            p.stdout.close()
            p.stderr.close()
