--[[
	BjzHub 通用換服入口。執行後開啟 UI，按「搜尋並加入」才會傳送。
	遠端 main 必須已包含同版 ServerHopEngine；本機修改不會自動同步遠端。
]]
local ENGINE_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/ServerHopEngine.luau"
local LIBRARY_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Library/BjzUiLibrary_2.0.luau"
local SINGLETON_KEY = "__BjzHubServerHop"
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
assert(Player, "請先進入遊戲")
assert(type(getgenv) == "function" and type(loadstring) == "function", "需要 getgenv 與 loadstring")
local Env = getgenv()
assert(type(Env) == "table", "getgenv 未回傳有效環境")
local Request = Env.request or request
local GetHui = Env.gethui or gethui
assert(type(Request) == "function", "執行器未提供 sUNC request，無法讀取公開伺服器清單")
assert(type(GetHui) == "function", "執行器未提供 gethui，無法建立介面")
local bRootOk, Root = pcall(GetHui)
assert(bRootOk and typeof(Root) == "Instance", "gethui 未回傳有效 UI 容器")

local Previous = Env[SINGLETON_KEY]
if type(Previous) == "table" and type(Previous.Destroy) == "function" then
	Previous.Destroy()
end

--[[
	公開單例：設定僅留在本次執行，不改寫其他功能的設定檔。
]]
local Api = { Version = "1.0.0", Config = { MaxPlayers = 10, MaxPages = 5, bEmptyOnly = false } }
--[[
	入口自行擁有的 UI、引擎與工作狀態，初始化未完成時可為 nil。
]]
local _Window, _Engine, _Status = nil, nil, nil
local _bDestroyed, _bRunning = false, false
--[[
	用來使取消前已排程、尚未開始的搜尋失效。
]]
local _Generation = 0
Env[SINGLETON_KEY] = Api

--[[
	更新仍存活的狀態段落。
	@param Message 顯示文字。
]]
local function _Report(Message: string): ()
	if not _bDestroyed and _Status then
		_Status:Set("目前狀態", Message)
	end
end

--[[
	卸載自己建立的引擎與 UI，可重複呼叫，不覆蓋較新的單例。
]]
function Api.Destroy(): ()
	if _bDestroyed then
		return
	end
	_bDestroyed = true
	if _Engine then
		_Engine:Destroy()
	end
	if _Window then
		_Window:Destroy()
	end
	if Env[SINGLETON_KEY] == Api then
		Env[SINGLETON_KEY] = nil
	end
end

--[[
	停止後續搜尋與換服嘗試，已送出的傳送無法撤回。
]]
function Api.Cancel(): ()
	_Generation += 1
	if _Engine and not _bDestroyed then
		_Engine:Cancel()
	end
end

--[[
	以設定快照啟動一次背景搜尋，忽略重複點擊。
]]
function Api.Start(): ()
	if _bDestroyed or _bRunning or not _Engine then
		return
	end
	_bRunning = true
	local Generation = _Generation
	local Settings = {
		MaxPlayers = if Api.Config.bEmptyOnly then 0 else Api.Config.MaxPlayers,
		MaxPages = Api.Config.MaxPages,
		MaxAttempts = 5,
	}
	--[[
		執行會 yield 的引擎；卸載後不再更新 UI，引擎會停止後續操作。
	]]
	task.spawn(function()
		if not _bDestroyed and Generation == _Generation then
			local Code, Message = _Engine:Run(Settings)
			_Report(Code .. "：" .. Message)
		end
		_bRunning = false
	end)
end

