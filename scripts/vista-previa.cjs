const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const mime = { '.html':'text/html; charset=utf-8', '.css':'text/css; charset=utf-8', '.js':'text/javascript; charset=utf-8', '.jpg':'image/jpeg', '.jpeg':'image/jpeg', '.png':'image/png' };
http.createServer((req, res) => {
  let relative;
  try { relative = decodeURIComponent(new URL(req.url, 'http://localhost').pathname); }
  catch { res.writeHead(400); return res.end(); }
  if (relative === '/') relative = '/prueba.html';
  const target = path.resolve(root, '.' + relative);
  if (!target.startsWith(root + path.sep) || !mime[path.extname(target).toLowerCase()]) { res.writeHead(403); return res.end(); }
  fs.stat(target, (error, stat) => {
    if (error || !stat.isFile()) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'Content-Type':mime[path.extname(target).toLowerCase()], 'Content-Length':stat.size });
    if (req.method === 'HEAD') return res.end();
    fs.createReadStream(target).pipe(res);
  });
}).listen(4173, '127.0.0.1', () => console.log('Vista previa: http://127.0.0.1:4173/'));
