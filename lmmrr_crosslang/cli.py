import argparse,json
from pathlib import Path
from .report import report

def main():
    p=argparse.ArgumentParser(prog='lmmrr-compare',description='Non-bootstrap R/Python indexed-innovation validation')
    p.add_argument('--fixtures',default='fixtures');p.add_argument('--output',default='results/nonbootstrap_report.html')
    a=p.parse_args(); print('Generated:',report(Path(a.fixtures),Path(a.output)))
if __name__=='__main__':main()
