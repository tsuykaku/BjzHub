-- Run from repository root: lune run Tests/RaidTycoonEngines.spec.luau
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/2PlayerRaidTycoon/2PlayerRaidTycoon_Bjz.luau")
Luau.compile(Source)

--[[
	擷取實際遊戲適配函數；排除會下載模組與啟動背景工作的入口。
	@param Start 起始函數宣告。
	@param Finish 下一個函數宣告。
	@return 原檔中的函數原始碼，包含其間的註解。
]]
local function _Extract(Start, Finish)
	local First = assert(Source:find(Start, 1, true))
	local Last = assert(Source:find(Finish, First + #Start, true))
	return Source:sub(First, Last - 1)
end

local Vector3 = Rbx.Vector3
local World = Rbx.Instance.new("Workspace")
local Camera = Rbx.Instance.new("Camera")
Camera.ViewportSize = Rbx.Vector2.new(800, 600)
World.CurrentCamera = Camera
local Character = Rbx.Instance.new("Model")
Character.Parent = World
local LocalHumanoid = Rbx.Instance.new("Humanoid")
LocalHumanoid.Health = 100
LocalHumanoid.Parent = Character
local LocalRoot = Rbx.Instance.new("Part")
LocalRoot.Name = "HumanoidRootPart"
LocalRoot.Position = Vector3.zero
LocalRoot.Parent = Character
local Tool = Rbx.Instance.new("Tool")
Tool.Parent = Character
Tool:SetAttribute("GunProto", true)
Tool:SetAttribute("Ammo", 0)
Tool:SetAttribute("Range", 320)
Tool:SetAttribute("FullDamageDistance", 90)
Tool:SetAttribute("ReloadTime", 2)
Tool:SetAttribute("ShellTime", 0.45)
local TargetModel = Rbx.Instance.new("Model")
TargetModel.Parent = World
local TargetPart = Rbx.Instance.new("Part")
TargetPart.Position = Vector3.new(0, 0, -50)
TargetPart.CFrame = Rbx.CFrame.new(TargetPart.Position)
TargetPart.Size = Vector3.new(2, 2, 2)
TargetPart.Parent = TargetModel

--[[
	固定投影，讓測試只驗證適配器與封包流程。
	@param self 測試相機。
	@param Point 待投影位置。
	@return 測試畫面座標及正深度。
	@return true 表示位於畫面內。
]]
Rbx.implementMethod("Camera", "WorldToViewportPoint", function(self, Point)
	return Vector3.new(400 + Point.X * 5, 300 - Point.Y * 5, -Point.Z), true
end)

--[[
	修正 Lune 測試環境的 lookAt 朝向約定，生產碼仍使用 Rbx 原生實作。
	@param Origin 射擊原點。
	@param Point 目標位置。
	@param Up 上方向。
	@return 面向目標的 CFrame。
]]
local function _LookAt(Origin, Point, Up)
	local Direction = (Point - Origin).Unit
	local Right = Direction:Cross(Up).Unit
	return Rbx.CFrame.fromMatrix(Origin, Right, Right:Cross(Direction), -Direction)
end
local TestCFrame = table.clone(Rbx.CFrame)
TestCFrame.lookAt = _LookAt
local Environment = setmetatable({
	workspace = World,
	Vector3 = Vector3,
	Vector2 = Rbx.Vector2,
	CFrame = TestCFrame,
	Instance = Rbx.Instance,
	UDim = Rbx.UDim,
	UDim2 = Rbx.UDim2,
	Color3 = Rbx.Color3,
}, { __index = getfenv() })
local CSilentAimEngine = Luau.load(Fs.readFile("Core/Features/SilentAimEngine.luau"), {
	environment = Environment,
})()

--[[
	建立不發送網路請求的載入測試環境，執行來源檔真正的版本與快取檢查。
	@param Cached 初始快取；可故意提供舊版或錯誤型別。
	@param Modules 每次下載應回傳的模組；NETWORK_ERROR 模擬傳輸錯誤。
	@return 實際遊戲模組載入函數。
	@return 已要求的原始碼網址陣列。
	@return 保存模組快取的測試環境。
]]
local function _MakeModuleLoader(Cached, Modules)
	local Requests = {}
	local Cache = { RaidTycoonSilentAimEngineModule = Cached }
	--[[
		記錄下載網址並回傳讀取指定測試模組的原始碼。
		@param self 測試 game 物件。
		@param URL 來源檔要求的原始碼網址。
		@return 可編譯的測試模組原始碼；NETWORK_ERROR 會拋出傳輸錯誤。
	]]
	local function _HttpGet(self, URL)
		table.insert(Requests, URL)
		if Modules[#Requests] == "NETWORK_ERROR" then
			error("simulated network failure")
		end
		return "return Modules[" .. #Requests .. "]"
	end
	--[[
		編譯測試下載內容，只有模組回傳值由測試提供，介面檢查仍使用實際遊戲來源。
		@param Text 測試 HttpGet 回傳的原始碼。
		@return 可執行的測試模組函數。
	]]
	local function _Compile(Text)
		return Luau.load(Text, { environment = { Modules = Modules } })
	end
	local LoaderSource = _Extract("local SILENT_AIM_MODULE_URL =", "local function _ToolNow(")
		.. "\nreturn _LoadSilentAimEngine"
	local Loader = Luau.load(LoaderSource, {
		environment = setmetatable({
			_Environment = Cache,
			game = { HttpGet = _HttpGet },
			loadstring = _Compile,
		}, { __index = getfenv() }),
	})()
	return Loader, Requests, Cache
end

local CachedLoader, CachedRequests = _MakeModuleLoader(CSilentAimEngine, {})
assert(
	CachedLoader() == CSilentAimEngine and #CachedRequests == 0,
	"Compatible cache must be reused without redownloading or replacing hook registries"
)
local InvalidCacheLoader, InvalidCacheRequests = _MakeModuleLoader(true, { CSilentAimEngine })
assert(
	InvalidCacheLoader() == CSilentAimEngine and #InvalidCacheRequests == 1,
	"A truthy non-table cache must be replaced rather than indexed"
)
local OldModule = table.clone(CSilentAimEngine)
OldModule.API_VERSION = nil
OldModule.SetTargetMarkerParent = nil
local RetryLoader, RetryRequests, RetryCache = _MakeModuleLoader(OldModule, { OldModule, CSilentAimEngine })
assert(RetryLoader() == CSilentAimEngine and RetryCache.RaidTycoonSilentAimEngineModule == CSilentAimEngine)
assert(
	#RetryRequests == 2
		and RetryRequests[1]:find("?api=2&release=", 1, true)
		and RetryRequests[2]:find("&reload=", 1, true),
	"Old downloaded contents must trigger one retry with a different cache key"
)
local IncompleteModule = table.clone(CSilentAimEngine)
IncompleteModule.SetTargetMarkerParent = nil
local IncompleteLoader = _MakeModuleLoader(IncompleteModule, { CSilentAimEngine })
assert(IncompleteLoader() == CSilentAimEngine, "Matching API version alone must not validate an incomplete cache")
local FailedLoader, FailedRequests, FailedCache = _MakeModuleLoader(OldModule, { IncompleteModule, IncompleteModule })
local bLoaded, LoadError = pcall(FailedLoader)
assert(
	not bLoaded
		and #FailedRequests == 2
		and tostring(LoadError):find("SetTargetMarkerParent", 1, true)
		and FailedCache.RaidTycoonSilentAimEngineModule == OldModule,
	"Repeated incompatibility must stop with the missing method named and leave cache untouched"
)
local NetworkLoader, NetworkRequests = _MakeModuleLoader(nil, { "NETWORK_ERROR", CSilentAimEngine })
assert(
	NetworkLoader() == CSilentAimEngine and #NetworkRequests == 2,
	"A transient download error must allow the single bounded retry"
)

local State = { bAlive = true, Restores = {}, Connections = {}, Counts = {} }
local Options = {
	Aim = true,
	Reload = true,
	Distance = 5000,
	FOV = 800,
	bNoSpread = false,
	bInstantReload = false,
	AimPriority = "離游標最近",
	bAimMarker = true,
}
local Seen, Reloads = nil, 0
--[[
	記錄原生換彈入口實際讀到的時間及實參，驗證套用先於原函數且不重送換彈。
]]
local _ReloadTimings, _ReloadArguments = {}, nil
--[[
	記錄原始 frame 收到的封包，模擬包含尾端 nil 的回傳值。
	@param ... 遊戲原始實參。
	@return 第一個測試回傳值。
	@return 保留的尾端 nil。
]]
local function _Frame(...)
	Seen = table.pack(...)
	return "original", nil
end
local Fire = { frame = _Frame }
--[[
	模擬原生彈匣的正常換彈入口。
	@param ... 原生換彈實參，必須保留 nil。
	@return 測試用原生回傳值。
	@return 保留的尾端 nil。
]]
local function _Reload(...)
	Reloads += 1
	_ReloadArguments = table.pack(...)
	table.insert(_ReloadTimings, {
		ReloadTime = Tool:GetAttribute("ReloadTime"),
		ShellTime = Tool:GetAttribute("ShellTime"),
		ShellExit = Tool:GetAttribute("ShellExit"),
	})
	return "native reload", nil
end
local Magazine = { ammo = 0, reloading = false, reload = _Reload }
local Modules = { Fire = { Value = Fire }, Magazine = { Value = Magazine } }
--[[
	依名稱提供測試模組，不下載或 require 遊戲實例。
	@param self 測試模組目錄。
	@param Name 子模組名稱。
	@return 模組容器；不存在時為 nil。
]]
local function _FindFirstChild(self, Name)
	return Modules[Name]
end
local Client = { FindFirstChild = _FindFirstChild }
--[[
	提供測試用 GunProtoClient。
	@param self 測試 PlayerScripts。
	@param Name 要尋找的腳本名稱。
	@return 測試客戶端模組目錄。
]]
local function _FindClient(self, Name)
	return Client
end
--[[
	模擬已載入的 PlayerScripts，無需等待。
	@param self 測試本機玩家。
	@param Name 子物件名稱。
	@param Timeout 原程式指定的等待秒數。
	@return 測試 PlayerScripts 目錄。
]]
local function _WaitForChild(self, Name, Timeout)
	return { FindFirstChild = _FindClient }
end
local LocalPlayer = { Character = Character, WaitForChild = _WaitForChild }
--[[
	取得目前提供的單一測試候選。
	@param Context 引擎射擊上下文。
	@return 帶有部位及顯示資料的候選快照。
]]
local function _GetCandidates(Context)
	return { { Model = TargetModel, Part = TargetPart, Data = { Name = "Enemy", Kind = "Player" } } }
end
--[[
	此測試只驗證協定及射程；視線幾何由引擎測試另行涵蓋。
	@param Context 本次射擊上下文。
	@param Candidate 目前候選。
	@param Point 瞄準位置。
	@return true 表示此測試場景沒有遮蔽物。
]]
local function _IsVisible(Context, Candidate, Point)
	return true
end
--[[
	提供 Viewport 中央的測試游標，讓遊戲適配測試無須讀取實際輸入裝置。
	@return 測試游標的像素座標。
]]
local function _GetCursorPosition()
	return Rbx.Vector2.new(400, 300)
end
local Engine = CSilentAimEngine.new(
	{ World = World, GetCandidates = _GetCandidates, IsVisible = _IsVisible, GetCursorPosition = _GetCursorPosition },
	{ bEnabled = true, bVisibleOnly = false }
)
Environment._State, Environment._Options = State, Options
Environment.LocalPlayer = LocalPlayer
Environment._SilentAimEngine = Engine
Environment._Environment = { RaidTycoonSilentAimEngineModule = CSilentAimEngine, RaidTycoonBjz = State }

--[[
	載入真正的 Patch、Unload、SetupGuns，字串內的空函數僅替代與此次驗證無關的遊戲依賴。
]]
local AdapterSource = [[
local function _LoadModule(Module) return Module and Module.Value end
local function _ObserveTool(Tool) end
local function _ApplyRate(Tool, Config) end
local function _RestoreModes() end
local function _RestoreShake() end
local function _RestoreRates() end
local function _UiContext(Callback) return Callback() end
local function _Report(Key, Error) error(Key .. ": " .. tostring(Error)) end
]]
AdapterSource ..= _Extract("local SPREAD_ATTRIBUTES =", "local _OriginalModes =")
AdapterSource ..= _Extract("local function _RestoreSpread(", "local function _ApplyRate(")
AdapterSource ..= _Extract("local function _ToolNow(", "local function _Allied(")
AdapterSource ..= _Extract("local function _RefreshWeaponStats(", "local function _ProducerReady(")
AdapterSource ..= _Extract("local function _AimRange(", "local function _GetAimCandidates(")
AdapterSource ..= _Extract("local function _SetTarget(", "local function _ChooseAimPart(")
AdapterSource ..= _Extract("local function _ConfigureAim(", "local function _TargetHUDStep(")
AdapterSource ..= _Extract("function _State.Unload(", "local function _Patch(")
AdapterSource ..= _Extract("local function _Patch(", "local function _LoadModule(")
AdapterSource ..= _Extract("local function _SetupGuns(", "function _State.GetDebugInfo(")
AdapterSource ..= "\nreturn {Setup = _SetupGuns, RestoreSpread = _RestoreSpread, RestoreReload = _RestoreReloadDurations}"
local Adapter = Luau.load(AdapterSource, { environment = Environment })()
Adapter.Setup({ FindFirstChild = _FindFirstChild })
assert(State.bSilentAimBound, "Actual RaidTycoon binding must install")
local OriginalAim = Vector3.xAxis
local Results = table.pack(Fire.frame(1, 2, nil, 4, 5, 6, OriginalAim, nil))
assert(Seen.n == 8 and Seen[3] == nil and Seen[8] == nil, "Packed nil arguments must survive both wrappers")
assert(Seen[7] == TargetPart.Position and Seen[6] == 6, "Only aim position may be rewritten")
assert(Results.n == 2 and Results[1] == "original" and Results[2] == nil, "Original returns must survive")
assert(State.Target.Part == TargetPart and Reloads == 1, "Actual shot HUD and normal reload must remain active")
assert(
	State.bReloadTimingPatched and _ReloadTimings[1].ReloadTime == 2 and _ReloadTimings[1].ShellTime == 0.45,
	"Disabled instant reload must preserve native timing"
)
Options.bInstantReload = true
Tool:SetAttribute("Ammo", 7)
Magazine.ammo = 3
local BeforeManualReload = Reloads
local ReloadResults = table.pack(Magazine.reload("manual", nil))
assert(
	Reloads == BeforeManualReload + 1
		and ReloadResults.n == 2
		and ReloadResults[1] == "native reload"
		and ReloadResults[2] == nil
		and _ReloadArguments.n == 2
		and _ReloadArguments[1] == "manual",
	"Manual reload wrapper must preserve arguments/returns and invoke the original exactly once"
)
local InstantTiming = _ReloadTimings[#_ReloadTimings]
assert(
	InstantTiming.ReloadTime == 0 and InstantTiming.ShellTime == 0 and InstantTiming.ShellExit == 0,
	"Manual reload must read zeroed magazine, shell-fill and shell-exit durations"
)
assert(
	Tool:GetAttribute("Ammo") == 7 and Magazine.ammo == 3 and not Magazine.reloading,
	"Instant timing must not invent ammunition or force reload completion flags"
)
Tool:SetAttribute("ReloadTime", 1.4)
Magazine.reload()
assert(
	_ReloadTimings[#_ReloadTimings].ReloadTime == 0,
	"A game-updated reload duration must be zeroed before the next native reload"
)
Tool:SetAttribute("ShellTime", 0.8)
Options.bInstantReload = false
Adapter.RestoreReload()
assert(
	Tool:GetAttribute("ReloadTime") == 1.4
		and Tool:GetAttribute("ShellTime") == 0.8
		and Tool:GetAttribute("ShellExit") == nil,
	"Disable must restore the latest baseline, preserve a later game update and remove absent overrides"
)
Options.bInstantReload = true
Tool:SetAttribute("Ammo", 0)
Magazine.ammo = 0
local BeforeAutoReload = Reloads
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
assert(
	Reloads == BeforeAutoReload + 1 and _ReloadTimings[#_ReloadTimings].ReloadTime == 0,
	"Automatic reload must use zero durations without issuing duplicate reload calls"
)
Options.bInstantReload = false
Adapter.RestoreReload()
Fire.frame(1, 2, 3, 4, 5, 6, nil, nil)
assert(
	Seen.n == 8 and Seen[7] == TargetPart.Position and Seen[8] == nil,
	"An absent optional aim point must still be filled by the RaidTycoon adapter"
)
Fire.frame(1, 2, 3, 4, 5, 6)
assert(
	Seen.n == 7 and Seen[7] == TargetPart.Position,
	"A missing seventh argument must extend the packed argument count"
)
Fire.frame(1, 2, 3, 4, 5, 6, "invalid")
assert(Seen[7] == "invalid", "Unexpected aim payload types must pass through unchanged")
TargetPart.Position = Vector3.new(0, 0, -100)
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
assert(Seen[7] == TargetPart.Position, "FullDamageDistance=90 must no longer exclude a target 100 studs away")
TargetPart.Position = Vector3.new(0, 0, -321)
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
assert(Seen[7] == OriginalAim, "Actual weapon Range=320 must remain enforced")
TargetPart.Position = Vector3.new(0, 0, -50)
Options.Aim = false
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
assert(Seen[7] == OriginalAim, "Disabling aim must immediately preserve original aim")
Tool:SetAttribute("HipSpread", 0.4)
Tool:SetAttribute("AdsSpread", 0.05)
Tool:SetAttribute("MoveSpread", 1.2)
Tool:SetAttribute("BloomPerShot", 0.1)
Options.bNoSpread = true
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
for _, Key in ipairs({ "HipSpread", "AdsSpread", "MoveSpread", "BloomPerShot", "BloomMax" }) do
	assert(Tool:GetAttribute(Key) == 0, Key .. " must be zero while no spread is enabled")
end
assert(Seen[7] == OriginalAim, "No spread must work independently without enabling SilentAim")
Tool:SetAttribute("MoveSpread", 0.8)
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
assert(Tool:GetAttribute("MoveSpread") == 0, "Game-updated spread must be reapplied before frame")
Tool:SetAttribute("HipSpread", 0.9)
Options.bNoSpread = false
Adapter.RestoreSpread()
assert(Tool:GetAttribute("HipSpread") == 0.9, "Disable must preserve a later game-owned update")
assert(
	Tool:GetAttribute("AdsSpread") == 0.05
		and Tool:GetAttribute("MoveSpread") == 0.8
		and Tool:GetAttribute("BloomPerShot") == 0.1
		and Tool:GetAttribute("BloomMax") == nil,
	"Disable must restore original/updated values and remove originally absent overrides"
)
Options.Aim = true
Tool.Parent = nil
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
assert(Seen[7] == OriginalAim, "Unequipped weapons must not redirect")
assert(State.AimStatus == "no equipped weapon", "Diagnostics must explain an unequipped snapshot")
Tool.Parent = Character

--[[
	離線直接執行 UI 回呼；遊戲腳本的執行身分管理由其原有流程負責。
	@param Callback 待執行的同步 UI 回呼。
	@return 回呼的全部回傳值。
]]
local function _RunMarkerUI(Callback)
	return Callback()
end
Environment._UiContext = _RunMarkerUI
local MarkerParent = Rbx.Instance.new("Folder")
Engine:SetTargetMarkerParent(MarkerParent)
local RenderMarker = Luau.load(
	_Extract("local function _TargetHUDStep(", "local function _EspStep(") .. "\nreturn _TargetHUDStep",
	{ environment = Environment }
)()
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
RenderMarker()
local SharedMarker = MarkerParent:GetChildren()[1]:FindFirstChild("AimPartCircle")
assert(
	SharedMarker.Visible and SharedMarker.Size.X.Offset == 10,
	"Actual game marker callback must render the shared engine's aim-part-sized circle"
)
Options.AimPriority = "距離最近"
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
RenderMarker()
assert(SharedMarker.Visible, "Changing the game selection mode must keep shared marker rendering functional")

TargetPart.Name = "HumanoidRootPart"
local Humanoid = Rbx.Instance.new("Humanoid")
Humanoid.Health = 100
Humanoid.MaxHealth = 100
Humanoid.Parent = TargetModel
local Ally = { Character = TargetModel:Clone(), DisplayName = "Ally", bAlly = true }
Ally.Character.Parent = World
local Enemy = { Character = TargetModel, DisplayName = "Enemy", bAlly = false }
local Targets, EspOptions, Renders
Renders = 0
--[[
	記錄實際 espStep 傳給共用引擎的完整快照與選項。
	@param self 測試 ESP 引擎。
	@param Snapshot 本次玩家快照。
	@param Settings 本次渲染選項。
]]
local function _RefreshEsp(self, Snapshot, Settings)
	Targets, EspOptions = Snapshot, Settings
end
--[[
	記錄每次快照更新後的繪製呼叫。
	@param self 測試 ESP 引擎。
]]
local function _RenderEsp(self)
	Renders += 1
end
--[[
	回傳本機、隊友及敵人，驗證呼叫端的敵友篩選。
	@param self 測試 Players 服務。
	@return 測試玩家清單。
]]
local function _GetPlayers(self)
	return { LocalPlayer, Ally, Enemy }
end
--[[
	提供確定性的測試陣營分類。
	@param Player 待分類玩家。
	@return true 表示隊友，false 表示敵人。
]]
local function _Allied(Player)
	return Player.bAlly
end
--[[
	提供確定性的測試陣營色。
	@param Player 待分類玩家。
	@return 玩家對應的測試顏色。
]]
local function _FactionColor(Player)
	return if Player.bAlly then Rbx.Color3.new(0, 1, 0) else Rbx.Color3.new(1, 0, 0)
end
--[[
	離線直接執行 UI 回呼，不模擬 Executor 身分。
	@param Callback 需要執行的同步回呼。
	@return 回呼的全部回傳值。
]]
local function _UiContext(Callback)
	return Callback()
end
Environment.Players = { GetPlayers = _GetPlayers }
Environment._Allied, Environment._FactionColor, Environment._UiContext = _Allied, _FactionColor, _UiContext
Environment._EspEngine = { Refresh = _RefreshEsp, Render = _RenderEsp }
Options.Enemies, Options.Allies = true, false
Options.Distance, Options.bESPLabels, Options.bESPTracers = 500, true, false
local EspStep = Luau.load(
	_Extract("local function _EspStep(", "local function _RenderFrame(") .. "\nreturn _EspStep",
	{ environment = Environment }
)()
EspStep()
assert(
	#Targets == 1 and Targets[1].Object == TargetModel and Targets[1].Part == TargetPart,
	"Actual ESP adapter must filter allies and anchor enemy markers to the character root"
)
assert(
	Targets[1].Title:find("HP", 1, true) and Targets[1].Color == _FactionColor(Enemy),
	"ESP snapshot must preserve health and faction color"
)
assert(
	EspOptions.MaxDistance == 500 and EspOptions.bShowLabels and not EspOptions.bShowTracers and Renders == 1,
	"Actual ESP options must reach the shared engine"
)
Options.Enemies, Options.Allies, Options.bESPLabels, Options.bESPTracers = false, true, false, true
EspStep()
assert(
	#Targets == 1 and Targets[1].Object == Ally.Character and not EspOptions.bShowLabels and EspOptions.bShowTracers,
	"Toggle changes must replace the snapshot and update labels/tracers"
)
Options.Allies = false
EspStep()
assert(#Targets == 0, "Disabling both factions must send an empty snapshot for marker removal")
Environment._EspEngine = nil
Options.bNoSpread = true
Options.bInstantReload = true
Fire.frame(1, 2, 3, 4, 5, 6, OriginalAim)
State:Unload()
assert(
	Tool:GetAttribute("ReloadTime") == 1.4
		and Tool:GetAttribute("ShellTime") == 0.8
		and Tool:GetAttribute("ShellExit") == nil
		and Magazine.reload == _Reload,
	"Unload must restore reload timings and the original Magazine.reload method"
)
assert(#MarkerParent:GetChildren() == 0, "Game unload must remove the shared engine marker UI")
assert(
	Tool:GetAttribute("HipSpread") == 0.9 and Tool:GetAttribute("BloomMax") == nil,
	"Unload must restore no-spread modifications"
)
assert(Fire.frame == _Frame and not State.bAlive, "Unload must restore wrappers and shared binding in ownership order")
State:Unload()
print(
	"PASS: RaidTycoon loader/cache, aim/marker, reload timing/manual/auto/restore, nils/returns, no-spread, ESP and unload"
)