--[[
	初始化遠端依賴及新版 UI；任一步失敗均由外層清理入口資源。
]]
local function _Initialize(): ()
	local CServerHopEngine = loadstring(game:HttpGet(ENGINE_URL))()
	if _bDestroyed then
		return
	end
	assert(
		type(CServerHopEngine) == "table"
			and CServerHopEngine.Version == "1.0.0"
			and type(CServerHopEngine.new) == "function",
		"遠端 ServerHopEngine 版本不符；請先更新 main"
	)
	local Library = loadstring(game:HttpGet(LIBRARY_URL))()
	if _bDestroyed then
		return
	end
	assert(type(Library) == "table" and type(Library.CreateWindow) == "function", "BjzUiLibrary API 不相容")
	_Engine = CServerHopEngine.new({
		PlaceId = game.PlaceId,
		JobId = game.JobId,
		Player = Player,
		TeleportService = TeleportService,
		Request = Request,
		--[[
			解析 Rbx 的公開伺服器回應，格式由引擎檢查。
			@param Body API 的 JSON 字串。
			@return 解碼後的分頁。
		]]
		Decode = function(Body)
			return HttpService:JSONDecode(Body)
		end,
		--[[
			編碼不透明分頁游標，避免特殊字元破壞查詢。
			@param Value 原始游標。
			@return URL 編碼後游標。
		]]
		Encode = function(Value)
			return HttpService:UrlEncode(Value)
		end,
		--[[
			讓引擎短暫 yield，不另外持有計時器。
			@param Seconds 等待秒數。
		]]
		Wait = function(Seconds)
			task.wait(Seconds)
		end,
		Clock = os.clock,
		Report = _Report,
	})
	_Window = Library:CreateWindow({
		Name = "通用伺服器搜尋",
		Brand = "BjzHub",
		Subtitle = "PlaceId " .. tostring(game.PlaceId),
		ConfigId = "BjzHubServerHop_" .. tostring(Player.UserId) .. "_" .. tostring(game.PlaceId),
		Width = 700,
		Height = 500,
		ConfigurationSaving = { bEnabled = false },
		OnUnload = Api.Destroy,
	})
	_Window.ScreenGui.Parent = Root
	assert(_Window.ScreenGui.Parent == Root, "UI 無法掛到 gethui 容器")
	Api.Window = _Window
	Api.LibraryVersion = Library.Version
	local Page = _Window:CreateTab({ Name = "伺服器" })
	local Controls = Page:CreateSection({ Name = "搜尋條件", Side = "left" })
	local Status = Page:CreateSection({ Name = "狀態與說明", Side = "right" })
	--[[
		更新空服限定條件；不影響執行中的設定快照。
		@param bValue true 僅尋找清單人數為 0 的伺服器；false 使用人數上限。
	]]
	Controls:CreateToggle({
		Name = "只找 0 人伺服器",
		bCurrentValue = false,
		bSave = false,
		Callback = function(bValue)
			Api.Config.bEmptyOnly = bValue
		end,
	})
	--[[
		更新目的服加入前人數上限。
		@param Value 上限人數，範圍為 1 至 100。
	]]
	Controls:CreateSlider({
		Name = "人數上限（加入前）",
		Range = { 1, 100 },
		Increment = 1,
		CurrentValue = 10,
		bSave = false,
		Callback = function(Value)
			Api.Config.MaxPlayers = Value
		end,
	})
	--[[
		更新掃描上限，避免無界分頁查詢。
		@param Value 頁數上限，範圍為 1 至 20。
	]]
	Controls:CreateSlider({
		Name = "最多搜尋頁數",
		Range = { 1, 20 },
		Increment = 1,
		CurrentValue = 5,
		bSave = false,
		Callback = function(Value)
			Api.Config.MaxPages = Value
		end,
	})
	Controls:CreateButton({ Name = "搜尋並加入", Callback = Api.Start })
	Controls:CreateButton({ Name = "取消搜尋 / 重試", Callback = Api.Cancel })
	Controls:CreateButton({ Name = "卸載", Callback = Api.Destroy })
	_Status = Status:CreateParagraph({ Title = "目前狀態", Content = "待命；按搜尋才會換服" })
	Status:CreateParagraph({
		Title = "搜尋方式",
		Content = "空服優先；找不到時，選掃描範圍內符合上限且人數最少的服。開啟只找 0 人後，不會放寬條件。",
	})
	Status:CreateParagraph({
		Title = "限制",
		Content = "公開清單可能沒有空服，人數也可能改變。無法建立私人服。明確傳送失敗才換下一服；等待結果時不重複傳送。取消不能撤回已送出的傳送。",
	})
end

local bOk, Reason = pcall(_Initialize)
if not bOk then
	Api.Destroy()
	error("[BjzHub ServerHop] 初始化失敗：" .. tostring(Reason), 0)
end
return Api
