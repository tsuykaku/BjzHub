local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local EngineClass = Luau.load(Fs.readFile("Universal/ServerHopEngine.luau"))()
Luau.compile(Fs.readFile("Universal/ServerHop_Bjz.luau"))

--[[
	建立完全離線的 HTTP、時間與傳送替身。
	@param Pages 依請求順序使用的分頁。
	@return 搜尋器。
	@return 可注入故障及觀察請求、連線的測試狀態。
]]
local function _Fixture(Pages)
	local State = { Time = 0, Requests = {}, Sent = {}, Active = 0, Pages = Pages, Responses = {}, Failures = {}, WaitHook = nil }
	local Event = {}
	--[[
		記錄傳送事件訂閱。
		@param self 事件替身。
		@param Callback 事件接收者。
		@return 可重複解除的連線。
	]]
	function Event.Connect(self, Callback)
		State.Active += 1
		State.Callback = Callback
		local bConnected = true
		return {
			--[[
				解除本訂閱。
			]]
			Disconnect = function()
				if bConnected then State.Active -= 1; bConnected = false end
			end,
		}
	end
	local Services = { PlaceId = 123, JobId = "current", Player = {}, TeleportService = { TeleportInitFailed = Event } }
	--[[
		讀取指定測試回應，必要時觸發取消或卸載。
		@param Options HTTP 請求資訊。
		@return HTTP 替身回應。
	]]
	Services.Request = function(Options)
		table.insert(State.Requests, Options.Url)
		if State.RequestHook then State.RequestHook() end
		return State.Responses[#State.Requests] or { StatusCode = 200, Body = tostring(#State.Requests) }
	end
	--[[
		將替身 Body 映射到分頁，也可用錯誤文字驗證 JSON 例外清理。
		@param Body 回應識別碼。
		@return 該識別碼的分頁。
	]]
	Services.Decode = function(Body)
		if Body == "bad" then error("Invalid JSON") end
		return State.Pages[tonumber(Body)]
	end
	--[[
		編碼測試游標。
		@param Cursor 原始游標。
		@return 確定可觀察的編碼結果。
	]]
	Services.Encode = function(Cursor) return "encoded-" .. Cursor end
	--[[
		推進虛擬時間並允許在等待中注入事件。
		@param Seconds 推進秒數。
	]]
	Services.Wait = function(Seconds)
		State.Time += Seconds
		if State.WaitHook then State.WaitHook() end
	end
	--[[
		取得虛擬秒數。
		@return 測試時間。
	]]
	Services.Clock = function() return State.Time end
	--[[
		記錄最新狀態。
		@param Message 引擎狀態文字。
	]]
	Services.Report = function(Message) State.Message = Message end
	--[[
		模擬指定服同步例外、明確非同步失敗或未決請求。
		@param self 傳送服務替身。
		@param PlaceId 目的地。
		@param ServerId 目的服。
		@param Player 目前玩家。
	]]
	function Services.TeleportService.TeleportToPlaceInstance(self, PlaceId, ServerId, Player)
		table.insert(State.Sent, ServerId)
		if State.Failures[ServerId] == "throw" then error("blocked") end
		if State.Failures[ServerId] == "event" then
			State.Callback(Player, "GameFull", "full", PlaceId, { ServerInstanceId = ServerId })
		end
	end
	return EngineClass.new(Services), State
end

--[[
	建立 API 清單項目。
	@param Id 服 ID。
	@param Count 加入前玩家數。
	@param Capacity 容量，省略為 10。
	@return 清單項目。
]]
local function _Server(Id, Count, Capacity)
	return { id = Id, playing = Count, maxPlayers = Capacity or 10 }
end

local Engine, State = _Fixture({
	{ data = { _Server("current", 0), _Server("full", 10), _Server("two", 2), _Server("bad", -1), false }, nextPageCursor = "a+b" },
	{ data = { _Server("zero", 0), _Server("one", 1), _Server("two", 2) } },
})
State.Failures.zero = "event"
State.Failures.one = "throw"
assert(Engine:Run({ MaxPlayers = 2 }) == "Pending")
assert(table.concat(State.Sent, ",") == "zero,one,two", "應空服優先，明確失敗後重試")
assert(State.Requests[1]:find("/123/servers/Public", 1, true), "應使用 PlaceId")
assert(State.Requests[2]:find("cursor=encoded-a+b", 1, true), "應使用編碼游標")
assert(Engine:Run() == "Busy", "未決傳送不可重入")
assert(State.Active == 1)
State.Callback({}, "Failure", "unrelated", 123, { ServerInstanceId = "two" })
assert(Engine:Run() == "Busy", "忽略其他玩家失敗")
State.Callback(Engine._Services.Player, "Failure", "late", 123, { ServerInstanceId = "two" })
assert(State.Active == 0 and not Engine._bPending, "晚到的明確失敗應清除未決狀態")
Engine:Destroy(); Engine:Destroy()
assert(State.Active == 0 and Engine:Run() == "Destroyed")

Engine, State = _Fixture({ { data = { _Server("one", 1) } } })
assert(Engine:Run({ MaxPlayers = 0 }) == "NotFound" and #State.Sent == 0, "只找空服不可放寬")

Engine, State = _Fixture({ { data = {}, nextPageCursor = "repeat" }, { data = {}, nextPageCursor = "repeat" } })
assert(Engine:Run() == "NotFound" and #State.Requests == 2, "重複游標應停止")
Engine, State = _Fixture({ { data = {}, nextPageCursor = "next" } })
assert(Engine:Run({ MaxPages = 1 }) == "NotFound" and #State.Requests == 1, "應遵守頁數上限")

Engine, State = _Fixture({ {}, { data = { _Server("zero", 0) } } })
State.Responses[1] = { StatusCode = 429, Body = "", Headers = { ["Retry-After"] = "3" } }
assert(Engine:Run() == "Pending" and State.Time >= 18 and #State.Requests == 2, "429 應依 Retry-After 退避")
Engine:Destroy(); assert(State.Active == 0)

Engine, State = _Fixture({})
State.Responses = { { StatusCode = 403 }, { StatusCode = 403 }, { StatusCode = 403 } }
assert(Engine:Run() == "Failed" and #State.Requests == 1, "403 不應重試")
State.Responses[2] = { StatusCode = 200, Body = "bad" }
assert(Engine:Run() == "Failed" and not Engine._bBusy, "JSON 例外應釋放 Busy")
State.Responses[3] = { StatusCode = 200, Body = "3" }
State.Pages[3] = { data = {} }
assert(Engine:Run() == "NotFound", "失敗後應可重試")

Engine, State = _Fixture({ { data = { _Server("zero", 0) } } })
--[[
	在 HTTP 尚未返回時取消，返回後不可再傳送。
]]
State.RequestHook = function() Engine:Cancel() end
assert(Engine:Run() == "Cancelled" and #State.Sent == 0)
Engine, State = _Fixture({ { data = { _Server("zero", 0) } } })
--[[
	在 HTTP 尚未返回時卸載，不可再傳送。
]]
State.RequestHook = function() Engine:Destroy() end
assert(Engine:Run() == "Cancelled" and #State.Sent == 0 and State.Active == 0)

Engine, State = _Fixture({})
State.Responses[1] = { StatusCode = 503 }
--[[
	退避期間取消，避免發出下一次 HTTP。
]]
State.WaitHook = function() Engine:Cancel() end
assert(Engine:Run() == "Cancelled" and #State.Requests == 1)
print("ServerHop: all offline behavior checks passed; entry syntax compiled")

-- UI 入口替身：驗證 API 接合、重複執行與部分初始化清理，不證明真實 UI 互動。
local Shared, Jobs = {}, {}
local Windows, Engines = {}, {}
local EngineModule = { Version = "1.0.0" }
--[[
	建立觀察入口生命週期的引擎替身。
	@param Dependencies 入口傳入的執行能力。
	@return 引擎替身。
]]
function EngineModule.new(Dependencies)
	local Object = { Runs = 0, Cancels = 0, Destroys = 0 }
	--[[
		記錄啟動時採用的設定快照。
		@param self 引擎替身。
		@param Settings 搜尋條件。
		@return 替身結果代碼。
		@return 替身結果說明。
	]]
	function Object.Run(self, Settings) self.Runs += 1; self.Settings = Settings; return "NotFound", "test" end
	--[[
		記錄取消。
		@param self 引擎替身。
	]]
	function Object.Cancel(self) self.Cancels += 1 end
	--[[
		記錄卸載。
		@param self 引擎替身。
	]]
	function Object.Destroy(self) self.Destroys += 1 end
	table.insert(Engines, Object)
	return Object
end
local Library = {}
--[[
	建立只支援目前公開 API 的視窗替身；呼叫錯誤 API 時測試直接失敗。
	@param self UI 函式庫。
	@param Options 視窗選項。
	@return 視窗替身。
]]
function Library.CreateWindow(self, Options)
	local Window = { ScreenGui = {}, Options = Options, Destroys = 0 }
	--[[
		模擬視窗卸載回呼，可重入但僅記錄一次銷毀。
		@param self 視窗替身。
	]]
	function Window.Destroy(self)
		if self.Destroys > 0 then return end
		self.Destroys += 1; Options.OnUnload()
	end
	--[[
		以同一個替身提供分頁與區段的公開 API。
		@param self 視窗替身。
		@param Settings 分頁選項。
		@return 可建立區段的替身。
	]]
	function Window.CreateTab(self, Settings) return self end
	--[[
		建立區段；由標記模擬部分初始化失敗。
		@param self 視窗替身。
		@param Settings 區段選項。
		@return 區段替身。
	]]
	function Window.CreateSection(self, Settings)
		if Shared.bFailUi then error("UI init failure") end
		return self
	end
	--[[
		接受控制項選項。
		@param self 視窗替身。
		@param Settings 控制項選項。
	]]
	local function _Control(self, Settings) end
	Window.CreateSlider, Window.CreateToggle, Window.CreateButton = _Control, _Control, _Control
	--[[
		建立具有 Set 公開方法的段落。
		@param self 視窗替身。
		@param Settings 段落選項。
		@return 段落替身。
	]]
	function Window.CreateParagraph(self, Settings)
		return {
			--[[
				接受 UI 狀態更新。
				@param self 段落替身。
				@param Title 標題。
				@param Body 內文。
			]]
			Set = function(self, Title, Body) end,
		}
	end
	table.insert(Windows, Window)
	return Window
end
local FakeGame = { PlaceId = 123, JobId = "current" }
--[[
	提供入口需要的服務替身。
	@param self 遊戲替身。
	@param Name 服務名稱。
	@return 服務替身。
]]
function FakeGame.GetService(self, Name)
	return if Name == "Players" then { LocalPlayer = { UserId = 1 } } else {}
end
--[[
	回傳依賴 URL 作為假原始碼，由測試 loadstring 解析，不接觸網路。
	@param self 遊戲替身。
	@param Url 原始碼網址。
	@return 相同網址。
]]
function FakeGame.HttpGet(self, Url) return Url end
--[[
	讀取入口使用的共享環境。
	@return 共享環境。
]]
local function _GetEnv() return Shared end
--[[
	回傳有效容器的 typeof 替身。
	@param Value 被檢查物件。
	@return Instance 字串。
]]
local function _Typeof(Value) return "Instance" end
--[[
	提供 UI 根容器。
	@return 容器替身。
]]
local function _GetHui() return {} end
--[[
	入口只檢查能力存在，此替身不發出請求。
	@param Options 未使用的請求。
]]
local function _Request(Options) end
--[[
	將入口排程的工作保留到測試主動執行。
	@param Callback 工作回呼。
]]
local function _Spawn(Callback) table.insert(Jobs, Callback) end
--[[
	以本機替身取代遠端依賴，保留入口的原始載入結構。
	@param Url 依賴 URL。
	@return 回傳對應依賴的函數。
]]
local function _LoadString(Url)
	--[[
		提供已編譯的依賴替身。
		@return URL 對應模組。
	]]
	return function() return if Url:find("ServerHopEngine", 1, true) then EngineModule else Library end
end
local Environment = setmetatable({ game = FakeGame, getgenv = _GetEnv, gethui = _GetHui,
	request = _Request, typeof = _Typeof, loadstring = _LoadString, task = { spawn = _Spawn } }, { __index = getfenv() })
local Entry = Luau.load(Fs.readFile("Universal/ServerHop_Bjz.luau"), { environment = Environment })
local First = Entry()
assert(#Jobs == 0 and Engines[1].Runs == 0, "入口不能自動傳送")
First.Start(); First.Start(); First.Cancel(); table.remove(Jobs, 1)()
assert(Engines[1].Runs == 0, "取消應使尚未執行的背景工作失效")
First.Config.bEmptyOnly = true
First.Start(); table.remove(Jobs, 1)()
assert(Engines[1].Runs == 1 and Engines[1].Settings.MaxPlayers == 0)
local Second = Entry()
assert(Engines[1].Destroys == 1 and Windows[1].Destroys == 1, "重複執行應卸載舊實例")
First.Destroy()
assert(Shared.__BjzHubServerHop == Second, "舊實例不得清掉新單例")
Second.Destroy(); Second.Destroy()
assert(Engines[2].Destroys == 1 and Shared.__BjzHubServerHop == nil)
Shared.bFailUi = true
assert(not pcall(Entry), "部分 UI 初始化失敗應回報錯誤")
assert(Engines[3].Destroys == 1 and Windows[3].Destroys == 1 and Shared.__BjzHubServerHop == nil)
print("ServerHop: entry lifecycle and public UI API checks passed")
