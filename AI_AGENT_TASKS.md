# AI Agent 開發任務清單

本文件供 AI coding agent（如 Claude Code）依序實作「人生編年史 Life Chronicle」。每個任務都標明依據的企劃書章節、交付內容與驗收標準。

## 0. 開始之前必讀

### 0.1 權威來源

- **[人生編年史_APP_開發企劃書_v3.md](人生編年史_APP_開發企劃書_v3.md) 是唯一規格來源。** 本文件中的「§」代表企劃書章節（例如 §5.1），「驗收 #N」代表企劃書第 13 節第 N 條驗收測試。
- 實作時發現企劃書**未定義、互相矛盾或無法實作**之處：**停止並回報**，列出選項與建議，不得自行發明規則後繼續。
- 未經使用者指示，不得修改企劃書。經同意修改 `.md` 後，必須重新產生 HTML（見 0.4）。

### 0.2 不可違反的產品規則

1. **不用學就會用**（§4.3）：每個功能都必須有看得見的按鈕或選單入口；左滑、長按等手勢只能當捷徑。違反此原則的設計，不論出自哪套成熟系統，一律不採用。
2. **時間不可假造**（§5）：模糊時間不得補成某月某日顯示，也不得當成確定事實。
3. **排序只有一套標準**（§5.1）：所有排序必須呼叫同一個比較器，不得在畫面或 SQL 各自另寫排序邏輯。
4. **層級不可變更**（§9）：`layer` 只在建立時由資料存取層寫入，之後任何操作都不得修改；判定只看當下典藏狀態，絕不參考內容時間。
5. **不刪除使用者原件**（§7.2）：APP 永遠不主動刪除相簿或外部原始檔。
6. **附件共用同一套限制**（§7.1–§7.4、§8.11）：排除影片（依格式標頭與容器軌道判定），每篇附件合計不得超過 **25,000,000 bytes**，件數不限；新增、編輯、回顧、追憶、分享匯入及備份還原都不得繞過。額度依每筆引用的實際保存大小計算，實體去重不減免額度。
7. **不自動處置既有附件**（§7.1、§8.11）：超額只阻止新增，不自動刪除、壓縮或替換既有附件；封存違反影片或額度規則時拒絕整包，不靜默轉換或略過。
8. **資料不出裝置**（§2.2）：不得加入任何網路上傳、分析追蹤或雲端服務 SDK。唯一例外是地圖選點載入 OpenStreetMap 圖資（§4.1），且不得傳送任何使用者資料。

### 0.3 技術限制

- Flutter SDK **3.47.6**（Dart 3.13.5）。**未經使用者同意，不得執行 `flutter upgrade` 或 `flutter pub upgrade --major-versions`**；`drift` 與 `drift_dev` 的次版本必須一致（目前為 2.35.x）。
- 需要新套件時：先確認與目前 SDK 相容，並在回報中說明用途；不得為小功能引入大型相依。
- **授權相容**：本專案採 MIT License（見 `LICENSE`）。新增套件須為 MIT、BSD、Apache 2.0 等寬鬆授權；GPL、LGPL、AGPL 等具傳染性的授權，或授權不明的套件，須先詢問使用者。
- 首發平台為 Android；程式碼不得寫死 Android 專屬做法，平台差異集中在少數介面層（§2.4）。

### 0.4 常用指令

