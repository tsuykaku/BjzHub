-- 2 Player Raid Tycoon | place 126710589265077 | Bjz UI
-- Based on the supplied November 2026 client snapshot, not live-server testing.
-- No anti-cheat bypass or ban protection is claimed.
-- Server-owned infinite ammunition and wall penetration are unavailable.
-- Fire-rate scaling affects client cadence only; server rate limits remain authoritative.
-- Instant reload removes client timing only; server reload validation remains authoritative.
-- Auto rebirth spends in-game cash and resets base progress when RebirthReady is true.
-- Stop: getgenv().RaidTycoonBjz:Unload()
local _Environment = (getgenv and getgenv()) or _G
if _Environment.RaidTycoonBjz and _Environment.RaidTycoonBjz.Unload then
	_Environment.RaidTycoonBjz:Unload()
end
assert(type(gethui) == "function", "需要 gethui()；所有自建 UI 皆放於 gethui()")
assert(type(loadstring) == "function", "執行環境不支援 loadstring")
local UIParent = gethui()
local NewInstance = Instance.new
local GetIdentity = _Environment.getthreadidentity or getthreadidentity or getidentity
local SetIdentity = _Environment.setthreadidentity or setthreadidentity or setidentity
--[[
	初始 Executor 執行身分；建立 UI 時保存，跨回呼繪製時暫時恢復，nil 表示無法取得。
]]
local _UIIdentity
if type(GetIdentity) == "function" then
	local bSuccess, Value = pcall(GetIdentity)
	if bSuccess then
		_UIIdentity = Value
	end
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
assert(LocalPlayer, "請於客戶端執行")
--[[
	腳本工作階段；對外保留 RaidTycoonBjz 的控制方法，集中管理卸載、診斷及背景工作。
]]
local _State = {
	Version = "2.11.0",
	StartedAt = os.clock(),
	History = {},
	Counts = {},
	bAlive = true,
	Connections = {},
	Restores = {},
	Errors = {},
	Modules = {},
}
_State.Options = {
	Reload = false,
	bInstantReload = false,
	Recoil = false,
	bNoSpread = false,
	Auto = false,
	Aim = false,
	AimPlayers = true,
	AimNPC = true,
	AimPart = "Head",
	AimPriority = "離游標最近",
	bAimMarker = true,
	bESPLabels = true,
	bESPTracers = false,
	Allies = false,
	Enemies = false,
	Collect = false,
	Produce = false,
	Build = false,
	Rebirth = false,
	Rate = 1,
	FOV = 180,
	Distance = 5000,
	Interval = 0.5,
	ProduceInterval = 0,
}
--[[
	共用 UI 選項。既有公開選項鍵（如 Aim、Reload）維持原名以保留外部存取相容性；新增布林鍵採 b 前綴。
]]
local _Options = _State.Options
--[[
	視窗、原生覆蓋層及遊戲彈匣模組；由初始化設定，nil 表示尚未建立。
]]
local _Window, _Effects, _Magazine
--[[
    共用引擎由 _Main 初始化，Unload 負責銷毀；初始化前為 nil。
]]
local _EspEngine, _SilentAimEngine
--[[
	弱鍵 NPC 登錄表；場景新增 Humanoid 時填入，候選收集會移除失效項目。
]]
local _NPCs = setmetatable({}, { __mode = "k" })
--[[
	以 UserId 索引的好友查詢狀態，背景工作更新，射擊路徑只讀取快取。
]]
local _Friends = {}
--[[
	弱鍵武器觀察紀錄，避免同一工具重複安裝屬性事件。
]]
local _ToolObservers = setmetatable({}, { __mode = "k" })
--[[
	保留最近二十把武器的診斷摘要，收槍後仍供除錯輸出使用。
]]
local _WeaponRecords = {}
--[[
	戰鬥採樣與事件緩衝；本地通知與伺服器事件分別累計，不代表命中確認。
]]
local _Combat = { Samples = {}, Events = {}, RemoteShots = 0, LocalShots = 0, Last = nil }
--[[
	註冊事件並加入卸載清單；卸載時統一斷線。
	@param Signal 要註冊的 Rbx 事件訊號。
	@param Callback 同步執行的回呼；事件回呼由 Rbx 訊號觸發。
	@return 受管理的事件連線。

	使用範例：
	```lua
	-- 前提：工作階段已初始化；角色加入事件統一由 Unload 斷線。
	local Connection = _Watch(workspace.DescendantAdded, _CacheHumanoid)
	```
]]
local function _Watch(Signal, Callback)
	local Connection = Signal:Connect(Callback)
	table.insert(_State.Connections, Connection)
	return Connection
end
--[[
	暫時切回初始 UI 執行身分執行回呼，完成或拋錯後還原原身分。
	@param Callback 同步執行的回呼；事件回呼由 Rbx 訊號觸發。
	@return 回呼的全部回傳值；回呼錯誤會在還原身分後重新拋出。

	使用範例：
	```lua
	local Value = _UiContext(function() return _UIIdentity end)
	-- 回呼執行後恢復呼叫前的執行身分。
	```
]]
local function _UiContext(Callback)
	local Previous
	if _UIIdentity ~= nil and type(GetIdentity) == "function" and type(SetIdentity) == "function" then
		local bSuccess, Value = pcall(GetIdentity)
		if bSuccess then
			Previous = Value
			pcall(SetIdentity, _UIIdentity)
		end
	end
	local Result = table.pack(xpcall(Callback, debug.traceback))
	if Previous ~= nil then
		pcall(SetIdentity, Previous)
	end
	if not Result[1] then
		error(Result[2], 0)
	end
	return table.unpack(Result, 2, Result.n)
end
--[[
	本腳本修改過的武器晃動原值；關閉選項或卸載時條件式還原。
]]
local _OriginalShake = setmetatable({}, { __mode = "k" })
--[[
	武器原始開火間隔與最近套用值；遊戲自行修改時更新基準。
]]
local _OriginalRates = setmetatable({}, { __mode = "k" })
--[[
	武器擴散屬性與連射擴散上限；零值覆寫武器屬性或遊戲預設設定。
]]
local SPREAD_ATTRIBUTES = { "HipSpread", "AdsSpread", "MoveSpread", "BloomPerShot", "BloomMax" }
--[[
	逐武器保存擴散屬性原值，包含原本未設定的屬性；關閉選項或卸載時還原。
]]
local _OriginalSpread = setmetatable({}, { __mode = "k" })
--[[
	武器換彈、逐發填裝與填裝退出的本地等待時間欄位。
]]
local RELOAD_DURATION_ATTRIBUTES = { "ReloadTime", "ShellTime", "ShellExit" }
--[[
	逐武器保存換彈時間原值，包含未設定的屬性；關閉或卸載時條件式還原。
]]
local _OriginalReloadDurations = setmetatable({}, { __mode = "k" })
--[[
	武器切為全自動前的開火模式，用於關閉選項及卸載還原。
]]
local _OriginalModes = setmetatable({}, { __mode = "k" })
--[[
	以互動物件索引的本地再次嘗試時間，避免失敗互動被立即重送。
]]
local _Cooldowns = setmetatable({}, { __mode = "k" })
--[[
	追加活動紀錄，最多保留三十筆。
	@param Kind 既有功能或事件分類鍵，公開選項名稱保持相容。
	@param Message 要記錄的活動內容。
]]
local function _Record(Kind, Message)
	table.insert(_State.History, string.format("+%.2fs [%s] %s", os.clock() - _State.StartedAt, Kind, Message))
	if #_State.History > 30 then
		table.remove(_State.History, 1)
	end
end
--[[
	按錯誤鍵去重、記錄並輸出警告。
	@param Key 既有屬性、模組方法或選項鍵。
	@param Error 待記錄的錯誤值。
]]
local function _Report(Key, Error)
	if _State.Errors[Key] ~= tostring(Error) then
		_State.Errors[Key] = tostring(Error)
		_Record("Error/" .. Key, tostring(Error))
		warn("[RaidTycoonBjz/" .. Key .. "] " .. tostring(Error))
	end
end
--[[
	僅還原仍由本腳本設定為 AUTO 的武器模式，清除保存紀錄。
]]
local function _RestoreModes()
	for Tool, Saved in pairs(_OriginalModes) do
		--[[
			還原本腳本設定的單一武器開火模式。
		]]
		pcall(function()
			if Tool:GetAttribute("FireMode") == "AUTO" then
				Tool:SetAttribute("FireMode", Saved.Value)
			end
		end)
		_OriginalModes[Tool] = nil
	end
end
--[[
	僅還原仍為零的武器晃動倍率，清除保存紀錄。
]]
local function _RestoreShake()
	for Tool, Saved in pairs(_OriginalShake) do
		--[[
			還原本腳本設定的單一武器晃動倍率。
		]]
		pcall(function()
			if Tool:GetAttribute("ShakeScale") == 0 then
				Tool:SetAttribute("ShakeScale", Saved.Value)
			end
		end)
		_OriginalShake[Tool] = nil
	end
end
--[[
	僅還原仍符合本腳本套用值的開火間隔，清除保存紀錄。
]]
local function _RestoreRates()
	for Tool, Saved in pairs(_OriginalRates) do
		--[[
			還原本腳本設定的單一武器開火間隔。
		]]
		pcall(function()
			if Tool:GetAttribute("FireInterval") == Saved.Applied then
				Tool:SetAttribute("FireInterval", Saved.Value)
			end
		end)
		_OriginalRates[Tool] = nil
	end
end
--[[
	僅還原仍為本腳本歸零值的擴散屬性；遊戲已改寫的值保持不變。
]]
local function _RestoreSpread()
	for Tool, Attributes in pairs(_OriginalSpread) do
		for Key, Saved in pairs(Attributes) do
			--[[
				還原單一武器擴散屬性，原值為 nil 時移除覆寫屬性；外層攔截失效物件錯誤。
			]]
			pcall(function()
				if Tool:GetAttribute(Key) == 0 then
					Tool:SetAttribute(Key, Saved.Value)
				end
			end)
		end
		_OriginalSpread[Tool] = nil
	end
end

--[[
	歸零武器的腰射、瞄準、移動與連射擴散，遊戲更新屬性時同步更新還原基準。
	@param Tool 本機目前裝備的武器。

	使用範例：
	```lua
	-- 前提：Tool 為目前裝備武器，bNoSpread 已啟用。
	_ApplyNoSpread(Tool)
	_RestoreSpread() -- 關閉功能時還原原值，包含原本未設定的屬性。
	```
]]
local function _ApplyNoSpread(Tool)
	local Attributes = _OriginalSpread[Tool]
	if not Attributes then
		Attributes = {}
		_OriginalSpread[Tool] = Attributes
	end
	for _, Key in ipairs(SPREAD_ATTRIBUTES) do
		local Current = Tool:GetAttribute(Key)
		local Saved = Attributes[Key]
		if not Saved then
			Saved = { Value = Current }
			Attributes[Key] = Saved
		elseif Current ~= 0 then
			Saved.Value = Current
		end
		if Current ~= 0 then
			Tool:SetAttribute(Key, 0)
		end
	end
end

--[[
	還原仍由本腳本歸零的換彈時間；遊戲後續改寫的屬性保持不變。
]]
local function _RestoreReloadDurations()
	for Tool, Attributes in pairs(_OriginalReloadDurations) do
		for Key, Saved in pairs(Attributes) do
			--[[
				還原單一換彈時間，原值為 nil 時移除覆寫；外層攔截失效物件錯誤。
			]]
			pcall(function()
				if Tool:GetAttribute(Key) == 0 then
					Tool:SetAttribute(Key, Saved.Value)
				end
			end)
		end
		_OriginalReloadDurations[Tool] = nil
	end
end

--[[
	歸零目前武器的本地換彈等待時間，不更改彈藥、換彈旗標或伺服器請求內容。
	遊戲改寫時間欄位後，下次套用會更新還原基準。
	@param Tool 本機目前裝備的武器。

	使用範例：
	```lua
	-- 前提：Tool 為裝備武器，bInstantReload 已啟用。
	_ApplyInstantReload(Tool) -- 在原生換彈函數讀取時間前套用。
	_RestoreReloadDurations() -- 關閉功能時還原原值。
	```
]]
local function _ApplyInstantReload(Tool)
	local Attributes = _OriginalReloadDurations[Tool]
	if not Attributes then
		Attributes = {}
		_OriginalReloadDurations[Tool] = Attributes
	end
	for _, Key in ipairs(RELOAD_DURATION_ATTRIBUTES) do
		local Current = Tool:GetAttribute(Key)
		local Saved = Attributes[Key]
		if not Saved then
			Saved = { Value = Current }
			Attributes[Key] = Saved
		elseif Current ~= 0 then
			Saved.Value = Current
		end
		if Current ~= 0 then
			Tool:SetAttribute(Key, 0)
		end
	end
end

--[[
	依倍率調整本地開火間隔；遊戲更新屬性時重新取得基準。
	@param Tool 目前武器工具；允許 nil 的讀取流程會退回預設值。
	@param Config 遊戲模組提供的設定表；尚未載入時可為 nil。
]]
local function _ApplyRate(Tool, Config)
	if _Options.Rate == 1 then
		_RestoreRates()
		return
	end
	local Saved = _OriginalRates[Tool]
	local Current = Tool:GetAttribute("FireInterval")
	local Fallback = Config and Config.Gun and Config.Gun.FireInterval
	if not Saved then
		local Base = type(Current) == "number" and Current or Fallback
		if type(Base) ~= "number" or Base <= 0 then
			return
		end
		Saved = { Value = Current, Base = Base }
		_OriginalRates[Tool] = Saved
	elseif Current ~= Saved.Applied then
		-- Refresh the baseline if the game itself updates this tool's stat.
		-- Config may be unavailable while attributes are being reset/replaced.
		local Base = type(Current) == "number" and Current or Fallback
		if type(Base) ~= "number" or Base <= 0 then
			_OriginalRates[Tool] = nil
			return
		end
		Saved.Value = Current
		Saved.Base = Base
	end
	Saved.Applied = math.max(0.005, Saved.Base / math.clamp(_Options.Rate, 0.25, 5))
	if Current ~= Saved.Applied then
		Tool:SetAttribute("FireInterval", Saved.Applied)
	end
