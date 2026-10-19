# 封存 JSON Schema 驗證

本工具使用正式 `ArchiveRepository` 輸出測試 ZIP，再以 Ajv 的 JSON Schema Draft 2020-12 驗證器離線檢查。只供開發及驗收使用，APP 不依賴 Node.js、Ajv 或網路上的 Schema 服務。

所有匯出 `.md`（含 README 與追憶分檔）另外以 `commonmark 0.31.2` JavaScript 參考實作解析，檢查單一一級標題、圖片替代文字及相對連結；HTML 入口檢查本機檔案與錨點。排除的媒體不得仍產生連結或圖片要求。CommonMark 本身允許未配對的強調符號作為普通文字，因此不把使用者合法的 `*`／`_` 字元一律視為解析錯誤；純文字跳脫及格式保留另有 Dart 核心測試。

從專案根目錄執行：

```powershell
flutter test tools/archive_schema/export_test.dart
cd tools/archive_schema
npm ci --ignore-scripts --no-audit --no-fund
npm run check
```

也可以驗證自行解壓縮的新版封存目錄：`npm run check -- D:\備份\已解壓目錄`。提供目錄時只驗證該份實際資料；省略參數才執行內建的正向及負向案例。

產物在忽略提交的 `build/archive_schema_validation/`。`full/`、`no_media/` 與 `custom/` 分別為完整、不含媒體及自訂排除部分副本的正式 ZIP 解壓驗證資料；不修改模擬器或正常 APP 資料庫。

- `schema/<資料表>.schema.json`：可直接驗證對應的 `data/<資料表>.json` 陣列。
- `schema/data.schema.json`：驗證將所有資料表 JSON 組成的物件，並以相對 `$ref` 引用各表 Schema。
- `schema/time_value.schema.json`：描述十種時間精確度；檢查日曆日期與閏年，但不將年月或年份補成精確日期。
- `schema/manifest.schema.json`：描述完整的 manifest，包括檔案清單、計數、範圍、分包資訊及典藏狀態。

驗證涵蓋正式匯出內容，以及錯誤型別、缺少／多餘欄位、無時區的時間戳記、無效 ULID／雜湊、座標範圍與成對限制、層級與典藏期間、永久刪除狀態、非法路徑和不合法時間值等負向案例。

`contentSchema` 是 JSON Schema 的內容註解，不能假設通用驗證器會自動解析字串內的 JSON。本工具會額外解析各時間欄位，再以時間值 Schema 驗證。範圍兩端先後、相對參照循環、跨資料表外鍵、同 ID／唯一值衝突、校驗雜湊與筆數一致性仍須由 APP 核心及還原流程檢查；JSON Schema 不取代這些檢查。Schema 描述的是目前匯出版本，不改變匯入端對較新次版本之已知欄位處理。

開發相依固定為 [Ajv 8.17.1](https://github.com/ajv-validator/ajv/blob/v8.17.1/package.json) 與 [ajv-formats 3.0.1](https://github.com/ajv-validator/ajv-formats/blob/v3.0.1/package.json)，兩者皆為 MIT 授權；`package-lock.json` 固定實際相依版本。

閱讀檔驗證使用 [CommonMark JavaScript 參考實作](https://github.com/commonmark/commonmark.js)，版本固定為 `0.31.2`、BSD-2-Clause 授權；同樣只供開發，不加入 APP 相依。
