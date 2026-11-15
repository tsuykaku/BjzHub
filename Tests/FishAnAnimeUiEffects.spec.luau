--!nonstrict
--[[ 驗證正式遊戲 UI 特效適配：精確範圍、原生 UI 保留、重新生成、失敗重試與停止清理。 ]]
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
Luau.compile(Source)
--[[ @param Class 類別。 @param Name 名稱。 @param Parent 父物件。 @return 新物件。 ]]
local function _Object(Class, Name, Parent)
	local Object = Rbx.Instance.new(Class)
	Object.Name, Object.Parent = Name, Parent
	return Object
end
local Signals, Jobs, Connections = {}, {}, {}
--[[ @param Root 玩家 UI。 @return 此容器的新增事件。 ]]
Rbx.implementProperty("PlayerGui", "DescendantAdded", function(Root)
	if Signals[Root] then return Signals[Root] end
	local Signal = {}
	--[[ @param self 事件。 @param Callback 回呼。 @return 可解除的連線。 ]]
	function Signal.Connect(self, Callback)
		local Connection = { bConnected = true, Callback = Callback }
		--[[ @param self 連線。 ]]
		function Connection.Disconnect(self) self.bConnected = false end
		table.insert(Connections, Connection)
		return Connection
	end
	--[[ @param self 事件。 @param Object 新物件。 ]]
	function Signal.Fire(self, Object)
		for _, Connection in Connections do if Connection.bConnected then Connection.Callback(Object) end end
	end
	Signals[Root] = Signal
	return Signal
end)
local Root = _Object("PlayerGui", "PlayerGui")
local Main = _Object("ScreenGui", "MainGui", Root)
local Stats = _Object("Frame", "Stats", Main)
local StatScript = _Object("LocalScript", "StatCollectFX", Main)
local StatsDisplay = _Object("LocalScript", "StatsDisplay", Main)
for _, Name in { "Food", "Gems", "Cash" } do _Object("TextLabel", Name, Stats).Text = "123" end
local Burst = _Object("ImageLabel", "CollectFX", Stats)
local WrongClass = _Object("TextButton", "CollectFX", Stats)
local Store = _Object("Frame", "StoreGUI", Main)
local Scroll = _Object("ScrollingFrame", "ScrollingFrame", Store)
local Offer = _Object("Frame", "OfferCashStore", Scroll)
local Buy = _Object("TextButton", "Buy", Offer)
local Handler = _Object("LocalScript", "StarHandler", Offer)
local Stars = _Object("Folder", "ShootingStarsFX", Offer)
local Star = _Object("ImageLabel", "Star", Stars)
local Streak = _Object("Frame", "Streak", Stars)
local Third = _Object("Frame", "3", Offer)
local Best = _Object("TextLabel", "BestLabel", Third)
local Pulse = _Object("LocalScript", "SizeFXHandler", Best)
local Fish = _Object("Frame", "FishAction", Main)
local AutoFish = _Object("TextButton", "AutoFish", Fish)
local Enabled = _Object("UIGradient", "Enabled", AutoFish)
local Unverified = _Object("LocalScript", "StarHandler", Fish)
local WrongFolder = _Object("ImageLabel", "Star", Fish)
local Panel = _Object("ScreenGui", "BjzUi", Root)
local PanelHandler = _Object("LocalScript", "StarHandler", Panel)
local ButtonsTop = _Object("Frame", "ButtonsTop", Main)
local Box = _Object("TextButton", "LuckyBox", ButtonsTop)
local Rays = _Object("ImageLabel", "Rays1", Box)
local Spin = _Object("LocalScript", "RotationSpinSizeFXHandler", Rays)
local Module = _Object("ModuleScript", "SharedStarFxController")
local Modules = _Object("Folder", "Modules")
Module.Parent = Modules
local Controller = { bDeleteUiEffects = true }
local Runtime = { bAlive = true, Window = { ScreenGui = Panel } }
local State = { Stops = 0, bFail = false }
--[[ @param Object 要停止的特效腳本。 ]]
local function _StopStar(Object) assert(Object.Parent) State.Stops += 1 end
--[[ 執行背景工作直至完成；保留批次 yield 語意。 ]]
local function _Drain()
	while #Jobs > 0 do
		local Thread = table.remove(Jobs, 1)
		if coroutine.status(Thread) ~= "dead" then
			local bOk, Error = coroutine.resume(Thread)
			assert(bOk, Error)
			if coroutine.status(Thread) ~= "dead" then table.insert(Jobs, Thread) end
		end
	end
