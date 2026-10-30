import csv
import json
import tempfile
import unittest
from pathlib import Path
from app.engine import analyze, status, _holm, explanations
from app.generate_demo import generate
from app.report import render_report

class EngineTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root=Path(self.tmp.name)
        generate(self.root)
    def tearDown(self):self.tmp.cleanup()
    def test_demo_is_never_inferential(self):
        a=analyze(self.root)
        self.assertTrue(a['demo'])
        self.assertEqual(len(a['processes']),20)
        self.assertTrue(all(p['holm_p'] is None for p in a['processes']))
        self.assertEqual(sum(status(p)=='demo_signal' for p in a['processes']),4)
    def test_demo_is_deterministic(self):
        before=(self.root/'traces.csv').read_bytes()
        generate(self.root)
        self.assertEqual(before,(self.root/'traces.csv').read_bytes())
    def test_holm_formula(self):
        self.assertEqual(_holm([.01,.03,.04]),[.03,.06,.06])
    def test_eligible_complete_family(self):
        with (self.root/'evidence.csv').open('w',newline='') as f:
            writer=csv.writer(f)
            writer.writerow(['model','process','p_value','calibration','scope','b_refits','origin','family_id','family_size','demo_signal'])
            for mi,model in enumerate(['A · Baseline illustration','B · Mean drift illustration','C · Grouping illustration','D · Serial illustration','E · Random-slope illustration']):
                for pi,proc in enumerate(['mean_indexed','cluster_indexed','serial_indexed','blup_indexed']):
                    writer.writerow([model,proc,.01 if pi==0 else .4,'refit_parametric_bootstrap',
                                    'global_process',999,'user_supplied',f'family_{mi}',4,'false'])
        a=analyze(self.root)
        first=[p for p in a['processes'] if p['model']==a['models'][0]]
        self.assertEqual(len(first),4)
        self.assertAlmostEqual(first[0]['holm_p'],.04)
        self.assertEqual(status(first[0]),'signal')
        self.assertTrue(all(x['holm_p'] is not None for x in first))
    def test_incomplete_family_withholds_inference(self):
        evidence=self.root/'evidence.csv'
        with evidence.open(encoding='utf8') as f:
            rows=list(csv.DictReader(f))
        for r in rows:
            r.update(p_value='.01',calibration='refit_parametric_bootstrap',scope='global_process',
                     b_refits='999',origin='user_supplied',family_size='5')
        with evidence.open('w',newline='',encoding='utf8') as f:
            w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
        a=analyze(self.root)
        self.assertTrue(all(p['holm_p'] is None for p in a['processes']))
        self.assertTrue(all(status(p)=='unverified' for p in a['processes']))
    def test_malformed_trace_rejected(self):
        trace=self.root/'traces.csv'
        with trace.open(encoding='utf8') as f:
            rows=list(csv.DictReader(f))
        rows[10]['upper']=rows[10]['lower']
        with trace.open('w',newline='',encoding='utf8') as f:
            w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
        with self.assertRaisesRegex(ValueError,'Invalid envelope'):analyze(self.root)
    def test_static_report(self):
        obj=analyze(self.root)
        dest=render_report(obj,self.root/'report.html')
        content=dest.read_text()
        self.assertIn('SYNTHETIC',content.upper())
        self.assertIn('10.1080/00949655.2026.2748404',content)
        self.assertIn('<svg',content)
        self.assertGreater(len(content),10000)
    def test_explanation_no_causal_claims(self):
        obj=analyze(self.root)
        ex=explanations(obj,obj['models'][0])
        self.assertEqual(len(ex),4)
        self.assertIn('not an identified cause',ex[0]['interpretation'])

if __name__=='__main__':unittest.main()