end
--[[
	停止自動化、斷開事件、還原修改並銷毀 UI 及兩個引擎；可重複呼叫。
	@param self 接收操作的腳本工作階段；Unload 可重複呼叫。

	使用範例：
	```lua
	local Runtime = getgenv().RaidTycoonBjz
	Runtime:Unload()
	Runtime:Unload() -- 再次呼叫不重複清理。
	```
]]
function _State.Unload(self: typeof(_State))
	if not self.bAlive then
		return
	end
	if self.StopTreadmill then
		self:StopTreadmill("unload")
	end
	self.bAlive = false
	for _, Connection in ipairs(self.Connections) do
		Connection:Disconnect()
	end
	_RestoreModes()
	_RestoreShake()
	_RestoreRates()
	_RestoreSpread()
	_RestoreReloadDurations()
	if _Magazine then
		local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
		if Tool and type(Tool:GetAttribute("Ammo")) == "number" then
			_Magazine.ammo = Tool:GetAttribute("Ammo")
		end
	end
	for Index = #self.Restores, 1, -1 do
		pcall(self.Restores[Index])
	end
	if _SilentAimEngine then
		--[[
			在 UI 執行身分下解除引擎綁定並銷毀其目標圈。
		]]
		_UiContext(function()
			_SilentAimEngine:Destroy()
		end)
	end
	if _EspEngine then
		--[[
			在初始 UI 身分下銷毀 ESP 引擎。
		]]
		_UiContext(function()
			_EspEngine:Destroy()
		end)
	end
	if _Effects then
		_Effects:Destroy()
	end
	if _Window and not _Window.bDestroyed then
		_Window:Destroy()
	end
	if _Environment.RaidTycoonBjz == self then
		_Environment.RaidTycoonBjz = nil
	end
end
_Environment.RaidTycoonBjz = _State
--[[
	包裝已知模組方法並登錄還原器，卸載時保留其他擁有者後續的修改。
	@param Owner 直接持有待包裝函數的模組表。
	@param Key 既有屬性、模組方法或選項鍵。
	@param MakeWrapper 接收原函數並同步回傳包裝函數的工廠。

	使用範例：
	```lua
	-- 前提：Owner 為直接持有 Fire 函數的遊戲模組。
	_Patch(Owner, "Fire", function(Original) return Original end)
	-- Unload 僅還原仍由此包裝器持有的欄位。
	```
]]
local function _Patch(Owner, Key, MakeWrapper)
	assert(type(Owner[Key]) == "function", "缺少函式 " .. Key)
	local Original = Owner[Key]
	local Wrapped = MakeWrapper(Original)
	Owner[Key] = Wrapped
	--[[
		僅在方法欄位仍由本包裝器持有時還原原函數。
	]]
	table.insert(_State.Restores, function()
		if Owner[Key] == Wrapped then
			Owner[Key] = Original
		end
	end)
end
--[[
	載入遊戲 ModuleScript，記錄載入結果；require 可能 yield。
	@param Instance 要 require 的遊戲 ModuleScript；nil 表示模組尚不存在。
	@return 模組回傳值；缺少模組或載入失敗時為 nil。
]]
local function _LoadModule(Instance)
	if not Instance then
		return nil
	end
	local bSuccess, Value = pcall(require, Instance)
	if bSuccess then
		_State.Modules[Instance:GetFullName()] = "OK"
		return Value
	end
	_State.Modules[Instance:GetFullName()] = tostring(Value)
	_Report(Instance.Name, Value)
	return nil
end
--[[
	共用引擎原始碼網址；版本查詢參數用來避開執行器保留的舊網址下載結果。
]]
local SILENT_AIM_MODULE_URL =
	"https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/SilentAimEngine.luau?api=2&release=2.10.1"
local SILENT_AIM_API_VERSION = 2
--[[
	此遊戲實際使用的引擎方法；快取與下載結果皆須通過同一份介面檢查。
]]
local SILENT_AIM_REQUIRED_METHODS = {
	"new",
	"CreateBinding",
	"SetTargetMarkerParent",
	"RenderTargetMarker",
	"ClearSelection",
	"Configure",
	"Select",
	"BindMethod",
	"Destroy",
	"GetLastError",
}

--[[
	檢查共用引擎的模組版本與完整介面，不把只含版本號的舊快取視為可用。
	@param Module 快取或下載執行後的模組回傳值。
	@return 不相容原因；nil 表示版本與方法皆符合要求。
]]
local function _SilentAimModuleIssue(Module): string?
	if type(Module) ~= "table" then
		return "模組回傳 " .. type(Module) .. "，預期為 table"
	end
	if Module.API_VERSION ~= SILENT_AIM_API_VERSION then
		return "API_VERSION=" .. tostring(Module.API_VERSION) .. "，預期為 " .. SILENT_AIM_API_VERSION
	end
	for _, Key in ipairs(SILENT_AIM_REQUIRED_METHODS) do
		if type(Module[Key]) ~= "function" then
			return "缺少方法 " .. Key .. "（實際型別 " .. type(Module[Key]) .. "）"
		end
	end
	return nil
end

--[[
	重用相容的引擎快取；否則以原始碼網址載入，不相容或下載失敗時最多重試一次。
	重試使用新的查詢參數；只有通過驗證的模組才寫入快取，失敗會列出具體原因。
	此處只下載並執行共用模組，不安裝 hook；呼叫前應先卸載舊遊戲工作階段。
	@return 與本腳本相容的共用引擎模組；兩次載入都失敗時拋出錯誤。

	使用範例：
	```lua
	local CSilentAimEngine = _LoadSilentAimEngine()
	-- 模組已通過 API 版本與本腳本使用的方法檢查，尚未建立引擎實例。
	```
]]
local function _LoadSilentAimEngine()
	local Cached = _Environment.RaidTycoonSilentAimEngineModule
	local CacheIssue = _SilentAimModuleIssue(Cached)
	if not CacheIssue then
		return Cached
	end
	local Failures = {}
	for Attempt = 1, 2 do
		local URL = SILENT_AIM_MODULE_URL
		if Attempt == 2 then
			URL ..= "&reload=" .. tostring(os.clock())
		end
		--[[
			依專案慣例取得原始碼並立即編譯執行，讓外層回報下載或執行錯誤。
			@return 遠端程式回傳的模組值，仍須通過介面檢查。
		]]
		local bSuccess, Module = pcall(function()
			return loadstring(game:HttpGet(URL))()
		end)
		local Issue = if bSuccess then _SilentAimModuleIssue(Module) else tostring(Module)
		if not Issue then
			_Environment.RaidTycoonSilentAimEngineModule = Module
			return Module
		end
		table.insert(Failures, "第 " .. Attempt .. " 次：" .. Issue)
	end
	error(
		"SilentAim 引擎載入失敗；快取："
			.. CacheIssue
			.. "；"
			.. table.concat(Failures, "；")
			.. "。請確認 GitHub main 的 Core/Features/SilentAimEngine.luau 已同步為 API 2。",
		0
	)
end

--[[
	尋找目前裝備且具備 GunProto 武器屬性的工具。
	@return 已裝備武器；角色不存在或未持槍時為 nil。
]]
local function _ToolNow()
	local Character = LocalPlayer.Character
	if not Character then
		return nil
	end
	for _, Owner in ipairs(Character:GetChildren()) do
		if
			Owner:IsA("Tool")
			and (
				Owner:GetAttribute("GunProto") == true
				or Owner:GetAttribute("Ammo") ~= nil
				or Owner:GetAttribute("FireMode") ~= nil
			)
		then
			return Owner
		end
	end
	return nil
end
--[[
	取得本機存活角色、Humanoid 與根部位。
	@return 存活角色；死亡或必要部位缺失時為 nil。
	@return 該角色的 Humanoid；無有效角色時不回傳。
	@return 該角色的根部位；無有效角色時不回傳。
]]
local function _Living()
	local Character = LocalPlayer.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	if Humanoid and Root and Humanoid.Health > 0 then
		return Character, Humanoid, Root
	end
	return nil
end
--[[
	以基地識別或有效隊伍判斷玩家是否為隊友。
	@param Player 要查詢或處理的玩家。
	@return true 表示隊友，false 表示不屬於相同陣營。
]]
local function _Allied(Player)
	local Id = LocalPlayer:GetAttribute("PlotId")
	if Id ~= nil then
		return Player:GetAttribute("PlotId") == Id
	end
	return LocalPlayer.Team ~= nil
		and not LocalPlayer.Neutral
		and not Player.Neutral
		and Player.Team == LocalPlayer.Team
end
--[[
	從 Shared.Tycoon 與 GunProto 載入的遊戲模組；初始化前為 nil，缺少時停用依賴其規則的流程。
]]
local _Rules, _Own, _Me, _TycoonConfig, _GunConfig, _TeamLook, _GunTargets
--[[
	優先讀取遊戲基地色，失敗時退回隊伍色或中立色。
	@param Player 要查詢或處理的玩家。
	@return 玩家目前的陣營顏色。
]]
local function _FactionColor(Player)
	local PlotId = Player:GetAttribute("PlotId")
	if PlotId ~= nil and _TeamLook then
		for _, Plot in ipairs(CollectionService:GetTagged("TycoonPlot")) do
			if (Plot:GetAttribute("PlotId") or Plot.Name) == PlotId then
				local bSuccess, Color = pcall(_TeamLook.ofPlot, Plot)
				if bSuccess and typeof(Color) == "Color3" then
					return Color
				end
			end
		end
	end
	if Player.Team and not Player.Neutral then
		return Player.Team.TeamColor.Color
	end
	if _TeamLook then
		local bSuccess, Color = pcall(_TeamLook.neutral)
		if bSuccess and typeof(Color) == "Color3" then
			return Color
		end
	end
	return Player.TeamColor.Color
end
--[[
	取得好友狀態快取；過期時排入背景查詢，不在此發送網路請求。
	@param Player 要查詢或處理的玩家。
	@return 該玩家的好友查詢狀態與期限。
]]
local function _QueueFriendCheck(Player)
	local Id = Player.UserId
	local Cached = _Friends[Id]
	if Cached and Cached.Status == "checking" then
		return Cached
	end
	if not Cached or Cached.Expires <= os.clock() then
		Cached = { Name = Player.Name, Status = "queued", Expires = os.clock() + 30 }
		_Friends[Id] = Cached
	end
	return Cached
end
--[[
	依好友快取判斷是否禁止瞄準；未知與錯誤狀態採排除。
	@param Player 要查詢或處理的玩家。
	@return true 表示好友或尚未確認，false 表示已確認非好友。
]]
local function _FriendBlocked(Player)
	-- No network calls or yielding on the render/fire path. Unknown/error states are excluded.
	local Cached = _QueueFriendCheck(Player)
	return Cached.Status ~= "notfriend"
end
--[[
	在背景查詢 Rbx 好友狀態並更新快取，可能 yield；卸載後丟棄結果。
	@param Player 要查詢或處理的玩家。

	使用範例：
	```lua
	-- 僅在可 yield 的背景工作呼叫；射擊路徑使用快取。
	_QueueFriendCheck(LocalPlayer)
	_ResolveFriend(LocalPlayer)
	```
]]
local function _ResolveFriend(Player)
	local Cached = _QueueFriendCheck(Player)
	if Cached.Status ~= "queued" then
		return
	end
	Cached.Status = "checking"
	--[[
		透過 Rbx 非同步 API 查詢本機與該玩家的好友關係，可能 yield。
		@return true 表示好友，false 表示非好友。
	]]
	local bSuccess, bIsFriend = pcall(function()
		return LocalPlayer:IsFriendsWithAsync(Player.UserId)
	end)
	local Api = "IsFriendsWithAsync"
	if not bSuccess then
		Api = "IsFriendsWith (compatibility)"
		--[[
			非同步 API 失敗時改用相容好友查詢，可能 yield。
			@return true 表示好友，false 表示非好友。
		]]
		bSuccess, bIsFriend = pcall(function()
			return LocalPlayer:IsFriendsWith(Player.UserId)
		end)
	end
	if not _State.bAlive or _Friends[Player.UserId] ~= Cached then
		return
	end
	Cached.API = Api
	Cached.CheckedAt = os.clock()
	if bSuccess and type(bIsFriend) == "boolean" then
		Cached.Status = bIsFriend and "friend" or "notfriend"
		Cached.Expires = os.clock() + 30
		Cached.Error = nil
	else
		Cached.Status = "error"
		Cached.Error = tostring(bIsFriend)
		Cached.Expires = os.clock() + 10
		_Report("FriendCheck/" .. Player.Name, bIsFriend)
	end
end
--[[
	套用玩家敵友、好友、血量、無敵及遊戲傷害規則。
	@param Player 要查詢或處理的玩家。
	@return true 表示可瞄準敵方玩家，false 表示應排除。
]]
local function _Enemy(Player)
	if Player == LocalPlayer or _Allied(Player) or _FriendBlocked(Player) then
		return false
	end
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if
		not Humanoid
		or Humanoid.Health <= 0
		or Character:GetAttribute("Invulnerable") == true
		or Character:FindFirstChildOfClass("ForceField")
	then
		return false
	end
	if _Rules then
		local bSuccess, bAllowed = pcall(_Rules.shotLands, LocalPlayer, Player)
		return bSuccess and bAllowed == true
	end
	return Player:GetAttribute("Passive") ~= true
end
--[[
	登錄非玩家角色的 Humanoid，供 NPC 候選來源使用。
	@param Object 需要檢查的場景物件。
]]
local function _CacheHumanoid(Object)
	if not Object:IsA("Humanoid") then
		return
	end
	local Model = Object.Parent
	if Model and Model:IsA("Model") and not Players:GetPlayerFromCharacter(Model) then
		_NPCs[Model] = Object
	end
end
--[[
	套用 NPC 的血量、無敵、盟友與遊戲傷害規則。
	@param Model 目標角色或 NPC 模型。
	@param Humanoid 角色血量與狀態來源。
	@return true 表示可瞄準敵方 NPC，false 表示應排除。
]]
local function _NpcEnemy(Model, Humanoid)
	if
		not Model:IsDescendantOf(workspace)
		or Humanoid.Health <= 0
		or Model == LocalPlayer.Character
		or Players:GetPlayerFromCharacter(Model)
		or Model:GetAttribute("Invulnerable") == true
		or Model:GetAttribute("Shielded") == true
		or Model:GetAttribute("MedigunAllyOf") == LocalPlayer.UserId
		or Model:FindFirstChildOfClass("ForceField")
	then
		return false
	end
	if _GunTargets then
		local bSuccess, Relation = pcall(_GunTargets.relation, Model, Humanoid)
		return bSuccess and Relation == "enemy"
	end
	if _Rules and _Rules.shotLandsOnNpc then
		local bSuccess, bAllowed = pcall(_Rules.shotLandsOnNpc, Humanoid, nil, LocalPlayer, LocalPlayer.Character)
		return bSuccess and bAllowed == true
	end
	return false
end
--[[
	更新目標提示資料；Part 為 nil 時清除目標。
	@param Part 互動或目標部位；SetTarget 允許 nil 以清除目標。
	@param Name 顯示名稱。
	@param Kind 既有功能或事件分類鍵，公開選項名稱保持相容。
]]
local function _SetTarget(Part, Name, Kind)
	if Part then
		_State.Target = { Part = Part, Name = Name, Kind = Kind }
	else
		_State.Target = nil
		if _SilentAimEngine then
			_SilentAimEngine:ClearSelection()
		end
	end
end
--[[
	依部位選項及備援順序取得角色瞄準部位。
	@param Model 目標角色或 NPC 模型。
	@return 可用部位，最後退回 PrimaryPart；均不存在時為 nil。
]]
local function _ChooseAimPart(Model)
	local Names = _Options.AimPart == "Head" and { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }
		or (
			_Options.AimPart == "Root" and { "HumanoidRootPart", "UpperTorso", "Torso", "Head" }
			or { "UpperTorso", "Torso", "HumanoidRootPart", "Head" }
		)
	for _, Name in ipairs(Names) do
		local Part = Model:FindFirstChild(Name)
		if Part and Part:IsA("BasePart") then
			return Part
		end
	end
	return Model.PrimaryPart
