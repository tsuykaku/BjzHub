local Fs, Luau, Rbx = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Afk_Bjz.luau")
Luau.compile(Source)
assert(not Source:find("BjzUiLibrary", 1, true), "AFK 入口不能載入 UI 函式庫")
local Now, Jobs, Signals, Connections, Warnings = 0, {}, {}, {}, {}
local DestroySignals = {}
local State = { Fps = 60, bRendering = true, Starts = 0, Destroys = 0, IdleClicks = 0, bClamp = false, bLoadFail = false, Downloads = 0 }
--[[
	建立可觀察解除狀態的訊號。
	@return 訊號替身。
]]
local function _Signal()
	local Signal = { Connections = {} }
	--[[
		訂閱訊號。
		@param self 訊號。
		@param Callback 回呼。
		@return 可解除的連線。
	]]
	function Signal.Connect(self, Callback)
		local Connection = { bConnected = true, Connected = true, Callback = Callback }
		--[[
			解除自己的訂閱。
			@param self 連線。
		]]
		function Connection.Disconnect(self) self.bConnected, self.Connected = false, false end
		table.insert(self.Connections, Connection)
		table.insert(Connections, Connection)
		return Connection
	end
	--[[
		發送新增物件或閒置事件。
		@param self 訊號。
		@param ... 原始參數。
	]]
	function Signal.Fire(self, ...)
		for _, Connection in self.Connections do if Connection.bConnected then Connection.Callback(...) end end
	end
	return Signal
end
--[[
	提供物件的新增事件。
	@param Object 資料物件。
	@return 對應訊號。
]]
Rbx.implementProperty("Instance", "DescendantAdded", function(Object)
	if not Signals[Object] then Signals[Object] = _Signal() end
	return Signals[Object]
end)
--[[
	提供原生銷毀事件；測試在銷毀前明確派送，不使用定時掃描模擬清理。
	@param Object 要銷毀的物件。
	@return 對應的銷毀訊號。
]]
Rbx.implementProperty("Instance", "Destroying", function(Object)
	if not DestroySignals[Object] then DestroySignals[Object] = _Signal() end
	return DestroySignals[Object]
end)
--[[
	建立真實資料物件。
	@param ClassName 類別。
	@param Name 名稱。
	@param Parent 父物件。
	@return 新物件。
]]
local function _Object(ClassName, Name, Parent)
	local Object = Rbx.Instance.new(ClassName)
	Object.Name, Object.Parent = Name, Parent
	return Object
