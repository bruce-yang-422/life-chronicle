// 由企劃書 .md 重新產生 .html，保留既有 HTML 的 <head> 樣式與 <footer>。
const fs = require('fs');
const path = require('path');
const md = require('markdown-it')('commonmark').enable('table');

const root = path.resolve(__dirname, '../..');
const mdPath = path.join(root, '人生編年史_APP_開發企劃書_v2.md');
const htmlPath = path.join(root, '人生編年史_APP_開發企劃書_v2.html');

const old = fs.readFileSync(htmlPath, 'utf8');
const head = old.slice(0, old.indexOf('<main>') + '<main>'.length);
const footer = old.slice(old.indexOf('<footer>'));
fs.writeFileSync(htmlPath, head + md.render(fs.readFileSync(mdPath, 'utf8')) + footer);
console.log('已產生', path.basename(htmlPath));
