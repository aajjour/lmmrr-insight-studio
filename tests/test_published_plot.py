import tempfile
from pathlib import Path
import unittest
from lmmrr_crosslang.published_plot import make_report

class PlotTest(unittest.TestCase):
    def test_descriptive_report(self):
        with tempfile.TemporaryDirectory() as folder:
            csv = Path(folder)/'numbers.csv'
            csv.write_text('component,index,value\nrr.sequence,1,1\nrr.sequence,2,0\nrr.sequence,3,-1\nrr.sequence,4,2\n')
            out = make_report(csv, Path(folder)/'plot.html')
            html = out.read_text()
            self.assertIn('rr.sequence', html)
            self.assertIn('Uncalibrated', html)
            self.assertIn('10.1080/00949655.2026.2748404', html)
