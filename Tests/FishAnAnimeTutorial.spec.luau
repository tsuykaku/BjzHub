--!nonstrict
--[[ 驗證正式跳過教學流程；原生回呼獨立執行，且只確認教學專用對話框。 ]]
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
Luau.compile(Source)
--[[ @param Class 類別。 @param Name 名稱。 @param Parent 容器。 @return 新物件。 ]]
local function _Object(Class, Name, Parent)
	local Object = Rbx.Instance.new(Class)
	Object.Name, Object.Parent = Name, Parent
	return Object
end
--[[ @param Button 按鈕。 @return 用按鈕本身辨識 Activated 訊號。 ]]
Rbx.implementProperty("GuiButton", "Activated", function(Button) return Button end)
local Gui = _Object("PlayerGui", "PlayerGui")
local Main = _Object("ScreenGui", "MainGui", Gui)
local Buttons = _Object("Frame", "Buttons", Main)
local Skip = _Object("TextButton", "SkipTutorial", Buttons)
local Confirmation = _Object("Frame", "ConfirmationGUI", Main)
Confirmation.Visible = false
local UI = _Object("Frame", "UI", Confirmation)
local Title = _Object("TextLabel", "Title0", UI)
local Yes = _Object("TextButton", "Yes", UI)
local Controller = { bAutoSkipTutorial = true }
local Runtime = { bAlive = true }
local State = { Now = 0, Queries = 0, Clicks = 0, Confirmations = 0, NativeJobs = {}, Callbacks = {}, Fires = 0,
	Reply = { completed = false, ready = true }, bUseConnections = true }
--[[ 由原生跳過按鈕開啟教學專用確認。 ]]
State.Callbacks[Skip] = function()
	State.Clicks += 1
	Title.Text, Confirmation.Visible = "Skip Tutorial?", true
end
--[[ 模擬原生結束流程的完成同步；本功能關閉後仍應執行。 ]]
State.Callbacks[Yes] = function()
	State.Confirmations += 1
	if State.bPauseNative then coroutine.yield() end
	Confirmation.Visible, State.bCompleted = false, true
end
--[[ 執行原生工作的一個階段，供測試在結束流程中途關閉功能。 ]]
local function _RunOneNative()
	local Job = table.remove(State.NativeJobs, 1)
	if type(Job) == "function" then Job = coroutine.create(Job) end
	if coroutine.status(Job) == "dead" then return end
	local bOk, Error = coroutine.resume(Job)
	assert(bOk, Error)
	if coroutine.status(Job) ~= "dead" then table.insert(State.NativeJobs, Job) end
end
--[[ 執行原生排程；不由入口的功能卸載取消。 ]]
local function _DrainNative()
	while #State.NativeJobs > 0 do _RunOneNative() end
end
local Remote = {}
--[[ @param self 遠端物件。 @param ClassName 類別。 @return 是否是查詢函數。 ]]
function Remote.IsA(self, ClassName) return ClassName == "RemoteFunction" end
--[[ @param self 查詢遠端。 @return 已確認格式的教學狀態。 ]]
function Remote.InvokeServer(self)
	State.Queries += 1
	if State.OnQuery then State.OnQuery() end
	return State.Reply