end
--[[
	結合距離選項與武器射程，不依傷害衰減距離排除目標。
	@param Tool 目前武器工具；允許 nil 的讀取流程會退回預設值。
	@return 此次武器的有效搜尋距離，單位為 studs。
]]
local function _AimRange(Tool)
	--[[
		優先取得武器數值屬性，缺少時讀取遊戲預設設定。
		@param Key 既有屬性、模組方法或選項鍵。
		@return 數值設定；屬性與預設都不是數字時為 nil。
	]]
	local function _Stat(Key): number?
		local Value = Tool and Tool:GetAttribute(Key)
		if type(Value) == "number" then
			return Value
		end
		local Baseline = _GunConfig and _GunConfig.Gun[Key]
		if type(Baseline) == "number" then
			return Baseline
		end
		return nil
	end
	local Limit = _Options.Distance
	local Range = _Stat("Range")
	if type(Range) == "number" then
		Limit = math.min(Limit, math.max(0, Range))
	end
	return Limit
end
--[[
	優先使用槍口 Attachment，其次為本機根部位，最後為相機位置。
	@param Camera 當前有效相機。
	@param Tool 目前武器工具；允許 nil 的讀取流程會退回預設值。
	@return 本次射擊的世界座標原點。
]]
local function _ShotOrigin(Camera, Tool)
	local Muzzle = Tool and Tool:FindFirstChild("Muzzle", true)
	if Muzzle and Muzzle:IsA("Attachment") then
		return Muzzle.WorldPosition
	end
	local _, _, Root = _Living()
	return Root and Root.Position or Camera.CFrame.Position
end
--[[
    以即時玩家／NPC 狀態建立候選快照；沿用遊戲敵友與好友保護規則。
    @param Context 引擎提供的射擊上下文，此處不需要讀取。
    @return 有效目標及顯示資訊；部位缺失時不加入候選。
]]
local function _GetAimCandidates(Context)
	local Candidates = {}
	--[[
        將已通過遊戲規則的角色加入快照。
        @param Model 目標角色。
        @param Name 目標顯示名稱。
        @param Kind Player 或 NPC，供目標提示使用。
        @param Humanoid 目標血量來源。
    ]]
	local function _AddCandidate(Model, Name, Kind, Humanoid)
		local Part = _ChooseAimPart(Model)
		if Part and Part:IsA("BasePart") then
			table.insert(Candidates, {
				Id = Model,
				Model = Model,
				Part = Part,
				Health = Humanoid.Health,
				Data = { Name = Name, Kind = Kind },
			})
		end
	end
	if _Options.AimPlayers then
		for _, Player in ipairs(Players:GetPlayers()) do
			if _Enemy(Player) then
				_AddCandidate(
					Player.Character,
					Player.DisplayName .. " (@" .. Player.Name .. ")",
					"Player",
					Player.Character:FindFirstChildOfClass("Humanoid")
				)
			end
		end
	end
	if _Options.AimNPC then
		for Model, Humanoid in pairs(_NPCs) do
			if not Model.Parent or Humanoid.Parent ~= Model then
				_NPCs[Model] = nil
			elseif _NpcEnemy(Model, Humanoid) then
				local Name = Humanoid.DisplayName ~= "" and Humanoid.DisplayName or Model.Name
				_AddCandidate(Model, Name .. " [" .. Model.Name .. "]", "NPC", Humanoid)
			end
		end
	end
	_State.AimCandidateCount = #Candidates
	return Candidates
end

--[[
    從實際射擊原點檢查遮蔽，並保留最近一次遮蔽物診斷。
    @param Context 引擎提供的射擊原點及相機。
    @param Candidate 已通過遊戲規則的候選。
    @param Point 目標瞄準位置。
    @return true 表示無遮蔽或先命中目標自身，false 表示被其他物件阻擋。
]]
local function _IsAimVisible(Context, Candidate, Point)
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	local Ignore = { Context.Camera }
	if LocalPlayer.Character then
		table.insert(Ignore, LocalPlayer.Character)
	end
	Params.FilterDescendantsInstances = Ignore
	local Hit = workspace:Raycast(Context.Shot.Origin, Point - Context.Shot.Origin, Params)
	if Hit and not Hit.Instance:IsDescendantOf(Candidate.Model) then
		_State.LastObstruction = {
			At = os.clock(),
			Target = Candidate.Data.Name,
			Part = Hit.Instance:GetFullName(),
			Distance = Hit.Distance,
			Material = tostring(Hit.Material),
		}
		return false
	end
	return true
end

--[[
    將現有 UI 選項同步至共用引擎；射擊與背景預覽皆在選取前呼叫。

	使用範例：
	```lua
	-- 前提：共用引擎已建立。
	_ConfigureAim()
	local Part = _SelectTarget() -- 無有效目標時為 nil。
	```
]]
local function _ConfigureAim()
	_SilentAimEngine:Configure({
		bEnabled = _State.bAlive and _Options.Aim,
		FovMode = "Pixels",
		FovRadius = _Options.FOV,
		MaxDistance = _Options.Distance,
		Priority = if _Options.AimPriority == "距離最近" then "Distance" else "Cursor",
		bShowTargetMarker = _Options.bAimMarker,
		bVisibleOnly = true,
	})
end

--[[
    取得本機有效武器的射擊原點與實際射程，不以封包方向長度代替射程。
    @return 射擊設定；未持槍、死亡、停用或無相機時為 nil。
]]
local function _GetAimShot()
	local Camera = workspace.CurrentCamera
	local Tool = _ToolNow()
	if not _State.bAlive or not _Options.Aim then
		_State.AimStatus = "disabled"
		return nil
	end
	if not Camera then
		_State.AimStatus = "no camera"
		return nil
	end
	if not Tool then
		_State.AimStatus = "no equipped weapon"
		return nil
	end
	if not _Living() then
		_State.AimStatus = "local character not alive"
		return nil
	end
	_State.AimStatus = "ready"
	return { Origin = _ShotOrigin(Camera, Tool), Range = _AimRange(Tool) }
end

--[[
    將引擎解同步至黃色目標標記。
    @param Solution 當次選取解；nil 會清除標記。
    @return 選取部位；無目標時為 nil。
]]
local function _SetAimSolution(Solution)
	if not Solution then
		_State.AimStatus = "no target within weapon range, FOV and visibility rules"
		_SetTarget(nil)
		return nil
	end
	local Candidate = Solution.Candidate
	_State.AimStatus = "target selected"
	_SetTarget(Candidate.Part, Candidate.Data.Name, Candidate.Data.Kind)
	return Candidate.Part
end

--[[
    以共用引擎更新背景目標預覽；射擊綁定仍會獨立重新選取。
    @return 預覽目標部位；停用或無有效目標時為 nil。
]]
local function _SelectTarget()
	if not _SilentAimEngine then
		_SetTarget(nil)
		return nil
	end
	_ConfigureAim()
	local Shot = _GetAimShot()
	if not Shot then
		_SetTarget(nil)
		return nil
	end
	return _SetAimSolution(_SilentAimEngine:Select(Shot))
end
--[[
	在呼叫端的 UI 執行身分下繪製共用引擎的瞄準部位圓圈。
]]
local function _TargetHUDStep()
	if not _SilentAimEngine then
		return
	end
	--[[
		讓引擎依目前相機、選取部位與投影尺寸更新目標圈。
	]]
	_UiContext(function()
		_SilentAimEngine:RenderTargetMarker()
	end)
end
--[[
    收集玩家 ESP 快照，敵友篩選與陣營色由遊戲層提供，繪製與移除交由共用引擎。
]]
local function _EspStep()
	if not _EspEngine then
		return
	end
	local Targets = {}
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
			local Root = Character and Character:FindFirstChild("HumanoidRootPart")
			local bAlly = _Allied(Player)
			if
				Humanoid
				and Root
				and Root:IsA("BasePart")
				and Humanoid.Health > 0
				and ((bAlly and _Options.Allies) or (not bAlly and _Options.Enemies))
			then
				table.insert(Targets, {
					Object = Character,
					Part = Root,
					Priority = 1,
					Color = _FactionColor(Player),
					Title = string.format(
						"%s [%s] HP %d/%d",
						Player.DisplayName,
						bAlly and "隊友" or "敵方",
						math.floor(Humanoid.Health),
						math.floor(Humanoid.MaxHealth)
					),
				})
			end
		end
	end
	--[[
        在原始 UI 執行身分下更新及繪製引擎管理的視覺物件。
    ]]
	_UiContext(function()
		_EspEngine:Refresh(Targets, {
			bShowLabels = _Options.bESPLabels,
			bShowTracers = _Options.bESPTracers,
			MaxDistance = _Options.Distance,
			MaxMarkers = math.huge,
		})
		_EspEngine:Render()
	end)
	_State.Counts.ESPUpdates = (_State.Counts.ESPUpdates or 0) + 1
end
--[[
	在相機更新後繪製 ESP 與目標提示，分別攔截並回報繪製錯誤。
	@param Dt 本次渲染經過的秒數。
]]
local function _RenderFrame(Dt)
	if not _State.bAlive then
		return
	end
	_State.LastRenderDT = Dt
	_State.Counts.RenderFrames = (_State.Counts.RenderFrames or 0) + 1
	local bEspSuccess, EspError = xpcall(_EspStep, debug.traceback)
	if not bEspSuccess then
		_Report("ESP", EspError)
	end
	local bMarkerSuccess, MarkerError = xpcall(_TargetHUDStep, debug.traceback)
	if not bMarkerSuccess then
		_Report("TargetMarker", MarkerError)
	end
end
--[[
	檢查物件及所有祖先的 Shown 屬性。
	@param Node 自動化互動或跑步機物件。
	@return true 表示未被隱藏，false 表示任一祖先明確標為隱藏。
]]
local function _Shown(Node)
	while Node and Node ~= workspace do
		if Node:GetAttribute("Shown") == false then
			return false
		end
		Node = Node.Parent
	end
	return true
end
--[[
	以遊戲 Own 模組與基地識別確認所有權。
	@param Node 自動化互動或跑步機物件。
	@return true 表示本機基地物件，false 表示無法確認或不屬於本機。
]]
local function _Mine(Node)
	if not _Own or LocalPlayer:GetAttribute("PlotId") == nil then
		return false
	end
	return _Own.isMine(Node, LocalPlayer) == true
end
--[[
	取得遊戲跑步機設定，尚未載入時使用空設定。
	@return 跑步機設定表或空表。
]]
local function _TreadmillConfig()
	return _TycoonConfig and _TycoonConfig.Treadmill or {}
end
--[[
	以 Model 類型及設定標籤辨識跑步機。
	@param Node 自動化互動或跑步機物件。
	@return true 表示跑步機；不存在或不符合類型與標籤時為 false。
]]
local function _IsTreadmill(Node)
	return Node ~= nil and Node:IsA("Model") and CollectionService:HasTag(Node, _TreadmillConfig().Tag or "Treadmill")
end
--[[
	取得跑步機輸送帶或一般互動物件的實體部位。
	@param Node 自動化互動或跑步機物件。
	@return 互動用部位；找不到時為 nil。
]]
local function _PartOf(Node)
	if _IsTreadmill(Node) then
		local Belt = Node:FindFirstChild(_TreadmillConfig().Belt or "Belt")
		return Belt and Belt:IsA("BasePart") and Belt or nil
	end
	if Node:IsA("BasePart") then
		return Node
	end
	if Node:IsA("Attachment") then
		return Node.Parent
	end
	return Node:FindFirstChild("Pad", true) or Node:FindFirstChildWhichIsA("BasePart", true)
end
--[[
	確認解鎖條件與現金支付能力，排除 Robux 商品及通行證。
	@param Node 自動化互動或跑步機物件。
	@return 可負擔的現金價格；未解鎖、付費商品或資金不足時為 nil。
]]
local function _PurchasePrice(Node)
	local Id = Node:GetAttribute("PurchaseId")
	local Config = _TycoonConfig and Id and _TycoonConfig.get(Id)
	if not Config then
		return nil
	end
	-- Never invoke paid product prompts or spend premium currency.
	if Config.product or Config.productId or Config.gamepass or Config.gamepassId then
		return nil
	end
	if _Rules.rebirthLocked(Config, _Me.rebirths or 0, _Me.legacy, Id) then
		return nil
	end
	if
		_TycoonConfig.Lock
		and _Rules.releaseLocked(
			_TycoonConfig.Lock,
			Id,
			ReplicatedStorage.Shared.Tycoon:GetAttribute(_TycoonConfig.Lock.Attr) == true
		)
	then
		return nil
	end
	local Price = Node:GetAttribute("Price")
	if type(Price) ~= "number" then
		Price = Config.cost
	end
	if type(Price) ~= "number" or Price < 0 or Price > (_Me.cash or 0) then
		return nil
	end
	return Price
end
--[[
	確認腳本、指定功能與本機存活狀態。
	@param Kind 既有功能或事件分類鍵，公開選項名稱保持相容。
	@return true 表示可執行；停用、卸載或死亡時為 false。
]]
local function _Active(Kind)
	return _State.bAlive and _Options[Kind] == true and _Living() ~= nil
end
--[[
	清除跑步機工作階段，要求角色離開原生約束並嘗試發送停止請求。
	@param self 接收操作的腳本工作階段；Unload 可重複呼叫。
	@param Reason 停止工作階段的原因，用於診斷。
]]
function _State.StopTreadmill(self: typeof(_State), Reason)
	local Session = self.Treadmill
	if not Session then
		return
	end
	self.Treadmill = nil
	self.LastTreadmill = {
		Path = Session.Node:GetFullName(),
		Reason = tostring(Reason),
		Detail = Session.LastReason,
		Attempts = Session.Attempts or 0,
		At = os.clock(),
		bConfirmed = Session.bConfirmed,
	}
	-- Jump uses the game's own letGo handler to release its local align constraints.
	if Session.Character == LocalPlayer.Character then
		local Humanoid = Session.Character:FindFirstChildOfClass("Humanoid")
		if Humanoid and Humanoid.Health > 0 then
			--[[
				要求角色跳躍，交由遊戲釋放跑步機原生約束。
			]]
			pcall(function()
				Humanoid.Jump = true
			end)
		end
	end
	if Session.Remote and Session.Remote.Parent and Session.Node.Parent then
		--[[
			向仍有效的跑步機 RemoteEvent 發送停止請求。
		]]
		local bSuccess, Error = pcall(function()
			Session.Remote:FireServer(Session.Node, "stop")
		end)
		if not bSuccess then
			_Report("TreadmillStop", Error)
		end
	end
	_Record("Treadmill", "stop: " .. tostring(Reason))
