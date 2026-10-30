import tempfile,unittest,json
from pathlib import Path
from lmmrr_crosslang.report import report
class TestReport(unittest.TestCase):
    def test_report_and_status(self):
        with tempfile.TemporaryDirectory() as temp:
            folder=Path(temp); root=Path(__file__).resolve().parents[1]
            report(root/'fixtures',folder/'overview.html')
            html=(folder/'overview.html').read_text()
            self.assertIn('No calibrated inferential verdicts',html)
            self.assertIn('sleepstudy__RS__time',html)
            self.assertIn('Orthodont__RI__time',html)
            obj=json.loads((folder/'nonbootstrap_results.json').read_text())
            self.assertEqual(obj['bootstrap'],'NOT_IMPLEMENTED')
if __name__=='__main__':unittest.main()
