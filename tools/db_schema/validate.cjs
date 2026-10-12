// 從專案根目錄執行：node tools/db_schema/validate.cjs
// 解析器僅供本機開發驗證，安裝於忽略提交的暫存目錄：
// npm install --prefix build/dbml_validation --no-save --package-lock=false @dbml/core@10.3.1
const fs = require('fs');
const path = require('path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const { Parser } = require(path.join(root, 'build/dbml_validation/node_modules/@dbml/core'));
const dbml = fs.readFileSync(path.join(root, 'docs/database/life_chronicle.dbml'), 'utf8');
const sql = fs.readFileSync(path.join(root, 'docs/database/life_chronicle.sql'), 'utf8');
const model = new Parser().parse(dbml, 'dbmlv2');
const tables = model.schemas.flatMap(schema => schema.tables);
const refs = model.schemas.flatMap(schema => schema.refs);
const sqlTables = [...sql.matchAll(/CREATE(?: VIRTUAL)? TABLE\s+"?(\w+)"?/g)].map(match => match[1]);
const sqlRefs = [...sql.matchAll(/REFERENCES\s+\w+\s*\(\w+\)/g)];
assert.deepEqual(tables.map(table => table.name).sort(), sqlTables.sort());
assert.equal(refs.length, sqlRefs.length);
assert.ok(tables.some(table => table.name === 'event_life_periods'));
assert.ok(tables.some(table => table.name === 'search_index'));
console.log(`DBML 官方解析器驗證通過：${tables.length} 張表、${refs.length} 個外鍵，與 SQLite 建表檔一致。`);
