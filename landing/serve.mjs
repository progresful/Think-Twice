// Tiny static server for previewing the landing page: node serve.mjs [port]
import { createServer } from 'node:http';
import { createReadStream, statSync } from 'node:fs';
import { dirname, join, normalize, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = dirname(fileURLToPath(import.meta.url)), port = +process.env.PORT || +process.argv[2] || 4188;
const types = { '.html': 'text/html; charset=utf-8', '.png': 'image/png', '.mp4': 'video/mp4', '.js': 'text/javascript', '.css': 'text/css' };
createServer((req, res) => {
  const path = join(root, normalize(decodeURIComponent(req.url.split('?')[0])).replace(/^(\.\.[/\\])+/, ''));
  const file = path.endsWith('/') || path === root ? join(path, 'index.html') : path;
  let size; try { size = statSync(file).size; } catch { res.writeHead(404).end('Not found'); return; }
  const head = { 'Content-Type': types[extname(file)] || 'application/octet-stream', 'Accept-Ranges': 'bytes', 'Cache-Control': 'no-store' };
  const m = /bytes=(\d*)-(\d*)/.exec(req.headers.range || '');
  if (m) {
    const start = m[1] ? +m[1] : 0, end = m[2] ? Math.min(+m[2], size - 1) : size - 1;
    res.writeHead(206, { ...head, 'Content-Range': `bytes ${start}-${end}/${size}`, 'Content-Length': end - start + 1 });
    createReadStream(file, { start, end }).pipe(res);
  } else { res.writeHead(200, { ...head, 'Content-Length': size }); createReadStream(file).pipe(res); }
}).listen(port, () => console.log(`http://localhost:${port}`));
