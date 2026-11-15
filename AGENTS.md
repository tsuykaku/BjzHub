# BjzHub：Codex 工作指南

本文件適用於整個儲存庫。回覆與新增文件預設使用繁體中文；程式識別字保留英文。

## 開始工作前

- 撰寫、修改或審查 Luau 程式碼前，閱讀並遵循 `.codex/skills/luau-code-guide/SKILL.md`。本文件只摘要重點，完整命名、註解與 API 選型規則以該檔為準。
- 先查看 Git 狀態、目標檔案與呼叫端，保留使用者既有變更。修改限制在任務範圍，不順便整批更名、格式化或升級舊腳本。

## 專案性質與檔案分工

這是用戶端 Luau 腳本集合，多數供 Executor 執行。各遊戲通常是獨立入口，沒有統一啟動器或建置流程；不要假設它是 Rojo／Studio ModuleScript 專案。

| 路徑 | 職責 |
| --- | --- |
| `Games/<遊戲>/` | 遊戲專屬入口。 |
| `Core/Features/` | 共用功能。 |
| `Library/BjzUiLibrary_2.0.luau` | 現行 UI 函式庫；提供視窗、分頁、控制項、設定保存、游標與 SVG 等能力。檔名的 2.0 不等於內部 API 版本。 |
| `Library/BjzUiLibrary_1.0.luau` | 舊 UI API，與新版不可直接互換。 |
| `Universal/` | 通用功能。 |
| `Tests/*.spec.luau` | 使用 Lune 的離線測試。 |

## 執行環境與外部載入

- Executor 入口不能假設具有 Studio 的 `script`、相對 ModuleScript `require` 或伺服器權限。測試的 `require("@lune/...")` 僅屬 Lune 環境。
- 外部腳本統一使用 `loadstring(game:HttpGet("原始碼網址"))()`；若回傳模組，接收其回傳值。網址須直接提供原始碼，不使用 `blob` 網頁。
- 既有部分腳本仍含本機檔案優先、舊網址、不同副檔名或 CoreGui 用法。這些是相容性歷史，不能當作新功能範本；未涉及本次任務時不整批遷移。修改載入行為前核對原有需求及呼叫端。
- 本機修改不會同步到遠端 `main`。遠端載入的實測須確認實際取得的模組版本，不能把本機測試成功當成遠端版本已更新。
- Executor 能力須檢查存在性與型別，必要時處理呼叫錯誤；不能僅根據 Executor 名稱推定支援。缺少必要能力時提供具體原因或停用受影響功能。
- 不把客戶端數值修改描述成已改變伺服器權威狀態；實際遊戲物件路徑、Remote 與封包形狀須有原始碼、快照或觀察依據，不能猜測。

## API 與依賴選型

- Executor 功能先查證 sUNC 對應文件 `https://github.com/sUNC-Utilities/docs`，優先使用已收錄且適用的 API；不足之處再搜尋 Pesde 並評估函式庫，最後才自行實作。其他新增通用 Luau 功能依 skill 先搜尋 Pesde。
- 沿用專案既有模組與接合方式，避免重複實作。sUNC 是文件與規範，不是執行期函式庫。
- 記錄查證來源與選型理由；網路無法存取不等於沒有 API 或套件，不編造查詢結果。目前儲存庫沒有 `pesde.toml`／`pesde.lock`，不要假設已有套件安裝流程。

## 共用引擎與遊戲適配

- 遊戲場景掃描、敵友與存活判斷、武器來源、協定及更新排程留在遊戲適配層。不要把遊戲名稱、固定場景路徑或 Remote 寫入通用核心。

## UI、狀態與卸載

- 新建 UI 根容器掛在 `gethui()` 回傳的有效 Instance，所有 UI 子元件放在其下。使用現有 BjzUi 公開 API，不在遊戲入口複製整份 UI 函式庫。
- 修改 UI 前核對實際載入版本、型別與呼叫端，尤其是 `CreateWindow → CreateTab → CreateSection` 與 `b` 前綴欄位；不要以舊版 `MainFrame` 等入口猜測新版介面。
- `workspace/BjzUi/UiConfig.json` 只保存 UI 函式庫通用外觀，不保存遊戲 Flag、遊戲分頁或玩家資料。各遊戲設定保存於 `workspace/BjzUi/<GameName>/<GameName>_<GameId>.json`，不得依玩家 UserId 分組；既有新路徑設定優先於內建預設值。
- 變更保存格式時明確說明相容性；不備份舊檔，不建立 `UiConfigLegacy.json`。使用者提供的遊戲設定可作為指定遊戲的內建預設值。
- 專案任何檔案的檔名均不得包含 `Delta`（不分大小寫），適用於既有檔案、新增檔案與更名後的檔案，不限遊戲入口或副檔名。遇到不符規則的檔名應更名，並同步更新路徑引用；不保留含該字樣的備份或相容檔案。
- 新增或更名的檔案與資料夾使用 PascalCase。遊戲入口可保留明確指定的 `_Bjz` 後綴，例如 `Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau`；固定工具檔名 `AGENTS.md`、`SKILL.md`、既有版本及副檔名保留。除上述檔名禁用規則外，不批次更名無關舊檔。文件使用 Rbx 稱呼平台。
- 支援重複執行：依既有入口卸載舊實例，避免重複事件、背景工作、UI 與 hook。新增資源必須有對應清理；部分初始化失敗也要能釋放已建立資源。
- `Destroy`／`Unload` 應可重複呼叫；解除自己持有的連線、RenderStep 與綁定，還原自己變更的狀態，只銷毀自己建立的物件。
- 還原方法表時確認目前仍由自己持有，不能覆蓋其他 wrapper。

## 驗證與交付

從儲存庫根目錄執行相關測試：

```powershell
rtk lune run Tests/EspEngine.spec.luau
rtk lune run Tests/SilentAimEngine.spec.luau
rtk lune run Tests/RaidTycoonEngines.spec.luau
```

- 新增邏輯測試聚焦行為、相容性、失敗與清理路徑；沒有對應測試的 UI／遊戲入口變更，至少檢查語法及呼叫端相容性。純文件變更不需執行遊戲測試。
- 離線測試使用投影、Raycast、lookAt 與 Executor API 替身，不證明真實 Executor hook、遊戲伺服器命中或 UI 互動已驗證。不要為迎合替身而破壞原生語意。
- 交付前檢查差異與空白錯誤；說明改了什麼、執行哪些驗證及尚未驗證的部分。工具不存在或測試失敗時如實回報，不宣稱通過。