| 用途 | 指令 |
| --- | --- |
| 安裝相依套件 | `flutter pub get` |
| 產生 drift 程式碼 | `dart run build_runner build --delete-conflicting-outputs` |
| 程式碼檢查 | `flutter analyze` |
| 執行測試 | `flutter test` |
| 5,000 筆獨立效能測試入口建置 | `flutter build apk --debug --target-platform android-x64 -t tools/timeline_benchmark.dart`；備份後保留資料安裝，測後恢復一般入口 |
| 在模擬器執行 | `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 成功後開啟 APP；連線偵錯使用 `flutter attach -d emulator-5554` |
| 檢查 Markdown 文件 | `cd tools/plan_doc && npm install && npm run check` |
| 由企劃書 `.md` 產生 HTML | `cd tools/plan_doc && npm run build` |

### 0.5 程式碼規範

- 識別名稱（類別、函式、變數、資料表欄位）使用英文；**註解、介面文字、錯誤訊息使用繁體中文**。
- **多語系（§4.7）**：所有系統介面文字以 gen_l10n 集中管理於 `lib/l10n/`，第一階段提供繁體中文（`app_zh.arb`）與英文（`app_en.arb`）。新增任何介面文字時，**兩個 ARB 檔都必須同時加入**。**禁止在 Widget 中硬編碼任何語言的文字**（由自動化測試檢查）。
- 純 Dart 核心邏輯需要產生顯示文字時（如時間格式），透過介面注入文字來源，不得在 `lib/core/` 寫死任何語言。
- **核心邏輯寫成純 Dart**（不依賴 Flutter 與資料庫），放在 `lib/core/`，並以單元測試覆蓋。
- 資料庫一律透過 repository 存取；widget 不得直接操作 drift。
- 所有寫入都經過同一個權限檢查（§9.3），介面、匯入、批次處理不得繞過。
- 專案文件（`.md`）採 CommonMark＋GFM 表格；APP 匯出的 `.md` 採嚴格 CommonMark 0.31.2（§8.4）。CommonMark 的 `**粗體**` 緊鄰中文標點時可能失效，撰寫後執行 `npm run check` 確認。

### 0.6 Git 規範

- 遠端儲存庫：<https://github.com/bruce-yang-422/life-chronicle>，主分支 `main`。
- **commit 訊息使用繁體中文＋英文**，格式如下：

  ```text
  新增時間軸排序比較器 / Add timeline sort comparator

  - 實作 §5.1 舊到新與新到舊排序規則
  - 以兩張範例表為測試資料

  - Implement oldest-first and newest-first rules from §5.1
  - Use both example tables as test fixtures
  ```

  第一行為「中文摘要 / English summary」；內文先列中文重點，空一行後列對應的英文重點。
- **Contributors 只能有使用者本人**：commit 作者與提交者一律為 `Bruce Yang <bruce89933036@hotmail.com>`（已設定於本專案 git config）；不得加入任何共同作者署名行或「Generated with …」等字樣，讓其他人或 AI 出現在 Contributors 中。
- 一個任務一個（或少數幾個）commit，不混入無關修改；`build/`、`.dart_tool/`、`node_modules/` 等不得提交。
- 未經使用者同意，不得 push、強制推送（force push）或改寫已推送的歷史。

### 0.7 完成定義（每個任務都適用）

1. `flutter analyze` 無任何問題。
2. `flutter test` 全部通過，且新增邏輯有對應測試。
3. 任務列出的驗收標準逐條確認，涉及畫面的項目在模擬器上實際操作過。
4. 更新本文件「任務總覽」的狀態欄，並在回報中列出：完成內容、測試結果、未完成或有疑慮之處。
5. 不得以「之後再補」略過驗收項目；做不到就如實回報。

## 1. 預定專案結構

```text
lib/
├── main.dart
├── app/                 # App 外殼：主題、路由、在地化、響應式版面
├── core/                # 純 Dart 核心邏輯（不依賴 Flutter）
│   ├── ids/             # ULID 產生器
│   ├── time/            # 時間值模型、排序區間換算、排序比較器
│   └── archive/         # 封存格式：manifest、CommonMark 產生器、校驗
├── data/
│   ├── db/              # drift 資料表、索引、觸發器、遷移
│   └── repositories/    # 資料存取層與權限檢查
├── features/
│   ├── timeline/        # 時間軸首頁
│   ├── event_editor/    # 完整新增與編輯、時間選擇器
│   ├── event_detail/    # 紀事本末詳情
│   ├── attachments/     # 附件匯入與倉庫
│   ├── search/          # 簡易搜尋
│   └── backup/          # 匯出、匯入、備份紀錄
└── l10n/                # 繁體中文介面文字
test/                    # 與 lib/ 對應的測試結構
```

## 2. 任務總覽（第一階段 MVP：Android 版）

狀態：未開始／進行中／完成／受阻。依賴欄列出必須先完成的任務。

| ID | 任務 | 依賴 | 企劃書 | 狀態 |
| --- | --- | --- | --- | --- |
| T00 | 專案基礎設定 | — | §2.4、§4.4 | 完成 |
| T01 | ULID 產生器 | T00 | §8.3 | 完成 |
| T02 | 時間值模型與顯示格式 | T00 | §5、§4.6 | 完成 |
| T03 | 排序區間換算 | T02 | §5.1 步驟一 | 完成 |
| T04 | 排序比較器（雙向） | T03 | §5.1 | 完成 |
| T05 | 資料庫結構與約束 | T01、T03 | §10、§9.2 | 完成 |
| T06 | Repository 與權限檢查 | T04、T05 | §9.3、§5.1 | 完成 |
| T07 | 時間軸首頁 | T06 | §4.6 | 完成 |
| T08 | 完整新增與時間選擇器 | T06 | §4.1、§5 | 完成 |
| T09 | 紀事本末詳情與回顧 | T08 | §4.2、§5 | 完成 |
| T10 | 附件匯入、照片壓縮與額度 | T06 | §7.1–§7.6 | 進行中 |
| T11 | 簡易搜尋 | T06 | §6 | 完成 |
| T12 | 匯出 ZIP 封存 | T09、T10 | §8.1–§8.7、§8.11 | 進行中 |
| T13 | 匯入與還原 | T12 | §8.8、§8.11 | 進行中 |
| T14 | 平板版面、深色模式、無障礙 | T07、T09 | §4.3–§4.5 | 進行中 |
| T15 | 第一階段整體驗收 | 全部 | §12、§13 | 進行中 |
| T16 | 多語系架構（繁中＋英文） | T00、T02 | §4.7 | 完成 |
| T17 | 地點 GPS 錨點 | T08、T10 | §4.1 | 進行中 |
| T18 | 最近刪除 | T06、T09 | §9.3 | 進行中 |
| T19 | APP 鎖定與私密事件保護 | T00、T06 | §4.8 | 進行中 |

### 目前進度（2026-10-21）

#### 最新剩餘工作清點（接續實作時優先看本表）

依 v3 重新清點，第一階段共 **20 項任務：12 項完成、8 項進行中、0 項未開始**。T10 因新增影片排除、25 MB 額度及照片壓縮需求重新開啟。以下 8 項包含功能缺口與尚缺驗收，不能以任務數換算完成百分比。

§13 共 61 條；本階段追蹤 **56 條**（#1–#8、#11–#22、#25–#60），其中 **55 條明確納入第一階段，#56 的階段歸屬待確認**（見 §5）。#9、#10、#23、#24、#61 屬後續階段。舊版 #3、#4、#6、#7 等附件案例也已修訂，須按 v3 重新驗收；目前沒有 v3 完整逐條通過報告。

| 任務 | 剩餘內容 |
| --- | --- |
| T10 附件 | 每篇 25 MB 交易閘門、主要容器內容判定與 JPEG 動態照片靜態截取已實作，仍待裝置驗收；剩餘完整匯入預覽、照片壓縮與中繼資料、內建 PDF／錄音檢視、額度與基本空間 UI。分工與順序見 T10.1–T10.8；不能視為全部新增規格已完成。 |
| T12 匯出 | 新增 §8.11：依實際輸出範圍檢查影片、事件額度、媒體大小／雜湊與違規報告。仍須分享至外部目的地的完整落地驗證、macOS／Android 外部解壓閱讀與跨實體裝置核對。獨立分包、>4 GiB ZIP64 正式匯出／還原、Windows 獨立校驗、Android 分包選取／還原及分享面板已完成；私密／個別媒體排除維持完成。 |
| T13 還原 | 新增 §8.11：所有分包及外部旁檔校驗、媒體實際類型、引用／大小／雜湊、事件及衝突決策後額度、去重後空間＋500 MB、安全拒絕與報告；均須在寫入前通過。另有損毀包僅還原完好部分、其餘版本相容性、大型媒體裝置取消、跨實體裝置完整還原。完整分包組合還原／缺包拒絕與 Windows >4 GiB 正式還原已完成；v1→v2 主題規則遷移、同名標籤 ID 重連、較新次版本提示及共享同名衝突逐筆決策已實作，不重列為未實作。 |
| T14 版面／無障礙 | 全頁面最大字級、螢幕閱讀器與 48dp 逐項稽核、裝置旋轉／分割畫面；320dp 三倍字級裝置流程曾被模擬器繪圖崩潰中斷。iOS 視覺與縮小一階已完成。 |
| T15 整體驗收 | v3 的 55 條第一階段驗收報告及 #56 階段確認、中階 Android 實機、首次使用者不看教學、100 筆事件的完整裝置備份還原流程。資料層往返測試不能代替實機。 |
| T17 GPS | Android 成功定位／逾時／離線／EXIF／地圖拖曳操作、座標驗證與私密保護、圖資連網範圍稽核；本輪取消／重試／離頁競態與錯誤恢復已補，裝置拒絕權限提示已確認。iOS 原生實作屬後續平台工作。 |
| T18 最近刪除 | 標題快照與私密遮蔽、照片／追憶 Repository 回歸已完成；仍須裝置操作完整刪除、復原、永久刪除及參照／照片／追憶組合案例。 |
| T19 安全性 | 全內容與參照隱私／權限稽核、復原碼與遺族密碼裝置驗收；iOS Keychain／Face ID 與預覽保護屬後續平台工作。 |

本表不含已提前完成的第二階段智慧主題 T20；連同 T20 共 **21 項追蹤任務、13 項完成**。主介面五個分頁已無啟用中的「此功能開發中」佔位頁。**T10.1 主要容器（含 MPEG-PS／TS）與 T10.2 額度核心已接入附件 Repository，真實媒體已完成獨立原生比對；T10.3 逐檔預覽／額度與 T10.4 Android 照片壓縮已接入新增／編輯／詳情；照片保存偏好、GPS 移除與確認後清理中斷照片暫存已接入；去定位縮圖／比較快取與逐檔進度已接入；下一步補 T10.6 額度 UI、T10.8 空間門檻及 HEIF／舊版 Android 驗收與各入口，接著補 T12／T13 的 §8.11 驗證。** 損毀包部分還原不得繞過 v3 附件限制；T15 實機與首次使用者驗收不能由本機測試取代。

#### v3 規格切換（2026-10-20）

- 唯一規格改為 v3；README 與文件工具同步使用 v3 路徑。此次只更新文件，不宣稱已實作 v3 新增功能。
- T07／T08／T09 原本的時間軸、表單與詳情功能維持完成；新增低空間提醒、附件預覽／額度及檢視需求統一列入 T10，不遺漏於既有完成狀態。
- 以下實作紀錄保留為歷史證據，與本頁後段具日期的舊檢查點相同；**影片可匯入、僅完整複製、未設額度等舊結論已由 v3 取代**，接續工作以最新清點及 T10／T12／T13 為準。
- 舊版 373 項測試、ZIP64／分包裝置報告不代表 v3 已通過。大型 ZIP64 驗收改用多篇各自合規、合計超過 4 GB 的非影片附件；原單一超大附件或影片測資只作歷史容器測試證據，不作 v3 附件合規證據。

#### 實作與驗證紀錄（新到舊）

- **T10.5 去定位預覽快取（2026-10-21）**：原生背景管線另產生不複製 EXIF 的 JPEG／透明 PNG 衍生圖，先轉正方向及 sRGB，絕不以原件當作失敗替代。匯入縮圖長邊 80 px、時間軸／詳情縮圖最多 512 px、比較預覽最多 1600 px；這些介面已改讀衍生快取，不直接解碼原始附件作縮圖。
- **可清除、可重建**：正式快取位於 `getTemporaryDirectory()/photo_cache`，與持久附件／草稿分開，不寫入附件或 blob、不扣事件額度、不納入封存包。依實際保存內容 SHA-256＋尺寸＋版本重用，另存快取校驗；缺檔、像素／校驗損毀、含 GPS 或尺寸不符時重建。同一快取並行請求只產生一次；來源在預覽前後改變時拒絕並移除對應快取。產生中的 partial 受保護，中斷 partial 納入既有確認清理，已完成的可重建快取不混入無引用附件刪除。
- **私密保護**：時間軸／詳情在讀取縮圖前，經 Repository 驗證事件主角及私密權限，且只接受該事件已引用的附件路徑；即使快取存在也不能繞過鎖定。缺少權限或預覽失敗立即顯示替代圖示，不自動重試私密資料。可視列離開時釋放解碼圖片，磁碟快取仍可重用。
- **逐檔與整批保存**：照片檢查、壓縮及比較顯示目前檔名、已處理／總件數與剩餘件數；附件準備、草稿複製、事件保存新增 `AttachmentFileProgress`，保留原有 bytes 進度。排除檔與重複內容也正確計入處理件數，但「處理完成」不代表資料庫交易已提交。草稿最終保存若出現新排除項目即拒絕整批，不靜默漏存。取消原生工作後清理本次 partial，不改原件或既有附件。
- **原生驗證**：`tools/photo_compression/run.ps1` 的隔離合成圖片 **178 項檢查通過**（`build/photo_compression/run_4705812e/report.json`），新增預覽 80／512／1600 px 的比例與上限、八種方向、所有 GPS 標籤移除、未複製相機 EXIF、原件 GPS／雜湊不變及取消清理。完整 **452 項回歸測試通過**（`build/photo_preview_full_final.log`），靜態分析無問題，文件與差異檢查通過。其後進度對話框加入長檔名捲動，介面／語系定向 **19 項通過**；最終 Android x64 debug APK 建置成功（`build/photo_preview_build_final.log`）。無新增套件或資料庫 schema 變更；本輪不安裝模擬器 APP。
- **剩餘範圍**：T10.5 的去定位快取及逐檔進度已實作，仍須完整選檔／壓縮／取消的裝置操作驗收。T10.4 的 HEIF 真實樣本、舊版 Android 與低記憶體驗收未完成；T10.6 事件額度 UI、T10.7 內建照片／PDF／錄音檢視及完整快取管理、T10.8 的 500 MB 安全餘量與低空間提醒、T12／T13 封存政策仍待實作。

- **照片保存偏好與 GPS（2026-10-21）**：資料與備份 → 設定 → 照片保存，提供「一律預設壓縮」、預設高畫質／標準／精簡檔位及「壓縮時移除照片定位」。預設仍優先原始檔、標準壓縮、保留 GPS；偏好存於獨立持久性 JSON，以暫存寫入後替換，失敗不改已保存狀態。匯入載入偏好後套用逐張預設，仍可改為原始檔。
- **使用者同意的規格例外**：§7.3 明確補入「選擇移除定位時，即使處理結果較大也不退回原檔」，超額仍禁止保存；已同步重產 v3 HTML。原始檔模式完整保留原資料，設定頁及預覽明示差異；只影響後續匯入，不改既有附件。原生編碼僅寫入允許的一般 EXIF，移除模式不寫入任何 GPS 標籤，原件保持原樣。
- **草稿中繼資料**：`AttachmentSource` 可攜帶已擷取的拍攝時間與座標，草稿副本及 JSON 序列化保留這些欄位；重開草稿後仍能供地點建議及最終附件引用使用，不需再從已去 GPS 的照片還原定位。舊草稿未含此欄位時沿用既有讀取方式；不更改資料庫 schema。
- **中斷照片暫存**：`PhotoWorkStore` 追蹤程序內仍使用的工作目錄，程序中斷留下的專屬暫存檔列入既有附件倉庫的確認清理流程。使用中的目錄、資料庫已引用路徑、草稿引用均保留；草稿損毀時保守不清照片暫存。只處理專屬 `photo_work/import-*` 範圍，不跟隨目錄連結、不刪外部原件，拒絕釋放根目錄以外的路徑。
- **原生驗證與剩餘**：隔離合成圖片的 **119 項原生檢查通過**（`build/photo_compression/run_8f61feae/report.json`），新增全部 GPS 標籤移除、結果較大不退回原件、相機／拍攝時間保留及原件 GPS 不變案例。仍待去定位的持久預覽快取、逐檔剩餘進度、HEIF／舊版 Android／低記憶體裝置驗收，以及 T10.8 的 500 MB 安全餘量。完整 **443 項回歸測試通過**（`build/photo_preferences_full_final.log`），靜態分析無問題、文件與差異檢查通過；Android x64 debug APK 已建置（`build/photo_preferences_build_final.log`）。本輪未安裝或操作既有 APP 資料。

- **T10.4 Android 照片壓縮管線（2026-10-21）**：新增原生 `PhotoProcessor` 與獨立背景執行緒、Dart 尺寸政策及 `PhotoImportSession`。提供 4096／3072／2048 px 三檔、只縮小不放大、短邊四捨五入、降採樣解碼、EXIF 八種方向轉正與 Catmull–Rom 雙三次取樣；JPEG 品質 90／85／80／75，以 3,000,000 bytes 為目標，不為達標再降低解析度。透明 PNG／WebP 輸出 PNG；結果較大則沿用原始檔。GIF／APNG／動畫 WebP／HEIF sequence 不進入靜態壓縮。
- **T10.3 預覽串接**：每張照片顯示解析度、原始／高畫質／標準／精簡選擇、實際結果大小與 JPEG 品質；可比較原始與壓縮影像，提供全部標準壓縮及精簡按鈕。依選取順序試算剩餘額度，放不下的照片預設標準壓縮並說明。實際結果仍超額時留在預覽並停用保存；壓縮失敗不靜默改存原件，需重試、明確改原始檔或取消勾選。縮圖／比較以等比例解碼限制長邊 80／1600 px。
- **資料與取消保護**：壓縮前後重算來源大小與雜湊，驗證原生輸出的尺寸、格式、品質、實際大小與雜湊；原件改變或回傳其他路徑即拒絕。沿用來源拍攝時間／GPS 供資料庫地點建議；壓縮保留一般 EXIF 與 GPS，廣色域先轉 sRGB。預覽暫存只放在新建的專屬工作目錄，取消或草稿／事件完成複製後釋放，不刪外部原件、草稿副本或入庫 blob。
- **原生與程式驗證**：`powershell -ExecutionPolicy Bypass -File tools/photo_compression/run.ps1` 在獨立 `/data/local/tmp/life_chronicle_photos_*` 目錄產生合成圖片，不使用相簿、相機或 APP 資料；正式壓縮引擎 **82 項原生檢查通過**，涵蓋八種方向及相機／拍攝時間／GPS、透明 PNG／WebP、JPEG 品質 75 仍大於 3 MB、Display P3 轉 sRGB、原件雜湊不變、取消與既存輸出不覆寫。證據：`build/photo_compression/run_bfbc3429/report.json`。完整回歸 **432 項通過**（`build/photo_full_test.log`）；其後等比例預覽及新增 320px／兩倍字級測試的 UI／語系定向 **17 項通過**。靜態分析通過，Android x64 debug APK 建置通過。
- **剩餘範圍**：目前原生壓縮僅在 Android API 30+ 提供；舊版 Android 維持原檔匯入，仍須補相容實作／驗收。HEIC／HEIF 已有系統解碼路徑，但尚缺真實格式樣本；需補更多動畫／超大圖／低記憶體實機驗收。尚未加入「一律預設壓縮」及預設檔位設定、GPS 移除設定、去定位的持久預覽快取、程序中斷後暫存清理與逐檔剩餘進度；T10.4／T10.5 不宣稱全部完成。500 MB 安全餘量仍由 T10.8 追蹤。本輪只建置 APK，未重新安裝或變更模擬器既有 APP 資料。

- **T10.3 原始檔預覽與試算（2026-10-21）**：新增逐檔勾選、受限尺寸解碼縮圖（無法解碼時用檔案圖示）、內容判定 MIME、名稱、實際 bytes 與十進位 MB。顯示已用／待加入／保存後剩餘 25 MB 額度；涵蓋事件全部層與草稿待保存引用，同一已提交草稿引用重試不重算，相同內容的不同引用仍各自計額。新增／編輯／詳情已串接。
- **選取與保存**：單檔超額停用勾選並說明，影片及無法驗證者保留排除原因；取消勾選會重算邏輯容量及去重後實體需求，整批超額（含僅 1 byte）、無勾選或所選檔案空間不足時停用匯入。只回傳選定的有效集合，最終交易仍由 Repository 重新驗證。保留動態照片僅取靜態圖像的提示。
- **驗證與限制**：逐檔預覽 7 項測試包含 25,000,001 bytes 邊界、取消勾選、單檔排除、重複雜湊、事件＋草稿容量、320px／兩倍文字及回傳所選計畫；另新增 Repository 已提交草稿重試／跨事件引用衝突測試。照片解析度、原始／壓縮模式、品質與壓縮預估依賴 T10.4，尚未實作；500 MB 安全餘量／完整空間提示留在 T10.8。未重新安裝模擬器 APP，裝置選檔驗收仍待完成。 全套 **422 項測試通過**（`build/attachment_preview_full_final.log`），靜態分析無問題，文件檢查與 `git diff --check` 通過。

- **T10.1 MPEG-PS／TS 軌道判讀（2026-10-21）**：新增純 Dart `MpegProbe`。PS 依 MPEG-1／2 pack、PES 邊界及 PSM 走訪，檢查 PSM CRC，不在壓縮 payload 中搜尋假 start code。TS 支援 188／192（M2TS）／204 bytes 封包，先收集整份 PAT，再驗證各節目 PMT；涵蓋表格倒序、版本變更、跨封包 section、pointer、CRC、重複封包、連續號與 discontinuity。含影片 PES／軌道即排除，純音訊可保存，未知私有串流、加密或損毀內容維持無法驗證。另辨識 AVC／HEVC Annex B 與 MPEG-4 Visual 裸串流。
- **影片旗標與 MIME 分開**：`MediaProbe.containsVideo` 作為資料存取層影片判定依據；純音訊 TS／PS 仍保存標準 `video/mp2t`／`video/mpeg` 容器 MIME，不因 `video/` 前綴誤拒絕。T12／T13 後續接入政策時也必須依實際軌道旗標判斷，不能只用 MIME 字串篩選。
- **Android 真實樣本與獨立比對**：以既有 SDK 的 Java／D8 在 `/data/local/tmp/life_chronicle_media_probe_*` 獨立執行 Android 編碼器，產生純色 AVC／VP8、靜音 AAC 與 JPEG；沒有使用相簿、攝影機或麥克風。AAC／AVC 實際資料再封裝為 PS／TS。APP 共用解析器與 Android `MediaExtractor` 的 **11 份實樣結果一致**，包含改名影片、改名音訊、音訊 TS／PS 與影片 TS；JPEG 及組合動態照片的靜態長度亦通過。AVC 的 `video.ps` 在這台模擬器未產生原生 track，僅通過 APP 結構分類，不列入 11 份原生通過數。證據：`build/media_probe_native/samples/probe_report.json`、`mpeg_native.json`、`inspection.log`。
- **正式 Repository 實樣往返**：`tools/media_probe/import_test.dart` 使用獨立記憶體 SQLite 與測試目錄；14 個來源中排除 8 份影片，保存 6 筆引用／5 份實體副本（含去重與動態照片靜態結果），全部來源雜湊不變。此獨立案例已通過，不取代實際 APP 選檔／預覽操作。模擬器原有 APP 未重新安裝或存取資料；前後 `/data` 剩餘空間均約 494 MB。
- **重現工具與剩餘驗收**：`powershell -ExecutionPolicy Bypass -File tools/media_probe/run.ps1` 會建立新的工作區及裝置測試目錄，編碼／封裝／原生比對並執行獨立 Repository 案例，支援 Device／FlutterRoot／JdkRoot／SdkRoot 參數；不安裝 APK。T10.1 仍缺完整選檔 UI 與更多 HEIF／其他品牌動態照片／少見串流配置驗收。下一步為 T10.3 逐檔預覽、勾選與每篇額度試算；T10.4 壓縮、T12／T13 規格閘門仍未完成。
- **本輪回歸**：定向 38 項（包含上述獨立實樣案例）及完整 **416 項回歸測試全數通過**；最終靜態分析無問題，文件檢查通過。記錄為 `build/mpeg_probe_target_final.log`、`mpeg_probe_full_final.log`、`mpeg_probe_analyze_final.log`。Windows PowerShell 5 一鍵重現亦通過（含獨立 Repository 1 項），日誌 `build/mpeg_probe_native_reproduction.log`，最新實樣報告 `build/media_probe_native/run_090e942a/samples/probe_report.json`。

- **T10.1 內容判定與匯入閘門（2026-10-21）**：新增純 Dart `MediaProbe`，依內容解析 BMFF（MP4／MOV／M4A／3GP）、Matroska／WebM、AVI、FLV、ASF 與 Ogg 的主要軌道結構；不採信副檔名或平台 MIME。純音訊與後置影片軌分別判定，支援 BMFF 延伸長度／零長度及 Matroska 未知長度 Segment；跳過媒體 payload，以有界緩衝處理。PDF、圖像、錄音及 ZIP／OOXML 依內容記錄 MIME，Office 檔案保留可供系統開啟的類型。
- **混合批次及繞過防護**：`prepare` 逐檔排除影片或無法驗證的已知媒體容器，不影響同批合格檔案；確認框顯示繁中／英文排除原因，全部排除時停用匯入。草稿副本及最終入庫副本再次檢查內容，手製計畫不能藉錯誤 MIME 放行影片；既有去重 blob 的類型於有效新增引用的交易內更正，不改檔案內容。來源長度變動時拒絕保存，不默默截斷原始檔。
- **JPEG 動態照片**：解析外層 JPEG markers，略過 EXIF 縮圖與熵資料；辨識尾接 MP4、標準 XMP 動態宣告及 Samsung 尾段標記，僅複製靜態 JPEG。保存大小、SHA-256 及事件額度使用實際靜態結果；草稿與直接保存一致，原件不修改。確認框明示只保存靜態部分。配對選取的 Live Photo MOV 依影片規則排除。
- **驗證與未完成範圍**：自製結構測資涵蓋主要容器、改名、純音訊、混合批次、無可用檔案的雙語 UI、動態照片、手製計畫、來源變動與錯誤結構；另以虛擬 1 GiB `mdat` 驗證定位略過而非整檔載入。這些是容器解析測試，仍須可解碼的真實影音／HEIF／動態照片樣本與 Android 裝置驗收。MPEG-PS／TS 目前辨識到容器後顯示無法驗證，不猜測為純音訊；下一步補軌道解析。其他品牌動態照片尾段、較少見串流配置與舊版 Office 的精確子類 MIME 仍待補強，T10.1 維持進行中。未新增套件、改動資料庫 schema、安裝模擬器或修改使用者資料；T12／T13 尚未接入此內容政策。
- **本輪測試紀錄**：最終完整 **404 項測試通過**，靜態分析無問題，文件檢查通過。紀錄為 `build/media_probe_target_final.log`、`media_probe_core_final.log`、`media_probe_full_final.log`、`media_probe_analyze_final.log`；前兩份為定向／核心的中途檢查，最終完整結果以後兩份為準。

- **T10.2 每篇附件額度核心（2026-10-21）**：新增純 Dart `AttachmentQuota`，上限精確為 25,000,000 bytes；AttachmentRepository 依 `attachments` 關聯 `blobs.byte_size` 即時加總所有層，最終寫入交易內檢查整批新增引用，不因實體去重減免額度。新事件／事件編輯、修訂、blob 與附件引用失敗一併回復；草稿相同引用重試不重複扣額，相同 blob 的不同引用仍逐筆計算。既有超額事件可只改文字，不允許再新增空附件，也不自動處理既有檔案。針對手製計畫的重複雜湊逐筆核對實際保存大小，避免偽造大小少計額度。
- **本輪驗證範圍**：補上十進位精確邊界、整批超額總和、重複引用／跨事件去重、原始與追憶共用額度、滿額草稿重試、跨 Repository 同時新增、300 筆引用、事件編輯與修訂回復、既有超額及偽造計畫案例。新增／編輯／詳情的額度錯誤使用繁中及英文 ARB，1 byte 超額不顯示為零。完整 **386 項回歸測試通過**，靜態分析無問題，文件檢查通過；紀錄為 `build/attachment_quota_full_final.log`、`attachment_quota_analyze_final.log`。
- **尚未完成**：T10.1 影片／容器判定、T10.3 保存前逐檔預覽與試算、T10.4 照片壓縮、T10.6 額度 UI 及尚未存在的分享／回顧附件入口、T12／T13 封存寫入政策與裝置驗收。不能把本輪容量檢查當成全部 v3 附件驗收通過。未改動資料庫 schema，也未安裝到模擬器或修改使用者資料。

- **一般預覽安裝修復（2026-10-20）**：最終一般 APK 更新曾遇模擬器空間不足，Android 系統快取回收不足以解決；改建 x64 精簡 APK 後成功。Flutter 的 ABI 分包曾自動將版本碼加為 4001，已以 Gradle 明確指定 `-Psplit-per-abi=true -Pforce-version-code-ignoring-abi=true` 重建，`aapt` 核對為 1 後以保留資料的 `adb install -r -d` 恢復，已驗證裝置實際版本碼 1。僅以環境變數傳遞該 Gradle 旗標未奏效，後續精簡建置須明確傳參並核對版本碼。一般入口精簡產物為 `build/app/outputs/flutter-apk/app-x86_64-debug.apk`（約 84.3 MB），日誌為 `build/split_archive_compact_version1_build.log`；原有業務表、媒體、草稿及既有備份雜湊均一致。預覽更新先備份、只用保留資料安裝，失敗停止；曾觀察到 `flutter run` 自動重新安裝造成資料遺失，常用指令已改為安全流程。

- **T12 獨立 ZIP 分包與 T13 完整組合還原（2026-10-20）**：依 §8.5 新增每包 1 GiB／2 GiB／4,000 MiB 上限選擇，預設單一 ZIP64；媒體整檔分配，不切碎單一附件。第一包保存全部文字／JSON／Schema／完整 manifest，其餘包只含媒體及各自的 `SHA256SUMS.txt`，命名為 `_part01-of-02.zip`。每包預留文字膨脹／ZIP64 標頭／校驗清單預算，完成後再核對實際長度；首包文字或單檔太大時明示調高上限／排除附件／取消分包，失敗與取消清理整組暫存並保留前次備份。所有分包完整校驗後才發布並登錄最近備份；每包另有外部 `.sha256`，整組另附 `.parts.json`，以可攜的相對檔名記錄各包位元組大小及 SHA-256，分享時一併帶出。未新增套件或改變資料庫／封存資料表格式。
- **分包安全與介面驗證（2026-10-20）**：匯入及驗證可多選 ZIP，順序不限；檢查包名與 manifest 分配、重複／跨包衝突、媒體路徑／符號連結／壓縮方式／容量、各包 SHA 及第一包的完整檔案雜湊。僅選第一包時明示缺少包名、不寫資料；分包內自行重算 SHA 的偽造媒體仍被全包 manifest 拒絕。分享及最近備份重新載入涵蓋全部 ZIP／旁檔。最終完整 **373 項測試全數通過**、分析無問題；四種既有範圍的獨立 Schema／CommonMark／HTML 核對 **352 項通過**。日誌為 `build/split_archive_full_final.log`、`split_archive_repository.log`、`split_archive_analyze_final.log`、`split_archive_schema_validation.log`。核心配置、正式往返、缺包／重複包／偽造媒體、過小上限、取消與舊備份保留均有測試。
- **ZIP64 真實大型往返（2026-10-20）**：新增明確執行的 `tools/archive_zip64/export_test.dart`，以工作區內 **4,295,032,832 bytes（4 GiB＋64 KiB）** 的檔案經正式 Repository 匯出、重新解壓校驗、匯入與完整還原；來源／封存內／還原副本 SHA-256 一致，來源資料未變，還原完整性 `ok`、外鍵錯誤 0。大型驗收單項通過，耗時約 5 分 29 秒，與一般 373 項分開統計。Python 獨立串流核對整包 CRC 與媒體 SHA，確認 ZIP64 EOCD／locator、Store 方式及 UTF-8 旗標。證據為 `build/zip64_acceptance.log`、`build/zip64_acceptance/report.json`、`independent_report.json`；重現指令為 `flutter test tools/archive_zip64/export_test.dart --timeout 30m`。大型測試檔只在電腦的忽略目錄 build，未放入模擬器；此結果不替代中階 Android／macOS／跨實體裝置的大型驗收。
- **分包 Android 操作與資料核對（2026-10-20）**：`tools/split_archive_acceptance.dart` 使用獨立 SQLite／媒體／草稿／備份／記憶體偏好，僅驗收入口提供 512 KiB 小型上限。實際匯出 2 包（273,587／492,273 bytes），每包獨立解壓與 SHA 清單一致，合併閱讀版通過 31 項核對。裝置先驗證缺包提示，再反向多選兩包、確認還原並顯示 0 新增／0 替換／30 略過與 3 附件；後續補齊外部索引並核對各包實際大小／SHA，最終系統分享面板確認帶出 5 個檔案（2 ZIP＋2 校驗旁檔＋1 分包索引），未傳送給他人或外部服務。測試下載檔已移除，保留資料裝回一般入口，預覽停在備份範圍；20 張業務表（含修訂紀錄）、50 事件／100 段落／5 附件引用、7 份媒體及草稿完全一致，完整性 `ok`、外鍵錯誤 0。報告為 `build/split_archive_device_report.json`、`split_archive_preservation_report.json`，畫面為 `build/demo_archive_validation/split_archive_selected.png`、`split_archive_missing.png`、`split_archive_multi_select.png`、`split_archive_restore_all.png`、`split_archive_restore_report.png`、`split_archive_index_share.png`、`split_archive_normal_preview.png`。T12／T13 仍保留上表未完成驗收。

- **T12 私密事件排除（2026-10-20，使用者同意第一個方案）**：備份範圍新增可見勾選，匯出副本過濾私密事件、所有層的記述／追憶／附件引用、事件對照／篇章引用／雙向關聯及相關修訂；移除私密標題快照，保留相對參照 ID、最後排序區間、保留列的作者／層級／時間。共用副本與未引用倉庫副本保留，私密專屬 blob／媒體排除；人物／地點／標籤等獨立資料仍保留並在介面說明。來源資料不回寫；無可用參照時以「參照事件未提供」顯示，避免誤判為已刪除。企劃書 §4.1／§5.1／§8.6 與 HTML 已同步，未新增套件或修改資料庫 schema。
- **私密封存／還原驗證（2026-10-20）**：啟用排除時使用格式 1.2／schema 2，manifest 只記規則與排除總數，不列私密標題、檔名、ID 或雜湊；未啟用保持 1.1。還原預覽及報告明示刻意排除，不重建空白事件；較新次版本提示門檻更新。新增純 Dart 過濾、範圍組合、UI 專屬副本停用／共用保留、私密快照、原始／追憶內容、正式 ZIP 往返與還原預覽測試。最終完整 **366 項測試通過**、分析無問題，四種範圍的獨立 Schema／CommonMark／HTML 核對 **352 項通過**。日誌為 `build/private_export_full_final.log`、`private_export_analyze_final.log`、`private_export_schema_validation.log`，驗收／一般入口 APK 均建置成功。
- **私密排除 Android 預覽（2026-10-20）**：`tools/private_export_acceptance.dart` 使用獨立資料庫、草稿、媒體、備份與記憶體偏好。已實際勾選、確認並匯出，留下 2 一般事件／1 附件引用／2 blob（共用及倉庫），刻意排除 1 私密事件／1 專屬 blob／1 私密標題快照；整包私密測試標記缺席，裝置 ZIP 再通過 29 項獨立核對。系統檔案選取器開啟後，還原預覽明示排除筆數；未向原資料庫匯入。測後已保留資料裝回一般入口，Android Studio 預覽停在新備份範圍選項；50 事件／100 段落／5 附件引用、20 張業務表（含修訂紀錄）、7 份媒體與草稿一致，完整性 `ok`、外鍵錯誤 0。報告為 `build/private_export_device_report.json`、`private_export_preservation_report.json`；畫面為 `build/demo_archive_validation/private_export_scope_selected.png`、`private_export_restore_preview_exact.png`、`private_export_final_preview.png`。T12 其餘分包／ZIP64／分享與跨實體裝置驗收缺口仍保留。
- **T07 效能驗收完成（2026-10-20）**：先前引擎下載阻礙已解除，現有程式以獨立 5,000 筆資料庫建置 debug／profile，在 Android Studio 內嵌模擬器重新量測。從 `TimelinePage` 建立到第一批事件完成繪製（含資料庫開啟／查詢，不含首次造資料及引擎啟動），profile 三次為 **613／688／671ms**，均低於 1 秒；debug 為 890／1,309／1,280ms，不宣稱 debug 全數達標或代表中階實機效能。先前年份／排序／篩選等驗收證據保留，T07 改為完成；T15 實機效能仍待驗收。測後恢復一般入口，20 張業務表、媒體與草稿一致。報告為 `build/timeline_remeasure_report.json`，建置為 `timeline_profile_retry.log`，量測為 `timeline_profile_1.log`～`timeline_profile_3.log`；該階段完整 361 項測試通過，最終本輪回歸為上述 366 項。

- **T09 詳情與回顧完成（2026-10-20）**：書寫卡片頂部新增 48dp 可見拖曳把手，以段落編號標示操作對象，補上獨立朗讀標籤與上移／下移無障礙動作，保留既有可見排序按鈕。新增真實拖曳回歸，驗證自訂標題與正文一起移動並保存草稿；另以正式 ZIP 完整核對未命名記述直接為內文、自訂段落排序、空段落不出現在閱讀版、追加回顧不覆寫及還原後作者／層級／時間一致。最終完整 **361 項測試全數通過**，分析無問題，驗收／一般入口 APK 均建置通過；日誌為 `build/detail_full_numbered.log`、`detail_analyze_final.log`、`detail_drag_numbered.log`、`detail_roundtrip_final.log`、`detail_normal_numbered_build.log`。
- **T09 Android 驗收 #2／#30（2026-10-20）**：新增禁止 release 的 `tools/detail_acceptance.dart`，所有測試使用獨立 SQLite、草稿、媒體、備份及偏好，未向使用者資料建立事件。裝置實際閱讀一段未命名記述、以編號把手拖曳「想對你說的話」至第一段、保存後追加第二則回顧並確認第一則保留，再透過正式備份頁匯出 ZIP。裝置封存與讀取順序一致、空段落未出現在 Markdown／HTML；獨立 Schema／CommonMark／HTML 連結驗證 **29 項通過**。驗收資料為 2 事件／4 段落（含供隱藏驗證的空段落）／2 回顧，報告為 `build/detail_device_report.json`、封存解壓在 `build/detail_device_archive/`，畫面為 `build/demo_archive_validation/detail_single_device.png`、`detail_dragged.png`、`detail_reflections_device.png`、`detail_export_device.png`。已以 `lib/main.dart` 一般入口裝回正常預覽，T09 狀態改為完成；不代表 T12／T13 全部封存功能或 T15 整體驗收完成。
- **一般入口恢復與資料核對（2026-10-20）**：已裝回一般入口，Android Studio 預覽停在原本資料的新增書寫區。最初驗收前至最終恢復後，20 張使用者業務表（含原修訂紀錄）、7 份媒體雜湊及草稿完全一致，維持 50 事件／100 段落／5 附件引用，完整性 `ok`、外鍵錯誤 0，沒有向原資料庫寫入測試事件或歷史。核對為 `build/detail_preservation_report.json`，一般入口安裝日誌為 `build/detail_restore_install.log`，畫面為 `build/demo_archive_validation/detail_final_preview.png`。獨立驗收資料保留於專用 `detail_acceptance` 目錄供重現，不作為一般 APP 啟動入口。


- **書寫欄位辨識改善（2026-10-20，使用者回報）**：段落標題改為固定外部標籤，搭配獨立圓角外框及可留空的範例提示；正文使用固定「內文」標籤、六行起跳的明確輸入框與書寫提示。外框／底色／聚焦狀態自行定義，避免 iOS 分組的無框欄位主題使書寫區與說明文字混淆。格式工具列移至正文下方，Markdown 提示獨立顯示；新增、編輯及共用 Markdown 書寫／回顧入口同步套用，保留原先縮小後字級。新提示同步繁中／英文 ARB，未變更資料結構或書寫儲存方式。
- **書寫回歸（2026-10-20）**：新增操作案例驗證固定標題／內文標籤、輸入兩個欄位與預覽後草稿分開保存；窄畫面三倍字級、格式工具列、emoji、草稿恢復與段落操作相關回歸通過。最終完整 **359 項測試全數通過**，分析無問題，Android x64 debug APK 建置成功。日誌為 `build/writing_editor_tests.log`、`writing_layout_tests.log`、`writing_full.log`、`writing_analyze_final.log`、`writing_build.log`。T14 全站無障礙與 T15 整體驗收仍維持原缺口。
- **書寫裝置預覽（2026-10-20）**：完整備份後保留資料安裝 APK，Android Studio 模擬器已捲至書寫區，實際確認標題／內文框、正文聚焦藍框及鍵盤入口；預覽停在新版書寫區，未輸入或清除使用者草稿。前後 20 張業務表、7 份媒體雜湊及草稿一致，保留 50 事件／100 段落／5 附件引用，完整性 `ok`、外鍵錯誤 0。報告為 `build/writing_device_report.json`，畫面為 `build/demo_archive_validation/writing_preview_final.png`、`writing_keyboard.png`，安裝日誌為 `build/writing_install.log`。

- **T20 需求修訂：標籤智慧主題（使用者已確認）**：原本手動選事件的篇章改為「主題瀏覽」；主題保存名稱及標籤 ID 條件，可選全部符合（AND）／任一符合（OR），加上可選排除標籤。排除優先、至少一個納入標籤、同標籤不能同時納入與排除。結果隨事件／標籤／最近刪除狀態即時更新，沿用唯一時間排序器，不保存固定事件快取。私密與最近刪除事件不納入。主題設定沿用層級／典藏權限，刪除主題不修改事件或標籤。原手動篇章保留閱讀，使用者設定條件並儲存後才轉換；後文手動篇章紀錄僅為歷史。
- **智慧主題資料與封存相容**：SQLite schema 升為 v2，v1 僅新增可空的 `stories.rules_json` 欄位並保留資料與觸發器；新封存格式 1.1／schema 2，接受舊版 schema 1 篇章缺少規則欄位。規則內標籤 ID 隨同名標籤還原重連，JSON 保存條件，Markdown／HTML 保存匯出當下的符合結果與條件。主題名稱的全文搜尋亦依規則即時計算；智慧結果不修改原始層事件或其時間。企劃書 §4.2、§10 與 HTML 已依使用者確認同步。
- **智慧主題最終驗證（2026-10-20）**：最終完整 **358 項測試全數通過**、分析無問題、Android x64 debug APK 建置成功。涵蓋 AND／OR／排除優先、空條件與交錯標籤驗證、規則保存／ID 重連、事件與標籤異動的串流更新、刪除／復原、私密排除、舊版篇章轉換不改事件、典藏唯讀、英文 320dp 三倍字級與鍵盤／寬度切換、v1 SQLite 升級保留層級／作者／觸發器、v1 封存缺欄相容、v2 規則往返及同名標籤重用。獨立 Schema／CommonMark **270 項檢查通過**。日誌為 `build/themes_target_tests.log`、`themes_ui_migration_tests.log`、`themes_archive_tests.log`、`themes_full_final_pass.log`、`themes_analyze_final.log`、`themes_build.log`；`themes_target_tests.log` 為修正前的中途紀錄，最終結果以後述完整回歸為準。
- **智慧主題裝置驗收（2026-10-20）**：完整備份後以 `adb install -r` 保留資料更新 Android Studio 模擬器，確認 SQLite 已升至 v2。實際建立臨時主題、搜尋標籤、設定納入 16 歲／排除 17 歲（AND 符合 3 筆），編輯為 OR 並納入 18 歲（符合 6 筆），開啟原事件詳情並確認刪除主題。測試主題已移除，預覽停在新版「主題瀏覽」。前後 19 張非修訂紀錄業務表、7 份媒體雜湊及草稿一致，保留 50 事件／100 段落／5 附件引用；只追加本次主題建立／修改／刪除 3 筆歷史，完整性 `ok`、外鍵錯誤 0。報告為 `build/themes_device_report.json`，畫面為 `build/demo_archive_validation/themes_editor_and.png`、`themes_detail_and.png`、`themes_editor_or.png`、`themes_detail_or.png`、`themes_preview_final.png`。T20 本次修訂範圍完成；T13 其他版本／分包與 T14／T15 的整體驗收缺口仍保留。

以下為按日期累積的實作證據；較早紀錄中的測試總數與缺口保留作歷史，不覆蓋上表的最新清點。

- **故事篇章提前實作（T20，2026-10-20，使用者指定）**：原列第二階段的篇章改為優先交付，第一階段 20 項的原始統計維持不變。已接上篇章清單／空狀態、建立與改名、多選既有事件、可見的上移／下移／移出按鈕、依自訂順序閱讀及開啟原事件完整詳情、刪除確認。篇章只保存事件 ID 與順序，同一事件可屬於多篇章，移出或刪除篇章不修改事件、記述、附件或最近刪除。沿用 iOS 風格與縮小一階字級，全部新文字同步繁中／英文 ARB，未新增套件或變更資料庫 schema。
- **篇章權限與備份（2026-10-20）**：新增 Repository 使用共用建立層級與修改權限檢查；典藏中的原始篇章唯讀，家人建立的後續追憶篇章保留原作者、建立時間、層級與典藏期間。私密引用未驗證時僅顯示佔位並在開啟前驗證，新加入私密引用須有權限；既有未授權引用可保留但不揭露內容。已刪除事件在篇章標示且不可新選，永久刪除同步移除引用。篇章名稱接入既有全文搜尋；正式 ZIP 保存篇章與引用，Markdown／HTML 新增按篇章順序連結原事件的閱讀版，原始與追憶檔案分開。
- **篇章自動化回歸（2026-10-20）**：新增 13 項測試（6 項 Repository、5 項 Widget、1 項閱讀版、1 項正式 ZIP 還原），涵蓋共用／排序／刪除不改原事件、無效輸入交易回滾、私密／典藏／追憶權限、最近刪除／永久刪除、搜尋與串流更新、完整畫面操作、重新鎖定、英文 320dp 三倍字級／鍵盤及寬度切換、閱讀連結與跳脫、ZIP 還原順序不複製事件。最終完整 **350 項測試全數通過**，分析無問題，Android x64 debug APK 建置成功。日誌為 `build/stories_repository_tests.log`、`stories_integration_tests.log`、`stories_full_final.log`、`stories_analyze_final.log`、`stories_build.log`。
- **篇章裝置驗收與預覽（2026-10-20）**：完整備份私有資料後，已保留資料安裝 APK 至 Android Studio 內嵌模擬器，實際建立臨時篇章、選入兩個事件、改名／下移調序、開啟原事件詳情及確認刪除篇章，結束後移除測試篇章，預覽停在篇章分頁。UI 自動化擷取曾被系統中止（exit 137），已由原畫面接續完成，未重複建立資料。前後 19 張非修訂紀錄的業務表、7 份媒體雜湊與草稿完全一致，保留 50 筆事件、100 段落、5 個附件引用，完整性 `ok`、外鍵錯誤 0；僅追加測試篇章的建立／修改／刪除 3 筆修訂紀錄。報告為 `build/stories_device_report.json`，安裝為 `stories_install.log`，畫面為 `build/demo_archive_validation/stories_detail.png`、`stories_editor_reordered.png`、`stories_event_detail.png`、`stories_delete_confirmation.png`、`stories_preview_final.png`。T20 本次篇章交付範圍完成，不取代 T14 全站無障礙及 T15 實體裝置等整體驗收。

- **T17 定位取消與延遲回呼修正（2026-10-20）**：編輯頁使用請求編號隔離定位結果，使用者取消、改用地圖、確認捨棄草稿或頁面卸載時，先使舊請求失效再取消原生定位。平台取消失敗不阻擋文字地點或手動選點；過期成功／錯誤均不改寫草稿或結束下一筆等待狀態。Android 原生成功／逾時／監聽回呼核對原始請求身分，避免舊回呼完成新請求。未新增套件或變更資料結構／介面文字。
- **定位回歸（2026-10-20）**：新增 **9 項 Widget 測試**，涵蓋拒絕／逾時／定位關閉後可重試、取消後結果交錯、取消平台失敗、頁面卸載、地圖回傳座標不被覆寫、拒絕定位後仍可正式儲存文字地點，以及捨棄草稿不被延遲結果重建。最終完整 **337 項全數通過**，分析無問題，Android x64 debug APK 建置成功；日誌為 `build/gps_requests_tests_final.log`、`gps_requests_full_final.log`、`gps_requests_analyze_final.log`、`gps_requests_build.log`。地圖測試僅驗證選點頁回傳資料與競態，不冒稱已測圖資／釘選拖曳。
- **定位裝置預覽與資料核對（2026-10-20）**：完整備份私有資料後，以 `adb install -r` 成功更新 Android Studio 內嵌模擬器，實際點擊目前位置並拒絕權限，確認出現可繼續使用文字地點的提示。測後恢復原本未授權狀態及權限詢問旗標，預覽停在新增頁。前後 20 張業務表、7 份媒體雜湊與草稿檔案一致，維持 50 筆事件、100 段落、5 個附件引用，完整性 `ok`、外鍵錯誤 0；報告為 `build/gps_requests_device_report.json`，畫面為 `build/demo_archive_validation/gps_requests_denied.png`、`gps_requests_preview.png`。T17 其餘缺口如上表，維持「進行中」。

- **預設文字與 UI 縮小一階（2026-10-20，使用者指定）**：保留 iOS 風格，正文 16→14sp、頁面大標題 32→28sp、一般標題 17／21→15／19sp、一般圖示 22→20dp、底部分頁 64→56dp。輸入欄位與按鈕內距、分組間距、頁面內距、卡片圓角、列表與彈出視窗同步縮小；時間軸圖文列 184→160dp、精簡列 80→72dp，捲動定位仍共用既有列高換算。已很小的輔助文字保留可讀下限，互動入口至少 48dp，未限制系統字級放大。企劃書 §4.4 與 HTML 已同步；未新增套件或變更資料庫／業務資料。
- **縮小版驗證與預覽（2026-10-20）**：最終完整 **328 項測試通過**，分析無問題，x64 debug APK 建置與保留資料安裝成功；日誌為 `build/compact_ui_full_final.log`、`compact_ui_analyze.log`、`compact_ui_build.log`、`compact_ui_install.log`。Android Studio 內嵌模擬器已實際確認時間軸與新增頁，預覽停在新增頁，系統字級仍為原本 1.0。更新前完整備份私有資料，前後 20 張業務表及 7 份媒體雜湊一致，保留 50 筆事件、100 個段落及 5 個附件引用，完整性 `ok`、外鍵錯誤 0；比較為 `build/compact_ui_data_comparison.json`，畫面為 `build/demo_archive_validation/compact_ui_timeline.png`、`compact_ui_editor.png`。T14 全頁面無障礙與裝置極限設定等既有驗收缺口仍保留。

- **T14 搜尋頁大字級與鍵盤改善（2026-10-20）**：搜尋表單與結果改用同一個 `CustomScrollView`，結果以 Sliver 按需建立，避免大字級／鍵盤開啟時固定表單擠壓結果區。窄螢幕或放大字級時年份欄位上下排列，切換寬度保留輸入條件；鍵盤可直接送出搜尋，有效條件送出後收起鍵盤，拖曳亦可收起。年份錯誤提示加入即時朗讀語意；沿用現有繁中／英文文字與 iOS 樣式，未新增套件或變更資料庫／排序／搜尋規則。
- **搜尋大字級回歸（2026-10-20）**：新增 6 項 Widget 測試，涵蓋繁中／英文 320dp 三倍字級與鍵盤下搜尋後開啟詳情、年份錯誤與朗讀語意／修正、切換寬度保留條件及空結果、重新鎖定移除私密結果、60 筆結果按需建立並捲到最後一筆。完整 **328 項全數通過**、分析無問題，x64 debug APK 建置並保留資料安裝成功。日誌為 `build/search_accessibility_full.log`、`search_accessibility_analyze.log`、`search_accessibility_build.log`、`search_accessibility_install.log`。
- **搜尋裝置驗證與限制（2026-10-20）**：Android Studio 內嵌 `Medium_Phone` 已以兩倍字級實際輸入 `demo-16`、送出搜尋、核對僅顯示對應 16 歲紀錄並開啟詳情；完成後恢復原本字級 1.0、1080×2400 解析度與一般空白條件搜尋預覽。320dp／三倍字級的裝置驗證途中模擬器發生 `bad color buffer handle` 並退出，已保留資料以軟體繪圖冷啟動恢復，該極限設定的裝置全流程仍未完成，不以自動化通過取代裝置驗收。裝置報告為 `build/search_accessibility_device_report.json`，畫面位於 `build/demo_archive_validation/search_large_font_*.png` 與 `search_accessibility_preview_final.png`。操作前完整備份 APP 私有目錄；結束後 20 張業務表與 7 份媒體雜湊完全一致，維持 50 筆事件、100 個段落、5 個附件引用，完整性 `ok`、外鍵錯誤 0，見 `build/search_accessibility_data_comparison.json`。T14 維持「進行中」，全頁面朗讀／48dp 與旋轉／分割畫面稽核仍待完成。

- **T14 全站 iOS 視覺重設（2026-10-20，使用者指定）**：集中更新系統藍、灰白分組／純黑深色背景、大標題、無陰影圓角卡片、細分隔線、輸入欄位、操作按鈕、底部分頁、彈出視窗與 Cupertino 導覽轉場；安全性開關採自適應 Cupertino 風格。新增／編輯頁分成事件資訊、地點、人物與標籤、隱私與關聯、記述與附件；文字工具列改為獨立底色區塊。搜尋使用分組結果與分隔線，備份與設定採分組清單，詳情統一標題與閱讀字級。群組欄位移除獨立外框，避免浮動標籤被圓角裁切。繁中／英文分組標題同步 ARB；企劃書 §4.4 與 HTML 已同步。未新增套件或變更資料庫結構。
- **iOS 視覺重設驗證（2026-10-20）**：完整回歸 **322 項全數通過**；搜尋／備份排版微調後 7 項、最終分組欄位微調後 10 項相關回歸通過，最終分析無問題。新增 320dp／三倍字級表單捲至儲存且保留草稿案例，既有普通字級工具列同排、深色大字級首頁、平板寬度切換保留選取與草稿案例通過。日誌為 `build/ios_redesign_full.log`、`ios_redesign_polish_tests.log`、`ios_redesign_group_final_tests.log`、`ios_redesign_analyze.log`、`ios_redesign_build_final.log`。T14 維持「進行中」：全頁面螢幕閱讀器、48dp 逐項稽核與裝置旋轉／分割畫面驗收尚未完成。
- **iOS 視覺重設裝置預覽（2026-10-20）**：最終 x64 APK 已保留資料安裝，套件首次安裝時間不變；Android Studio 內嵌 `Medium_Phone` 已顯示新版繁中介面，停在新增頁。實際開啟時間軸、搜尋、備份、時區設定、事件詳情，並確認新增頁淺色／深色切換，結束恢復原本淺色設定。部署前完整備份 APP 私有目錄，原有 20 張業務表與 7 份媒體雜湊完全一致，維持 50 筆事件、100 個段落與 5 個附件引用，完整性 `ok`、外鍵錯誤 0。比較為 `build/ios_redesign_data_comparison.json`，完整備份位於 `build/demo_archive_validation/ios_redesign_before_20261020_154006/private_data.tar`，安裝日誌為 `build/ios_redesign_install.log`；畫面在同目錄 `ios_*.png`（最終新增頁為 `ios_editor_final.png`）。未解除安裝或清除業務資料。

- **預覽面板與繁中語言（2026-10-20）**：Android Studio 的 Running Devices 已展開 `Medium Phone API 36.0`，使用者確認看到 APP。因模擬器語言為英文，已透過 Android 原生每個 APP 語言設定，將本 APP 預覽指定為 `zh-Hant-TW`；實際確認時間軸與導覽文字已切回繁中。未改動 APP 的語言跟隨系統規則或業務資料。操作面板時誤貼到 `main.dart` 的文字已復原，檔案與原版本一致。畫面為 `build/demo_archive_validation/preview_traditional_chinese.png`。

- **T18 相對參照標題快照（2026-10-20，使用者已確認）**：沒有追憶附掛的原事件永久刪除前，於同一交易將原標題與私密標記存入直接參照者的 `time_payload.deleted_reference`，不改參照者的層級、作者、修改時間或最後排序區間，包含後續追憶層參照者。時間軸、搜尋、詳情及編輯預覽在原事件不存在時使用快照；私密快照未驗證時遮蔽，重新鎖定立即隱藏。原事件仍存在時優先讀取原事件；時間選擇器保留同一參照的快照，重新指定時移除舊快照。舊格式無快照時不推測標題。JSON／ZIP 還原保留快照，Markdown／HTML 標示原標題與已刪除；時間值 Schema 同步。企劃書 §5.1 與 HTML 已更新，未新增套件或更動資料庫 schema v1。
- **T18／T19 刪除確認視窗保護（2026-10-20）**：私密事件永久刪除確認視窗監聽安全性狀態，重新鎖定後遮蔽標題並停用確認，提交前再次檢查私密權限。新增回歸涵蓋鎖定後無法提交、普通／私密刪除參照顯示、解鎖及重新鎖定、快照 JSON 相容性、原始／追憶參照者資訊不變、時間選擇器與跨資料庫 ZIP 還原。完整 **321 項測試通過**、分析無問題、Schema／CommonMark／HTML **264 項檢查通過**，x64 debug APK 建置通過；日誌為 `build/recycle_snapshot_full.log`、`recycle_snapshot_analyze.log`、`recycle_snapshot_schema_export.log`、`recycle_snapshot_schema_check.log`、`recycle_snapshot_build.log`。
- **Android Studio 預覽與資料復原（2026-10-20）**：既有 `Medium_Phone` 啟動崩潰後，以軟體繪圖冷啟動恢復；內嵌面板須從 View → Tool Windows → Running Devices 開啟。模擬器 `/data` 設為 6 GB，更新 APK 曾因空間不足失敗；備份並移除三個可重建 Flutter 偵錯檔（約 103 MB）後，`adb install -r` 成功，詳見 `build/recycle_snapshot_install_final.log`。使用者執行 `flutter run` 的時段發生套件重新安裝（首次安裝時間重設），畫面核對發現資料空白；已由操作前 `build/demo_archive_validation/recycle_final_before_20261020_151043/files.tar` 回復紀錄與媒體。復原後 20 張業務表與 7 份媒體雜湊完全一致，維持 50 筆事件、100 個段落、5 個附件引用，完整性 `ok`、外鍵錯誤 0；比對為 `build/recycle_restore_comparison.json`。一般入口新版已開啟，僅連線偵錯可用 `flutter attach -d emulator-5554`。未解除安裝其他 APP。最近刪除入口與一般畫面已操作，新的私密／快照案例由自動化測試驗證，尚未在裝置建立對應案例；T18／T19 維持「進行中」，不視為全項裝置驗收。

- **模擬器清理與持久安裝（2026-10-19 最新）**：先完整備份 APP 私有資料，再回收 Android 快取、移除已備份的舊測試暫存（約 5 MB）與可重建 Flutter 偵錯快照／kernel（約 103 MB）；未清除 APP 資料、照片、正式備份或解除安裝。可用空間由約 390 MB 增至清理後 591 MB，保留資料安裝最新 x64 debug APK **成功**，安裝後剩約 590 MB。重開 APP 已確認個別影音副本選擇功能存在，不再依賴熱更新。前後 20 張業務表與全部媒體雜湊一致，維持 50 筆事件、100 個段落、5 個附件引用與 7 個 blob，完整性 `ok`、外鍵錯誤 0。先前「新版 APK 持久安裝受容量限制」已解除。備份與比對位於 `build/restore_device_validation/cleanup_before/`、`cleanup_after/`，舊測試暫存另備份至 `build/emulator_cleanup/`；安裝日誌為 `build/archive_cleanup_install.log`。

- **T12 個別影音副本排除（2026-10-19 最新）**：「資料與備份 → 匯出 ZIP」可逐一選擇要包含的影音副本，共用同一 blob 的附件合列並顯示名稱、大小與引用數；有附件引用的副本優先列出。畫面明示只排除檔案副本，附件名稱等紀錄資料仍保留。範圍選擇與容量確認皆可取消；重新鎖定立即遮蔽選項名稱並停用提交。匯出計畫僅計入已選副本容量，使用 `scope.type = custom`／`reason = user_excluded`，並以 `_custom.zip` 命名；JSON Schema 已納入規格原有的 `custom` 值。manifest、檔案清單、SHA-256、Markdown／HTML 排除說明及還原的 `excluded` 狀態保持一致。未知副本選擇拒絕寫入；明確排除已遺失的副本仍可匯出其餘資料。私密權限在列出選項與封存器讀取計畫時均檢查。
- **T12 個別排除驗證（2026-10-19 最新）**：新增 2 項純 Dart 核心測試、3 項 Repository 測試及 7 項 Widget 測試，涵蓋共用副本、原件／資料不變、跨資料庫還原、未知／遺失副本、私密權限、完整畫面匯出／取消、英文、大字級與重新鎖定。完整回歸 **313 項全數通過**，`flutter analyze` 無問題，x64 debug APK 建置通過。獨立驗證工具現在正式匯出完整／不含媒體／自訂三種樣本，Schema／CommonMark／HTML 共 **252 項檢查通過**。未新增 APP 套件或變更資料庫 schema v1。
- **T12 個別排除裝置驗收（2026-10-19 最新）**：在既有 Android Studio 內嵌 `Medium_Phone` 實際取消學生證模擬圖副本，確認範圍／排除數與容量後完成自訂 ZIP；讀回封存，獨立 Schema／閱讀連結驗證 **125 項通過**。前後 20 張業務表與全部媒體雜湊一致，保留 50 筆事件、100 個段落、5 個附件引用、7 個 blob，完整性 `ok`、外鍵錯誤 0。裝置快照為 `build/restore_device_validation/custom_before_live/`、`custom_after_live/`；封存與畫面位於 `build/archive_reading_device/*_custom/`、`build/archive_custom_device_scope.png`。程式已以 attach／hot restart 同步；保留資料安裝 APK 仍遭 Android 回報空間不足，沒有解除安裝或清除 APP 資料，故持久安裝尚未完成。本輪不包含私密事件整筆排除、分包、ZIP64 大型資料與分享驗收；T12 維持「進行中」。日誌為 `build/archive_custom_full.log`、`archive_custom_analyze.log`、`archive_custom_build.log`、`archive_custom_install.log`。

- **T12 離線閱讀版補齊（2026-10-19 最新）**：Markdown／HTML 補上地點名稱、座標與半徑、參與人物、標籤、明確連結的人生階段、隱私標示、關聯事件與已刪除參照、段落作者／時間及附件原名／拍攝／匯入資訊。後續追憶事件與附掛段落／回顧／附件另存 `markdown/remembrance/`，保留作者、記錄時間與原事件往返連結；HTML 亦提供對應錨點。不含媒體時改顯示排除說明，不再產生指向不存在副本的圖片或連結。6 項核心測試涵蓋內容、跳脫、段落順序、追憶分檔、相對路徑、排除媒體與非法媒體路徑。完整回歸 295 項通過、分析無問題、版本碼 1 的 x64 debug APK 建置通過。開發工具加入 BSD-2-Clause 的 CommonMark JavaScript 參考實作（固定 0.31.2，僅開發相依），與獨立 JSON Schema 驗證合計 168 項檢查通過。
- **T12 實際閱讀包驗證（2026-10-19 最新）**：透過既有 Android Studio 內嵌 `Medium_Phone` 的 APP 介面，分別匯出完整與不含媒體 ZIP；每份均經獨立 Schema／CommonMark／HTML 本機連結驗證 125 項通過。維持 50 筆事件、100 個段落、5 個附件引用與 7 個 blob；前後 20 張業務表內容及全部媒體雜湊一致，完整性 `ok`、外鍵錯誤 0。裝置樣本沒有追憶，追憶分檔由核心及正式匯出測試涵蓋。本輪以 attach／hot restart 同步 Dart 實作；先前 APK 安裝受可用空間限制，尚未完成持久安裝，重新啟動 APP 後仍需安裝新版 APK。產物位於忽略提交的 `build/archive_reading_device/` 與 `build/restore_device_validation/reading_after_live/`。T12 尚待自訂排除範圍、分包、ZIP64 與裝置分享等驗收。
- **T13 同名共享參考資料規則（2026-10-19 使用者已確認）**：不同 ID 的同名地點／人物／標籤保留本機 ID，逐筆選擇保留本機或採用封存內容，不預選；即使其他內容相同仍需確認。匯入事件的地點、人物與標籤引用改連到本機 ID，原始修訂紀錄不重寫。名稱比對沿用既有唯一值（地點／人物 `name_key`、標籤 `label`），純座標地點不因名稱皆為空而合併。企劃書 §8.8 與 HTML 已同步；資料層與繁中／英文差異介面已接上，驗證結果見後續更新。
- **T13 同名合併驗證（2026-10-19 最新）**：新增 5 項 Repository 測試與 1 項 Widget 測試，涵蓋保留本機／採用封存、台／臺及全半形人物名稱、內容相同仍需決策、重複匯入、混合選擇、新事件引用、未完成選擇拒絕寫入、晚期失敗完整復原與暫存清理。ID 與名稱分別指向不同本機項目，或多筆封存資料映射到同一目標時，拒絕推測而回報受影響資料檔；此類交錯身分未實作自動合併。完整回歸 **301 項通過**，`flutter analyze` 無問題，最終 x64 debug APK 建置通過；畫面最後補上內容相同時的名稱顯示。日誌為 `build/archive_reference_full.log`、`build/archive_reference_analyze.log`、`build/archive_reference_build.log`。未變更正式 APP 相依或 schema v1；T13 尚有下列損毀包、相容性與實體裝置驗收缺口。

- **T12 JSON Schema 補齊（2026-10-19 最新）**：以純 Dart `ArchiveSchema` 產生目前格式的 23 份 Schema：20 張業務表各自對應 `data/<表名>.json`、集合入口 `data.schema.json`、十種時間值與完整 manifest。補上必填／可空型別、ULID／SHA-256、含時區時間戳記、日曆日期／閏年、座標成對與範圍、層級與典藏期間、永久刪除狀態、路徑、計數與分包資訊的結構約束。時間欄位的 `contentSchema` 是內容註解，外部工具另行解析字串再驗證；外鍵、參照循環、範圍先後、雜湊與筆數一致性仍由 APP 核心／還原流程檢查，不以 Schema 冒充完整語意驗證。
- **T12 獨立驗證（2026-10-19 最新）**：新增 `tools/archive_schema/`，以正式封存器建立含十種精確度、追憶與完整／排除媒體的測試包，再以 Ajv Draft 2020-12 離線驗證。新增開發工具相依 `ajv 8.17.1`、`ajv-formats 3.0.1`（MIT，鎖定檔固定版本，僅供開發，不加入 APP）；用法與限制見該目錄 README。140 項正向／負向檢查、工具匯出測試及 289 項完整 Flutter 測試通過，`flutter analyze` 無問題。日誌為 `build/archive_schema_reference.log`、`archive_schema_export.log`、`archive_schema_full_tests.log`、`archive_schema_analyze.log`；未新增 Flutter 套件或變更 schema v1。
- **T12 裝置實際匯出與安裝限制（2026-10-19 最新）**：既有 Android Studio 內嵌 `Medium_Phone` 已透過正式介面匯出含 23 份 Schema 的完整 ZIP，50 筆事件、100 個段落、5 個附件引用、7 個 blob 與 3,318 筆修訂紀錄的實際資料通過 72 項獨立檢查。ZIP SHA-256 與備份紀錄相符，匯出前後資料及媒體雜湊一致，完整性 `ok`、外鍵錯誤 0。產物與比較在 `build/archive_schema_device/`，日誌為 `build/archive_schema_device_validation.log`。版本碼 1 APK 建置成功（`build/archive_schema_build.log`），但模擬器約剩 414 MB，`adb install -r` 及系統快取回收後重試均因空間不足失敗；未解除安裝或刪除使用者資料。本次裝置驗證以 `flutter attach`＋hot restart 載入新的純 Dart 邏輯，結束連線後 APP 保持運作；這不是持久 APK 更新，結束／重啟 APP 後仍須安裝新版 APK 才會保留本輪變更。T12 維持「進行中」，完整閱讀版、分包、ZIP64、分享等驗收缺口仍未完成。

- **T13 正式匯入流程（2026-10-19 最新）**：「資料與備份 → 匯入與還原 ZIP」已接上原生檔案選取、驗證預覽、各類筆數、同 ID 的欄位差異與逐筆選擇、最後確認及核對報告。衝突不預選，未選完不能還原；報告包含新增／替換／略過、各類新增筆數、還原後附件數與可用媒體副本總容量（去重計算）、排除項目及額外檔案。預覽後資料變更會拒絕寫入並要求重新核對；取消與離頁清理暫存，重新鎖定立即遮蔽差異。跨主角成功還原後重新載入主角與 Repository 環境；繁中／英文文字均透過 ARB。
- **T13 核心補強與回歸（2026-10-19 最新）**：覆蓋權限在任何典藏設定寫入前以共同權限規則檢查，避免先匯入一般模式後繞過原始層唯讀限制；層級仍不可變。媒體複製與雜湊檢查改為可逐段取消，補上複製中途取消與晚期失敗回復、重複匯入略過筆數（含修訂紀錄）、共用副本容量統計測試。9 項匯入 Widget 測試涵蓋採用備份、保留本機、取消確認／選檔、預覽後變更、重新鎖定、大字級、英文損毀檔提示及排除項目。完整 `flutter test` 288 項通過，`flutter analyze` 無問題；日誌為 `build/restore_full_tests.log`、`build/restore_analyze.log`。
- **T13 模擬器驗證（2026-10-19 最新）**：已先備份 `Medium_Phone`／Android 16 API 36 的 APP 私有資料，再以版本碼 1 的 x64 APK 保留資料安裝。首次安裝空間不足，Android 系統快取回收後重試成功，未解除安裝或清除 APP 資料。實際操作原生 Downloads ZIP 選取、50 筆預覽、標題差異、未選時停用／選後啟用還原、最後確認取消及離頁；未在裝置執行覆蓋還原。前後 20 張業務表內容及所有媒體雜湊完全一致，維持 50 筆事件、100 個段落、5 個附件引用與 7 個 blob，完整性 `ok`、外鍵錯誤 0。最終修正版已安裝並重新啟動；備份、比較、截圖與 UI 證據位於 `build/restore_device_validation/`，建置日誌為 `build/restore_ui_build_final.log`。測試 ZIP 與 UI 暫存檔已自裝置清理。
- **T13 尚未完成（依最新實作更新）**：損毀包僅還原完好部分的選擇、舊版本／分包相容性、真正大型媒體的裝置取消與完整跨實體裝置還原驗收。不同 ID 的同名共享參考資料已支援逐筆決策與重用本機 ID；交錯 ID／名稱身分目前拒絕推測。不能把一般還原流程完成視為 T13 全項驗收。T12 的自訂排除範圍／分包／ZIP64／裝置分享與 T15 實機及首次使用者驗收仍未完成，任務總覽狀態仍為「進行中」。

- **T12／T13 已確認規則實作（2026-10-19）**：使用者已決定保留根目錄 `README.md`／`SHA256SUMS.txt` 為大小寫例外，並限制跨主角僅能還原到空白資料庫。路徑與校驗清單使用核心固定規則，呼叫端不再自行指定大小寫例外。新增純 Dart 主角政策，預覽與寫入交易均強制檢查；僅能取代未填寫的自動初始資料，不覆蓋已有姓名／生日、作者、事件（含最近刪除）或參考資料。交易晚期失敗會復原原主角／作者並清理本次副本及暫存區。企劃書 §8.3、§8.8 與 HTML 已同步，兩項決策已從待決策表移除。
- **封存政策驗證（2026-10-19）**：完整回歸 277 項通過，`flutter analyze` 無問題；補強晚期失敗副本清理後，封存核心／Repository／既有 demo 建包還原工具共 16 項測試通過。日誌為 `build/archive_policy_full_tests.log`、`build/archive_policy_analyze.log`、`build/archive_policy_target_tests.log`。demo 工具測試產生的資料包已回復原版本，未變更裝置資料、套件或 schema v1。T12／T13 維持「進行中」：正式檔案選取、逐筆衝突決策及核對報告介面、共享參考資料衝突處理、完整閱讀版／Schema／分包與裝置驗收仍待完成。

- **T18／T19 最近刪除私密保護（2026-10-19）**：修正未驗證時清單直接顯示私密事件標題的缺口，改為「私密事件」並提供可見驗證入口；查看前需驗證，復原／永久刪除入口於驗證後才顯示。取消驗證不開啟詳情，重新鎖定立即遮蔽；未獲私密權限的遺族不能查看或修改。沿用既有 ARB 與安全性服務，未新增套件或變更 schema v1。新增 6 項 Widget 測試，涵蓋取消、原生驗證、重新鎖定、遺族限制、復原、永久刪除確認及 320dp／三倍字級版面。
- **T18 追憶照片整合回歸（2026-10-19）**：新增附件資料層測試，涵蓋原始附件與追憶照片共同附掛、軟刪除後時間軸隱藏且附件可開啟、復原後兩份附件皆保留、永久刪除保留標題與追憶附件、來源移除後副本仍可開啟，以及清理無引用副本不刪除追憶附件或外部原件。此測試以媒體位元組 fixture 驗證保存與檔案開啟介面，不代表真實圖片解碼或裝置檢視器驗收。
- **本輪驗證與缺口（2026-10-19）**：`flutter analyze` 無問題，`flutter test` 共 267 項全部通過；日誌為 `build/recently_deleted_analyze.log`、`build/recently_deleted_full_tests.log`。目前 `adb devices` 沒有連線裝置，本輪尚未在模擬器／實機操作新介面，未建置或安裝 APK。T18／T19 狀態維持「進行中」；相對參照永久刪除後的原標題保存、完整隱私稽核及裝置驗收仍待完成。T12／T13 的控制檔大小寫與跨主角還原限制已再次列出選項，尚待使用者確認，本輪未自行決定或修改企劃書。

- **首頁工具列間距修正**：移除 `Wrap.spacing` 與額外空白元件重複計入的間距；一般手機字級的年份、排序、篩選與顯示模式恢復同一排，大字級仍允許必要換行。相關手機／平板／大字級 11 項測試通過，靜態檢查無問題，版本碼 1 的修正版 APK 已保留資料安裝；日誌為 `build/demo_archive_validation/timeline_toolbar_layout_tests.log` 與 `timeline_toolbar_layout_analyze.log`。

- **已完成 11 項**：T00–T06、T08、T10、T11、T16；T07、T09、T12–T15、T17–T19 進行中。T15 已開始整理驗收狀態，尚未完成整體驗收。最新完整回歸為 260 項測試全部通過，`flutter analyze` 無問題；另有模擬 ZIP 建立／還原工具測試通過。T09 的驗收 #30 仍待 T12 的完整 Markdown 匯出驗證；自動化通過不取代尚缺的實機及首次使用者驗收。
- **卡片距今時間（2026-10-14）**：精簡清單與圖文卡片均顯示距今時間，以事件發生日期計算完整日／月／年，支援今天及未來。年月／年份加「約」，季度、半年與範圍使用約略上下界；未知、相對事件與年齡推估不以排序日期假造精確時間。依設定的時區判定今天，每分鐘檢查跨日及返回 APP 時更新。核心涵蓋閏日、月末、區間、未來與雙語單複數；兩種模式及大字級測試通過。260 項完整回歸、靜態檢查與版本碼 1 APK 建置通過，已保留資料安裝並在模擬器確認距今標籤。日誌為 `elapsed_full_tests.log`、`elapsed_analyze.log`、`elapsed_boundaries_tests.log`、`elapsed_build.log`，畫面為 `elapsed_cards.png` 及 `elapsed_compact.png`，均位於 `build/demo_archive_validation/`。
- **完整新增與編輯（2026-10-14 最新調整）**：依使用者要求移除「進階編輯」切換，新增與編輯直接顯示全部欄位、Markdown 記述、自訂段落及排序；選填欄位可留空，草稿與原有段落保留。最新完整回歸為 260 項通過，靜態檢查無問題；一般入口版本碼 1 APK 已保留資料安裝，模擬器已確認新增頁直接呈現地點、人物、隱私與關聯事件。詳見 T08 與 `build/demo_archive_validation/full_editor_tests_final.log`、`full_editor_analyze.log`、`full_editor_build.log`、`full_editor_form.png`。
- **已在模擬器操作的畫面**：時間軸、完整新增與編輯、十種精確度的時間選擇器、紀事本末詳情、段落編輯／排序、追加回顧、批次附件匯入／開啟、附件倉庫與待清理清單、FTS5 搜尋及年份區間。故事篇章仍為佔位。本輪新版 Android APK 已建置並保留資料安裝，已核對擬真資料的時間軸縮圖、詳情、圖片開啟與搜尋首次顯示；備份匯出／校驗／分享、最近刪除、安全性設定及地圖選點的完整裝置驗收仍待完成，正式匯入還原介面仍未完成。
- **已確認人生階段規則**：使用者於 2026-10-12 選擇「明確連結，篩選只看連結」。已同步更新企劃書及 HTML，新增 `event_life_periods`、Repository 權限與修訂紀錄；未上架期間資料庫維持 `schema_version = 1`，直接更新初始結構。T12／T13 須包含這份關聯資料。
- **資料庫命名與版本**：14 張單欄主鍵資料表已改用單數實體名稱加 `_id`（如 `event_id`、`subject_id`），外鍵、SQL 查詢與觸發器同步修改。Drift 的 Dart `id` 屬性透過 `.named()` 映射到實際 SQL 欄位。依使用者指示，未上架期間統一維持 `schema_version = 1`，直接更新初始結構，不保留歷史版本遷移。
- **資料庫文件與工具**：已建立 `docs/database/life_chronicle.dbml` 與 `docs/database/life_chronicle.sql`，由實際 APP 結構匯出，包含 20 張業務資料表及 1 張 FTS5 虛擬表、43 個外鍵。執行 `flutter test tools/db_schema/export_test.dart` 重新產生文件並驗證空白 SQLite 重建；`node tools/db_schema/validate.cjs` 使用本機開發用的官方 DBML 解析器驗證。兩項驗證均通過；DBML 可貼到 dbdiagram.io，SQL 用於建立空白資料庫。
- **Android demo（2026-10-12 歷史紀錄）**：`Medium_Phone`／`emulator-5554`、Android 16 API 36；當時已追加 5,000 筆英文及 1,000 筆繁中假資料，沒有清除既有資料。2026-10-14 IDE 一般版本碼 1 遇到先前分架構 APK 的版本碼 4001，Flutter 自動解除安裝後資料歸零；舊 6,000 筆仍有本機備份，尚未自行還原。目前有本輪操作建立的 2 筆測試事件、2 個 blob、3 個附件引用；APP 的 Android 語言偏好已重新設為 `zh-Hant-TW`。
- **開發資料庫套用與備份**：模擬器已套用具名主鍵的 schema v1 並安裝新版 debug APK，繁中時間軸與篩選操作通過。套用前後完整紀錄比對一致，6,000 筆測試事件及其他紀錄保留；完整性與外鍵檢查通過。套用前的本機備份存於忽略提交的 `build/database_backup_before_pk_rename/`。
- **已提交並推送的實作**：上述程式、測試、資料庫文件及企劃書同步變更，已於 2026-10-12 以中英文 commit `94f8051` 推送至 `origin/main`，共 38 個檔案；作者與提交者均為 Bruce Yang。
- **本次實作（2026-10-14）**：精簡模式不查詢或監聽記述／附件／blob 預覽；切換圖文卡片才載入，並持續監聽更新。年份與年外參照鏈沒有年齡推估時不查詢生日；所有排序仍使用唯一比較器。新增獨立 5,000 筆效能測試入口，不修改正常資料庫或持久性偏好；本次未新增套件或修改資料庫結構。
- **接續實作 T08～T11（2026-10-14）**：新增草稿持久保存、事件與段落／關聯交易、只追加回顧、整批附件驗證與保存、容量確認／取消／中斷清理、中文部分搜尋。沒有新增套件、沒有變更 schema v1；平台差異集中於附件介面，Android 已操作驗證，iOS 尚未在 macOS／裝置建置驗證。建置模擬器 APK 使用 `flutter build apk --debug --target-platform android-x64`，不加 `--split-per-abi`，版本碼維持 1，安裝只用 `adb install -r`，失敗時不自動解除安裝。
- **T12～T19 本輪實作**：已加入封存／還原核心、響應式主從版面、最近刪除、密碼與安全儲存、GPS 平台介面及地圖選點。新增 `local_auth`、`flutter_secure_storage`、`flutter_map`、`latlong2`，以及本地化原生驗證提示用的 `local_auth_android`／`local_auth_darwin`；用途分別為原生解鎖、安全儲存、OSM 圖資及座標處理。Flutter SDK 與資料庫 schema v1 未升級。上述功能與距今時間已於 cee0dfd 提交並推送至 origin/main；其後的完整編輯表單與本次文件更新尚未提交。詳細實作與缺口見下方驗收檢查點。
- **擬真 demo（2026-10-14 最新裝置狀態）**：使用者確認模擬器的 1,002 筆事件均無效並授權刪除。先備份資料庫、附件與持久性檔案，再透過正式 Repository 刪除及 ZIP 還原核心，以交易取代成 50 筆創作紀錄、100 個敘述段落及 5 個 JPG 附件。涵蓋虛構角色林沐辰 16～35 歲、2006～2025 年；16～25 歲每年 3 筆、26～35 歲每年 2 筆。主角姓名／生日／作者／典藏設定原樣保留。既有 2 個無引用倉庫副本未清理，不屬於新 ZIP 的 5 份附件。
- **下一步**：接續共享參考資料衝突、損毀包的完好部分還原與版本／分包相容性，再逐條執行完整裝置驗收；正式檔案選取、逐筆衝突與核對報告已於 2026-10-19 接上。一般入口 APK 已恢復，不會在平常啟動時執行 demo 匯入工具。T07 的 5,000 筆首頁 1 秒目標仍未達標：先前 debug 三次為 2,602／2,028／1,692 ms，profile 建置受引擎套件下載失敗阻擋，本輪未重測。T09 驗收 #30、T12／T13 完整封存功能及 T15 實機／首次使用者測試均未完成。
- **Markdown、手機 emoji 與時區（2026-10-14 最新追加）**：記述及追加回顧已支援原文編輯／預覽、粗體／斜體按鈕、表格插入、CommonMark 格式與表格渲染；寬表格可水平捲動。Emoji 使用手機鍵盤，包含膚色與家庭組合 emoji，原文保存、預覽及資料回讀測試通過，沒有 APP 自訂 emoji 選擇器。Markdown 圖片不自動載入、連結點擊複製，照片由附件管理。封存 HTML 保留表格，嚴格 CommonMark 的 `.md` 轉為逐列分組清單，JSON 保留完整原文。
- **可讀時間與設定入口**：建立、回顧、附件及最近刪除的時間已改為一般在地化日期與時分，不顯示 ISO 分隔符、秒或毫秒。「資料與備份 → 設定 → 時間顯示與時區」可跟隨手機或指定常用城市，包含夏令時間並持久保存；事件日期／模糊時間與 UTC 儲存值不變。封存閱讀版本使用匯出時所選時區，JSON 仍保留 UTC。新增 `flutter_markdown_plus 1.0.12`、`markdown 7.3.1` 與 `timezone 0.11.2`，用途為離線排版、解析與時區轉換，沒有升級 SDK 或改動 schema v1。
- **本輪追加驗證**：252 項完整測試及靜態檢查通過，涵蓋手機 emoji 保存、格式預覽、表格轉換／窄畫面捲動、繁中／英文可讀時間、夏令時間／跨年與設定持久保存。模擬器已操作 Markdown／表格／emoji 獨立預覽、設定入口、選台北時區及詳情時間更新；測試後恢復跟隨手機，一般 APK 已保留資料安裝。現有 50 筆事件、100 個段落及 5 個附件保持原樣。日誌與畫面位於 `build/demo_archive_validation/markdown_timezone_tests.log`、`markdown_timezone_analyze_final.log` 及同目錄截圖。企劃書與 HTML 已同步，已包含在 cee0dfd 提交中。
- **Markdown 語法逐項確認**：H1～H6（井字號後加空白）、項目符號、編號、巢狀清單、行內程式碼與標準 `[連結文字](網址)` 均已支援。新增核心與 Widget 驗證，包括巢狀層次、非 1 起始編號、六級標題顯示、程式碼與連結格式匯出；連結可點擊複製網址，沿用既有不自動連網規則。相關 8 項測試通過，日誌為 `build/demo_archive_validation/markdown_syntax_tests.log`；本次未變更已部署 APP 的行為或裝置資料。
- **工具列、原生日期與寬標題（2026-10-14 最新）**：補齊 H1～H6、項目符號／編號、增加／減少縮排、行內程式碼及連結插入按鈕，提示文字允許換行。精確日期使用 Android 原生 `DatePickerDialog`；年份改用年份選擇器，月份與年齡改用選項，季度／半年沿用選項，時間範圍兩端各自選擇，沒有數字輸入框。詳情標題已移到操作列下方，完整寬度自然換行。255 項完整測試及靜態檢查通過，新版已以版本碼 1 保留資料安裝。模擬器已核對完整工具列、寬標題、繁中原生日期對話框，以及取消兩層選擇器後仍為原有時間未定；草稿未清除。
- **格式 demo 更新**：新版 ZIP 為 `demo_data/LifeChronicle_20261014080000_01m4wpss006k64hsnp9e489t28_full.zip`（1,529,670 bytes），旁檔與 `demo_package.json` 已更新。50 筆故事的 100 個原始段落加入標題、粗體、巢狀／編號清單、表格、行內程式碼、emoji 與示範連結；原有事件、日期、作者、照片、附件識別碼保留。更新前備份位於 `build/demo_archive_validation/before_demo_format_update_20261014_175916/`；舊版 ZIP 亦保留於 `demo_data/v1/`。
- **格式 demo 核對**：透過正式 ZIP 還原核心更新，僅對與原始 v1 相同的 demo 段落採用新版，手動改過的段落保留。本次替換 100 個段落、新增事件／附件 0，仍為 50 筆事件、100 個段落、5 個附件。先前附件核對不符的更新已回滾，修正為保留原始全部資料列、只改段落格式後通過。裝置逐段內容與 ZIP JSON、五份附件與 SHA-256 完全一致，完整性 `ok`、外鍵錯誤 0。一般 APP 入口已恢復，模擬器已看到新居事件的格式內容。最新日誌為 `pickers_toolbar_tests_final.log`、`pickers_toolbar_analyze_last.log`，更新報告及畫面位於同一 `build/demo_archive_validation/` 目錄；正式匯入介面與跨主角政策仍未完成。
- **接續時注意**：
  - 首次開啟自動建立的主角與本人作者，名稱為空字串，畫面需顯示為「我」（介面文字放 ARB）。
  - 地點與人物是共用參考資料、不分層級；生命典藏期間也可補上地點座標（已向使用者說明）。
  - 年齡推估的確定程度視為「推估」；企劃書的 `order` 欄位在資料庫中名為 `position`（SQL 保留字）。
  - 企劃書 §14 仍有待決策項目（APP 內語言切換、資料庫是否另外加密、正式上架後的地圖圖資來源等），碰到時依第 5 節詢問使用者。

## 3. 任務明細

### T00 專案基礎設定

- 移除範本的計數器程式，建立第 1 節的資料夾結構。
- 設定 `flutter_localizations`，預設語系 `zh_TW`；建立 `lib/l10n/` 介面文字機制。
- 建立 `ThemeData`（§4.4）：一組主色＋中性色、8dp 間距、圓角卡片；淺色與深色兩套主題，跟隨系統。
- 建立 Riverpod `ProviderScope` 與空白的五個主分頁骨架（§4：人生時間軸／搜尋與視圖／新增節點／故事篇章／資料與備份）。
- 驗收：APP 啟動顯示繁體中文的底部導覽列；切換系統深色模式時主題跟著切換；`flutter analyze` 無問題。

### T01 ULID 產生器

- 在 `lib/core/ids/` 實作 ULID：26 字元 Crockford Base32、前 48 位元為毫秒時間戳記、其餘為安全亂數。
- 同一毫秒內連續產生時須單調遞增。
- 驗收：單元測試涵蓋格式、字元集、時間可解析、同毫秒單調遞增、大量產生無重複。

### T02 時間值模型與顯示格式

- 在 `lib/core/time/` 定義時間值模型，支援 §5 表格全部類型：`day`、`month`、`quarter`、`half_year`、`year`、`approx_year`、`range`、`relative`、`age_estimate`、`unknown`；`range` 起訖可各自有不同精確度。
- 可序列化為 JSON（`time_payload`），並可完整還原。
- 實作兩種顯示格式：
  - 完整格式（詳情頁）：「2003-09-15」「2003 年第 3 季」「2003 年上半年」「約 2003 年」「2002～2004 年」「大學畢業後」「約 20 歲」「時間未定」。
  - 列表格式（§4.6）：「12/28」「12 月」「第 4 季」「下半年」「月份未定」「約 2003 年」「2002～2004」。
- 驗收：每種類型的建立、驗證（如月份 1–12、季 1–4）、JSON 來回轉換、兩種顯示格式皆有測試；任何類型都不會顯示出未輸入的月日（驗收 #1、#14 的顯示部分）。

### T03 排序區間換算

- 實作 §5.1 步驟一：每種時間值換算為 `sort_start`、`sort_end`（日期，不含時區）。
- `relative` 與 `age_estimate` 需要外部資訊，以介面注入（取得關聯事件區間、取得主角生日），不得直接查資料庫。
- `relative` 必須偵測循環參照並回報錯誤；參照事件不存在時回傳「保留最後區間並標示」所需的狀態。
- `age_estimate` 在生日只知年份時放寬區間；無生日時視同 `unknown`。
- 驗收：§5.1 步驟一表格每一列至少一個測試，含閏年 2 月、跨年 `range`、循環參照。

### T04 排序比較器（雙向）

- 實作 §5.1 的舊到新五條規則與新到舊五條對稱規則，作為**全專案唯一**的排序實作。
- 實作年份分組：一律依 `sort_start` 所在年份分組；`unknown` 集中於最後。
- 驗收：
  - 以 §5.1 兩張範例表為測試資料，**任意打亂輸入順序**（至少 100 次隨機排列），輸出必須與範例完全一致（驗收 #16、#29 的排序部分）。
  - 「2003 年下半年」排在「2003 年上半年」之後（舊到新）（驗收 #14）。
  - 切換方向時事件不換組。

### T05 資料庫結構與約束

- 以 drift 建立 §10 全部資料表（第一階段用不到的表也先建立，避免日後遷移），`schema_version = 1`。
- 層級代號：`layer` 為 `original`（原始生命紀錄層）或 `remembrance`（後續追憶層）；`archive_settings.mode` 為 `normal` 或 `life_archive`。
- 所有內容表包含層級欄位：`layer`、`author_id`、`created_at`、`archive_session_id`。第一階段沒有生命典藏模式介面，但欄位與約束**現在就要建立**。
- 觸發器與約束（§10）：
  - 拒絕任何對 `layer` 的 UPDATE。
  - `layer = remembrance` 時 `author_id` 不得為 `is_subject_self` 的作者。
- 在 `sort_start`、`sort_end` 建立索引；建立 FTS5 全文索引供 T11 使用。
- 地點、人物、隱私、關聯事件與軟刪除（§4.1、§9.3）：`places`、`people`／`event_people`、`event_links` 資料表；`events` 的 `place_id`、`privacy`、`deleted_at`、`purged_at`；`attachments` 的拍攝座標。`places`／`people` 的 `name_key` 唯一；`event_links` 每對只存一列（`event_a_id < event_b_id`）。
- 驗收：測試證明修改 `layer` 的 SQL 會失敗、追憶內容設定本人作者會失敗；資料庫可從空白建立並開啟；地點與人物的正規化名稱不可重複、關聯事件不可反向重複或自我關聯。

### T06 Repository 與權限檢查

- 建立各實體的 repository；**新增時自動寫入 `layer`**（依 `archive_settings.mode`），呼叫端不得傳入 `layer`。
- 實作 §9.3 權限矩陣為單一檢查函式，所有寫入路徑都必須經過；第一階段僅一般模式，但生命典藏模式的分支也要實作並測試。
- 儲存事件時以 T03／T04 換算 `sort_start`、`sort_end`；關聯事件時間變更時，自動重算所有引用它的 `relative` 事件。
- 以 Riverpod 提供可監聽的查詢（資料變更時畫面自動更新）。
- 名稱正規化（`lib/core/`，純 Dart）：忽略「台／臺」、全形與半形、空白；地點與人物以正規化名稱比對，相同即重用既有資料。
- 軟刪除（§9.3）：刪除只寫入 `deleted_at`，所有查詢預設排除；復原清除 `deleted_at`；永久刪除依是否有後續追憶附掛，決定保留標題（`purged_at`）或完整移除。
- 驗收：權限矩陣每一格皆有測試；修改「大學畢業」日期後，「大學畢業後」的事件自動移動（驗收 #17）；追記時保留發生時間與記錄時間（驗收 #2）；驗收 #35 的資料層部分。

### T07 時間軸首頁

依 §4.6 實作：

- 年份分組、固定在頂端的年份標題（含筆數）、點擊收合／展開；完整列出所有事件。
- 頂部列：年份按鈕（點擊開啟年份清單，含各年筆數與「回到今年」）、排序方向按鈕（以文字顯示「新→舊／舊→新」）、篩選按鈕、顯示密度切換。
- 排序方向與顯示密度**記住使用者選擇**；切換方向時保持目前閱讀位置。
- 篩選面板（類別、人生階段、標籤、人物、地點、紀錄層）；已刪除事件不顯示；套用後頂部顯示條件標籤與「符合 N／M 筆」，一次點擊清除；無結果的年份隱藏。
- 月份分隔（事件多時）、「時間未定」區固定在最後、右側年份快速捲動條（捷徑）。
- 以 Sliver 虛擬化清單實作；依年份分段載入。
- 提供開發用的假資料產生工具（1,000 與 5,000 筆、跨 50 年、各種精確度），只在 debug 版本可用。
- 驗收：驗收 #26、#27、#28、#29；5,000 筆時首頁 1 秒內顯示（在模擬器記錄實測時間並回報）。

#### T07 前次驗證（2026-10-12）

- 自動化測試：20 筆完整列出與收合／展開；跨 50 年跳年與連續捲動；時間未定固定最後；模糊時間不補月日；職涯篩選顯示 N／M 並一次清除；排序切換保留閱讀事件及位置；圖文卡片摘要、附件數及月份分隔；兩個方向的年份查詢與既有唯一比較器結果一致。
- 資料層：年份筆數隨新增、改年、刪除、復原更新；人生階段不按時間重疊自動歸入；關聯遵守典藏權限與永久刪除規則；具名主鍵、外鍵與初始結構驗證；排序／密度持久性與連續寫入；1,000／5,000 筆假資料涵蓋 50 年及十種精確度並保留原資料。
- 模擬器已啟動並操作繁中年份／篩選面板與 debug 假資料工具；1,000 筆繁中資料可從 2026 年輸入「1990」直接跳年，年份標題顯示 16 筆、篩選顯示「符合 1000／6000 筆」。畫面與測試日誌暫存於忽略提交的 `build/timeline_validation/`。
- 視覺調整：採明確的低飽和墨綠／灰白色盤、純文字品牌標題、白色圓角事件卡片、日期／標題／分類字體層級、框線工具列、圓形新增按鈕及細線底部導覽；淺深色主題集中於 `AppTheme`，沒有新增套件。
- 正式名稱依企劃書為「人生編年史／Life Chronicle」，品牌區不加入未定義的宣傳句；Android 桌面名稱改用正式中英文名稱資源，並以測試確認與 ARB 一致。
- 效能：5,000 筆、debug 模式，從 `TimelinePage` 建立到第一批事件完成繪製的回呼為 **1,527 ms**，記錄 `TIMELINE_FIRST_CONTENT_MS=1527 COUNT=5000`。不包含 Flutter 引擎啟動前的時間；尚未符合 1 秒目標，也不能代表實機或 release 效能。
- 未完成驗收：照片縮圖的真實附件流程、完整詳情開啟及共享元素轉場須隨 T09／T10 驗證；中階 Android 實機效能與快速捲動流暢度仍待確認。

#### T07 本次驗證（2026-10-14）

- 查詢最佳化：精簡模式略過摘要、附件數與圖片查詢，也不因這些內容變動重新載入年份；圖文模式仍提供完整預覽及資料更新。沒有年齡推估的年份／參照鏈略過生日查詢，遇到年齡推估時仍使用原有區間換算器。
- 回歸測試：精簡與圖文模式雙向排序一致、相對事件標題保留、年齡推估及其相對參照使用生日、圖文記述新增後即時更新、回到圖文模式仍取得最新摘要。`flutter test` 186 項全數通過，`flutter analyze` 無問題。
- 重現入口：`tools/timeline_benchmark.dart` 使用 Application Support 內獨立的 `timeline_benchmark_5000.sqlite`，首次建立跨 50 年的 5,000 筆資料，之後重用；APP 啟動時重新開啟連線。測量從 `TimelinePage` 建立到第一批事件繪製回呼，包含畫面建立後的資料庫開啟及查詢，不含首次造資料或 Flutter 引擎啟動。
- 模擬器：`Medium_Phone`／`emulator-5554`、Android 16 API 36、繁體中文；debug 最終版本三次重測 `TIMELINE_FIRST_CONTENT_MS=2602/2028/1692 COUNT=5000`，未達 1 秒。此數據與前次環境／資料庫不同，不能當作前後改善幅度；也不能代表實機或 release 效能。精簡／卡片切換已實際操作，卡片顯示附件數；本次沒有真實附件，照片驗收仍待 T10。
- profile 測量：計時回呼已支援 profile；先以 debug 測試入口建立資料，再以 `flutter build apk --profile --target-platform android-x64 --split-per-abi -t tools/timeline_benchmark.dart` 建置。此次缺少引擎套件且無法連線至 `storage.googleapis.com`，建置失敗，沒有 profile 實測結果。
- 測試日誌、三次效能紀錄及畫面暫存於忽略提交的 `build/timeline_validation/`。模擬器空間不足以安裝全架構 debug APK，改用 x64 APK；已重新安裝正常 APP 入口，確認顯示既有 6,000 筆資料，正常資料庫 SHA-256 與恢復前一致，排序／密度偏好仍為原設定。效能測試不取代正常資料庫。T07 維持「進行中」。

### T08 完整新增與時間選擇器

- v3 新增的附件預覽、模式選擇與額度 UI 由 T10 負責，新增／編輯／分享匯入一律串接共用流程；本任務既有完成狀態不代表這些新增需求已完成。

- 新增與編輯直接提供完整表單（§4.1），不再使用快速／進階模式與切換按鈕；選填欄位可留空，既有草稿保留。
- **2026-10-14 使用者調整**：已移除「進階編輯」切換，新增與編輯均直接提供完整欄位、自訂段落與排序。260 項完整回歸及靜態檢查通過；版本碼 1 APK 已保留資料安裝，模擬器確認新增頁直接顯示地點、人物、隱私與關聯事件。驗證日誌為 `build/demo_archive_validation/full_editor_tests_final.log`、`full_editor_analyze.log`、`full_editor_build.log`，畫面為同目錄的 `full_editor_form.png`；未保存測試事件或清除草稿。
- 時間選擇器「由粗到細」（§5）：先選年份，可停在任何一層（年、半年、季、月、日），另可選「約略」「範圍」「相對事件」「年齡」「時間未定」。
- 編輯中自動儲存草稿，意外關閉後可恢復。
- 新增按鈕位於拇指熱區（§4.3）。
- 完整表單包含：地點（文字輸入時列出過去地點建議）、參與人物（從既有人物建議選取）、隱私層級（一般／私密）、關聯事件（可一次勾選多個）。
- 驗收：驗收 #1、#13、#14、#33、#36；只填標題與「時間未定」也能儲存。

### T09 紀事本末詳情與回顧

- v3 詳情頁額度列、內建附件檢視與回顧／追憶新增附件限制由 T10 負責；既有詳情驗收不能代替新規格驗收。

- 狀態：完成。361 項回歸、Android 獨立資料的 #2／#30 操作及正式 ZIP 閱讀版核對已通過，證據見上方最新紀錄。

- 詳情頁依序顯示：記述段落（依使用者排序）→ 日後回顧 → 附件（§4.2）。
- **記述段落不得寫死為起因／經過／結果**：預設只有一個未命名的「記述」欄；「新增段落」可選建議項目或輸入自訂標題；段落可增刪、改名、拖曳排序，空白段落不顯示（§4.2）。
- 回顧採**追加**，不覆寫先前內容；每則回顧有自己的作者與時間，追記內容標示「XX 年追記」（§5）。
- 從時間軸進入詳情使用共享元素轉場，並遵循系統「減少動態效果」設定（§4.4）。
- 驗收：驗收 #2、#30；新增回顧後舊回顧內容不變。

### T10 附件匯入、照片壓縮與額度

狀態：**進行中（v3 重新開啟）**。既有串流複製、SHA-256 去重、暫存驗證、交易保存及取消機制保留；T10.1 主要內容判定及 T10.2 額度核心已實作，T10.3 排除提示與無可用檔案時停用保存已先行接上；仍缺下列剩餘功能及裝置驗收。所有入口使用同一套資料存取層規則，不能只在 UI 攔截。

| 子任務 | 交付與驗收範圍 | 狀態 |
| --- | --- | --- |
| T10.1 實際類型判定 | §7.1：依檔案標頭及容器軌道排除影片，改名仍拒絕；純音訊 M4A／WebM 允許。其他非影片檔案可保存；Live Photo／Motion Photo 僅取靜態影像。`media_type` 記實際類型，不能只信副檔名或系統 MIME。#7、#53 | 進行中：主要容器含 PS／TS、JPEG 動態照片及原生實樣比對已完成；完整 UI／其他品牌樣本待驗收 |
| T10.2 每篇額度核心 | §7.1、§7.4：精確上限 25,000,000 bytes，件數不限；原始記述、回顧、追憶合併計算，每筆引用按保存 blob 大小扣額，即使實體去重或重複引用也不減免。額度即時加總 `attachments` 關聯的 `blobs.byte_size`，不另存可能失準的計數欄位；最終大小及併發新增在同一交易內檢查，失敗保留既有內容。#3–#6、#44–#48、#52 | 進行中：核心與 Repository 已實作，裝置待驗收 |
| T10.3 匯入預覽與解決選項 | §7.2：逐檔勾選、縮圖、實際類型、名稱、大小、照片解析度、原始檔／壓縮模式、品質與預估結果；頂部顯示已用／待加入／剩餘額度。原檔可容納時預設原檔，否則預設壓縮，支援一律壓縮偏好。單檔超額或不支援者標示原因並排除，不阻止同批其餘合格檔案；選定的有效集合全有或全無。超額提供壓縮全部、較小檔位、取消勾選或取消，保存按鈕停用且有文字說明。#7、#44–#47、#52 | 進行中：逐檔選取、額度、解析度、原始／三檔壓縮、實際大小／品質、比較與批次壓縮已接入；一律壓縮／預設檔位偏好已完成，裝置完整驗收未完成 |
| T10.4 照片壓縮管線 | §7.3：僅靜態 JPEG／PNG／HEIC／HEIF／WebP 可壓縮；非照片與動畫 GIF 保留原檔。高畫質／標準（預設）／精簡長邊 4096／3072／2048 px，等比例、短邊四捨五入、不裁切不放大、EXIF 轉正；大型照片採降採樣避免全尺寸解碼耗盡記憶體。JPEG 品質由 90 每次降 5 至 75，以 3 MB 為目標，不自動降低解析度；超過 3 MB 仍可在事件額度內保存，結果比原檔大則保留原檔並提示。透明影像輸出 PNG，HEIC 輸出 JPEG。#49–#51 | 進行中：Android API 30+ 管線、預覽與 82 項原生檢查已完成；HEIF 真實樣本、舊版相容與實機完整驗收未完成 |
| T10.5 中繼資料與整批保存 | §7.2–§7.4、§7.6：壓縮前讀取拍攝時間及 GPS 存入資料庫，不以匯入時間替代；保留拍攝／相機資訊及 ICC（或轉 sRGB），壓縮檔 GPS 預設保留、可移除，縮圖／預覽不含 GPS。處理前後大小與解析度可比較；背景壓縮／複製可取消，原檔及實際保存檔各算 SHA-256、驗證後原子移入持久目錄並以單一交易保存。實際超額回到解決選項，不保存任何附件；中斷暫存安全清理，不能清除草稿或已引用副本，不動外部原件。#3–#6、#51、#52 | 進行中：來源前後雜湊、一般 EXIF／GPS 保留、sRGB、可取消工作目錄與交易保存已接入；GPS 移除、草稿拍攝資訊及中斷暫存確認清理已完成；去定位快取及逐檔進度已完成；裝置完整操作驗收待完成 |
| T10.6 共用入口與額度 UI | §7.1–§7.2、§7.5：新增、編輯、回顧、追憶及分享選單匯入全部套用；詳情與編輯顯示十進位 MB 額度，剩餘不足 5 MB 提醒。既有超額資料只限制新增，不自動壓縮／刪除；遵守原始層／追憶層權限與私密保護。#44–#48 | 未完成 |
| T10.7 附件檢視與快取 | §7.1、§7.5、§12：照片及 PDF 於 APP 內檢視、錄音內建播放；Office／其他檔案以系統開啟，沒有可用 APP 仍能保存及匯出。照片縮圖長邊最多 512 px、預覽最多 1600 px；快取不計事件額度，可重建。PDF 縮圖與平板並排比較屬第二階段。#48、#54 | 進行中：匯入／時間軸／詳情去定位縮圖與比較快取已接入；內建照片／PDF／錄音檢視及完整快取管理未完成 |
| T10.8 基本儲存空間 | §7.5：匯入前可用空間須達預估新增容量＋500 MB；低於 1 GB 時時間軸顯示可關閉提醒，不阻擋文字記錄；分開顯示 APP 總占用與手機剩餘空間。完整分類／去重效益／排行／清理／備份狀態頁依 §12 屬第二階段，與 #56 的驗收歸屬須先釐清。#55、#56（階段待定） | 未完成 |

T10.1 主要內容解析與 T10.2 額度政策均已接入 Repository；MPEG-PS／TS 與實際編碼樣本已補，接著依賴兩者完成預覽、壓縮及 UI；T12／T13 重用同一政策，避免匯入和還原產生不同限制。未引用 blob 經使用者確認才清理；實體去重與倉庫統計不可改變每篇的邏輯額度。完整儲存空間頁與既有照片轉壓縮不得誤列為本輪已完成。

### T11 簡易搜尋

- 以 FTS5 搜尋標題、敘述、地點、人物、標籤、附件名稱（§6）；中文需能以部分字詞搜尋到。
- 可依時間區間縮小範圍；只記得年份的事件也要能被搜尋到。
- 點擊結果開啟該事件的紀事本末。
- 驗收：中文關鍵字（含兩字詞）可搜尋到對應事件；時間未定的事件也出現在結果中。

#### T08～T11 本次驗證（2026-10-14）

- T08：完整新增與編輯欄位、既有地點／人物建議、十種時間類型、範圍兩端各自精確度、人物／標籤／隱私與多選關聯。草稿及待提交附件使用持久性目錄，逐次排入原子寫入；保存後清理中斷再試不重複建立事件或附件。驗收 #1、#13、#14、#33、#36 的資料與介面部分有對應測試；模擬器已確認強制關閉後恢復標題與半年時間。
- T09：時間軸／搜尋進入完整詳情，段落可自訂、改名、增刪、拖曳與使用可見的上移／下移按鈕；空白段落不顯示。回顧只追加，保留作者、建立時間及「XX 年追記」。共享標題轉場及系統減少動態效果有 Widget 測試；模擬器已操作回顧與自訂段落排序。驗收 #2 及 #30 的詳情部分通過；#30 的 Markdown 匯出尚未實作，故 T09 維持進行中。
- T10：使用者選擇多檔批次且全有或全無。串流 SHA-256／去重／容量確認／複製至 `.partial`／大小與雜湊驗證／原子改名／單一交易登錄；失敗清理本次未完成副本，取消、空間不足、來源變更、既有副本損毀與權限拒絕均有測試。拍攝時間可取得時保存，不以匯入時間代替。已移除的引用不刪除共用副本，無引用及中斷副本要經確認才清理；草稿引用會被保護，含 Windows 路徑正規化回歸測試。
- T10 模擬器驗收 #3～#6：本輪產生的照片與影片一次匯入，影片再匯入另一事件顯示「新增 0 B／相同副本 1 個」，倉庫只有 2 個 blob、3 個引用。刪除測試來源影片後仍可用 Google Photos 播放 APP 副本；刪除其中一個事件後另一引用仍可用的資料層測試通過。另以中斷 `.partial` 檔重啟驗證，只列為待清理，不登錄為可用附件；清理前說明影響及容量。大檔中途取消與整批回復以串流測試驗證，沒有宣稱已完成中階實機驗收。
- T11：unicode61 FTS5 索引接收純 Dart 產生的 Unicode 字元／雙字詞編碼，支援中文一字、兩字、英文及字面標點，並核對完整子字串避免錯誤命中。搜尋標題、記述、回顧、地點、人物、標籤、附件原檔名及篇章；即時更新、軟刪除／復原、跨年區間交集及時間未定有測試。搜尋及關聯事件沿用唯一比較器與目前排序方向；私密結果有標示，保護驗證仍屬 T19。模擬器已操作附件名稱搜尋、年份縮小與開啟詳情。
- 驗證：`flutter analyze` 無問題；`flutter test` 225 項全數通過；版本碼 1 的 x64 debug APK 建置及保留資料安裝成功。資料庫完整性與外鍵檢查通過。日誌、畫面、安裝前備份、裝置資料核對暫存於忽略提交的 `build/timeline_validation/`。iOS 平台程式尚未建置／實測；T12 ZIP 與 Markdown、T13 還原、T14 實機及無障礙整體驗收仍未完成。

### T12 匯出 ZIP 封存

依 §8.1–§8.7、§8.11 實作：

- 目錄結構（§8.2）、檔案與編碼規範（§8.3）：ASCII 路徑、完整 SHA-256 媒體檔名、事件檔名只含日期與 ID。
- `data/` JSON 為權威資料；附上 `schema/` JSON Schema。
- **CommonMark 產生器**（§8.4）：放在 `lib/core/archive/`，純 Dart；使用者文字跳脫、行尾反斜線硬換行、不使用任何擴充語法；`index.html` 靜態閱讀頁。
- ZIP 規範（§8.5）：文字 Deflate、媒體 Store、UTF-8 檔名旗標、ZIP64、可選分割封存。
- `manifest.json` 與 `SHA256SUMS.txt`、ZIP 外旁檔（§8.6）。
- 匯出流程（§8.7）：`.partial` 暫存 → 逐檔驗證 → 重新開啟 ZIP 全部驗證 → 改為正式檔名 → 記錄備份紀錄。
- 透過系統檔案選取或分享機制輸出（§8.10）。
- **v3 新增、尚未完成**（§8.11）：按實際匯出範圍檢查全部媒體存在、大小／SHA-256 相符、無影片及所有輸出事件符合 25 MB；舊資料違規也必須中止並列出事件供使用者處理。刻意排除的事件／附件不算缺漏，manifest、引用與額度計算必須一致，不能修改來源資料。
- 驗收：驗收 #8、#18、#19、#22、#60；#22 使用多篇各自合規的附件累計超過 4 GB。CommonMark 驗證在 Dart 測試中進行；若需外部參考實作比對，可另寫 `tools/` 腳本，不得加入 APP 相依。

### T13 匯入與還原

依 §8.8、§8.11 實作：

- 安全檢查（拒絕絕對路徑、`..`、符號連結；壓縮炸彈與空間檢查）→ 版本相容判斷 → 完整性驗證 → 暫存區 → 單一交易寫入。
- 附件依 SHA-256 去重；同 ID 衝突列出差異由使用者決定，不自動覆蓋。
- **依封存包原樣還原 `layer`、作者、建立時間，不重新判定。**
- **v3 新增、尚未完成**：先確認全部分包齊全及外部旁檔雜湊，再驗證附件實際類型、blob 大小／SHA-256／引用完整性、每篇所有層的總額度；刻意排除者不列缺漏。衝突決策後的擬合併結果也須重算額度，超額時可改保留本機或取消，不能自動略過附件。去重後新增容量加 500 MB 安全餘量須足夠，全部通過後才進入正式寫入。
- §8.11 違規報告列出事件（私密標題須保護）、ID、路徑、實際類型與超額大小，可複製文字但不預覽附件；影片／額度等規格違規拒絕整包，本機資料完全不變，不提供自動壓縮、轉換或跳過。§8.8 損毀包完好部分還原不能繞過這些檢查。
- 完成後顯示核對報告。
- 驗收：驗收 #20、#21、#25、#57–#60；匯入失敗時原有資料完全不變（以測試證明）。

### T14 平板版面、深色模式、無障礙

- 依 §4.5 斷點切換：手機單欄＋底部導覽列；平板側邊導覽欄；橫向雙欄主從式。
- 旋轉、分割畫面時保留目前選取事件與編輯內容。
- 系統字級最大時不破版、觸控目標至少 48dp、螢幕閱讀器標籤完整、不只靠顏色傳達資訊（§4.3）。
- 驗收：驗收 #11、#12。

### T15 第一階段整體驗收

- 逐條追蹤 v3 的 #1–#8、#11–#22、#25–#60，共 56 條；其中 #56 階段待確認，其餘 55 條納入第一階段。#3、#4、#6、#7 等既有編號也已改寫，須依 v3 原文重新驗收，不能直接沿用舊版通過標記。
- 附件重點：實際類型／改名影片、25,000,000／25,000,001 bytes 邊界、混合類型／重複引用／所有層共用額度、300 張照片、EXIF／GPS／透明／HEIC／GIF、壓縮結果超額整批回復、低空間、內建檢視與匯出／還原相同規則。測試資料須為有效實際格式，避免只有副檔名的假檔掩蓋問題。
- 對照 §12 第一階段完成判準：可建立 100 筆節點並完成備份還原；相簿刪除原件後仍可開啟獨立副本；Android 實機通過驗收。
- 進行一次「首次使用者不看教學」測試（驗收 #15），記錄卡住的地方並回報。
- 產出驗收報告，列出通過、未通過與待決事項。

#### T12～T19 驗收檢查點（2026-10-14，尚未完成）

以下記錄目前工作樹的實作與測試證據，不取代第 0.7 節完成定義，也不代表第一階段已通過。

| 任務 | 已有實作 | 尚未完成的主要項目 |
| --- | --- | --- |
| T12 | CommonMark 跳脫與硬換行、靜態 HTML 與閱讀版資訊、追憶分檔與往返連結、排除媒體說明、業務資料 JSON、23 份 JSON Schema、CommonMark 參考實作與 HTML 連結驗證、SHA-256 清單、完整／不含媒體／自訂副本排除匯出、暫存 ZIP 重開驗證、旁檔與備份紀錄、匯出／校驗／分享介面、三種裝置實際匯出核對；最新版 APK 已保留資料安裝 | 私密事件整筆排除、分割封存、超過 4 GB 的 ZIP64 實測、裝置分享 |
| T13 | 路徑／符號連結／容量／雜湊檢查、單一主角政策、暫存區、正式檔案選取／同 ID 與同名參考資料逐筆衝突決策／核對報告、引用重新連結、附件去重、交易還原與失敗回復／清理，保留來源層級／作者／時間；晚期失敗與串流複製取消測試 | 損毀包僅還原完好部分、舊版本與分包相容性、真正大型媒體取消與跨實體裝置完整還原驗收；交錯 ID／名稱身分目前拒絕推測 |
| T14 | 手機／平板導覽、寬畫面主從詳情、切換寬度保留選取與草稿、部分大字級排版修正及整合回歸 | 所有頁面最大字級、48dp 觸控目標、螢幕閱讀器、模擬器旋轉／分割畫面操作 |
| T17 | 座標與半徑模型、草稿／地點保存、Android 按需定位／取消／地圖連結／照片 EXIF 座標、OSM 選點與離線提示介面；Android APK 已建置 | 定位拒絕／逾時／離線／EXIF 與拖曳選點測試、資料驗證及私密保護檢查、圖資連網範圍核對、Android 定位與地圖操作；iOS 原生實作尚未完成 |
| T18 | 最近刪除入口、復原／永久刪除確認、詳情刪除與復原捷徑、保留追憶的唯讀詳情、部分已刪除參照標示 | 相對參照原標題保留完整性、照片與追憶整合案例、頁面操作及回歸測試 |
| T19 | PBKDF2、復原碼／遺族密碼、安全儲存、原生驗證、鎖定閘門、安全性設定、錯誤暫停、部分 Repository／畫面私密保護、Android 最近使用預覽保護；Widget 回歸及 Android APK 建置通過 | 全部內容與參照的隱私／權限稽核、復原與遺族流程裝置驗收；iOS Keychain／Face ID 與預覽保護尚未驗證 |
| T15 | 整理既有基準與本輪檢查點；資料層已有 100 筆事件封存還原案例 | 第一階段驗收逐條報告、裝置完整操作、Android 中階實機、首次使用者不看教學測試；資料層案例不能代替這些驗收 |

本輪測試紀錄：

- 封存核心的 2 項測試及封存 Repository 的 3 項測試曾通過。包含 100 筆事件跨兩個測試資料庫封存還原、附件去重與來源移除後讀取副本，以及損毀 manifest、非法路徑、符號連結、容量不足、媒體損毀和取消案例。這不是跨實體裝置驗收，也未證明所有晚期交易失敗皆已覆蓋。
- 密碼核心 4 項測試曾通過，包含 PBKDF2 標準向量、多區塊輸出、安全亂數碼及錯誤暫停序列化；安全性服務 5 項測試在整合執行中通過，涵蓋重啟鎖定、密碼限制、遺族權限、復原碼換發及私密查詢／寫入保護。
- 響應式 2 項測試包含寬度切換保留選取／草稿及繁中大字級深色首頁。安全性整合曾因巢狀 Navigator 共用 HeroController 造成 11 項 Widget 測試失敗，已隔離並於本輪完整回歸通過。另修正平板測試選到導覽欄捲動區、已刪除參照的過時斷言及安全性提示文字的 ARB 使用。
- 最新 `flutter analyze` 無問題，`flutter test` 242 項全數通過；普通入口版本碼 1 的 x64 debug APK 建置及 `adb install -r` 成功。首次還原的容量檢查曾因目錄不存在而失敗，發生在刪除前、原資料不變；修正為先建立還原目錄，並在封存 Repository 測試中驗證不存在目錄的情境。
- 歷史測試日誌位於忽略提交的 `build/`。最新回歸、分析、建置、裝置匯入報告、前後完整備份與畫面位於 `build/demo_archive_validation/`；最新通過日誌為 `full_tests_search_final.log` 與 `analyze_search_final.log`。使用者已授權取代無效事件，裝置變更見上方最新 demo 狀態。

已移除以事件層級限制共用地點補座標的新增檢查，遵守既有「生命典藏期間可補上共用地點座標」規則；座標有效性檢查仍保留。

#### 50 筆擬真 ZIP demo 驗證（2026-10-14）

- 資料包：`demo_data/LifeChronicle_20261014080000_01m4wpss006k64hsnp9e489t2d_full.zip`，1,513,198 bytes；同目錄附 ZIP SHA-256 旁檔、`demo_package.json` 及 `demo_validation.json` 核對結果。
- 附件為 3 張 AI 生成生活照片、1 張模擬學生證與 1 張模擬結業證書，全部為有效 JPG，沒有影片；證件圖片明確標示「模擬／無效」。來源圖片位於 `demo_data/source/`，故事資料與重建／備份／匯入／核對工具位於 `tools/demo_archive/`。
- 使用正式 `ArchiveRepository` 建包及 `ArchiveRestore` 還原；本機測試驗證 50 筆還原、重複匯入不增加筆數、中文搜尋與附件名稱搜尋。裝置逐份讀回五個副本，與 ZIP 內容及 SHA-256 完全一致，完整性檢查 `ok`、外鍵錯誤 0。
- 模擬器已操作繁中時間軸縮圖、新居紀錄詳情與系統圖片檢視器；搜尋頁已改為首次開啟列出所有可讀紀錄，新增 Widget 回歸並已部署，避免空白頁造成未匯入的誤解。
- 限制：本包綁定目前模擬器的主角 ID，透過 debug 工具匯入，不代表正式檔案選取／衝突介面已完成，也不決定跨主角合併政策；控制檔名稱沿用目前開發編碼器，大小寫政策仍待確認。沒有加入第二階段的故事篇章，亦未進行 Android 實機驗收。

### T16 多語系架構（繁中＋英文）

- gen_l10n：`app_zh.arb`（繁體中文，範本檔）與 `app_en.arb`（英文）；`zh` 基底檔為繁體中文，第二階段新增 `app_zh_Hans.arb` 時不需改動既有檔案。
- 語言跟隨系統：中文（任何字體）→ 繁體中文（Material 元件使用 zh-Hant-TW）；其他語言 → 英文。
- 時間顯示格式改由 ARB 提供文字：`lib/core/time/` 定義文字來源介面，由 `lib/l10n/` 的轉接類別實作，核心邏輯不寫死任何語言。
- 新增自動化測試：掃描 `lib/app/` 與 `lib/features/` 的字串常值，不得含有中日韓文字。
- 驗收：驗收 #31、#32；繁中與英文的時間格式皆不補出未輸入的月日。

### T17 地點 GPS 錨點

- 「使用目前位置」：只在使用者按下時要求定位權限；離線可用；保存緯度、經度與精確度（作為範圍半徑），可手動調整半徑表示區域。
- 照片拍攝位置：匯入附件時讀取 EXIF 座標，存入 `attachments`，並建議作為事件地點。
- 有座標的地點提供「以手機地圖 APP 開啟」（透過系統的地圖連結，不嵌入地圖 SDK）。
- **地圖選點**（§4.1）：以 `flutter_map`（BSD-3）與 OpenStreetMap 圖資實作，拖曳釘選點定位、可調整範圍半徑；標示 OpenStreetMap 著作權資訊；只在開啟地圖時連網；離線時提示並允許先以文字或目前位置儲存。不使用 Google Maps 等雲端 SDK，不做地址查詢。
- 驗收：驗收 #34、#37。

### T18 最近刪除

- 「最近刪除」清單：顯示已軟刪除的事件與刪除時間，可復原或永久刪除；不自動清除。
- 永久刪除前清楚說明影響；有後續追憶附掛時說明「將保留標題，追憶內容不受影響」。
- 後續追憶與相對事件標示「原事件『（原標題）』已刪除」。
- 驗收：驗收 #35。

### T19 APP 鎖定與私密事件保護

- 套件：`local_auth`（手機原生解鎖，含指紋、臉部、圖形／PIN 備援）、`flutter_secure_storage`（Android Keystore／iOS Keychain）；Android 的 `MainActivity` 需改為 `FlutterFragmentActivity`。
- 密碼核心（`lib/core/`，純 Dart）：PBKDF2-HMAC-SHA256 加鹽雜湊（以標準測試向量驗證）；復原碼與遺族密碼產生器（Crockford Base32、16 字元分 4 段、安全亂數）與輸入正規化；輸錯暫停計算。
- 安全性設定（§4.8）：
  - APP 開啟鎖定：自動鎖定時間、隱藏最近使用的 APP 預覽。
  - 私密事件保護：「再次驗證」或「指定輸入 APP 密碼」。驗證前時間軸只顯示時間與鎖頭，搜尋不比對私密內容。
  - 復原碼（1Password Emergency Kit 概念，最終手段）：一組，產生時只完整顯示一次；忘記密碼時先提供手機原生解鎖重設，不可用時才使用復原碼；使用後立即換發新碼並要求重新抄寫；可隨時重新產生。
  - 遺族密碼：一組固定、可重新產生；設定是否可開啟私密事件（預設不可）；不能查看或變更安全性設定；使用時寫入修訂紀錄。
- 設定流程：開啟前明確告知忘記密碼的後果與復原碼、遺族密碼的用途；兩組密碼產生後要求使用者確認已抄寫。
- 所有介面文字使用 ARB（§4.7）。
- 驗收：驗收 #38–#43。

## 4. 後續階段（尚未拆解）

以下依 §12 規劃，第一階段完成後再細分為任務：

### T20 標籤智慧主題（使用者要求提前並修訂需求）

- 依據：§4.2 專題篇章、§9.3 權限、§10 `stories`／`story_events`、§8 閱讀版與權威 JSON。
- 狀態：完成（使用者確認的智慧標籤規則已實作；358 項完整回歸、270 項外部檢查、分析、Android Studio 裝置操作與資料核對通過）。
- 本次交付：智慧主題建立／改名／刪除、標籤 AND／OR／排除、條件搜尋、結果自動更新／時間排序、原事件詳情、私密與典藏保護、舊資料升級、搜尋及 ZIP 閱讀版／還原。舊版手動篇章不再作為新增入口。
- 此任務不代表第二階段其他平台、人生階段視圖或變更歷史已完成。

- **第二階段**：iOS 版（macOS＋Xcode）、簡體中文／日文／韓文翻譯與排版實測（§4.7）、完整儲存空間頁與清理（§7.5，#56 階段歧義見 §5）、既有照片改為壓縮（驗收 #61）、PDF 縮圖與平板並排比較、跨平台影片判定／照片壓縮／25 MB 額度／備份互還一致性、任職與學歷區間、履歷／感情等視圖（驗收 #10）、追記及變更歷史。智慧主題 T20 已提前完成，不重列缺口。新照片匯入壓縮已移至第一階段；v3 不提供僅引用外部原件模式。
- **第三階段**：生命典藏模式介面與後續追憶層（§9，驗收 #9、#23、#24）、多人作者標示、備份驗證、長期相容及批次匯入。加密封存為 §8.9／§14 待決策功能，尚未確定交付階段。
- **後續選配**：本機 AI 訪談與分類、文件文字辨識、可選多裝置同步。

## 5. 待決策事項

以下事項**尚未由使用者決定**。實作到相關任務時，agent 必須**先停下來詢問使用者**，提供選項與建議，不得自行選定預設值後繼續。

| 待決策事項 | 來源 | 影響任務 | 碰到時的處理 |
| --- | --- | --- | --- |
| 完整儲存空間頁的驗收階段 | §12、§13 #56 | T10.8、T15 | §12 明定完整分類／排行／清理頁為第二階段，但第一階段完成判準要求附件相關驗收全通過，#56 又未標階段；先完成第一階段基本空間功能，涉及完整頁的階段及驗收時詢問，不擅改企劃書 |
| 照片壓縮參數的實機樣本調整 | §7.3、§14 | T10.4、T15 | 先依已定義 4096／3072／2048 px、JPEG 品質 90→75 實作及驗收；實機調整數值時再確認，不將基準當成未定義而停工 |
| Office 內建預覽、HEIC／AVIF 壓縮輸出 | §14 | T10 | 目前 Office 以其他 APP 開啟，壓縮照片依 §7.3 採 JPEG／透明 PNG；擴充格式或檢視器前先確認 |
| APP 內語言切換、資料庫額外加密 | §14 | T16、T19 | 現階段跟隨系統語言，資料庫依賴系統儲存加密與私有目錄；新增設定或 SQLCipher 前先確認 |
| 多份備份重新匯入時的衝突合併規則 | §14 | T13 | 第一階段依 §8.8 列出差異由使用者逐筆決定；自動合併規則須先詢問 |
| 加密備份是否提前到第一版、密碼復原政策 | §14 | T12 | 是否第一版提供與密碼政策均未定；未確認前不列為已實作或固定第三階段 |
| 原始生命紀錄層變更歷史的保存期限與刪除政策 | §14 | T05、T06 | 第一階段只建立 `change_history` 資料表並記錄，不實作清除機制 |
| iOS 版推出時機、是否提供桌面閱讀器 | §14 | 不影響第一階段 | 程式保持跨平台寫法（§2.4），不需詢問 |
| 正式上架後的地圖圖資來源 | §14 | T17 | 開發與第一階段使用 OpenStreetMap 圖資；使用者增加後是否改用其他圖資服務，屆時詢問 |

v3 已明定的附件決策不再詢問：每篇合計 25,000,000 bytes、件數不限、排除影片、支援照片原檔／壓縮；預覽排除無法加入的檔案後，所選有效集合整批成功才保存。原「單檔固定大小上限未決」項目已由此取代。

使用者做出決定後：更新企劃書對應章節與本表（移除已決定項目），再繼續實作。

已確認的封存決策（2026-10-14）：使用者同意解除雜湊循環。`manifest.files` 排除 `manifest.json` 與 `SHA256SUMS.txt`；`SHA256SUMS.txt` 仍校驗 manifest；ZIP 的大小與 SHA-256 放外部旁檔，manifest 的分包資訊只記名稱及內容清單。企劃書 §8.6 已據此更新。

已確認的封存決策（2026-10-19）：使用者同意保留根目錄 `README.md`／`SHA256SUMS.txt` 作為僅有的大小寫例外；其餘路徑沿用全小寫規則。跨主角只允許空白資料庫還原，已有內容時拒絕合併。尚未填寫的自動初始主角／本人作者／一般典藏設定可在交易內取代，已填主角資料或其他內容不視為空白；失敗時完整復原。企劃書 §8.3、§8.8 與 HTML 已同步，正式匯入介面已接上，完整缺口見最新 T13 檢查點。
