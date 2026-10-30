"""Loopback-only local server for the interactive educational dashboard."""
import argparse
import json
import sys
import webbrowser
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlsplit

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:sys.path.insert(0,str(ROOT))
from app.engine import analyze
from app.report import render_report

MIME={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8'}

def run(data, port=0, browser=True):
    result=analyze(data)
    payload=json.dumps(result,ensure_ascii=False,separators=(',',':')).encode('utf8')
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            path=urlsplit(self.path).path
            if path=='/api/data':
                body=payload; typ='application/json; charset=utf-8'
            elif path=='/report.html':
                dest=ROOT/'output'/'LMM_RR_Insight_Report.html'
                render_report(result,dest)
                body=dest.read_bytes();typ='text/html; charset=utf-8'
            elif path in ('/','/index.html','/style.css','/app.js'):
                name='index.html' if path=='/' else path.lstrip('/')
                body=(ROOT/'app'/name).read_bytes();typ=MIME[Path(name).suffix]
            else:
                self.send_error(404);return
            self.send_response(200)
            self.send_header('Content-Type',typ)
            if path=='/report.html':
                self.send_header('Content-Disposition','attachment; filename="LMM_RR_Insight_Report.html"')
            self.send_header('Content-Length',str(len(body)))
            self.send_header('Cache-Control','no-store')
            self.send_header('X-Content-Type-Options','nosniff')
            self.send_header('Content-Security-Policy',"default-src 'self' 'unsafe-inline'; img-src 'self' data:; script-src 'self'; connect-src 'self'; object-src 'none'; frame-ancestors 'none'")
            self.end_headers();self.wfile.write(body)
        def log_message(self,fmt,*args):pass
    server=ThreadingHTTPServer(('127.0.0.1',port),Handler)
    url=f'http://127.0.0.1:{server.server_port}/'
    print('LMM RR Insight Studio | LOCAL ONLY',flush=True)
    print('DATA:',Path(data).resolve(),flush=True)
    print('URL:',url,flush=True)
    print('Stop with Ctrl+C. No data leaves your Mac.',flush=True)
    if browser:webbrowser.open(url)
    try:server.serve_forever()
    except KeyboardInterrupt:pass
    finally:server.server_close()

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('--data',default=str(ROOT/'examples'/'demo'))
    ap.add_argument('--port',type=int,default=0)
    ap.add_argument('--no-browser',action='store_true')
    ap.add_argument('--report',help='write self-contained HTML report then exit')
    args=ap.parse_args()
    if args.report:
        print('Report written:',render_report(analyze(args.data),args.report))
    else:run(args.data,args.port,not args.no_browser)