end
local World, SoundService, PlayerRoot = _Object("Workspace", "Workspace"), _Object("Folder", "SoundService"), _Object("Folder", "Player")
local Storage = _Object("Folder", "ReplicatedStorage")
local SoundTemplate = _Object("Sound", "TemplateSound", Storage)
local AnimationTemplate = _Object("Animation", "TemplateAnimation", Storage)
SoundTemplate.SoundId, AnimationTemplate.AnimationId = "rbxassetid://100", "rbxassetid://200"
local Scripts = _Object("Folder", "PlayerScripts", PlayerRoot)
local PlayerScripts = _Object("Folder", "Player", Scripts)
local Rejoin = _Object("LocalScript", "AutoRejoinClient", PlayerScripts)
local NativeIdle = _Object("LocalScript", "AntiIdleClient", PlayerScripts)
local Logic = _Object("LocalScript", "FishingClient", PlayerScripts)
local WorldFx = _Object("Folder", "WorldFX", Scripts)
local FxScript = _Object("LocalScript", "GardenGreeneryClient", WorldFx)
local Sound = _Object("Sound", "Music", SoundService)
local SoundWithData = _Object("Sound", "SoundWithData", SoundService)
SoundWithData.Volume, SoundWithData.PlayOnRemove = 0.75, true
_Object("Folder", "Data", SoundWithData)
local Part = _Object("Part", "Ground", World)
local Humanoid = _Object("Humanoid", "Humanoid", _Object("Model", "Character", World))
local Animate = _Object("LocalScript", "Animate", Humanoid.Parent)
for _, Script in { Rejoin, NativeIdle, Logic, FxScript, Animate } do Script.Enabled = true end
local Animator = _Object("Animator", "Animator", Humanoid)
local AnimationPlayed, Track = _Signal(), { Stops = 0 }
--[[
	辨識動畫軌道。
	@param self 軌道。
	@param Name 類別。
	@return 是否為動畫軌道。
]]
function Track.IsA(self, Name) return Name == "AnimationTrack" end
--[[
	記錄停止動畫。
	@param self 軌道。
	@param Fade 淡出秒數。
]]
function Track.Stop(self, Fade) assert(Fade == 0.1) self.Stops += 1 end
--[[
	取得已播放動畫。
	@param Object 動畫控制器。
	@return 軌道清單。
]]
Rbx.implementMethod("Animator", "GetPlayingAnimationTracks", function(Object) return { Track } end)
--[[
	提供動畫開始事件。
	@param Object 動畫控制器。
	@return 訊號。
]]
Rbx.implementProperty("Animator", "AnimationPlayed", function(Object) return AnimationPlayed end)
--[[
	記錄原生聲音停止。
	@param Object 聲音。
]]
Rbx.implementMethod("Sound", "Stop", function(Object) Object:SetAttribute("Stopped", true) end)
local Player = { Idled = _Signal(), DescendantAdded = _Signal() }
--[[
	查詢玩家子物件。
	@param self 玩家。
	@param Name 子物件名稱。
	@return 對應物件。
]]
function Player.FindFirstChild(self, Name) return PlayerRoot:FindFirstChild(Name) end
--[[
	掃描玩家既有腳本。
	@param self 玩家。
	@return 子孫清單。
]]
function Player.GetDescendants(self) return PlayerRoot:GetDescendants() end
local Environment = {}
--[[
	讀取原生 FPS 上限。
	@return 目前上限。
]]
Environment.getfpscap = function() return State.Fps end
--[[
	模擬正常設定或不支援低上限的執行器。
	@param Fps 要求上限。
]]
Environment.setfpscap = function(Fps) State.Fps = if State.bClamp then math.max(30, Fps) else Fps end
local OriginalSetFps = Environment.setfpscap
local EngineModule = { Version = "3.0.0", LowMemoryVersion = 1, UiCleanupVersion = 1 }
--[[
	核對完整激進選項；實際引擎的永久 UI／視覺清理由 PerformanceEngine.spec 驗證。
	@param Options 引擎設定。
	@return 生命週期替身。
]]
function EngineModule.new(Options)
	assert(not Options.bRenderingEnabled and Options.bDeleteCoreGui and Options.bDeleteGetHui
		and Options.bDeleteVisuals and not Options.bPreserveUi)
	assert(Options.bLowMemory == (EngineModule.LowMemoryVersion == 1 and EngineModule.UiCleanupVersion == 1)
		and Options.bSetSavedQuality == false, "舊引擎需退回原 UI 清理流程，不得直接中斷 AFK")
	local bOriginal, bDestroyed = State.bRendering, false
	return {
		--[[ AFK 不得呼叫定時回收；避免維護工作有額外遍歷成本。 ]]
		Prune = function() error("不應定時回收") end,
		--[[ 啟動最低畫質與清理。 ]]
		Start = function() State.Starts += 1 State.bRendering = false end,
		--[[ @param bEnabled 渲染目標。 @return 是否成功。 ]]
		SetRenderingEnabled = function(bEnabled) State.bRendering = bEnabled return true end,
		--[[ 冪等還原引擎狀態。 ]]
		Destroy = function() if not bDestroyed then bDestroyed = true State.Destroys += 1 State.bRendering = bOriginal end end,
	}
end
local Services = { Players = { LocalPlayer = Player }, Workspace = World, SoundService = SoundService, ReplicatedStorage = Storage,
	RunService = {
		--[[ @param self 渲染服務。 @return 實際狀態。 ]]
		Is3dRenderingEnabled = function(self) return State.bRendering end,
	}, VirtualUser = {
		--[[ @param self 原生虛擬輸入服務。 ]]
		CaptureController = function(self) end,
		--[[ @param self 原生虛擬輸入服務。 @param Point 合成輸入位置。 ]]
		ClickButton2 = function(self, Point) State.IdleClicks += 1 end,
	} }
