#!/usr/bin/env node
'use strict';
// Same-origin reverse proxy: serves the bundled viewer under /__breakpoints__/ and proxies
// everything else to the user's dev server. Because the viewer and the framed site then share
// one origin (this proxy's port), scroll-sync and Save PNG work (they're blocked cross-origin).
//
// Usage: node server.js <http(s)-dev-url> <port> [viewer-dir]
const http = require('http');
const https = require('https');
const net = require('net');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const TARGET = process.argv[2];
const PORT = parseInt(process.argv[3] || '8765', 10);
const VIEWER_DIR = process.argv[4] || __dirname;

if (!TARGET || !/^https?:\/\//.test(TARGET)) {
  console.error('ERROR: usage: node server.js <http-dev-url> <port> [viewer-dir]');
  process.exit(1);
}
const target = new URL(TARGET);
const isHttps = target.protocol === 'https:';
const upstream = isHttps ? https : http;
const targetPort = target.port || (isHttps ? 443 : 80);
const PREFIX = '/__breakpoints__/';

function ctype(f) {
  if (f.endsWith('.html')) return 'text/html; charset=utf-8';
  if (f.endsWith('.js')) return 'text/javascript';
  if (f.endsWith('.css')) return 'text/css';
  if (f.endsWith('.png')) return 'image/png';
  if (f.endsWith('.svg')) return 'image/svg+xml';
  return 'application/octet-stream';
}

const server = http.createServer((req, res) => {
  // serve the bundled viewer (and any sibling assets) under the prefix
  if (req.url.startsWith(PREFIX)) {
    let rel = req.url.slice(PREFIX.length).split('?')[0] || 'viewer.html';
    rel = rel.replace(/\.\.+/g, '');                 // crude traversal guard
    const file = path.join(VIEWER_DIR, rel || 'viewer.html');
    fs.readFile(file, (err, buf) => {
      if (err) { res.writeHead(404); res.end('not found'); return; }
      res.writeHead(200, { 'content-type': ctype(file) });
      res.end(buf);
    });
    return;
  }
  // proxy everything else to the dev server
  const preq = upstream.request({
    host: target.hostname,
    port: targetPort,
    method: req.method,
    path: req.url,
    headers: Object.assign({}, req.headers, { host: target.host })
  }, (pres) => {
    res.writeHead(pres.statusCode, pres.headers);
    pres.pipe(res);
  });
  preq.on('error', (e) => { if (!res.headersSent) res.writeHead(502); res.end('proxy error: ' + e.message); });
  req.pipe(preq);
});

// websocket / HMR passthrough (http targets only; dev servers are http://localhost)
server.on('upgrade', (req, socket, head) => {
  if (isHttps) { socket.destroy(); return; }
  const u = net.connect(targetPort, target.hostname, () => {
    u.write(`${req.method} ${req.url} HTTP/1.1\r\n` +
      Object.entries(req.headers).map(([k, v]) => `${k}: ${v}`).join('\r\n') + '\r\n\r\n');
    if (head && head.length) u.write(head);
    socket.pipe(u);
    u.pipe(socket);
  });
  u.on('error', () => socket.destroy());
  socket.on('error', () => u.destroy());
});

server.listen(PORT, '127.0.0.1', () => {
  console.log('LISTENING ' + PORT);
});
