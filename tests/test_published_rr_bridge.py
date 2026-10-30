"""Contract tests for the Python facade. R execution is separately smoke-tested on Mac."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from lmmrr_crosslang.published_rr import (
    RRBridgeError, DOI, inspect_published_rr, run_published_rr
)

class PublishedBridgeContractTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        bridge = self.root / 'R/published_rr_bridge.R'
        bridge.parent.mkdir()
        bridge.write_text('# stub')
        src = self.root / 'reference/published_r/lmmRRdiag/R/recursive_residuals.R'
        src.parent.mkdir(parents=True)
        src.write_text('# stub')
        self.csv = self.root / 'data.csv'
        self.csv.write_text('y,x,group\n1,2,a\n2,3,a\n3,4,b\n')

    def fake_run(self, command, **kwargs):
        config = json.loads(Path(command[-1]).read_text())
        self.assertEqual(Path(config['repo_root']).resolve(), self.root.resolve())
        self.assertIn('published_rr_bridge.R', command[1])
        response = {'ok': True, 'mode': config['mode'],
                    'bootstrap_executed': False, 'scientific_reference_doi': DOI}
        if config['mode'] == 'run':
            self.assertEqual(config['formula'], 'y ~ x + (1|group)')
            response['numeric_components'] = 10
        Path(config['output_json']).write_text(json.dumps(response))
        class P:
            returncode = 0
            stderr = ''
        return P()

    @patch('lmmrr_crosslang.published_rr.shutil.which', return_value='/fake/Rscript')
    def test_inspection(self, _which):
        with patch('lmmrr_crosslang.published_rr.subprocess.run', side_effect=self.fake_run):
            result = inspect_published_rr(repo_root=self.root)
        self.assertTrue(result['ok'])
        self.assertFalse(result['bootstrap_executed'])

    @patch('lmmrr_crosslang.published_rr.shutil.which', return_value='/fake/Rscript')
    def test_python_calls_real_engine_contract(self, _which):
        with patch('lmmrr_crosslang.published_rr.subprocess.run', side_effect=self.fake_run):
            result = run_published_rr(self.csv, 'y ~ x + (1|group)',
                                      output_dir=self.root/'out', repo_root=self.root)
        self.assertEqual(result['numeric_components'], 10)
        self.assertFalse(result['bootstrap_executed'])

    def test_bootstrap_options_rejected(self):
        with self.assertRaisesRegex(ValueError, 'bootstrap/refit'):
            run_published_rr(self.csv, 'y ~ x + (1|group)',
                             output_dir=self.root/'out', repo_root=self.root,
                             rr_options={'n_bootstrap': 999})

    def test_missing_original_source_fails_closed(self):
        (self.root/'reference/published_r/lmmRRdiag/R/recursive_residuals.R').unlink()
        with self.assertRaises(RRBridgeError):
            inspect_published_rr(repo_root=self.root)

    def test_bad_formula_rejected(self):
        with self.assertRaises(ValueError):
            run_published_rr(self.csv, 'y ~ x', output_dir=self.root/'out', repo_root=self.root)

    @patch('lmmrr_crosslang.published_rr.shutil.which', return_value='/fake/Rscript')
    def test_r_errors_propagated(self, _which):
        def failed(command, **kwargs):
            config=json.loads(Path(command[-1]).read_text())
            Path(config['output_json']).write_text(json.dumps({'ok':False,'error':'R function requires extra args'}))
            class P:
                returncode=2
                stderr='details'
            return P()
        with patch('lmmrr_crosslang.published_rr.subprocess.run', side_effect=failed):
            with self.assertRaisesRegex(RRBridgeError, 'requires extra args'):
                inspect_published_rr(repo_root=self.root)

if __name__ == '__main__': unittest.main()