end
--[[
	釋放既有跑步機工作階段後傳送角色，等待位置同步並驗證距離；過程可能 yield。
	@param Part 互動或目標部位；SetTarget 允許 nil 以清除目標。
	@param Kind 既有功能或事件分類鍵，公開選項名稱保持相容。
	@param KeepSession 可選的跑步機工作階段，提供時不停止該工作階段。
	@return true 表示本地到達，false 表示狀態失效或位置被修正；不代表伺服器確認。

	使用範例：
	```lua
	-- 前提：Collect 已啟用，Part 為自有收款踏板。
	if _TeleportTo(Part, "Collect") then _Record("Collect", "到達本地位置") end
	```
]]
local function _TeleportTo(Part, Kind, KeepSession)
	local Character, Humanoid, Root = _Living()
	if not Character or not Part.Parent or not _Active(Kind) then
		return false
	end
	if _State.Treadmill and _State.Treadmill ~= KeepSession then
		_State:StopTreadmill("movement/" .. Kind)
	end
	-- The native treadmill client owns the hold constraints; wait for its cleanup.
	local ReleaseUntil = os.clock() + 1.5
	while Root:FindFirstChild("TreadmillHold") and _Active(Kind) and os.clock() < ReleaseUntil do
		task.wait(0.05)
	end
	if
		not _Active(Kind)
		or LocalPlayer.Character ~= Character
		or not Part.Parent
		or Root:FindFirstChild("TreadmillHold")
	then
		return false
	end
	_Record("Teleport/" .. Kind, Part:GetFullName())
	local Offset = Part.Size.Y / 2 + Humanoid.HipHeight + Root.Size.Y / 2 + 0.1
	local Destination = Part.Position + Vector3.new(0, Offset, 0)
	-- Preserve facing and use PivotTo so the whole character moves together.
	local RootGoal = CFrame.new(Destination) * Root.CFrame.Rotation
	Character:PivotTo(RootGoal * Root.CFrame:Inverse() * Character:GetPivot())
	Root.AssemblyLinearVelocity = Vector3.zero
	Root.AssemblyAngularVelocity = Vector3.zero
	task.wait(0.2)
	if not _Active(Kind) or LocalPlayer.Character ~= Character or not Part.Parent then
		return false
	end
	local Distance = (Root.Position - Destination).Magnitude
	if Distance > 8 then
		_Report("Teleport", "傳送位置被修正或未同步；已略過本次互動")
		return false
	end
	_Record("Teleport/" .. Kind, "local position reached; server acceptance unconfirmed")
	return true
end
--[[
	傳送至自有互動點後觸發提示、點擊或踏板接觸；傳送及接觸可能 yield。
	@param Node 自動化互動或跑步機物件。
	@param Kind 既有功能或事件分類鍵，公開選項名稱保持相容。

	使用範例：
	```lua
	-- 前提：Node 為自有收款點，Collect 已啟用。
	_Interact(Node, "Collect") -- 先傳送與驗證，再嘗試原生互動。
	```
]]
local function _Interact(Node, Kind)
	local Part = _PartOf(Node)
	if not Part or not Part:IsA("BasePart") or not _TeleportTo(Part, Kind) then
		return
	end
	if not _Active(Kind) or not _Mine(Node) or not _Shown(Node) then
		return
	end
	if Kind == "Build" and _PurchasePrice(Node) == nil then
		return
	end
	local _, _, Root = _Living()
	if not Root then
		return
	end
	local Prompt = Node:FindFirstChildWhichIsA("ProximityPrompt", true)
	local Click = Node:FindFirstChildWhichIsA("ClickDetector", true)
	if Prompt and Prompt.Enabled and type(fireproximityprompt) == "function" then
		local PromptPart = _PartOf(Prompt.Parent)
		if PromptPart and (PromptPart.Position - Root.Position).Magnitude <= Prompt.MaxActivationDistance then
			fireproximityprompt(Prompt)
			_Record(Kind, "prompt fired: " .. Prompt:GetFullName())
		else
			_Record(Kind, "prompt out of range")
		end
	elseif Click and type(fireclickdetector) == "function" then
		if (Part.Position - Root.Position).Magnitude <= Click.MaxActivationDistance then
			fireclickdetector(Click)
			_Record(Kind, "click fired: " .. Click:GetFullName())
		else
			_Record(Kind, "click out of range")
		end
	elseif Kind ~= "Produce" then
		if type(firetouchinterest) == "function" then
			_Record(Kind, "touch fired: " .. Part:GetFullName())
			firetouchinterest(Root, Part, 0)
			task.wait(0.05)
			-- Always release an already started touch, including during unload.
			if Root.Parent and Part.Parent then
				firetouchinterest(Root, Part, 1)
			end
		else
			_Report("Touch", "缺少 firetouchinterest；已傳送到踏板上，等待實際接觸收款／購買")
		end
	else
		_Record(Kind, "no usable producer prompt/click detector")
	end
end
--[[
	從指定標籤中選取已解鎖自有物件；建造優先低價，其餘優先距離。
	@param Kind 既有功能或事件分類鍵，公開選項名稱保持相容。
	@param Tag CollectionService 標籤名稱。
	@return 選中的工作物件；沒有有效候選時為 nil。
]]
local function _PickJob(Kind, Tag)
	local _, _, Root = _Living()
	if not Root then
		return nil
	end
	local Best, Score
	for _, Node in ipairs(CollectionService:GetTagged(Tag)) do
		if
			Node:IsDescendantOf(workspace)
			and _Mine(Node)
			and _Shown(Node)
			and os.clock() >= (_Cooldowns[Node] or 0)
		then
			local Part = _PartOf(Node)
			local Price = 0
			if Kind == "Build" then
				Price = _PurchasePrice(Node)
			end
			if Part and Part:IsA("BasePart") and Price ~= nil then
				local Distance = (Part.Position - Root.Position).Magnitude
				local Rank = Kind == "Build" and Price + Distance * 0.001 or Distance
				if not Score or Rank < Score then
					Best, Score = Node, Rank
				end
			end
		end
	end
	return Best
end
--[[
	追加戰鬥診斷事件，最多保留一百筆。
	@param Kind 既有功能或事件分類鍵，公開選項名稱保持相容。
	@param Detail 追加的診斷資訊。
]]
local function _CombatEvent(Kind, Detail)
	table.insert(_Combat.Events, string.format("+%.3f %s %s", os.clock() - _State.StartedAt, Kind, Detail))
	if #_Combat.Events > 100 then
		table.remove(_Combat.Events, 1)
	end
end
--[[
	擷取本地武器與複製屬性，排除換槍時計數跳動，保留十五秒採樣。
]]
local function _SampleCombat()
	local Now = os.clock()
	local Tool = _ToolNow()
	local Shot = Tool and Tool:GetAttribute("GunProtoShot")
	local Ammo = Tool and Tool:GetAttribute("Ammo")
	local bReloading = Tool and Tool:GetAttribute("Reloading")
	local Last = _Combat.Last
	if not Tool then
		if Last then
			_CombatEvent("Unequip", Last.Tool.Name)
		end
		_Combat.Last = nil
	else
		local bPending = true
		if not Last or Last.Tool ~= Tool then
			_CombatEvent("Equip", Tool:GetFullName())
			Last = nil
		else
			bPending = Last.bPending
			if type(Shot) == "number" and type(Last.Shot) == "number" and Shot ~= Last.Shot then
				if bPending or Shot < Last.Shot then
					-- GunProto's global counter can jump when a stale tool is equipped.
					_CombatEvent(
						"ShotBaseline",
						tostring(Last.Shot) .. " -> " .. tostring(Shot) .. "; excluded equip/reset jump"
					)
					bPending = false
				else
					_Combat.LocalShots += Shot - Last.Shot
					_CombatEvent(
						"LocalShot",
						string.format(
							"count=%s delta=%s dt=%.4f",
							tostring(Shot),
							tostring(Shot - Last.Shot),
							Now - Last.Time
						)
					)
				end
			end
			if Ammo ~= Last.Ammo then
				_CombatEvent("ObservedAmmo", tostring(Last.Ammo) .. " -> " .. tostring(Ammo))
			end
			if bReloading ~= Last.bReloading then
				_CombatEvent("Reloading", tostring(bReloading))
			end
		end
		_Combat.Last =
			{ Tool = Tool, Shot = Shot, Ammo = Ammo, bReloading = bReloading, Time = Now, bPending = bPending }
	end
	table.insert(_Combat.Samples, {
		Time = Now,
		Weapon = Tool and Tool.Name or "(unequipped)",
		Ammo = Ammo,
		LocalAmmo = Tool and _Magazine and _Magazine.ammo,
		Shot = Shot,
		bReloading = bReloading,
		Rate = _Options.Rate,
		Interval = Tool and Tool:GetAttribute("FireInterval"),
		LocalShots = _Combat.LocalShots,
		RemoteShots = _Combat.RemoteShots,
	})
	while #_Combat.Samples > 300 or (#_Combat.Samples > 1 and Now - _Combat.Samples[1].Time > 15) do
		table.remove(_Combat.Samples, 1)
	end
end
--[[
	為武器建立診斷紀錄與屬性事件連線，重複呼叫會重用既有紀錄。
	@param Tool 目前武器工具；允許 nil 的讀取流程會退回預設值。
	@return 該武器的持續診斷紀錄。

	使用範例：
	```lua
	local Tool = _ToolNow()
	if Tool then
	    local Stats = _ObserveTool(Tool)
	    assert(_ObserveTool(Tool) == Stats) -- 重用事件觀察紀錄。
	end
	```
]]
local function _ObserveTool(Tool)
	if _ToolObservers[Tool] then
		return _ToolObservers[Tool]
	end
	local Stats = {
		Name = Tool.Name,
		Path = Tool:GetFullName(),
		Initial = Tool:GetAttributes(),
		ShotNotifications = 0,
		ObservedAmmoSpent = 0,
		ReloadTransitions = 0,
		Events = {},
		LastShot = nil,
		CreatedAt = os.clock(),
		Ammo = Tool:GetAttribute("Ammo"),
	}
	local Original = _OriginalRates[Tool]
	Stats.OriginalInterval = Original and Original.Base
		or Tool:GetAttribute("FireInterval")
		or (_GunConfig and _GunConfig.Gun.FireInterval)
	_ToolObservers[Tool] = Stats
	table.insert(_WeaponRecords, Stats)
	-- Bounded records: removed weapons' summaries cannot grow indefinitely.
	if #_WeaponRecords > 20 then
		table.remove(_WeaponRecords, 1)
	end
	--[[
		更新該武器的最後活動時間與事件紀錄，最多保留一百二十筆。
		@param Kind 既有功能或事件分類鍵，公開選項名稱保持相容。
		@param Detail 追加的診斷資訊。
	]]
	local function _Event(Kind, Detail)
		local Now = os.clock()
		Stats.LastActive = Now
		_Combat.LastActive = Stats
		table.insert(Stats.Events, string.format("+%.4f %s %s", Now - _State.StartedAt, Kind, Detail))
		if #Stats.Events > 120 then
			table.remove(Stats.Events, 1)
		end
	end
	--[[
		記錄裝備武器的射擊通知、間隔與當時目標；此通知不代表伺服器命中。
	]]
	_Watch(Tool:GetAttributeChangedSignal("GunProtoShot"), function()
		if not _State.bAlive or not LocalPlayer.Character or Tool.Parent ~= LocalPlayer.Character then
			return
		end
		local Now = os.clock()
		Stats.ShotNotifications += 1
		local Delta = Stats.LastShot and Now - Stats.LastShot
		Stats.LastShot = Now
		local Target = _State.Target
		local TargetHumanoid = Target and Target.Part.Parent and Target.Part.Parent:FindFirstChildOfClass("Humanoid")
		_Event(
			"LocalShotNotification",
			string.format(
				"dt=%s index=%s rate=%s interval=%s ammo=%s localAmmo=%s target=%s targetHP=%s",
				Delta and string.format("%.5f", Delta) or "first",
				tostring(Tool:GetAttribute("GunProtoShot")),
				tostring(_Options.Rate),
				tostring(Tool:GetAttribute("FireInterval")),
				tostring(Tool:GetAttribute("Ammo")),
				tostring(_Magazine and _Magazine.ammo),
				Target and Target.Name or "none",
				tostring(TargetHumanoid and TargetHumanoid.Health)
			)
		)
	end)
	--[[
		觀察武器 Ammo 屬性下降並累計已觀察消耗。
	]]
	_Watch(Tool:GetAttributeChangedSignal("Ammo"), function()
		if not _State.bAlive then
			return
		end
		local Value = Tool:GetAttribute("Ammo")
		if type(Value) == "number" and type(Stats.Ammo) == "number" and Value < Stats.Ammo then
			Stats.ObservedAmmoSpent += Stats.Ammo - Value
		end
		_Event("ObservedAmmo", tostring(Stats.Ammo) .. " -> " .. tostring(Value))
		Stats.Ammo = Value
	end)
	--[[
		記錄武器換彈屬性通知與狀態。
	]]
	_Watch(Tool:GetAttributeChangedSignal("Reloading"), function()
		if not _State.bAlive then
			return
		end
		Stats.ReloadTransitions += 1
		_Event("Reloading", tostring(Tool:GetAttribute("Reloading")))
	end)
	return Stats
end
--[[
	更新裝備武器診斷並套用後座力、擴散、換彈時間、全自動與本地射速選項。
]]
local function _RefreshWeaponStats()
	local Tool = _ToolNow()
	_State.LastWeapon = Tool and Tool:GetFullName() or nil
	if not Tool then
		return
	end
	_ObserveTool(Tool)
	if _Options.bInstantReload then
		_ApplyInstantReload(Tool)
	end
	if _Options.bNoSpread then
		_ApplyNoSpread(Tool)
	end
	if _Options.Recoil then
		if not _OriginalShake[Tool] then
			_OriginalShake[Tool] = { Value = Tool:GetAttribute("ShakeScale") }
		end
		if Tool:GetAttribute("ShakeScale") ~= 0 then
			Tool:SetAttribute("ShakeScale", 0)
		end
	end
	if _Options.Auto then
		if not _OriginalModes[Tool] then
			_OriginalModes[Tool] = { Value = Tool:GetAttribute("FireMode") }
		end
		if Tool:GetAttribute("FireMode") ~= "AUTO" then
			Tool:SetAttribute("FireMode", "AUTO")
		end
	end
	_ApplyRate(Tool, _GunConfig)
	_State.Counts.WeaponStatUpdates = (_State.Counts.WeaponStatUpdates or 0) + 1
end
--[[
	確認生產物件仍有效且可用；跑步機另檢查顯示、建造及使用者狀態。
	@param Node 自動化互動或跑步機物件。
	@return true 表示可嘗試生產，false 表示物件失效或已被占用。
]]
local function _ProducerReady(Node)
	if not Node or not Node.Parent or not Node:IsDescendantOf(workspace) or not _Mine(Node) or not _Shown(Node) then
		return false
	end
	if _IsTreadmill(Node) then
		local Runner = Node:GetAttribute(_TreadmillConfig().RunnerAttr or "Runner")
		return Node:GetAttribute("Shown") == true
			and Node:GetAttribute("BuildSettled") ~= false
			and _PartOf(Node) ~= nil
			and (Runner == nil or Runner == LocalPlayer.UserId)
	end
	return true
