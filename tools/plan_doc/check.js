// 以 CommonMark（＋GFM 表格）解析 Markdown，找出因 CJK 標點等原因未被解析的強調符號。
// 用法：node check.js [檔案...]（預設檢查企劃書、README、AI_AGENT_TASKS）
const fs = require('fs');
const path = require('path');
const md = require('markdown-it')('commonmark').enable('table');

const root = path.resolve(__dirname, '../..');
const files = process.argv.length > 2
  ? process.argv.slice(2)
  : ['人生編年史_APP_開發企劃書_v2.md', 'README.md', 'AI_AGENT_TASKS.md'].map(f => path.join(root, f));

let total = 0;
for (const file of files) {
  const tokens = md.parse(fs.readFileSync(file, 'utf8'), {});
  for (const t of tokens) {
    if (t.type !== 'inline') continue;
    for (const c of t.children) {
      // 單一底線常見於檔名（如 v2_APP），屬正常文字，只檢查殘留的 * 與 __
      if (c.type === 'text' && /\*|__/.test(c.content)) {
        console.log(`${path.basename(file)}:${t.map ? t.map[0] + 1 : '?'}: ${c.content.slice(0, 80)}`);
        total++;
      }
    }
  }
}
console.log(total ? `發現 ${total} 處問題` : '檢查通過');
process.exit(total ? 1 : 0);
