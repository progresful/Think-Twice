"""Render film.html frame by frame to JPEGs through Chrome's debugging protocol.
Usage: uv run --python 3.12 --with websockets render4.py <seconds> <out_dir> [first_frame last_frame]"""
import asyncio, json, base64, subprocess, sys, time, urllib.request, os
import websockets
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
HERE = os.path.dirname(os.path.abspath(__file__))
total, out, FPS, PORT = float(sys.argv[1]), sys.argv[2], 30, 9334
os.makedirs(out, exist_ok=True)

async def main():
    p = subprocess.Popen([CHROME, '--headless=new', f'--remote-debugging-port={PORT}', f'--user-data-dir={HERE}/tmp/chrome-render',
                          '--hide-scrollbars', '--window-size=1920,1080', '--force-device-scale-factor=1', '--allow-file-access-from-files', 'about:blank'],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(50):
            try: tabs = json.load(urllib.request.urlopen(f'http://127.0.0.1:{PORT}/json')); break
            except Exception: time.sleep(0.2)
        ws = [t for t in tabs if t['type'] == 'page'][0]['webSocketDebuggerUrl']
        async with websockets.connect(ws, max_size=None) as c:
            n = 0
            async def call(method, **params):
                nonlocal n; n += 1
                await c.send(json.dumps({'id': n, 'method': method, 'params': params}))
                while True:
                    r = json.loads(await c.recv())
                    if r.get('id') == n: return r.get('result', {})
            await call('Page.enable')
            await call('Emulation.setDeviceMetricsOverride', width=1920, height=1080, deviceScaleFactor=1, mobile=False)
            await call('Page.navigate', url=f'file://{HERE}/film.html')
            for _ in range(60):   # wait until every image has loaded
                await asyncio.sleep(0.5)
                r = await call('Runtime.evaluate', expression='[...document.images].every(i=>i.complete&&i.naturalWidth>0)')
                if r.get('result', {}).get('value'): break
            else: raise SystemExit('images did not load')
            for f in range(int(sys.argv[3]) if len(sys.argv) > 3 else 0, int(sys.argv[4]) if len(sys.argv) > 4 else int(total * FPS)):
                await call('Runtime.evaluate', expression=f'setT({f / FPS})')
                r = await call('Page.captureScreenshot', format='jpeg', quality=94)
                open(f'{out}/f{f:05d}.jpg', 'wb').write(base64.b64decode(r['data']))
    finally:
        p.terminate()
asyncio.run(main())