end
--[[
	優先選擇最近的可用跑步機，沒有時退回原有生產按鈕。
	@return 候選生產物件；沒有可用物件時為 nil。
]]
local function _PickProducer()
	local _, _, Root = _Living()
	if not Root then
		return nil
	end
	local Best, Score
	for _, Node in ipairs(CollectionService:GetTagged(_TreadmillConfig().Tag or "Treadmill")) do
		if _ProducerReady(Node) and os.clock() >= (_Cooldowns[Node] or 0) then
			local Distance = (_PartOf(Node).Position - Root.Position).Magnitude
			if not Score or Distance < Score then
				Best, Score = Node, Distance
			end
		end
	end
	-- Retain the original clicker behavior when no usable treadmill is available.
	return Best or _PickJob("Produce", "ClickerScreen")
end
-- Match Client.Machines.Treadmill.standFrame, including its R6 hip correction.
--[[
	依輸送帶與控制台方向重現遊戲站位，包含 R6 髖部高度修正。
	@param Node 自動化互動或跑步機物件。
	@param Belt 跑步機輸送帶部位。
	@param Humanoid 角色血量與狀態來源。
	@param Root 角色 HumanoidRootPart。
	@return 角色根部位應使用的站位 CFrame。
]]
local function _TreadmillStandFrame(Node, Belt, Humanoid, Root)
	local Config = _TreadmillConfig()
	local Top = Belt.Position + Vector3.new(0, Belt.Size.Y / 2, 0)
	local Sum, Count = Vector3.zero, 0
	for _, Part in ipairs(Node:GetDescendants()) do
		if Part:IsA("BasePart") and Part ~= Belt and Part.Position.Y > Top.Y + 2 then
			Sum = Sum + Part.Position
			Count = Count + 1
		end
	end
	local Console = Count > 0 and Sum / Count or Top + Belt.CFrame.LookVector
	local Direction = Vector3.new(Console.X - Top.X, 0, Console.Z - Top.Z)
	Direction = Direction.Magnitude > 0.01 and Direction.Unit or Vector3.new(0, 0, 1)
	local Stand = Top + Direction * (Config.Forward or 1.5)
	local Hip = Humanoid.RigType == Enum.HumanoidRigType.R15 and Humanoid.HipHeight or 2
	return CFrame.lookAt(Stand, Stand + Direction) * CFrame.new(0, Hip + Root.Size.Y / 2 + (Config.Hip or 0.1), 0)
end
--[[
	先收起工具，再離開及重新進入原生區域並驗證站位；過程可能 yield。
	@param Node 自動化互動或跑步機物件。
	@param Session 目前跑步機工作階段及請求／確認紀錄。
	@return true 表示完成本地入場，false 表示工作失效、工具未收起或站位被修正。

	使用範例：
	```lua
	-- 前提：Session 是目前工作階段，Node 是可用自有跑步機。
	if _EnterTreadmill(Node, Session) then _RequestTreadmillStart(Session) end
	```
]]
local function _EnterTreadmill(Node, Session)
	local Character, Humanoid, Root = _Living()
	local Belt = _PartOf(Node)
	--[[
		檢查進入跑步機期間的角色、工作階段及輸送帶是否仍有效。
		@return true 表示可繼續入場，false 表示應中止。
	]]
	local function _Valid()
		return _Active("Produce")
			and _State.Treadmill == Session
			and LocalPlayer.Character == Character
			and _ProducerReady(Node)
			and Belt
			and Belt.Parent ~= nil
	end
	if not _Valid() then
		return false
	end
	Humanoid:UnequipTools()
	Humanoid.Sit = false
	Humanoid.Jump = false
	-- Allow unequip to replicate before crossing the native entry zone.
	task.wait(0.25)
	if not _Valid() or Character:FindFirstChildOfClass("Tool") then
		return false
	end
	if Root:FindFirstChild("TreadmillHold") then
		Session.LastReason = "native hold was not released"
		return false
	end
	local Goal = _TreadmillStandFrame(Node, Belt, Humanoid, Root)
	local Approach = Goal.Position + Belt.CFrame.RightVector * (Belt.Size.X / 2 + 4)
	--[[
		整體移動角色至根部位目標，並清除物理速度。
		@param Frame 角色根部位的目標 CFrame。
	]]
	local function _Move(Frame)
		Character:PivotTo(Frame * Root.CFrame:Inverse() * Character:GetPivot())
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
	end
	-- Leaving and re-entering rearms the native armed/leaving zone state.
	_Move(CFrame.new(Approach) * Goal.Rotation)
	task.wait(0.2)
	if not _Valid() then
		return false
	end
	_Move(Goal)
	Session.Goal = Goal.Position
	task.wait(0.35)
	if not _Valid() then
		return false
	end
	if (Root.Position - Goal.Position).Magnitude > 6 then
		Session.LastReason = "stand position was corrected"
		return false
	end
	return true
end
--[[
	節流發送跑步機啟動請求，先確認收槍及距離，再等待 Runner 確認。
	@param Session 目前跑步機工作階段及請求／確認紀錄。
]]
local function _RequestTreadmillStart(Session)
	if not _Active("Produce") or _State.Treadmill ~= Session or LocalPlayer.Character ~= Session.Character then
		return
	end
	local Config = _TreadmillConfig()
	local _, Humanoid, Root = _Living()
	if os.clock() - Session.LastRequest < math.max(0.6, Config.AskGap or 0.3) then
		return
	end
	Session.LastRequest = os.clock()
	if Session.Character:FindFirstChildOfClass("Tool") then
		Humanoid:UnequipTools()
		Session.LastReason = "waiting for tool unequip"
		return
	end
	if Humanoid.Jump then
		Humanoid.Jump = false
	end
	local Belt = _PartOf(Session.Node)
	if not Belt or (Root.Position - Belt.Position).Magnitude > (Config.StartRange or 14) then
		Session.LastReason = "outside start range"
		return
	end
	Session.Remote:FireServer(Session.Node, "start")
	Session.Attempts = Session.Attempts + 1
	Session.LastReason = "start requested; waiting for Runner"
	_State.Counts.TreadmillStartRequests = (_State.Counts.TreadmillStartRequests or 0) + 1
	_Record("Treadmill", "start request #" .. Session.Attempts .. ": " .. Session.Node:GetFullName())
end
--[[
	保留跑步機入場及至少一次生產週期所需的等待時間。
	@return true 表示應暫緩其他移動工作，false 表示可以切換工作。
]]
local function _TreadmillNeedsTime()
	local Session = _State.Treadmill
	if not Session or not _Active("Produce") then
		return false
	end
	-- Let entry/acknowledgement finish and permit at least one production cycle.
	if not Session.bConfirmed then
		return os.clock() - Session.At < 6
	end
	local Pace = tonumber(Session.Node:GetAttribute(_TreadmillConfig().PaceAttr or "Pace")) or 0.6
	return os.clock() - Session.ConfirmedAt < math.clamp(Pace * 2, 2, 5)
end
--[[
	建立或推進跑步機工作階段，檢查 Runner 確認並處理逾時；入場可能 yield。
	@param Node 自動化互動或跑步機物件。
	@return true 表示工作仍在進行，false 表示不能開始或已停止。

	使用範例：
	```lua
	-- 前提：Produce 已啟用，Node 為候選跑步機。
	_RunTreadmill(Node) -- 開始或繼續等待 Runner 確認。
	_State:StopTreadmill("使用者停止")
	```
]]
local function _RunTreadmill(Node)
	if not _Active("Produce") or not _ProducerReady(Node) then
		return false
	end
	local Config = _TreadmillConfig()
	local RunnerAttr = Config.RunnerAttr or "Runner"
	local Session = _State.Treadmill
	local Character = _Living()
	if Session then
		if Session.Node ~= Node or Session.Character ~= Character then
			_State:StopTreadmill("target/character changed")
			return false
		end
		local Runner = Node:GetAttribute(RunnerAttr)
		if Runner == LocalPlayer.UserId then
			if not Session.bConfirmed then
				Session.bConfirmed = true
				Session.ConfirmedAt = os.clock()
				Session.LastReason = "Runner confirmed"
				_State.Counts.TreadmillConfirmed = (_State.Counts.TreadmillConfirmed or 0) + 1
				_Record("Treadmill", "Runner confirmed: " .. Node:GetFullName())
			end
			return true
		end
		if not Session.bConfirmed and os.clock() - Session.At < 6 then
			_RequestTreadmillStart(Session)
			return true
		end
		_Cooldowns[Node] = os.clock() + 3
		_State:StopTreadmill("Runner cleared or start timed out")
		return false
	end
	local Shared = ReplicatedStorage:FindFirstChild("Shared")
	local Tycoon = Shared and Shared:FindFirstChild("Tycoon")
	local Remotes = Tycoon and Tycoon:FindFirstChild("Remotes")
	local Remote = Remotes and Remotes:FindFirstChild(Config.Remote or "Treadmill")
	if not Remote or not Remote:IsA("RemoteEvent") then
		_Cooldowns[Node] = os.clock() + 3
		_Report("Treadmill", "找不到跑步機 RemoteEvent")
		return false
	end
	Session = {
		Node = Node,
		Remote = Remote,
		Character = Character,
		At = os.clock(),
		bConfirmed = false,
		LastRequest = -math.huge,
		Attempts = 0,
		LastReason = "entering zone",
	}
	_State.Treadmill = Session
	-- Adopt an existing native session without teleporting out of its hold.
	if Node:GetAttribute(RunnerAttr) == LocalPlayer.UserId then
		return true
	end
	if not _EnterTreadmill(Node, Session) then
		if _State.Treadmill == Session then
			_State:StopTreadmill("entry cancelled/failed")
		end
		_Cooldowns[Node] = os.clock() + 3
		return false
	end
	Session.At = os.clock()
	if Node:GetAttribute(RunnerAttr) ~= LocalPlayer.UserId then
		_RequestTreadmillStart(Session)
	end
	return true
end
--[[
	在有效距離內觸發原生生產點擊或提示。
	@param Node 自動化互動或跑步機物件。
	@return true 表示已嘗試觸發，false 表示狀態、距離或 Executor 能力不足。
]]
local function _FireProducer(Node)
	if not _Active("Produce") or not _ProducerReady(Node) then
		return false
	end
	local _, _, Root = _Living()
	local Part = _PartOf(Node)
	if not Root or not Part then
		return false
	end
	local Click = Node:FindFirstChildWhichIsA("ClickDetector", true)
	local Prompt = Node:FindFirstChildWhichIsA("ProximityPrompt", true)
	if
		Click
		and type(fireclickdetector) == "function"
		and (Part.Position - Root.Position).Magnitude <= Click.MaxActivationDistance
	then
		fireclickdetector(Click)
	elseif
		Prompt
		and Prompt.Enabled
		and type(fireproximityprompt) == "function"
		and (Part.Position - Root.Position).Magnitude <= Prompt.MaxActivationDistance
	then
		fireproximityprompt(Prompt)
	else
		return false
	end
	_State.Counts.ProductionAttempts = (_State.Counts.ProductionAttempts or 0) + 1
	return true
