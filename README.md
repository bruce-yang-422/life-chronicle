# 人生編年史 Life Chronicle

人生不必每天記錄；值得記住的時刻，都應有一個能持續補充、長期保存的位置。

「人生編年史」是一款**本機優先（local-first）、離線可用、無開發者伺服器**的個人生命史 APP。首頁以編年時間軸（timeline）呈現人生關鍵節點，點擊後展開紀事本末；資料可完整匯出為 JSON、CommonMark Markdown 與原始附件，打包成 ZIP 自行備份。即使 APP 停止維護，資料仍可閱讀與搬遷。

## 核心特色

- **模糊時間**：支援精確日期、年月、季度、半年、年份、約略年份、時間範圍、相對事件、年齡推估與時間未定，不假造月日。
- **編年體＋紀事本末**：時間是第一層導航；點進事件閱讀起因、經過、結果、感受與多次回顧。
- **附件獨立保存**：照片、影片、聲音、PDF 完整複製到 APP 私有目錄，以 SHA-256 去重。
- **開放格式備份**：ZIP 封存包含 JSON（權威資料）、CommonMark Markdown、原始附件與校驗碼。
- **生命典藏模式（Life Archive Mode）**：啟用後，既有的原始生命紀錄轉為唯讀，保留當事人的人生歷程。後續追憶層仍允許新增、修改及刪除回憶。紀錄層級於建立時確定，不因模式切換而改變。模式可經由多步驟確認啟用或解除，無須死亡驗證或外部伺服器。
- **不用學就會用**：UX 最高準則，手機與平板皆有對應版面。

## 技術架構

| 項目 | 選擇 |
| --- | --- |
| 框架 | Flutter（Dart），單一程式碼庫支援 Android 與 iOS |
| 首發平台 | Android（Google Play），iOS 於第二階段推出 |
| 狀態管理 | Riverpod（`flutter_riverpod`） |
| 本機資料庫 | SQLite，透過 drift（`drift`、`drift_flutter`、`drift_dev`） |
| 雜湊與封存 | `crypto`（SHA-256）、`archive`（ZIP／ZIP64） |
| 檔案與分享 | `path_provider`、`file_picker`、`share_plus` |
| 在地化 | `flutter_localizations`、`intl`（繁體中文） |

## 開發環境

| 工具 | 版本／說明 |
| --- | --- |
| Flutter SDK | 3.47.6（stable），Dart 3.13.5 |
| 編輯器 | VS Code（Flutter、Dart extension）＋ Android Studio |
| Android | Android SDK 36、Android Emulator（AVD） |
| iOS（第二階段） | 需 macOS＋Xcode 與 Apple Developer 帳號 |

套件 ID（applicationId）：`io.github.bruce_yang_422.life_chronicle`

> 注意：升級 Flutter SDK 或套件主要版本前，先確認相容性；升級後執行 `flutter analyze` 與 `flutter test`。`drift` 與 `drift_dev` 的次版本需保持一致。

## 快速開始

1. 安裝相依套件：

   ```shell
   flutter pub get
   ```

2. 產生 drift 程式碼（修改資料表定義後都要重新執行）：

   ```shell
   dart run build_runner build --delete-conflicting-outputs
   ```

3. 啟動 Android 模擬器並執行：

   ```shell
   flutter emulators --launch Medium_Phone
   flutter run -d emulator-5554
   ```

   在 Android Studio 執行時，右上角裝置選單請選擇 Android 模擬器，而非 Windows (desktop)。

4. 程式碼檢查與測試：

   ```shell
   flutter analyze
   flutter test
   ```

## 文件

| 文件 | 說明 |
| --- | --- |
| [人生編年史_APP_開發企劃書_v2.md](人生編年史_APP_開發企劃書_v2.md) | 產品需求與技術規劃（權威規格） |
| [人生編年史_APP_開發企劃書_v2.html](人生編年史_APP_開發企劃書_v2.html) | 企劃書 HTML 版，由 `.md` 產生，請勿直接修改 |
| [AI_AGENT_TASKS.md](AI_AGENT_TASKS.md) | AI agent 開發任務清單、規範與驗收標準 |

## 開發規範摘要

- **企劃書為唯一規格來源**；實作與企劃書衝突時，先修訂企劃書再改程式。
- **不用學就會用**：每個功能都要有看得見的入口，手勢只能當捷徑。
- **時間不可假造**：不得把模糊時間補成某月某日。
- **Markdown 規範**：專案文件採 CommonMark＋GFM 表格；APP 匯出的 `.md` 採嚴格 CommonMark 0.31.2。
- 程式碼識別名稱用英文；註解、介面文字與文件用繁體中文。

## 授權

尚未決定。
