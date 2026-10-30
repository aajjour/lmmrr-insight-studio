import unittest
from pathlib import Path
import numpy as np
from lmmrr_crosslang import Input, compute, get_input
from lmmrr_crosslang.fixtures import DATASETS,MODELS

FIX=Path(__file__).resolve().parents[1]/'fixtures'
class TestCore(unittest.TestCase):
    def test_input_validation(self):
        x=get_input(FIX,'sleepstudy','RI')
        with self.assertRaises(ValueError):compute(Input(**{**x.__dict__,'sigma2':0}))
        with self.assertRaises(ValueError):compute(Input(**{**x.__dict__,'row_id':np.zeros(x.y.size,dtype=int)}))
    def test_zero_innovation(self):
        v=get_input(FIX,'sleepstudy','RI')
        z=compute(Input(**{**v.__dict__,'y':v.X@v.beta}))
        self.assertLess(max(abs(q) for q in z['innovation']),1e-12)
    def test_permutation_invariance(self):
        for ds in DATASETS:
            for m in MODELS:
                v=get_input(FIX,ds,m)
                a=compute(v)
                rng=np.random.default_rng(51)
                q=rng.permutation(v.y.size)
                perm=Input(y=v.y[q], X=v.X[q],beta=v.beta,Z=v.Z[q],D=v.D,sigma2=v.sigma2,
                           group=v.group[q],index=v.index[q],row_id=v.row_id[q])
                b=compute(perm)
                self.assertEqual(a['row_id'],b['row_id'])
                np.testing.assert_allclose(a['innovation'],b['innovation'],rtol=1e-12,atol=1e-11)
    def test_matrix_reconstruction(self):
        v=get_input(FIX,'Orthodont','RS');result=compute(v)
        ix=np.flatnonzero(v.group=='M01');ix=ix[np.argsort(v.index[ix])]
        U=v.Z[ix]@v.D@v.Z[ix].T+v.sigma2*np.eye(len(ix))
        L=np.linalg.cholesky(U)
        e=v.y[ix]-v.X[ix]@v.beta
        z=np.asarray([result['innovation'][result['row_id'].index(int(v.row_id[j]))] for j in ix])
        np.testing.assert_allclose(L@z,e,atol=1e-10)
    def test_fixtures(self):
        for ds,expectedn,groups in [('sleepstudy',180,18),('Orthodont',108,27)]:
            for st in MODELS:
                for ord in ('time','marginal_fitted','reverse_time'):
                    out=compute(get_input(FIX,ds,st,ord))
                    self.assertEqual(out['n'],expectedn)
                    self.assertEqual(out['groups'],groups)
                    self.assertEqual(out['inference']['global_alarm'],'NOT_AVAILABLE')
                    self.assertIsNone(out['inference']['p_value'])
                    self.assertLess(abs(out['centered_cusum'][-1]),1e-11)
                    self.assertTrue(np.isfinite(out['innovation']).all())
if __name__=='__main__': unittest.main()