end
--[[
	載入 GunProto 用戶端模組，接入共用 SilentAim 引擎，並包裝原生換彈入口以套用時間選項；等待 PlayerScripts 可能 yield。
	@param GunRoot Shared.GunProto 模組根節點。

	使用範例：
	```lua
	-- 前提：UI 與 SilentAim 引擎已建立，共用遊戲模組已載入。
	_SetupGuns(ReplicatedStorage.Shared.GunProto)
	-- 安裝結果記錄於 _State.bSilentAimBound，Unload 會解除。
	```
]]
local function _SetupGuns(GunRoot)
	_GunConfig = _LoadModule(GunRoot:FindFirstChild("Config"))
	_GunTargets = _LoadModule(GunRoot:FindFirstChild("Targets"))
	local Remotes = GunRoot:FindFirstChild("Remotes")
	local ShotRemote = Remotes and Remotes:FindFirstChild("Shot")
	if ShotRemote then
		--[[
			僅統計本機角色的伺服器射擊通知，不視為傷害確認。
			@param _ 此位置的伺服器射擊資料，本回呼不讀取。
			@param _ 此位置的伺服器射擊資料，本回呼不讀取。
			@param _ 此位置的伺服器射擊資料，本回呼不讀取。
			@param _ 此位置的伺服器射擊資料，本回呼不讀取。
			@param _ 此位置的伺服器射擊資料，本回呼不讀取。
			@param Shooter 伺服器事件指定的射擊角色。
		]]
		_Watch(ShotRemote.OnClientEvent, function(_, _, _, _, _, Shooter)
			if Shooter == LocalPlayer.Character then
				_Combat.RemoteShots += 1
				_CombatEvent("ServerShotEvent", "local character; not proof of damage")
			end
		end)
		_State.bShotMonitor = true
	end
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 15)
	local Client = PlayerScripts and PlayerScripts:FindFirstChild("GunProtoClient", true)
	if not Client then
		_Report("GunProto", "PlayerScripts.GunProtoClient 尚未載入")
		return
	end
	local Fire = _LoadModule(Client:FindFirstChild("Fire"))
	_Magazine = _LoadModule(Client:FindFirstChild("Magazine"))
	_State.bReloadTimingPatched = _Magazine ~= nil and type(_Magazine.reload) == "function"
	if _State.bReloadTimingPatched then
		--[[
			在原生換彈入口讀取時間前套用選項，涵蓋手動及自動換彈；卸載時還原此包裝器。
			@param Original 原生 Magazine.reload 函數。
			@return 保留原生換彈語意的包裝函數。
		]]
		_Patch(_Magazine, "reload", function(Original)
			--[[
				只更新本機裝備武器的等待時間，原函數恰好呼叫一次，不偽造彈藥或完成狀態。
				@param ... 原生換彈的全部實參，包含 nil。
				@return 原函數的全部回傳值及尾端 nil；原函數錯誤照常傳遞。
			]]
			return function(...)
				if _State.bAlive and _Options.bInstantReload then
					local Tool = _ToolNow()
					if Tool then
						_ApplyInstantReload(Tool)
					end
				end
				return Original(...)
			end
		end)
	end
	local Poses = _LoadModule(Client:FindFirstChild("Poses"))
	local Cam = _LoadModule(Client:FindFirstChild("Camera"))
	if Poses then
		--[[
			為姿勢後座力入口建立可卸載包裝器。
			@param Original 被包裝的原始遊戲函數。
			@return 包裝後的 kick 函數。
		]]
		_Patch(Poses, "kick", function(Original)
			--[[
				依選項略過後座力，其他狀態原樣轉交原函數。
				@param ... 完整原始實參，必須保留其中與尾端的 nil。
				@return 原函數的全部回傳值；停用後座力時無回傳值。
			]]
			return function(...)
				if _State.bAlive and _Options.Recoil then
					return
				end
				return Original(...)
			end
		end)
	end
	if Cam then
		--[[
			為相機晃動入口建立可卸載包裝器。
			@param Original 被包裝的原始遊戲函數。
			@return 包裝後的 shake 函數。
		]]
		_Patch(Cam, "shake", function(Original)
			--[[
				依選項略過相機晃動，其他狀態原樣轉交原函數。
				@param ... 完整原始實參，必須保留其中與尾端的 nil。
				@return 原函數的全部回傳值；停用晃動時無回傳值。
			]]
			return function(...)
				if _State.bAlive and _Options.Recoil then
					return
				end
				return Original(...)
			end
		end)
	end
	if Fire then
		--[[
            只處理本機有效武器的 frame 呼叫；第七參數可為缺省瞄準點或 Vector3。
            @param Values 引擎複製的完整實參。
            @param Arguments 原始完整實參。
            @return true 表示本機可瞄準呼叫，false 表示沿用原資料。
        ]]
		local function _MatchesLocalFrame(Values, Arguments)
			return _State.bAlive
				and _Options.Aim
				and (Arguments[7] == nil or typeof(Arguments[7]) == "Vector3")
				and _GetAimShot() ~= nil
		end
		--[[
            為 frame 綁定提供本機武器原點與射程，不要求原封包已含瞄準位置。
            @param Values 引擎複製的完整實參。
            @param Arguments 原始完整實參。
            @return 當次射擊資料；不符合狀態時為 nil。
        ]]
		local function _ReadFrameShot(Values, Arguments)
			return _GetAimShot()
		end
		-- frame 的缺省瞄準點可能為 nil，使用自訂協定讀取，避免通用 Position 映射拒絕該封包。
		local Binding = {
			Phase = "Before",
			Matches = _MatchesLocalFrame,
			Read = _ReadFrameShot,
		}
		--[[
            同步射擊當下的實際目標，將引擎解填入第七參數，必要時擴充實參數量。
            @param Values 完整實參副本，包含尾端 nil 數量。
            @param Solution 當次引擎選取解。
            @param Arguments 原始完整實參。
            @return 只改寫瞄準位置的完整封包。
        ]]
		Binding.Write = function(Values, Solution, Arguments)
			_SetAimSolution(Solution)
			Values[7] = Solution.Point
			Values.n = math.max(Values.n, 7)
			_State.Counts.AimRedirects = (_State.Counts.AimRedirects or 0) + 1
			_State.LastAimRedirect = {
				At = os.clock(),
				Name = Solution.Candidate.Data.Name,
				Distance = Solution.Distance,
			}
			return Values
		end
		local Disconnect, Reason = _SilentAimEngine:BindMethod(Fire, "frame", Binding)
		_State.bSilentAimBound = Disconnect ~= nil
		if not Disconnect then
			_Report("SilentAimBinding", Reason)
		end
	end
	if Fire then
		--[[
			在引擎綁定外保留武器診斷、正常換彈及即時設定同步。
			@param Original 被包裝的原始遊戲函數。
			@return 包裝後的 frame 函數。
		]]
		_Patch(Fire, "frame", function(Original)
			--[[
				同步射擊設定、處理正常換彈並呼叫引擎綁定；保留所有實參、回傳值及原函數錯誤。
				@param ... 完整原始實參，必須保留其中與尾端的 nil。
				@return 原始 frame 的全部回傳值，包含尾端 nil。
			]]
			return function(...)
				if not _State.bAlive then
					return Original(...)
				end
				local Args = table.pack(...)
				_State.LastAimInput = { At = os.clock(), Type = typeof(Args[7]), Count = Args.n }
				local Tool = _ToolNow()
				_State.Counts.FireFrames = (_State.Counts.FireFrames or 0) + 1
				_RefreshWeaponStats()
				if _Options.Reload and Tool and _Magazine and not _Magazine.reloading then
					local Real = Tool:GetAttribute("Ammo")
					if type(Real) == "number" and Real <= 0 then
						_Magazine.ammo = 0
						_Magazine.reload()
					end
				end
				_ConfigureAim()
				_SetTarget(nil)
				local Result = table.pack(pcall(Original, table.unpack(Args, 1, Args.n)))
				if not Result[1] then
					error(Result[2], 0)
				end
				return table.unpack(Result, 2, Result.n)
			end
		end)
	end
	_State.bGunsReady = Fire ~= nil and _Magazine ~= nil