end
local Environment = setmetatable({
	Controller = Controller, _Runtime = Runtime,
	LocalPlayer = { --[[ @param self 玩家。 @param Name 容器。 @return 當前玩家 UI。 ]]
		FindFirstChild = function(self, Name) return if Name == "PlayerGui" then Root else nil end },
	ReplicatedStorage = { --[[ @param self 服務。 @param Name 容器。 @return 模組容器。 ]]
		FindFirstChild = function(self, Name) return if Name == "Modules" then Modules else nil end },
	--[[ @param Value 原生效果模組。 @return 效果控制器。 ]]
	require = function(Value) assert(Value == Module and not State.bFail, "模擬效果模組未就緒") return { Stop = _StopStar } end,
	--[[ @param Key 功能。 @param Message 狀態。 ]]
	_Status = function(Key, Message) State.Message = Message end,
	task = {
		--[[ @param Callback 背景工作。 @return 執行緒。 ]]
		defer = function(Callback) local Thread = coroutine.create(Callback) table.insert(Jobs, Thread) return Thread end,
		cancel = coroutine.close, wait = coroutine.yield,
	},
}, { __index = getfenv() })
local Definition = assert(Source:find("local _UiEffects = {", 1, true))
local DefinitionEnd = assert(Source:find("local _Runtime = {", Definition, true))
local Start = assert(Source:find("-- UI_EFFECTS_START", 1, true))
local Finish = assert(Source:find("-- UI_EFFECTS_END", Start, true))
local Effects = Luau.load(Source:sub(Definition, DefinitionEnd - 1) .. Source:sub(Start, Finish - 1) .. "return _UiEffects", { environment = Environment })()
Effects.Step()
_Drain()
assert(StatScript.Parent == nil and Burst.Parent == nil and Handler.Parent == nil and Star.Parent == nil and Streak.Parent == nil)
assert(State.Stops == 1 and Stars.Parent == Offer, "停止粒子來源，保留模組仍引用的空容器")
assert(Pulse.Parent == nil and Spin.Parent == nil and Best.Parent == Third and Rays.Parent == Box)
assert(StatsDisplay.Parent == Main and WrongClass.Parent == Stats and Buy.Parent == Offer)
assert(AutoFish.Parent == Fish and Enabled.Parent == AutoFish and Unverified.Parent == Fish and WrongFolder.Parent == Fish)
assert(PanelHandler.Parent == Panel)
for _, Name in { "Food", "Gems", "Cash" } do assert(Stats:FindFirstChild(Name).Text == "123") end
local Recreated = _Object("ImageLabel", "CollectFX", Stats)
Root.DescendantAdded:Fire(Recreated)
_Drain()
assert(Recreated.Parent == nil, "新增裝飾必須持續清理")
local Pending = _Object("ImageLabel", "CollectFX", Stats)
Root.DescendantAdded:Fire(Pending)
Controller.bDeleteUiEffects = false
Effects.Stop()
_Drain()
assert(Pending.Parent == Stats and Burst.Parent == nil, "關閉取消待辦但不復原已刪除項目")
for _, Connection in Connections do assert(not Connection.bConnected) end
Controller.bDeleteUiEffects = true
Effects.StarController, State.bFail = nil, true
local Failed = _Object("LocalScript", "StarHandler", Offer)
Effects.Step()
_Drain()
assert(Failed.Parent == Offer and Effects.Retry[Failed] and State.Message:find("待重試", 1, true))
State.bFail = false
Effects.Step()
_Drain()
assert(Failed.Parent == nil and not Effects.Retry[Failed])
Root = _Object("PlayerGui", "Replacement")
local ReplacementMain = _Object("ScreenGui", "MainGui", Root)
local ReplacementProducer = _Object("LocalScript", "StatCollectFX", ReplacementMain)
Effects.Step()
_Drain()
assert(ReplacementProducer.Parent == nil and Effects.Root == Root, "重生替換 PlayerGui 後重新綁定")
local AfterUnload = _Object("LocalScript", "StatCollectFX", ReplacementMain)
Root.DescendantAdded:Fire(AfterUnload)
Runtime.bAlive, Controller.bDeleteUiEffects = false, false
Effects.Stop()
Effects.Stop()
_Drain()
assert(AfterUnload.Parent == ReplacementMain and #Jobs == 0)
for _, Connection in Connections do assert(not Connection.bConnected) end
print("FishAnAnimeUiEffects: exact scope, controls retained, recreation, retries, PlayerGui replacement and cancellation passed")