local Game = { PlaceId = 74729868188364 }
--[[
	取得本測試服務。
	@param self 遊戲。
	@param Name 服務名稱。
	@return 服務替身。
]]
function Game.GetService(self, Name) return assert(Services[Name], Name) end
--[[
	只接受共用引擎原始碼網址；禁止下載 UI 函式庫。
	@param self 遊戲。
	@param Url 原始碼網址。
	@return 假原始碼標記。
]]
function Game.HttpGet(self, Url)
	assert(Url == "https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/PerformanceEngine.luau")
	assert(not State.bLoadFail, "download unavailable")
	State.Downloads += 1
	return "ENGINE"
end
local TestEnvironment = {
	game = Game, Vector2 = Rbx.Vector2, _G = {},
	--[[ @return 共用執行環境。 ]]
	getgenv = function() return Environment end,
	--[[ @param Text 必須為引擎標記。 @return 假模組載入器。 ]]
	loadstring = function(Text)
		assert(Text == "ENGINE")
		--[[ @return 已驗證介面的共用引擎。 ]]
		return function() return EngineModule end
	end,
	--[[ @param Message 收集明確的降級原因。 ]]
	warn = function(Message) table.insert(Warnings, Message) end,
	--[[ @return 可控時鐘。 ]]
	os = { clock = function() return Now end },
	task = {
		--[[ @param Callback 要建立的工作。 @return 協程。 ]]
		defer = function(Callback) local Job = coroutine.create(Callback) table.insert(Jobs, Job) return Job end,
		--[[ @param Seconds 等待秒數，測試手動推進。 ]]
		wait = function(Seconds) coroutine.yield() end,
		cancel = coroutine.close,
	},
}
--[[ AFK 程式本身不得進行任何檔案讀寫；引擎／系統的快取不屬此替身可驗證範圍。 ]]
TestEnvironment.readfile = function() error("不應讀取檔案") end
--[[ 防止新增背景設定保存造成測試未察覺的磁碟寫入。 ]]
TestEnvironment.writefile = function() error("不應寫入檔案") end
--[[ 同樣禁止持續追加本機日誌。 ]]
TestEnvironment.appendfile = function() error("不應追加檔案") end
--[[
	載入整個正式入口。
	@return AFK 控制器。
]]
local function _Load() return Luau.load(Source, { environment = TestEnvironment })() end
--[[
	推進所有尚未停止的工作。
]]
local function _Step()
	for _, Job in Jobs do
		if coroutine.status(Job) == "suspended" then local bOk, Reason = coroutine.resume(Job) assert(bOk, Reason) end
	end
end
local Api = _Load()
assert(State.Fps == 1 and Api.Fps.bVerified and not Rejoin.Enabled and NativeIdle.Enabled and Logic.Enabled)
assert(Api.bAntiIdleReady and not State.bRendering)
_Step()
assert(not Sound.Parent and SoundWithData.Volume == 0 and SoundWithData.Data.Parent == SoundWithData)
assert(Part.Parent == World and Humanoid.Parent and Animator.Parent, "不可為省效能刪除碰撞或角色邏輯")
assert(not FxScript.Enabled and not Animate.Enabled and Track.Stops == 1)
assert(SoundTemplate.Parent == Storage and SoundTemplate.SoundId == "" and AnimationTemplate.AnimationId == "",
	"複製範本之前就應清空聲音與動畫 ID，而不是載入素材後才刪除")
AnimationPlayed:Fire(Track)
_Step()
assert(Track.Stops == 2)
Player.Idled:Fire()
Player.Idled:Fire()
assert(State.IdleClicks == 1)
Now += 61
Player.Idled:Fire()
assert(State.IdleClicks == 2, "自己的防閒置不依賴會被清除的 UI")
local NewSound = _Object("Sound", "Streamed", World)
World.DescendantAdded:Fire(NewSound)
_Step()
assert(not NewSound.Parent)
for Round = 1, 10 do
	local Temporary = {}
	for Index = 1, 100 do
		local Value = _Object("Animator", "Temporary" .. Index, Humanoid)
		table.insert(Temporary, Value)
		World.DescendantAdded:Fire(Value)
	end
	_Step()
	assert(Api.Resources.Animators == 101)
	for _, Value in Temporary do Value.Destroying:Fire() Value:Destroy() end
	assert(Api.Resources.Animators == 1, "物件銷毀當下就解除自身訂閱，不需要定時掃描")
	Now += 16
	_Step()
	assert(Api.Resources.Animators == 1, "已移除 Animator 的訂閱必須回收，不能每輪永久累加")