end
--[[
	彙整選項、武器、互動狀態與錯誤診斷，不發送測試射擊。
	@param self 接收操作的腳本工作階段；Unload 可重複呼叫。
	@return 可複製的多行診斷文字。
]]
function _State.GetDebugInfo(self: typeof(_State))
	local Lines = {
		"=== RaidTycoon Bjz Debug ===",
		"Version: " .. self.Version,
		"PlaceId: " .. tostring(game.PlaceId),
		"PlaceVersion: " .. tostring(game.PlaceVersion),
		"Uptime: " .. string.format("%.1fs", os.clock() - self.StartedAt),
		"GunProto modules loaded: " .. tostring(self.bGunsReady == true),
		"Movement: Teleport (local verification only)",
		"Infinite ammo / Wall damage: unsupported",
		"--- Player state ---",
	}
	for _, Key in ipairs({ "PlotId", "Side", "Passive", "Rookie", "RebirthReady", "Rebirths" }) do
		table.insert(Lines, Key .. ": " .. tostring(LocalPlayer:GetAttribute(Key)))
	end
	local _, Humanoid, Root = _Living()
	table.insert(Lines, "Health: " .. tostring(Humanoid and Humanoid.Health))
	table.insert(Lines, "Position: " .. tostring(Root and Root.Position))
	table.insert(Lines, "Cash: " .. tostring(_Me and _Me.cash))
	table.insert(Lines, "--- Functions / options ---")
	for Name, bAvailable in pairs({
		gethui = type(gethui) == "function",
		fireproximityprompt = type(fireproximityprompt) == "function",
		fireclickdetector = type(fireclickdetector) == "function",
		firetouchinterest = type(firetouchinterest) == "function",
		clipboard = type(_Environment.setclipboard or setclipboard or _Environment.toclipboard or toclipboard)
			== "function",
	}) do
		table.insert(Lines, Name .. ": " .. tostring(bAvailable))
	end
	local Keys = {}
	for Key in pairs(_Options) do
		table.insert(Keys, Key)
	end
	table.sort(Keys)
	for _, Key in ipairs(Keys) do
		table.insert(Lines, Key .. " = " .. tostring(_Options[Key]))
	end
	table.insert(Lines, "ESP scheduling: BindToRenderStep after camera; once per rendered frame")
	table.insert(Lines, "Last render dt: " .. tostring(self.LastRenderDT))
	table.insert(Lines, "Target marker: shared engine circle fitted to selected aim part")
	table.insert(Lines, "ESP visuals: shared Highlight / BillboardGui / tracers")
	table.insert(Lines, "SilentAim binding installed: " .. tostring(self.bSilentAimBound == true))
	table.insert(Lines, "SilentAim engine error: " .. tostring(_SilentAimEngine and _SilentAimEngine:GetLastError()))
	table.insert(Lines, "SilentAim selection status: " .. tostring(self.AimStatus))
	table.insert(Lines, "SilentAim eligible candidates: " .. tostring(self.AimCandidateCount))
	table.insert(Lines, "SilentAim redirected frames: " .. tostring(self.Counts.AimRedirects or 0))
	if self.LastAimInput then
		local Input = self.LastAimInput
		table.insert(
			Lines,
			string.format(
				"Last frame aim input: type=%s args=%d age=%.2fs",
				Input.Type,
				Input.Count,
				os.clock() - Input.At
			)
		)
	end
	if self.LastAimRedirect then
		local Redirect = self.LastAimRedirect
		table.insert(
			Lines,
			string.format(
				"Last aim redirect: target=%s distance=%.1f age=%.2fs",
				Redirect.Name,
				Redirect.Distance,
				os.clock() - Redirect.At
			)
		)
	end
	table.insert(Lines, "Aim part: " .. _Options.AimPart .. "; range filter: weapon Range and configured Distance")
	table.insert(Lines, "Effective aim range: " .. tostring(_AimRange(_ToolNow())))
	table.insert(
		Lines,
		"Server-owned infinite ammo, damage falloff removal and accepted fire-rate bypass: not implemented"
	)
	table.insert(Lines, "ESP backend: " .. tostring(self.ESPBackend))
	table.insert(Lines, "Initial UI identity: " .. tostring(_UIIdentity))
	table.insert(Lines, "UI identity restore API: " .. tostring(type(SetIdentity) == "function"))
	table.insert(
		Lines,
		"Current target: " .. (self.Target and (self.Target.Kind .. " / " .. self.Target.Name) or "none")
	)
	local NpcCount = 0
	for _ in pairs(_NPCs) do
		NpcCount += 1
	end
	table.insert(Lines, "Cached NPC models: " .. NpcCount)
	table.insert(
		Lines,
		"Production send interval: " .. tostring(_Options.ProduceInterval) .. "s (0 = scheduler maximum)"
	)
	table.insert(Lines, "Configured ManualCooldown: " .. tostring(_TycoonConfig and _TycoonConfig.ManualCooldown))
	table.insert(Lines, "--- Aim friend exclusion (unknown/check failures also excluded) ---")
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			local Cached = _Friends[Player.UserId]
			table.insert(
				Lines,
				Player.Name
					.. ": "
					.. (Cached and Cached.Status or "not queried / excluded")
					.. " api="
					.. tostring(Cached and Cached.API)
					.. " error="
					.. tostring(Cached and Cached.Error)
			)
		end
	end
	if self.LastObstruction then
		local Hit = self.LastObstruction
		table.insert(
			Lines,
			string.format(
				"Last aim obstruction: target=%s part=%s distance=%s material=%s age=%.2fs",
				Hit.Target,
				Hit.Part,
				tostring(Hit.Distance),
				Hit.Material,
				os.clock() - Hit.At
			)
		)
	end
	table.insert(Lines, "--- Equipped weapon ---")
	local Tool = _ToolNow()
	table.insert(Lines, "Tool: " .. tostring(Tool and Tool:GetFullName()))
	if Tool then
		for _, Key in ipairs({
			"GunProto",
			"Ammo",
			"MagSize",
			"Reloading",
			"FireMode",
			"FireInterval",
			"ShakeScale",
			"RecoilScale",
			"Range",
			"Projectile",
		}) do
			table.insert(Lines, Key .. ": " .. tostring(Tool:GetAttribute(Key)))
		end
		local Saved = _OriginalRates[Tool]
		table.insert(Lines, "Original FireInterval: " .. tostring(Saved and Saved.Base))
	end
	table.insert(Lines, "Fire.frame calls: " .. tostring(self.Counts.FireFrames or 0))
	table.insert(Lines, "Weapon-stat updates: " .. tostring(self.Counts.WeaponStatUpdates or 0))
	table.insert(Lines, "Last detected weapon: " .. tostring(self.LastWeapon))
	table.insert(Lines, "ESP updates: " .. tostring(self.Counts.ESPUpdates or 0))
	for _, Parent in pairs({ LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }) do
		if Parent then
			for _, Candidate in ipairs(Parent:GetChildren()) do
				if Candidate:IsA("Tool") then
					table.insert(
						Lines,
						string.format(
							"Tool candidate: %s | GunProto=%s Ammo=%s FireInterval=%s",
							Candidate:GetFullName(),
							tostring(Candidate:GetAttribute("GunProto")),
							tostring(Candidate:GetAttribute("Ammo")),
							tostring(Candidate:GetAttribute("FireInterval"))
						)
					)
				end
			end
		end
	end
	table.insert(Lines, "Local ammo: " .. tostring(_Magazine and _Magazine.ammo))
	table.insert(Lines, "Local reloading: " .. tostring(_Magazine and _Magazine.reloading))
	table.insert(Lines, "Instant reload timing wrapper: " .. tostring(self.bReloadTimingPatched == true))
	table.insert(Lines, "--- Combat configuration (defaults, not proof of server limits) ---")
	local CombatKeys = {
		"FireMode",
		"FireInterval",
		"BurstCount",
		"BurstDelay",
		"MagSize",
		"ReloadTime",
		"ShellTime",
		"ShellExit",
		"Heat",
		"CoolRate",
		"CoolDelay",
		"SpinUp",
		"Range",
		"Pellets",
		"Damage",
		"HeadDamage",
		"HipSpread",
		"AdsSpread",
		"MoveSpread",
		"BloomPerShot",
		"BloomMax",
		"Projectile",
		"Flame",
		"ChargeTime",
		"ChargeMin",
		"RecoilScale",
		"ShakeScale",
	}
	for _, Key in ipairs(CombatKeys) do
		table.insert(
			Lines,
			Key
				.. ": default="
				.. tostring(_GunConfig and _GunConfig.Gun[Key])
				.. " tool="
				.. tostring(Tool and Tool:GetAttribute(Key))
		)
	end
	if Tool then
		table.insert(Lines, "--- All current tool attributes ---")
		local Attrs = Tool:GetAttributes()
		local Names = {}
		for Name in pairs(Attrs) do
			table.insert(Names, Name)
		end
		table.sort(Names)
		for _, Name in ipairs(Names) do
			table.insert(Lines, Name .. " = " .. tostring(Attrs[Name]))
		end
	end
	table.insert(Lines, "--- Passive combat capture: last 15s, includes idle/reload ---")
	table.insert(Lines, "Shot listener installed: " .. tostring(self.bShotMonitor == true))
	table.insert(Lines, "Missing own Shot events does NOT establish rejection; server may exclude the shooter.")
	table.insert(
		Lines,
		"Observed Ammo is replicated state, not a server inventory query. No diagnostic shots are sent. First counter changes after equip/reset are excluded."
	)
	local First, Last = _Combat.Samples[1], _Combat.Samples[#_Combat.Samples]
	if First and Last and Last.Time > First.Time then
		local Dt = Last.Time - First.Time
		table.insert(
			Lines,
			string.format(
				"Window=%.3fs local shot counter delta=%d own Shot event delta=%d",
				Dt,
				Last.LocalShots - First.LocalShots,
				Last.RemoteShots - First.RemoteShots
			)
		)
		table.insert(
			Lines,
			string.format(
				"Observed rates: local counter=%.3f/s server Shot events=%.3f/s (not confirmed damage)",
				(Last.LocalShots - First.LocalShots) / Dt,
				(Last.RemoteShots - First.RemoteShots) / Dt
			)
		)
	end
	table.insert(Lines, "time weapon rate interval replicatedAmmo localAmmo reloading localCounter ownShotEvents")
	-- Summarize at 0.25s spacing; event changes are exported separately below.
	local PrintedAt = -math.huge
	for _, Sample in ipairs(_Combat.Samples) do
		if Sample.Time - PrintedAt >= 0.25 or Sample == Last then
			PrintedAt = Sample.Time
			table.insert(
				Lines,
				string.format(
					"%.3f %s %s %s %s %s %s %d %d",
					Sample.Time - self.StartedAt,
					Sample.Weapon,
					tostring(Sample.Rate),
					tostring(Sample.Interval),
					tostring(Sample.Ammo),
					tostring(Sample.LocalAmmo),
					tostring(Sample.bReloading),
					Sample.LocalShots,
					Sample.RemoteShots
				)
			)
		end
	end
	table.insert(Lines, "--- Event-driven weapon records (preserved after unequip; max 20 tools) ---")
	table.insert(Lines, "Local notifications and observed ammo changes are not confirmed hit/damage acknowledgements.")
	for _, Stats in ipairs(_WeaponRecords) do
		table.insert(
			Lines,
			string.format(
				"%s | shot notifications=%d observed ammo spent=%d reload transitions=%d last-active-age=%s",
				Stats.Path,
				Stats.ShotNotifications,
				Stats.ObservedAmmoSpent,
				Stats.ReloadTransitions,
				Stats.LastActive and string.format("%.2fs", os.clock() - Stats.LastActive) or "never"
			)
		)
		table.insert(Lines, "  original effective interval=" .. tostring(Stats.OriginalInterval))
		for _, Key in ipairs({
			"GunProto",
			"Ammo",
			"MagSize",
			"FireMode",
			"FireInterval",
			"ReloadTime",
			"ShellTime",
			"Range",
			"FullDamageDistance",
			"ZeroDamageDistance",
			"Projectile",
			"Heat",
		}) do
			table.insert(Lines, "  initial " .. Key .. "=" .. tostring(Stats.Initial[Key]))
		end
	end
	table.insert(Lines, "--- Last active weapon's event timeline (up to 120; retained while idle) ---")
	if _Combat.LastActive then
		table.insert(Lines, "Weapon: " .. _Combat.LastActive.Path)
		for _, Entry in ipairs(_Combat.LastActive.Events) do
			table.insert(Lines, Entry)
		end
	else
		table.insert(Lines, "No observed weapon attribute events yet")
	end
	table.insert(Lines, "--- Known client protocol (source-derived, not outgoing packet interception) ---")
	table.insert(
		Lines,
		"Fire(origin, aim, spread, hitPartOrPelletClaims, hitDistance, ads, charge, viewTime): no ammo or requested interval fields"
	)
	table.insert(Lines, "Reload(): normal reload request; Reload('stop'): shell-reload stop")
	table.insert(
		Lines,
		"GunProto server handlers are absent from the supplied saved place. Legacy shared validators belong to a separate weapon system. Bypass behavior remains unverified."
	)
	table.insert(Lines, "--- Recent combat changes (up to 100) ---")
	for _, Entry in ipairs(_Combat.Events) do
		table.insert(Lines, Entry)
	end
	table.insert(Lines, "--- Tagged automation objects (up to 5 own samples each) ---")
	for _, Tag in ipairs({
		"CollectPoint",
		"ClickerScreen",
		"ManualProducer",
		"PurchasePad",
		_TreadmillConfig().Tag or "Treadmill",
	}) do
		local Nodes = CollectionService:GetTagged(Tag)
		local Owned, VisibleCount, Affordable, Samples = 0, 0, 0, {}
		for _, Node in ipairs(Nodes) do
			local bSuccess, bIsMine = pcall(_Mine, Node)
			if bSuccess and bIsMine and Node:IsDescendantOf(workspace) then
				Owned += 1
				if _Shown(Node) then
					VisibleCount += 1
				end
				if Tag == "PurchasePad" then
					local bPriceSuccess, Price = pcall(_PurchasePrice, Node)
					if bPriceSuccess and Price ~= nil then
						Affordable += 1
					end
				end
				if #Samples < 5 then
					local Part = _PartOf(Node)
					local Prompt = Node:FindFirstChildWhichIsA("ProximityPrompt", true)
					local Click = Node:FindFirstChildWhichIsA("ClickDetector", true)
					table.insert(
						Samples,
						string.format(
							"%s | shown=%s id=%s price=%s distance=%s prompt=%s click=%s",
							Node:GetFullName(),
							tostring(_Shown(Node)),
							tostring(Node:GetAttribute("PurchaseId")),
							tostring(Node:GetAttribute("Price")),
							tostring(Root and Part and (Root.Position - Part.Position).Magnitude),
							tostring(Prompt and Prompt:GetFullName()),
							tostring(Click and Click:GetFullName())
						)
					)
				end
			end
		end
		table.insert(
			Lines,
			string.format("%s: total=%d own=%d shown=%d affordable=%d", Tag, #Nodes, Owned, VisibleCount, Affordable)
		)
		for _, Sample in ipairs(Samples) do
			table.insert(Lines, "  " .. Sample)
		end
	end
	table.insert(Lines, "--- Treadmill production ---")
	local Session = self.Treadmill
	table.insert(Lines, "Treadmill target: " .. tostring(Session and Session.Node:GetFullName()))
	table.insert(Lines, "Runner confirmed: " .. tostring(Session and Session.bConfirmed == true or false))
	if Session then
		table.insert(
			Lines,
			"Runner: " .. tostring(Session.Node:GetAttribute(_TreadmillConfig().RunnerAttr or "Runner"))
		)
		table.insert(Lines, "Taps: " .. tostring(Session.Node:GetAttribute(_TreadmillConfig().TapsAttr or "Taps")))
		table.insert(Lines, "Start attempts: " .. tostring(Session.Attempts))
		table.insert(Lines, "Start state: " .. tostring(Session.LastReason))
		local Belt = _PartOf(Session.Node)
		table.insert(Lines, "Belt distance: " .. tostring(Root and Belt and (Root.Position - Belt.Position).Magnitude))
		local Character, Humanoid = _Living()
		table.insert(Lines, "Equipped tool: " .. tostring(Character and Character:FindFirstChildOfClass("Tool")))
		table.insert(
			Lines,
			"Jump/Sit: " .. tostring(Humanoid and Humanoid.Jump) .. "/" .. tostring(Humanoid and Humanoid.Sit)
		)
	end
	if self.LastTreadmill then
		local Last = self.LastTreadmill
		table.insert(
			Lines,
			string.format(
				"Last treadmill: %s reason=%s detail=%s attempts=%d confirmed=%s age=%.2fs",
				Last.Path,
				Last.Reason,
				tostring(Last.Detail),
				Last.Attempts,
				tostring(Last.bConfirmed),
				os.clock() - Last.At
			)
		)
	end
	table.insert(Lines, "--- Automation polling ---")
	for Kind, Count in pairs(self.Counts) do
		table.insert(Lines, Kind .. ": " .. tostring(Count))
	end
	table.insert(Lines, "--- Module load results ---")
	for Name, Status in pairs(self.Modules) do
		table.insert(Lines, Name .. ": " .. Status)
	end
	table.insert(Lines, "--- Errors ---")
	for Key, Error in pairs(self.Errors) do
		table.insert(Lines, Key .. ": " .. Error)
	end
	table.insert(Lines, "--- Recent activity (attempts, not confirmed server results) ---")
	for _, Entry in ipairs(self.History) do
		table.insert(Lines, Entry)
	end
	table.insert(Lines, "=== End Debug ===")
	return table.concat(Lines, "\n")
end
--[[
	取得診斷資訊並嘗試複製；無剪貼簿能力時印至控制台。
	@param self 接收操作的腳本工作階段；Unload 可重複呼叫。
	@return true 表示已複製，false 表示剪貼簿不可用或複製失敗。
	@return 完整診斷文字或收集失敗訊息。
]]
function _State.CopyDebugInfo(self: typeof(_State))
	local bSuccess, Info = pcall(self.GetDebugInfo, self)
	if not bSuccess then
		Info = "RaidTycoon " .. self.Version .. " Debug collection failed: " .. tostring(Info)
		_Report("Debug", Info)
	end
	local Copy = _Environment.setclipboard or setclipboard or _Environment.toclipboard or toclipboard
	if type(Copy) ~= "function" and type(clipboard) == "table" then
		Copy = clipboard.set
	end
	local bCopied, CopyError = false, "No clipboard function"
	if type(Copy) == "function" then
		bCopied, CopyError = pcall(Copy, Info)
	end
	if not bCopied then
		print(Info)
		_Report("Clipboard", CopyError)
	end
	return bCopied, Info
end
--[[
	載入 UI 與共用引擎、建立控制項並啟動受卸載旗標管理的背景工作；載入與初始化可能 yield。

	使用範例：
	```lua
	-- 僅由腳本入口呼叫一次；錯誤交由入口卸載已建立資源。
	local bSuccess, Error = xpcall(_Main, debug.traceback)
	if not bSuccess then _State:Unload(); error(Error, 0) end
	```
]]
local function _Main()
	local Library = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/refs/heads/main/Library/BjzUiLibrary_2.0.luau")
	)()
	local CEspEngine = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/EspEngine.luau")
	)()
	assert(type(CEspEngine) == "table" and type(CEspEngine.new) == "function", "ESP 引擎載入失敗")
	local CSilentAimEngine = _LoadSilentAimEngine()
	_SilentAimEngine =
		CSilentAimEngine.new({ World = workspace, GetCandidates = _GetAimCandidates, IsVisible = _IsAimVisible })
	assert(Library.ConfigurationVersion == 2, "請同步更新 BjzUiLibrary_2.0.luau 後再執行")
	_Window = Library:CreateWindow({
		Name = "2 Player Raid Tycoon",
		Brand = "BJZ RAID",
		ConfigId = "TwoPlayerRaidTycoon_" .. tostring(game.PlaceId), GameName = "TwoPlayerRaidTycoon", GameId = game.PlaceId, LegacyConfigIds = { "RaidTycoonBjz_v26" },
		Width = 860,
		Height = 620,
		ToggleKey = Enum.KeyCode.RightShift,
		ConfigurationSaving = { bEnabled = false },
		--[[
			視窗卸載時釋放整個腳本工作階段。
		]]
		OnUnload = function()
			_State:Unload()
		end,
	})
	-- Library normally falls back to CoreGui; this script requires gethui exclusively.
	_Window.ScreenGui.Parent = UIParent
	_Effects = NewInstance("ScreenGui")
	_Effects.Name = "RaidTycoonOverlays"
	_Effects.IgnoreGuiInset = true
	_Effects.ResetOnSpawn = false
	_Effects.DisplayOrder = 1
	_Effects.Parent = UIParent
	_EspEngine = CEspEngine.new(_Effects, workspace)
	_SilentAimEngine:SetTargetMarkerParent(UIParent)
	_State.ESPBackend = "Core/Features/EspEngine (Highlight + BillboardGui)"
	local GunTab = _Window:CreateTab({ Name = "槍枝與瞄準", Icon = "crosshair" })
	local GunSection = GunTab:CreateSection({ Name = "槍枝", Side = "left" })
	local AimSection = GunTab:CreateSection({ Name = "Silent Aim", Side = "right" })
	local EspTab = _Window:CreateTab({ Name = "ESP", Icon = "eye" })
	local EspSection = EspTab:CreateSection({ Name = "玩家資訊", Side = "full" })
	local FarmTab = _Window:CreateTab({ Name = "基地自動化", Icon = "home" })
	local FarmSection = FarmTab:CreateSection({ Name = "基地", Side = "left" })
	local MoveSection = FarmTab:CreateSection({ Name = "移動與轉生", Side = "right" })
	local SysTab = _Window:CreateTab({ Name = "狀態與停止", Icon = "settings" })
	local Sys = SysTab:CreateSection({ Name = "控制", Side = "full" })
	--[[
		建立與選項綁定的開關，關閉時立即清理對應功能狀態。
		@param Section 要加入控制項的 UI 區段。
		@param Name 顯示名稱。
		@param Key 既有屬性、模組方法或選項鍵。
		@param Description 可選的開關說明文字。

		使用範例：
		```lua
		-- 前提：Section 是已建立的 UI 區段。
		_Toggle(Section, "隊友 ESP", "Allies") -- 開關直接同步公開選項鍵。
		```
	]]
	local function _Toggle(Section, Name, Key, Description)
		Section:CreateToggle({
			Name = Name,
			Description = Description,
			bCurrentValue = _Options[Key],
			--[[
				儲存開關值並立即還原受關閉功能影響的狀態。
				@param bValue true 啟用選項，false 停用並執行必要還原。
			]]
			Callback = function(bValue)
				_Options[Key] = bValue
				if Key == "Auto" and not bValue then
					_RestoreModes()
				end
				if Key == "Recoil" and not bValue then
					_RestoreShake()
				end
				if Key == "bNoSpread" then
					if bValue then
						_RefreshWeaponStats()
					else
						_RestoreSpread()
					end
				end
				if Key == "bInstantReload" then
					if bValue then
						_RefreshWeaponStats()
					else
						_RestoreReloadDurations()
					end
				end
				if Key == "Aim" or Key == "bAimMarker" then
					_ConfigureAim()
					if not bValue then
						_SetTarget(nil)
					end
				end
				if Key == "Produce" and not bValue then
					_State:StopTreadmill("disabled")
				end
			end,
		})
	end
	_Toggle(GunSection, "自動換彈", "Reload", "伺服器彈匣耗盡後正常換彈；不修改顯示彈數。")
	_Toggle(
		GunSection,
		"瞬間換彈",
		"bInstantReload",
		"取消本地換彈等待；關閉時還原。實際補彈時間仍依遊戲伺服器。"
	)
	_Toggle(GunSection, "無後座力", "Recoil")
	_Toggle(
		GunSection,
		"無擴散",
		"bNoSpread",
		"將腰射、瞄準、移動與連射擴散歸零；關閉或卸載時還原。"
	)
	_Toggle(
		GunSection,
		"全自動",
		"Auto",
		"按住開火；射速依倍率設定，伺服器仍可拒絕過快射擊。"
	)
	GunSection:CreateSlider({
		Name = "本地射速倍率（未繞過伺服器）",
		Range = { 0.25, 5 },
		Increment = 0.05,
		CurrentValue = _Options.Rate,
		Suffix = "×",
		--[[
			更新本地射速倍率並重新套用目前武器。
			@param Value 控制項的新值，依該控制項的範圍與單位儲存。
		]]
		Callback = function(Value)
			_Options.Rate = Value
			_RestoreRates()
			local Tool = _ToolNow()
			if Tool then
				_ApplyRate(Tool, _GunConfig)
			end
		end,
	})
	GunSection:CreateParagraph({
		Title = "伺服器限制",
		Content = "無限彈藥及穿牆傷害目前未實作。射速倍率改變本地開火間隔，實際傷害頻率仍由伺服器驗證。",
	})
	_Toggle(
		AimSection,
		"Silent Aim",
		"Aim",
		"依選取方式瞄準有效敵方玩家或 NPC；黃色圓圈貼合目前瞄準部位。"
	)
	_Toggle(AimSection, "鎖定敵方玩家", "AimPlayers")
	AimSection:CreateParagraph({
		Title = "Rbx 好友保護",
		Content = "好友不會成為自瞄目標。背景查詢期間或查詢失敗時，也會先排除該玩家。",
	})
	_Toggle(
		AimSection,
		"鎖定敵方 NPC",
		"AimNPC",
		"排除自己、同盟、死亡與無敵 NPC，依遊戲傷害規則判斷。"
	)
	AimSection:CreateDropdown({
		Name = "目標選擇方式",
		Options = { "離游標最近", "距離最近" },
		CurrentOption = _Options.AimPriority,
		--[[
			同步共用引擎的目標排序方式，下一次選取立即採用。
			@param Value 離游標最近或距離最近。
		]]
		Callback = function(Value)
			_Options.AimPriority = Value
			_ConfigureAim()
			_SetTarget(nil)
		end,
	})
	_Toggle(AimSection, "顯示瞄準部位圓圈", "bAimMarker")
	AimSection:CreateDropdown({
		Name = "瞄準部位",
		Options = { "Torso", "Head", "Root" },
		CurrentOption = _Options.AimPart,
		--[[
			儲存瞄準部位選項，下一次選取立即採用。
			@param Value 控制項的新值，依該控制項的範圍與單位儲存。
		]]
		Callback = function(Value)
			_Options.AimPart = Value
		end,
	})
	AimSection:CreateSlider({
		Name = "搜尋半徑（游標／準星）",
		Range = { 20, 800 },
		CurrentValue = _Options.FOV,
		--[[
			儲存準星搜尋像素半徑。
			@param Value 控制項的新值，依該控制項的範圍與單位儲存。
		]]
		Callback = function(Value)
			_Options.FOV = Value
		end,
	})
	EspSection:CreateParagraph({
		Title = "陣營 ESP",
		Content = "依陣營色標示玩家，名稱標籤顯示血量與距離，可開啟方向指引。",
	})
	_Toggle(EspSection, "隊友 ESP", "Allies")
	_Toggle(EspSection, "敵方 ESP", "Enemies")
	_Toggle(EspSection, "顯示名稱與血量", "bESPLabels")
	_Toggle(EspSection, "顯示方向指引", "bESPTracers")
	EspSection:CreateSlider({
		Name = "最大距離（studs）",
		Range = { 100, 5000 },
		CurrentValue = _Options.Distance,
		--[[
			同步 ESP 與瞄準共用的最大距離，單位為 studs。
			@param Value 控制項的新值，依該控制項的範圍與單位儲存。
		]]
		Callback = function(Value)
			_Options.Distance = Value
		end,
	})
	_Toggle(FarmSection, "自動收集錢", "Collect", "直接傳送至自己的收款點並觸發收款。")
	_Toggle(
		FarmSection,
		"自動生產錢",
		"Produce",
		"優先使用自己已解鎖且空閒的跑步機，自動收起工具並站上輸送帶；沒有可用跑步機時使用生產按鈕。"
	)
	_Toggle(
		FarmSection,
		"自動蓋房子",
		"Build",
		"直接傳送至自己基地買得起的建造踏板，優先低價；會花遊戲現金。"
	)
	MoveSection:CreateParagraph({
		Title = "直接傳送",
		Content = "收錢、建造與生產共用移動鎖；前往收錢或建造時會先離開跑步機，完成後自動返回。關閉自動生產或卸載時會停止跑步機。",
	})
	_Toggle(
		MoveSection,
		"自動重生／基地轉生",
		"Rebirth",
		"RebirthReady 為 true 時轉生；會重置基地並消耗遊戲現金。"
	)
	FarmSection:CreateSlider({
		Name = "生產發送間隔（0＝每幀）",
		Range = { 0, 0.5 },
		Increment = 0.01,
		CurrentValue = _Options.ProduceInterval,
		--[[
			儲存生產發送間隔，零表示每次排程皆可嘗試。
			@param Value 控制項的新值，依該控制項的範圍與單位儲存。
		]]
		Callback = function(Value)
			_Options.ProduceInterval = Value
		end,
	})
	FarmSection:CreateParagraph({
		Title = "極速生產",
		Content = "預設每幀嘗試生產；到達後持續觸發，不等待收錢與建造循環。收益仍受遊戲冷卻限制。",
	})
	MoveSection:CreateSlider({
		Name = "收款／建造間隔（秒）",
		Range = { 0.3, 3 },
		Increment = 0.1,
		CurrentValue = _Options.Interval,
		--[[
			儲存收款與建造工作間隔，單位為秒。
			@param Value 控制項的新值，依該控制項的範圍與單位儲存。
		]]
		Callback = function(Value)
			_Options.Interval = Value
		end,
	})
	Sys:CreateParagraph({
		Title = "功能限制",
		Content = "未進行線上實測，無法保證反外掛繞過或免封鎖。無限彈藥與穿牆傷害目前不支援；自動換彈採正常換彈流程。自動重生指基地轉生；死亡後復活由遊戲伺服器控制。",
	})
	Sys:CreateButton({
		Name = "複製 Debug 資訊",
		--[[
			複製診斷資訊並透過視窗顯示操作結果。
		]]
		Callback = function()
			local bCopied = _State:CopyDebugInfo()
			_Window:Notify({
				Title = bCopied and "已複製 Debug 資訊" or "剪貼簿不可用",
				Content = bCopied
						and "直接貼到對話即可。包含目標、原始武器設定、15 秒射擊與換彈採樣、互動物件及錯誤。"
					or "完整 Debug 已印至控制台，可手動複製。",
			})
		end,
	})
	Sys:CreateParagraph({
		Title = "射擊診斷採樣",
		Content = "自動保留最近 15 秒採樣，另以武器屬性事件保留最後一次戰鬥紀錄；收槍後仍可複製。只觀察數據，不會自動開槍。",
	})
	Sys:CreateButton({
		Name = "重新查詢場內好友",
		--[[
			清除場內玩家好友快取並排入背景重查，同時清除目標。
		]]
		Callback = function()
			for _, Player in ipairs(Players:GetPlayers()) do
				if Player ~= LocalPlayer then
					_Friends[Player.UserId] = nil
					_QueueFriendCheck(Player)
				end
			end
			_SetTarget(nil)
			_Window:Notify({
				Title = "好友查詢",
				Content = "背景更新中，尚未確認的玩家會暫時排除。Rbx API 本身可能有快取。",
			})
		end,
	})
	Sys:CreateButton({
		Name = "輸出 Debug 到控制台",
		--[[
			在控制台輸出診斷資訊並顯示收集結果。
		]]
		Callback = function()
			local bSuccess, Info = pcall(_State.GetDebugInfo, _State)
			print(Info)
			_Window:Notify({
				Title = "Debug",
				Content = bSuccess and "完整資訊已輸出至控制台。"
					or "資訊收集失敗，錯誤已輸出。",
			})
		end,
	})
	Sys:CreateButton({
		Name = "完全停止並卸載",
		--[[
			停止並卸載整個腳本。
		]]
		Callback = function()
			_State:Unload()
		end,
	})
	local Shared = ReplicatedStorage:WaitForChild("Shared", 15)
	local Tycoon = Shared and Shared:WaitForChild("Tycoon", 15)
	assert(Tycoon, "找不到 Shared.Tycoon；遊戲版本可能不同")
	_Own = _LoadModule(Tycoon:FindFirstChild("Own"))
	_Rules = _LoadModule(Tycoon:FindFirstChild("Rules"))
	_Me = _LoadModule(Tycoon:FindFirstChild("Me"))
	_TycoonConfig = _LoadModule(Tycoon:FindFirstChild("Config"))
	_TeamLook = _LoadModule(Tycoon:FindFirstChild("TeamLook"))
	local GunRoot = Shared:FindFirstChild("GunProto")
	if GunRoot then
		_SetupGuns(GunRoot)
	end
	for _, Player in ipairs(Players:GetPlayers()) do
		if Player ~= LocalPlayer then
			_QueueFriendCheck(Player)
		end
	end
	--[[
		玩家離場時移除其好友快取。
		@param Player 要查詢或處理的玩家。
	]]
	_Watch(Players.PlayerRemoving, function(Player)
		_Friends[Player.UserId] = nil
	end)
	--[[
		定期更新場內好友快取，卸載旗標失效後結束；查詢與輪詢均可能 yield。
	]]
	task.spawn(function()
		while _State.bAlive do
			for _, Player in ipairs(Players:GetPlayers()) do
				if not _State.bAlive then
					break
				end
				if Player ~= LocalPlayer then
					--[[
						在錯誤保護範圍內查詢目前玩家的好友關係，可能 yield。
					]]
					local bSuccess, Error = xpcall(function()
						_ResolveFriend(Player)
					end, debug.traceback)
					if not bSuccess then
						_Report("FriendWorker", Error)
					end
				end
			end
			task.wait(1)
		end
	end)
	for _, Object in ipairs(workspace:GetDescendants()) do
		_CacheHumanoid(Object)
	end
	--[[
		只將新增 Humanoid 排入延遲 NPC 登錄工作。
		@param Object 需要檢查的場景物件。
	]]
	_Watch(workspace.DescendantAdded, function(Object)
		if Object:IsA("Humanoid") then
			--[[
				下一次排程仍有效時登錄 NPC，卸載後略過。
			]]
			task.defer(function()
				if _State.bAlive then
					_CacheHumanoid(Object)
				end
			end)
		end
	end)
	_Environment.__RaidRenderSerial = (_Environment.__RaidRenderSerial or 0) + 1
	local RenderName = "RaidTycoonBjzRender_" .. tostring(_Environment.__RaidRenderSerial)
	RunService:BindToRenderStep(RenderName, Enum.RenderPriority.Camera.Value + 2, _RenderFrame)
	--[[
		卸載時解除指定名稱的渲染排程。
	]]
	table.insert(_State.Restores, function()
		RunService:UnbindFromRenderStep(RenderName)
	end)
	-- Acquisition, weapon stats and diagnostic sampling run separately from rendering.
	--[[
		背景更新目標預覽、武器設定與戰鬥採樣，每次循環 yield；卸載後結束。
	]]
	task.spawn(function()
		local LastStats = 0
		while _State.bAlive do
			local bTargetSuccess, TargetError = xpcall(_SelectTarget, debug.traceback)
			if not bTargetSuccess then
				_Report("TargetSelection", TargetError)
			end
			if os.clock() - LastStats >= 0.1 then
				LastStats = os.clock()
				local bStatSuccess, StatError = xpcall(_RefreshWeaponStats, debug.traceback)
				if not bStatSuccess then
					_Report("WeaponStats", StatError)
				end
			end
			local bSampleSuccess, SampleError = pcall(_SampleCombat)
			if not bSampleSuccess then
				_Report("CombatCapture", SampleError)
			end
			task.wait(0.05)
		end
	end)
	--[[
		輪替收款與建造工作，使用共用移動鎖並等待跑步機生產週期。
	]]
	task.spawn(function()
		local Jobs = { { "Collect", "CollectPoint" }, { "Build", "PurchasePad" } }
		local Index = 0
		while _State.bAlive do
			task.wait(_Options.Interval)
			if not _State.bAlive then
				break
			end
			Index = Index % #Jobs + 1
			local Kind, Tag = table.unpack(Jobs[Index])
			if
				_Options[Kind]
				and _Own
				and _Me
				and _Rules
				and _TycoonConfig
				and not _State.bMovementBusy
				and not _TreadmillNeedsTime()
			then
				_State.bMovementBusy = true
				--[[
					挑選自有工作物件並在冷卻保護下執行互動，傳送可能 yield。
				]]
				local bSuccess, Error = pcall(function()
					_State.Counts[Kind] = (_State.Counts[Kind] or 0) + 1
					local Node = _PickJob(Kind, Tag)
					if Node then
						_Cooldowns[Node] = os.clock() + (Kind == "Collect" and 8 or 2)
						_Interact(Node, Kind)
					else
						_Record(Kind, "no eligible target")
					end
				end)
				_State.bMovementBusy = false
				if not bSuccess then
					_Report(Kind, Error)
				end
			end
		end
	end)
	--[[
		背景管理跑步機或生產按鈕，使用共用移動鎖並處理工作切換；每次循環 yield。
	]]
	task.spawn(function()
		local Node, LastNote, NextPick = nil, -math.huge, 0
		while _State.bAlive do
			task.wait(_State.Treadmill and math.max(0.1, _Options.ProduceInterval) or _Options.ProduceInterval)
			if not _Active("Produce") then
				_State:StopTreadmill("inactive/dead")
				Node = nil
			elseif _Own and not _State.bMovementBusy then
				_State.bMovementBusy = true
				--[[
					推進生產工作或停止失效跑步機，入場過程可能 yield。
				]]
				local bSuccess, Error = xpcall(function()
					if _State.Treadmill then
						local Session = _State.Treadmill
						if not _ProducerReady(Session.Node) or Session.Character ~= LocalPlayer.Character then
							_State:StopTreadmill("unavailable/ownership changed")
							Node = nil
						else
							Node = Session.Node
						end
					end
					if not _State.Treadmill and (not _ProducerReady(Node) or os.clock() >= NextPick) then
						Node = _PickProducer()
						NextPick = os.clock() + 2
					end
					if not Node then
						if os.clock() - LastNote >= 2 then
							_Record("Produce", "no eligible producer")
							LastNote = os.clock()
						end
						return
					end
					if _IsTreadmill(Node) then
						if not _RunTreadmill(Node) then
							Node = nil
						end
						return
					end
					if not _FireProducer(Node) then
						-- All character movement is serialized with collect/build tasks.
						--[[
							傳送至一般生產按鈕，將傳送錯誤交由外層回報；可能 yield。
						]]
						local bMoved, MoveError = pcall(function()
							local Part = _PartOf(Node)
							if Part then
								_TeleportTo(Part, "Produce")
							end
						end)
						if not bMoved then
							error(MoveError, 0)
						end
						_FireProducer(Node)
					end
					if os.clock() - LastNote >= 1 then
						_Record(
							"Produce",
							"attempts="
								.. tostring(_State.Counts.ProductionAttempts or 0)
								.. "; income acceptance unconfirmed"
						)
						LastNote = os.clock()
					end
				end, debug.traceback)
				_State.bMovementBusy = false
				if not bSuccess then
					_State:StopTreadmill("producer error")
					if Node then
						_Cooldowns[Node] = os.clock() + 3
					end
					Node = nil
					_Report("ProduceFast", Error)
				end
			end
		end
	end)
	--[[
		定期檢查轉生條件並發送原生轉生請求；會消耗遊戲現金並重置基地進度。
	]]
	task.spawn(function()
		local Last = -math.huge
		while _State.bAlive do
			task.wait(1)
			if
				_State.bAlive
				and _Options.Rebirth
				and LocalPlayer:GetAttribute("RebirthReady") == true
				and os.clock() - Last >= 10
			then
				local Remotes = Tycoon:FindFirstChild("Remotes")
				local Remote = Remotes and Remotes:FindFirstChild("Rebirth")
				if Remote and Remote:IsA("RemoteEvent") then
					_State:StopTreadmill("rebirth")
					Last = os.clock()
					Remote:FireServer()
				end
			end
		end
	end)
	_Window:Notify({
		Title = "已載入",
		Content = "RightShift 顯示／隱藏。各功能預設關閉；狀態頁可診斷或完全停止。",
	})
end
local bSuccess, Error = xpcall(_Main, debug.traceback)
if not bSuccess then
	_State:Unload()
	error("[RaidTycoonBjz] " .. tostring(Error), 0)
end
