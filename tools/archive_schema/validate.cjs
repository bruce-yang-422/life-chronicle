// 離線驗證正式匯出的 JSON 與負向案例；不發出網路請求。
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const Ajv2020 = require('ajv/dist/2020').default;
const addFormats = require('ajv-formats');
const commonmark = require('commonmark');

const root = path.resolve(__dirname, '../../build/archive_schema_validation');
let checks = 0;
const supplied = process.argv.slice(2);
const scenarios = supplied.length
  ? supplied.map(folder => [folder, path.resolve(folder)])
  : ['full', 'no_media', 'custom'].map(scope => [scope, path.join(root, scope)]);
for (const [scope, folder] of scenarios) {
  const read = (name) => JSON.parse(fs.readFileSync(path.join(folder, name), 'utf8'));
  const ajv = new Ajv2020({strict: true, allErrors: true});
  addFormats(ajv);
  for (const file of fs.readdirSync(path.join(folder, 'schema'))) {
    if (file.endsWith('.schema.json')) ajv.addSchema(read(`schema/${file}`), file);
  }
  const run = (schema, value, expected = true) => {
    const validate = ajv.getSchema(schema);
    assert.ok(validate, `找不到 Schema：${schema}`);
    const valid = validate(value);
    assert.equal(valid, expected, `${scope}/${schema}: ${JSON.stringify(validate.errors)}`);
    checks++;
  };
  const data = {};
  for (const file of fs.readdirSync(path.join(folder, 'data'))) {
    if (!file.endsWith('.json')) continue;
    const table = file.slice(0, -5);
    data[table] = read(`data/${file}`);
    run(`${table}.schema.json`, data[table]);
  }
  run('data.schema.json', data);
  const manifest = read('manifest.json');
  run('manifest.schema.json', manifest);
  const excludedMedia = new Set(manifest.scope.excluded.map(item => item.path));
  const documents = ['README.md', ...walkMarkdown(path.join(folder, 'markdown'))
    .map(file => path.relative(folder, file).split(path.sep).join('/'))];
  for (const name of documents) {
    const source = fs.readFileSync(path.join(folder, name), 'utf8');
    const tree = new commonmark.Parser().parse(source);
    const walker = tree.walker();
    let event;
    let headings = 0;
    while ((event = walker.next())) {
      if (!event.entering) continue;
      const node = event.node;
      if (node.type === 'heading' && node.level === 1) headings++;
      if (node.type !== 'link' && node.type !== 'image') continue;
      if (/^[a-z][a-z0-9+.-]*:/i.test(node.destination)) continue;
      const resolved = path.posix.normalize(path.posix.join(path.posix.dirname(name), node.destination));
      assert.ok(!excludedMedia.has(resolved), `${name}: 不可連結已排除媒體 ${resolved}`);
      assert.ok(fs.existsSync(path.join(folder, resolved)), `${name}: 找不到連結 ${resolved}`);
      if (node.type === 'image') assert.ok(node.firstChild, `${name}: 圖片缺少替代文字`);
    }
    assert.equal(headings, 1, `${name}: 必須恰有一個一級標題`);
    checks++;
  }
  const html = fs.readFileSync(path.join(folder, 'index.html'), 'utf8');
  const anchors = new Set([...html.matchAll(/id="([^"]+)"/g)].map(match => match[1]));
  for (const match of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
    const destination = match[1];
    if (/^[a-z][a-z0-9+.-]*:/i.test(destination)) continue;
    if (destination.startsWith('#')) {
      assert.ok(anchors.has(destination.slice(1)), `index.html: 找不到錨點 ${destination}`);
    } else {
      assert.ok(!excludedMedia.has(destination), `index.html: 不可連結已排除媒體 ${destination}`);
      assert.ok(fs.existsSync(path.join(folder, destination)), `index.html: 找不到檔案 ${destination}`);
    }
  }
  checks++;
  // contentSchema 為標準註解，不假設驗證器會自動解析字串內的 JSON。
  for (const rows of Object.values(data)) {
    for (const row of rows) {
      for (const field of ['time_payload', 'birth_date', 'death_date', 'start_time', 'end_time']) {
        if (row[field] != null) run('time_value.schema.json', JSON.parse(row[field]));
      }
    }
  }
  if (supplied.length) continue;
  const badRow = (table, field, value) => {
    const rows = structuredClone(data[table]);
    rows[0][field] = value;
    run(`${table}.schema.json`, rows, false);
  };
  badRow('events', 'privacy', 'unrecognized');
  badRow('events', 'event_id', 'not-a-ulid');
  badRow('events', 'created_at', '2026-10-19T12:00:00');
  badRow('events', 'title', null);
  badRow('events', 'unexpected', 'unknown column');
  badRow('events', 'sort_start', '2000-02-30');
  badRow('events', 'archive_session_id', data.archive_sessions[0].archive_session_id);
  badRow('reflections', 'archive_session_id', null);
  badRow('authors', 'is_subject_self', 'true');
  badRow('blobs', 'sha256', 'bad hash');
  badRow('blobs', 'sha256', `${'a'.repeat(64)}\n`);
  badRow('blobs', 'byte_size', -1);
  badRow('places', 'latitude', 91);
  badRow('places', 'longitude', null);
  badRow('places', 'radius_m', 0);
  const missing = structuredClone(data.events);
  delete missing[0].title;
  run('events.schema.json', missing, false);
  const purged = structuredClone(data.events);
  purged[0].purged_at = '2026-10-19T00:00:00Z';
  run('events.schema.json', purged, false);
  for (const [field, value] of [['sha256','bad'], ['byte_size',-1], ['path','../escape'],
    ['path','data/Events.json'], ['path','data/README.md'], ['path','manifest.json'],
    ['path','data/'], ['path','data/events.json\n']]) {
    const invalid = structuredClone(manifest);
    invalid.files[0][field] = value;
    run('manifest.schema.json', invalid, false);
  }
  const invalidCount = structuredClone(manifest);
  invalidCount.counts.events = -1;
  run('manifest.schema.json', invalidCount, false);
  for (const value of [
    {type:'unknown',year:2000}, {type:'half_year',year:2000,half:3},
    {type:'relative',event_id:'invalid',relation:'after'}, {type:'age_estimate',age:151},
    {type:'range',start:{type:'unknown'},end:{type:'year',year:2020}},
    {type:'day',year:1900,month:2,day:29},
    {type:'day',year:2001,month:2,day:29},
    {type:'day',year:2000,month:4,day:31},
  ]) run('time_value.schema.json', value, false);
  for (const value of [
    {type:'day',year:2000,month:2,day:29},
    {type:'day',year:2004,month:2,day:29},
    {type:'day',year:1,month:1,day:1},
    {type:'day',year:9999,month:12,day:31},
  ]) run('time_value.schema.json', value);
}
console.log(`封存 Schema／CommonMark 驗證通過：${checks} 項檢查`);

function walkMarkdown(directory) {
  return fs.readdirSync(directory, {withFileTypes: true}).flatMap(entry => {
    const file = path.join(directory, entry.name);
    return entry.isDirectory() ? walkMarkdown(file) : entry.name.endsWith('.md') ? [file] : [];
  });
}
