---
name: luau-code-guide
description: 撰寫、修改或審查 Luau／Rbx 程式碼時，Executor 功能先查 sUNC 文件並優先使用已收錄 API；未涵蓋的需求再搜尋 Pesde 並評估函式庫，最後才自行實作。套用 PascalCase、私人識別字 _ 前綴、類別 C 前綴、Enum E 前綴、boolean b 前綴、常數及型別與文件註解規範。適用於 .luau 與 Rbx Luau .lua 檔案。
---

# Luau 程式碼規範

依下列規範產生及審查 Luau 程式碼。修改既有程式時，將變更限制在任務範圍；若更名會影響公開 API、序列化資料或外部呼叫端，先確認相依使用處並維持相容性。

## Executor 功能先查 sUNC 文件

針對 Rbx Executor 執行環境，使用或實作某項功能前，必須先查閱 [sUNC 文件原始碼](https://github.com/sUNC-Utilities/docs)，確認是否收錄對應功能。可從儲存庫的 `docs` 目錄查找，或閱讀該儲存庫連結的[官方文件網站](https://docs.sunc.io/)。採用順序為：**sUNC 已收錄且適用的 API → Pesde 合適函式庫 → 自行實作**。

1. 依需求與同義關鍵字搜尋文件，開啟對應 API 頁面，確認正式名稱、參數、回傳值、限制、錯誤行為與使用範例；不要只根據函數名稱或記憶推測用法。實作前簡短列出採用的 API 與文件連結；相同任務中已查證且條件未變的結果可沿用。
2. 若文件收錄可滿足需求的功能，優先直接使用 Executor 提供的對應 API，只撰寫必要的遊戲邏輯與接合程式，不自行重寫相同能力，也不為此引入重複套件。sUNC 是 API 規範與相容性參考，不是需要下載執行才能使用的函式庫；不要把文件儲存庫當作執行期依賴。
3. 文件有收錄不代表目標 Executor 一定支援。根據專案指定的 Executor 與版本確認相容性，初始化時對實際使用的能力做存在性及型別檢查；必要時在呼叫邊界處理錯誤。函數存在只能證明可呼叫入口存在，不能當作語意完全相容或通過 sUNC 測試的證據。不要以 Executor 名稱或宣稱的相容率推定所有 API 可用。
4. 若文件未收錄對應功能，或已確認 API 無法滿足需求／目標 Executor 不支援，說明查詢結果與限制，再依下節搜尋 Pesde；沒有合適函式庫時才自行實作。只為未涵蓋的部分補上實作。缺少必要能力時回報具體原因或停用受影響功能，不靜默假裝成功。
5. 保留 sUNC API 的正式拼字與文件指定欄位名稱，不因 PascalCase 規則替外部 API 改名。不要假設 Executor 腳本具有 Rbx Studio ModuleScript 的 `script`、相對 `require` 路徑或伺服器權限；模組載入方式須符合專案實際執行環境。一般 Rbx Studio／伺服器腳本不強行引入 Executor API。
6. 若文件或網路無法存取，明確記錄尚未查證，不能把查詢失敗視為「sUNC 沒有此功能」，也不能編造 API。先繼續不依賴此選型的工作，待可查證後再決定同一功能的實作方式。

## 自建 UI

- 自建 UI 皆放於 `gethui()`；將 UI 根容器的 `Parent` 設為 `gethui()` 的回傳值，其餘 UI 元件放於該容器下。

## 外部腳本載入

- Rbx Executor 載入外部腳本時，統一使用 `loadstring(game:HttpGet("外部腳本的原始碼網址"))()`：先取得原始碼，再編譯並立即執行。網址必須直接回傳 Luau 原始碼，不使用 GitHub 的 `blob` 頁面網址。
- 外部腳本若回傳模組表，可使用 `local Module = loadstring(game:HttpGet("原始碼網址"))()` 接收結果。保留此載入方式，不自行改用 `require`、`readfile`、其他 HTTP API 或自訂下載器取代；使用者另有指定時依其要求。
- 此規則適用於外部腳本載入，作為前述 sUNC API 優先規則在此情境的明確指定；不需要為載入外部腳本再搜尋其他載入 API 或 Pesde 套件。

## 未由 sUNC 涵蓋的功能先查找函式庫

Executor 需求依上節先完成 sUNC 查詢；已採用適用的 sUNC API 時，不必再為同一能力搜尋 Pesde。其餘 Luau／Rbx 功能必須先查找 Pesde 是否已有可用的函式庫，再決定實作方式，不要先自行撰寫通用功能才補做搜尋。

1. 先查看 `pesde.toml`、`pesde.lock` 與專案既有封裝，確認已安裝的函式庫能否處理需求，避免引入重複依賴。
2. 使用需求及同義關鍵字搜尋 [Pesde](https://pesde.dev/)，並查閱候選套件的原始碼儲存庫與官方文件，確認實際 API、版本及 Rbx 執行環境相容性。使用當次可查證的資料，不只依賴記憶中的套件名稱或人氣。
3. 有多個候選時，比較社群採用度：可取得的下載／依賴使用數、GitHub stars、實際專案採用案例與社群推薦。附上來源與查詢日期；不同指標分開說明，不把 stars 等同於使用人數，沒有可靠資料時明確標示未知，不宣稱某套件最受歡迎。
4. 同時比較功能符合度、維護與發布狀況、文件及型別支援、授權、相依負擔，以及與既有架構的整合成本。在符合需求的候選中，優先採用社群廣泛使用且持續維護的函式庫；若選擇較少人採用的方案，說明具體原因。
5. 實作前簡短交代搜尋結果、候選比較及採用理由；多個候選可使用精簡表格。確認有合適函式庫時，優先整合並只撰寫必要的遊戲邏輯與接合程式，保留第三方 API 命名，不為符合本 skill 而修改套件原始碼。
6. 搜尋後沒有合適函式庫，才自行實作。記錄搜尋關鍵字、來源與未採用理由，例如沒有相關套件、功能不符、環境不相容或維護狀況不適合。不要為使用套件而引入無關依賴。
7. 若網路或套件索引無法存取，明確說明尚未完成搜尋，不能將查詢失敗當作「沒有函式庫」；可先進行不依賴選型的工作，不逕行自行實作同一項通用功能。相同需求且候選版本與條件未變時，可沿用本次任務已查證的選型結果。

## 命名

| 項目 | 規則 | 範例 |
| --- | --- | --- |
| 函數、物件方法 | PascalCase | `CalculateDamage`、`TakeDamage` |
| 私人方法與內部輔助函數 | `_` 前綴 + PascalCase | `_UpdateHealth`、`_WarnReporterError`、`_IsAlive` |
| 變數、參數、迴圈變數、自訂物件欄位 | PascalCase | `PlayerCount`、`DamageAmount`、`Index`、`Health` |
| boolean 變數、參數、自訂物件欄位 | 小寫 `b` 前綴 + PascalCase | `bIsAlive`、`bCanAttack`、`bEnabled` |
| 私人變數與私人欄位 | `_` 前綴 + PascalCase | `_CurrentHealth`、`_ErrorReporter` |
| 私人 boolean 變數與欄位 | `_b` 前綴 + PascalCase | `_bIsAlive`、`_bEnabled` |
| 可透過 `.new()` 建立實例的自訂類別及其物件型別 | `C` 前綴 + PascalCase | `CDamageTracker`、`CDamageTrackerType` |
| 自訂 Enum 表與對應列舉型別 | `E` 前綴 + PascalCase | `ECode`、`EWeaponType` |
| 一般模組表、資料型別與型別參數 | PascalCase | `AppError`、`HealthData`、`ItemType` |
| 常數 | SCREAMING_SNAKE_CASE | `MAX_HEALTH`、`DEFAULT_DAMAGE` |

- 常數指語意上固定的設定值或不可變值；不要把所有未重新賦值的區域變數視為常數。
- 私人變數與欄位使用 `_` + PascalCase，例如模組內部狀態 `_ErrorReporter`、物件內部欄位 `self._CurrentHealth`。若同時為 boolean，前綴順序固定為 `_b`，例如 `_bIsEnabled`。
- 私人方法與僅供模組內部使用的輔助函數也使用 `_` + PascalCase，例如 `CClass._UpdateHealth`、`local function _WarnReporterError(...)`。回傳 boolean 的私人方法使用 `_IsAlive`，不加 `b` 前綴。更名時同步更新呼叫處、回呼引用與註解。
- 私人指僅供模組或物件內部實作使用的狀態；不要因為使用 `local`，就替一般函數參數、暫存變數、模組匯入或對外回傳的類別／模組表一律加上 `_`。`self` 與常數仍遵循各自的既有命名規則。`_` 是存取慣例，不提供語言層級的存取限制。
- boolean 變數的 `b` 前綴是一般 PascalCase 變數命名的例外，也適用於推導為 boolean 的變數與 `boolean?` 可選值。boolean 常數仍使用 SCREAMING_SNAKE_CASE，例如 `DEFAULT_ENABLED`；回傳 boolean 的函數或方法仍使用 PascalCase，例如 `IsAlive`，不加 `b` 前綴。
- 建構函式固定使用小寫 `new`；物件接收者固定使用小寫 `self`。
- `C` 前綴用於可建構的自訂類別及其物件型別；一般工具模組與單純資料結構不加 `C`。持有實例的變數依其用途使用 PascalCase，例如 `Tracker`。
- 自訂 Enum 表與其型別使用 `E` 前綴，例如 `AppError.ECode`；Enum 成員作為常數使用 SCREAMING_SNAKE_CASE，例如 `ECode.INVALID_MAX_HEALTH`。平台與第三方類別、Enum 保留原名。
- 保留 Luau 關鍵字、內建函數、原生型別、metamethod 及平台／第三方 API 的原名，例如 `typeof`、`setmetatable`、`number`、`__index`、`game`、`script`、`require`、`Instance.new`。不要為了命名規範更改這些識別字。
- 外部資料欄位、協定指定名稱與既有 API 若有固定拼字，保留其相容性；新增的自訂識別字遵循上表。

## 物件與型別

| 使用情境 | 推薦語法 |
| --- | --- |
| 定義物件方法 | `function CClass.Method(self: CClassType, ...)` |
| 定義私人物件方法 | `function CClass._Method(self: CClassType, ...)` |
| 呼叫物件方法 | `InstanceValue:Method(...)` |
| 呼叫私人物件方法 | `self:_Method(...)` |
| 定義建構函式 | `function CClass.new(...)` |
| 宣告物件型別 | `export type CClassType = ...` |
| 取得帶有 metatable 的型別 | `typeof(setmetatable(...))` |

- 物件方法使用點號定義，明確標註第一個參數 `self` 的物件型別；呼叫時使用冒號，由語法自動傳入接收者。
- 不要在冒號呼叫中再傳入 `self`。`Object:Method(Value)` 等價於 `Object.Method(Object, Value)`。
- 建構函式與不接收物件的靜態函數以點號定義及呼叫，不額外傳入 `self`。
- 將類別表的 `__index` 指回類別表，並在建構函式中設定實例的 metatable。
- 使用 `export type` 宣告物件型別，透過 `typeof(setmetatable({} :: { ... }, CClass))` 同時描述實例欄位與 metatable 提供的方法。欄位型別必須與建構函式實際初始化的值一致。
- 建構函式標註回傳的物件型別；方法參數與回傳值在有助於界定介面時加入型別。不要以 `any` 掩蓋物件型別錯誤。
- `typeof(setmetatable(...))` 中的運算式用於型別推導，不要為了宣告型別在執行期額外建立實例或呼叫有副作用的建構函式。

## 最外層局部變數註解

- 腳本最外層（模組作用域）的局部變數若無法從名稱與初始化內容立即理解用途，必須在宣告前加入 `--[[ ... ]]` 區塊註解。此規則也適用於模組層級的常數、狀態、查找表與類別／模組表。
- 說明變數在該腳本中的職責；必要時補充由誰設定、何時讀取、初始值或 `nil` 的含義，以及是否由同一模組的呼叫共用。不要只重述「建立一個表格」或「初始值為 nil」。
- 名稱與初始化內容已清楚表達用途的宣告可以省略，例如直接取得同名 Rbx service 或載入同名模組。函數仍遵循每個函數必須撰寫註解的規則。

## 型別註解

- `type` 與 `export type` 若無法從名稱及結構立即理解用途，必須在宣告前加入 `--[[ ... ]]` 區塊註解；名稱與結構已清楚表達用途的簡單型別可以省略。
- 註解說明型別代表的概念、使用情境與重要限制。欄位含義、單位、可選值或聯集分支的差異不明顯時，補充其語意，避免只重述型別語法。
- 對於回呼型別，說明由誰、何時呼叫及相關行為，並使用 `@param`／`@return` 描述參數與回傳值作用。對於 metatable 型別，說明實例資料與方法的關係。修改型別時同步更新註解。

## 函數註解

- 每個函數都必須撰寫 `--[[ ... ]]` 區塊註解，包含建構函式、公開／私有方法、區域輔助函數、巢狀函數及匿名回呼；名稱簡單或實作只有一行也不例外。
- 區塊註解放在函數定義前。匿名函數放在所屬宣告、表格欄位或註冊呼叫前，清楚對應該回呼。
- 起始標記 `--[[` 與結束標記 `]]` 各自獨立一行，內容縮排一層。函數文件統一使用此格式。
- 第一行簡述函數用途，再依函數簽章列出參數與回傳值說明；有參數或回傳值時不得省略其作用。
- 每個參數都必須以 `@param 參數名稱 作用說明` 獨立一行，依簽章順序逐項描述，包含明確宣告的 `self`、可選參數及可變參數 `...`。適用時補充限制、單位、預設值與 `nil` 的含義。
- 每個回傳值都必須以 `@return 作用說明` 獨立一行；多回傳值依回傳順序逐項列出 `@return`，boolean 回傳值交代 `true`／`false` 各自代表的狀態，可選回傳值交代 `nil` 的含義。無回傳值（`: ()`）不寫 `@return`，不要將無回傳值寫成回傳 `nil`。
- 若會修改狀態、拋出錯誤、yield 或呼叫外部回呼，記錄呼叫端需要知道的行為。只有無參數且無回傳值的簡單函數，才可以僅用一句準確的用途說明。
- 型別由 Luau 型別註記表達；`@param` 與 `@return` 必須補充作用，不重複列出型別。標籤放在用途說明之後，先列出所有 `@param`，再列出所有 `@return`。
- 功能複雜的函數必須在同一個區塊註解中提供使用範例程式碼，例如需要多步設定、參數間有相依限制、涉及非同步流程／回呼生命週期，或回傳結果難以只靠文字理解的函數。簡單函數也可以提供範例。
- 範例放在 `@param`／`@return` 之後，以「使用範例：」引出，並使用標示 `lua` 的 Markdown fenced code block（起始行為三個反引號接 `lua`，結束行為三個反引號）。程式碼區塊位於 `--[[ ... ]]` 註解內，沿用本 skill 的命名規範。
- 範例須展示必要的初始化、實際呼叫方式與預期回傳值或狀態變化；需要既有物件或環境時註明前提，避免未說明的變數。範例應聚焦最小可理解的使用流程，必要時補上關鍵邊界或失敗情境，並與函數實際行為保持一致。
- 實作內使用 `--` 單行註解說明設計原因；不能以實作內的註解取代函數前的區塊註解。修改函數行為時，同步更新文件。
- 區塊內容避免直接包含結束標記 `]]`；需要描述此符號時改用文字說明，以免提前結束註解。

## 完整範例

以下為 ModuleScript 的內容；`--!strict` 用來示範型別檢查，既有檔案是否切換 strict 模式依任務需求決定。

````luau
--!strict

local DEFAULT_HEALTH = 100

--[[
	生命值追蹤物件的類別表，同時提供建構函式及實例方法。
	實例以此表作為 metatable，透過 __index 共用方法。
]]
local CDamageTracker = {}
CDamageTracker.__index = CDamageTracker

--[[
	生命值追蹤實例的型別，包含 Health 資料及 CDamageTracker 提供的方法。
	Health 為目前生命值，由建構函式初始化，並由傷害方法修改。
]]
export type CDamageTrackerType = typeof(setmetatable({} :: {
	Health: number,
}, CDamageTracker))

--[[
	建立生命值追蹤物件。

	@param InitialHealth 初始生命值；省略或傳入 nil 時使用 DEFAULT_HEALTH。
	@return 新建立的生命值追蹤物件，其 Health 為指定值或預設值。
]]
function CDamageTracker.new(InitialHealth: number?): CDamageTrackerType
	local self = {
		Health = if InitialHealth == nil then DEFAULT_HEALTH else InitialHealth,
	}

	return setmetatable(self, CDamageTracker)
end

--[[
	將生命值減去 DamageAmount，結果最低為 0。

	@param self 要修改生命值的追蹤物件。
	@param DamageAmount 要扣除的生命值；不驗證正負，負值會增加生命值。

	使用範例：
	```lua
	local Tracker = CDamageTracker.new(100)
	Tracker:TakeDamage(25)
	print(Tracker.Health) -- 75
	```
]]
function CDamageTracker.TakeDamage(self: CDamageTrackerType, DamageAmount: number): ()
	self.Health = math.max(0, self.Health - DamageAmount)
end

--[[
	回傳目前生命值是否大於 0。

	@param self 要檢查生命值的追蹤物件。
	@return true 表示生命值大於 0；false 表示生命值小於或等於 0。
]]
function CDamageTracker.IsAlive(self: CDamageTrackerType): boolean
	return self.Health > 0
end

return CDamageTracker
````

在另一個 Script 中呼叫（依實際專案調整模組路徑）：

```luau
local CDamageTracker = require(script.Parent.CDamageTracker)

local Tracker = CDamageTracker.new(100)
Tracker:TakeDamage(25)
local bIsAlive = Tracker:IsAlive()
```

## 審查與驗證

確認 Executor 功能已先查閱 sUNC 對應文件，已收錄且適用的 API 優先使用，正式名稱、參數與回傳值符合文件，並處理目標 Executor 的能力檢查與失敗情境。未涵蓋或不適用的功能須記錄原因，再完成 Pesde 搜尋與候選評估；選型說明有可查證的來源。採用現成函式庫時確認套件設定、版本鎖定與呼叫端一致，自行實作時確認已記錄 sUNC 與函式庫均無合適方案的依據（非 Executor 需求只檢查函式庫）。

確認外部腳本使用 `loadstring(game:HttpGet("原始碼網址"))()` 載入，網址直接回傳原始碼，且需要模組回傳值時已正確接收。

確認私人變數、欄位、方法與內部輔助函數使用 `_` + PascalCase，私人 boolean 變數使用 `_b` + PascalCase，且型別欄位、初始化、讀寫與呼叫處、回呼引用及相關註解同步一致。

確認可建構類別及其物件型別使用 `C` 前綴、自訂 Enum 表及其型別使用 `E` 前綴，並同步檢查呼叫端與型別引用。

檢查腳本最外層局部變數的職責是否清楚；不能從名稱與初始化內容立即理解時，確認宣告前已有說明作用的區塊註解。

檢查 `type` 與 `export type` 的用途是否能從名稱與結構立即理解；不能時，確認已有說明用途與重要語意的區塊註解。

確認自訂名稱遵循規範、boolean 變數使用 `b` 前綴、`new`／`self` 等例外保留原名、方法定義和呼叫正確傳遞接收者，以及匯出型別與實例欄位一致。逐一確認每個函數都有對應的 `--[[ ... ]]` 區塊註解，所有參數與回傳值均使用 `@param`／`@return` 說明作用，且標籤順序、參數名稱及內容與簽章及實際行為一致。功能複雜的函數須有標示 `lua` 的範例程式碼區塊，並確認範例的前提、呼叫及預期結果正確。更名時檢查任務範圍內的引用，避免只改定義。若專案已有 Luau 型別檢查或測試指令，使用既有工具驗證；無可用工具時，明確說明僅完成靜態檢閱。

## 來源與適用範圍

物件型別註記方式參考 [Rbx Lua Style Guide：Prototype-based classes](https://roblox.github.io/lua-style-guide/#prototype-based-classes)，其示範 `export type`、`typeof(setmetatable(...))` 與明確標註 `self` 型別的點號方法定義。此 skill 的 PascalCase 命名是使用者自訂規範，不代表官方指南要求所有變數與函數都使用 PascalCase。未列出的風格沿用專案既有慣例。