end
local Burst = {}
local JobsBefore = #Jobs
for Index = 1, 2000 do
	local Value = _Object("Sound", "Burst" .. Index, World)
	table.insert(Burst, Value)
	World.DescendantAdded:Fire(Value)
end
assert(Api.Resources.Queued <= 512 and Api.Resources.QueuePeak <= 512 and #Jobs == JobsBefore,
	"1 FPS 下大量新增物件也不能建立無限佇列或每物件工作")
for _ = 1, 30 do _Step() end
for _, Value in Burst do assert(not Value.Parent, "溢位重掃仍須處理全部新增聲音") end
assert(Api.Resources.Queued == 0 and State.Downloads == 1, "長時間維護不能重新下載共用引擎")
local TemplateBurst = {}
for Index = 1, 1000 do
	local Value = _Object("Sound", "TemplateBurst" .. Index, Storage)
	Value.SoundId = "rbxassetid://300"
	table.insert(TemplateBurst, Value)
	Storage.DescendantAdded:Fire(Value)
end
for _ = 1, 30 do _Step() end
for _, Value in TemplateBurst do assert(Value.SoundId == "", "已處理的空範本不能阻塞溢位重掃") end
assert(Api.Resources.Queued == 0)
Rejoin.Enabled, State.Fps, State.bRendering = true, 120, true
Now += 16
_Step()
assert(not Rejoin.Enabled and State.Fps == 1 and not State.bRendering)
local NextApi = _Load()
assert(not Api.bActive and NextApi.bActive and State.Fps == 1 and State.Destroys == 1, "重複執行須先卸載舊實例")
NextApi.Destroy()
NextApi.Destroy()
assert(State.Fps == 60 and State.bRendering and Rejoin.Enabled and FxScript.Enabled and Animate.Enabled)
assert(SoundWithData.Volume == 0.75 and SoundWithData.PlayOnRemove)
assert(SoundTemplate.SoundId == "rbxassetid://100" and AnimationTemplate.AnimationId == "rbxassetid://200")
for _, Connection in Connections do assert(not Connection.bConnected) end
assert(Environment.FishAnAnimeRngAfkBjz == nil)

-- FPS API 缺少或把 1 強制調成 30，都不能宣稱成功。
Environment.setfpscap = nil
assert(not pcall(_Load) and State.Fps == 60)
Environment.setfpscap, State.bClamp = OriginalSetFps, true
assert(not pcall(_Load) and State.Fps == 60 and Environment.FishAnAnimeRngAfkBjz == nil, "被調整成其他上限時須回報且還原")
State.bClamp, State.bLoadFail = false, true
assert(not pcall(_Load) and State.Fps == 60 and Rejoin.Enabled and Environment.FishAnAnimeRngAfkBjz == nil,
	"下載失敗也必須解除防閒置訂閱、還原重連腳本與 FPS")
State.bLoadFail = false
EngineModule.LowMemoryVersion = nil
local LegacyApi = _Load()
assert(LegacyApi.bActive and not LegacyApi.bLowMemoryActive and State.Fps == 1,
	"遠端舊引擎仍需啟動原永久刪除與 AFK 流程，不能因版本閘門留下全部 UI")
LegacyApi.Destroy()
EngineModule.LowMemoryVersion = 1
EngineModule.UiCleanupVersion = nil
local OldUiApi = _Load()
assert(OldUiApi.bActive and not OldUiApi.bLowMemoryActive)
OldUiApi.Destroy()
EngineModule.UiCleanupVersion = 1
Rejoin.Enabled = false
local OriginallyDisabled = _Load()
OriginallyDisabled.Destroy()
assert(not Rejoin.Enabled, "不能將原本已停用的重連腳本開啟")
Rejoin.Enabled = true
local Final = _Load()
State.Fps = 144
Final.Destroy()
assert(State.Fps == 144, "卸載不得覆寫其他程式接手的 FPS 設定")
print("FishAnAnimeAfk: lifecycle, 1 FPS, rejoin, independent idle, cleanup, late objects and failure paths passed")