end
local Environment = setmetatable({ Controller = Controller, _Runtime = Runtime,
	--[[ @param Key 已確認將觸發原生教學按鈕的功能鍵。 ]]
	_Performance = { BeginInteraction = function(Key) assert(Key == "bAutoSkipTutorial") State.RenderingBegins = (State.RenderingBegins or 0) + 1 end },
	task = {
		--[[ @param Callback 原生回呼分派工作。 @return 可取消的工作。 ]]
		defer = function(Callback) local Job = coroutine.create(Callback) table.insert(State.NativeJobs, Job) return Job end,
		cancel = coroutine.close,
	},
	_Tutorial = { NextStateAt = 0, WaitUntil = 0 }, os = {
		--[[ @return 可控制的秒數。 ]]
		clock = function() return State.Now end },
	LocalPlayer = {
		--[[ @param self 玩家。 @param Key 屬性。 @return 教學完成狀態。 ]]
		GetAttribute = function(self, Key) assert(Key == "TutorialCompleted") return State.bCompleted end,
		--[[ @param self 玩家。 @param Name 容器名稱。 @return 玩家 UI。 ]]
		FindFirstChild = function(self, Name) assert(Name == "PlayerGui") return Gui end,
	},
	Remotes = { --[[ @param self 遠端容器。 @param Name 查詢名稱。 @return 僅提供教學查詢。 ]]
		FindFirstChild = function(self, Name) assert(Name == "GetTutorialState", "不可猜測或直接呼叫完成 Remote") return Remote end },
	--[[ @param Key 功能。 @param Message 顯示狀態。 ]]
	_Status = function(Key, Message) assert(Key == "bAutoSkipTutorial") State.Message = Message end,
	--[[ @param Signal 目標按鈕訊號。 @return 可用、停用與外部連線。 ]]
	getconnections = function(Signal)
		if not State.bUseConnections then return {} end
		--[[ 不應觸發停用或外部連線。 ]]
		local function _Unexpected() error("不可執行此連線") end
		return {
			{ Enabled = false, LuaConnection = true, ForeignState = false, Function = _Unexpected, Defer = _Unexpected },
			{ Enabled = true, LuaConnection = true, ForeignState = true, Function = _Unexpected, Defer = _Unexpected },
			{ Enabled = true, LuaConnection = true, ForeignState = false, Function = State.Callbacks[Signal],
				--[[ @param self 原生連線。 ]]
				Defer = function(self) if not State.bIgnoreDefer then table.insert(State.NativeJobs, State.Callbacks[Signal]) end end },
		}
	end,
	--[[ @param Signal 目標訊號。 @param ... 不傳入猜測參數。 ]]
	firesignal = function(Signal, ...)
		assert(select("#", ...) == 0)
		State.Fires += 1
		table.insert(State.NativeJobs, State.Callbacks[Signal])
	end,
}, { __index = getfenv() })
local Start = assert(Source:find("-- TUTORIAL_SKIP_START", 1, true))
local Finish = assert(Source:find("-- TUTORIAL_SKIP_END", Start, true))
local Tutorial = Luau.load(Source:sub(Start, Finish - 1) .. "return _Tutorial", { environment = Environment })()
State.bCompleted = true
Tutorial.Step()
assert(State.Queries == 0 and State.Clicks == 0)
State.bCompleted = false
Skip.Visible = false
Tutorial.Step()
assert((State.RenderingBegins or 0) == 0 and #State.NativeJobs == 0, "已存在但隱藏的教學按鈕不能觸發互動或開啟渲染")
Skip.Visible, Buttons.Visible = true, false
Tutorial.Step()
assert((State.RenderingBegins or 0) == 0 and #State.NativeJobs == 0, "父容器隱藏時同樣不能造成背景渲染閃爍")
Buttons.Visible = true
Tutorial.Step()
assert(State.Queries == 0 and State.Clicks == 0 and #State.NativeJobs == 1, "原生按鈕存在時不受查詢 ready 阻擋")
_DrainNative()
assert(State.Clicks == 1 and Confirmation.Visible)
Title.Text = "Rebirth?"
Tutorial.Step()
assert(#State.NativeJobs == 0 and State.Confirmations == 0, "不得確認其他交易或轉生對話框")
Title.Text = "Skip Tutorial?"
Tutorial.Step()
assert(#State.NativeJobs == 1 and Tutorial.WaitUntil == 10)
Tutorial.Step()
assert(#State.NativeJobs == 1, "等待完成期間不能重複確認")
Controller.bAutoSkipTutorial = false
_DrainNative()
assert(State.Confirmations == 1 and State.bCompleted, "已接受的原生結束流程不得隨開關取消")
Controller.bAutoSkipTutorial = true
Tutorial.Step()
assert(State.Message:find("教學已完成", 1, true) and State.Queries == 0)
State.bCompleted, State.Now, State.bIgnoreDefer = false, 20, true
State.Reply = { completed = false, ready = false }
Tutorial.Stop()
Tutorial.Step()
assert(#State.NativeJobs == 0, "模擬執行器的 Defer 存在但沒有實際觸發")
State.Now += 2
Tutorial.Step()
_DrainNative()
assert(Confirmation.Visible and State.Clicks == 2, "Defer 無效時必須改用原生 Function，即使 ready 尚未就緒")
Tutorial.Step()
State.Now += 2
Tutorial.Step()
State.bPauseNative = true
_RunOneNative()
Controller.bAutoSkipTutorial = false
Tutorial.Stop()
_DrainNative()
assert(State.Confirmations == 2 and State.bCompleted, "直接分派的結束回呼開始後也必須完成還原")
State.bPauseNative, State.bIgnoreDefer = false, false
Controller.bAutoSkipTutorial = true
State.bCompleted, State.Now, State.bUseConnections = false, 40, false
Tutorial.Stop()
Tutorial.State = nil
Tutorial.Step()
assert(State.Fires == 1 and #State.NativeJobs == 1, "無可用 Luau 連線時使用 firesignal")
_DrainNative()
Confirmation.Visible = false
State.Now += 2
Environment.getconnections, Environment.firesignal = false, false
Tutorial = Luau.load(Source:sub(Start, Finish - 1) .. "return _Tutorial", { environment = Environment })()
Tutorial.Step()
assert(State.Message:find("缺少可用", 1, true) and State.Confirmations == 2)
Skip.Parent = nil
Tutorial.State, Tutorial.NextStateAt = nil, 0
State.Reply = { completed = false, ready = false }
Tutorial.Step()
assert(State.Message:find("等待教學資料", 1, true))
State.Now += 20
State.Reply = { completed = true, ready = true }
Tutorial.Step()
assert(State.Message:find("教學已完成", 1, true))
Tutorial.State = nil
State.OnQuery = function() Controller.bAutoSkipTutorial = false end
State.Reply = { completed = false, ready = true }
Tutorial.Step()
assert(#State.NativeJobs == 0 and State.Confirmations == 2, "查詢途中取消不得操作 UI")
Runtime.bAlive = false
Controller.bAutoSkipTutorial = true
local Queries = State.Queries
Tutorial.Step()
assert(State.Queries == Queries)
print("FishAnAnimeTutorial: native skip/confirmation, deferred completion, readiness, completion, API fallback and cancellation passed")
