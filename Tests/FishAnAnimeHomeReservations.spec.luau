local Fs, Luau = require("@lune/fs"), require("@lune/luau")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local Controller = { bAutoCharacters = true, bAutoWorkers = true }
local Runtime = { Jobs = {}, RetryAt = { bAutoCharacters = 250 }, RetryNotBefore = {}, StartedAt = {}, FinishedAt = {} }
local Now, Messages = 10, {}
--[[
	記錄派工同步欄位，確認等待原因不會停留在尚未派工。
	@param self 測試欄位物件。
	@param Title 顯示標題。
	@param Message 顯示內容。
]]
Runtime.WorkerLabel = { Set = function(self, Title, Message) self.Message = Message end }
local Functions = { "local _CharacterPairs = {}" }
for _, Name in { "InventoryStamp", "ReserveHome", "WorkerStatus", "WaitWorkers", "WakeWorkers", "WorkersAllowed" } do
	table.insert(Functions, assert(Source:match("(function _CharacterPairs%." .. Name .. ".-\nend)")))
end
table.insert(Functions, assert(Source:match("(local function _RunFeature%(.-\nend)")))
local Engine = Luau.load(table.concat(Functions, "\n") .. "\n_CharacterPairs.RunFeature = _RunFeature\nreturn _CharacterPairs", { environment = {
	Controller = Controller, _Runtime = Runtime,
	_Performance = {
		--[[
			此測試只驗證家中與派工排程；渲染生命週期由獨立測試覆蓋。
			@param Key 開始的工作鍵。
		]]
		BeginInteraction = function(Key) end,
		--[[
			替代工作結束時釋放渲染保留。
			@param Key 結束的工作鍵。
		]]
		EndInteraction = function(Key) end,
	},
	--[[
		讀取測試時鐘。
		@return 可控制的目前秒數。
	]]
	os = { clock = function() return Now end },
	--[[
		記錄功能狀態。
		@param Key 功能鍵。
		@param Text 記錄顯示的狀態。
	]]
	_Status = function(Key, Text) Messages[Key] = Text end,
	--[[
		保留工作到手動推進，模擬 defer 的非同步啟動。
		@param Callback 延後執行的工作。
		@return 未開始的工作協程。
	]]
	task = { defer = function(Callback) return coroutine.create(Callback) end },
	--[[
		替代失敗後的位移釋放。
		@param Key 失敗後釋放位移的功能鍵。
	]]
	_RestoreMove = function(Key) end,
	--[[
		替代失敗後的派工工具釋放。
	]]
	_RestoreWorkerGear = function() end,
} })()
local Plot = {}
local Summary = { ["C|PendingHome||L62"] = { c = 1, bc = 1000 } }
assert(not Engine.WorkersAllowed(Plot, Summary) and Runtime.RetryAt.bAutoCharacters == 10, "沒有確認的家中配置時，先喚醒家中規劃而非派走強角")
assert(Runtime.WorkerWait == "Home" and Runtime.WorkerLabel.Message:find("家中", 1, true), "等待原因也必須顯示於派工同步狀態")
local Plan = { Target = { { Key = "C|PendingHome||L62" } }, SummaryStamp = Engine.InventoryStamp(Summary), Done = true }
Engine.ReserveHome(Plot, Plan, false)
assert(Runtime.HomeReservations.Keys["C|PendingHome||L62"], "尚未部署的目標角色也必須保留")
assert(not Engine.WorkersAllowed(Plot, Summary), "換位未完成前不得派遣")
Engine.ReserveHome(Plot, Plan, true)
assert(Engine.WorkersAllowed(Plot, Summary), "確認完成後才可從剩餘閒置人選派遣")
Runtime.CharacterPlan = { Done = false, Nodes = 155136 }
assert(not Engine.WorkersAllowed(Plot, Summary), "重現使用者報告 Done=false／155136節點時，不可再把家中候選派出去")
Runtime.CharacterPlan = nil
Runtime.Jobs.bAutoCharacters = {}
assert(not Engine.WorkersAllowed(Plot, Summary), "角色查詢或規劃工作正在執行時先等待")
Runtime.Jobs.bAutoCharacters = nil
Summary["C|PendingHome||L62"].c = 2
Runtime.RetryAt.bAutoCharacters = 250
assert(not Engine.WorkersAllowed(Plot, Summary) and Runtime.RetryAt.bAutoCharacters == 10, "取得新角色後不能等240秒間隔才保留家中人選")
Runtime.RetryNotBefore.bAutoCharacters, Runtime.RetryAt.bAutoCharacters = 20, 250
assert(not Engine.WorkersAllowed(Plot, Summary) and Runtime.RetryAt.bAutoCharacters == 20, "喚醒規劃不可繞過既有錯誤冷卻")
Controller.bAutoCharacters = false
assert(Engine.WorkersAllowed(Plot, Summary), "使用者關閉自動裝備後仍可獨立派遣，家中實際角色另由 HomeKeys 保護")

-- 同為300秒間隔：家中查詢先掛起，派工必須等待；家中完成後不再等300秒。
Controller.bAutoCharacters = true
Runtime.RetryNotBefore = {}
Plan.SummaryStamp = Engine.InventoryStamp(Summary)
Engine.ReserveHome(Plot, Plan, true)
Runtime.WorkerWait = nil
local Dispatches = 0
--[[
	模擬原生家中查詢延遲，完成時仍保留已確認的目標名單。
]]
local HomeFeature = { Key = "bAutoCharacters", Interval = 300, Step = function() coroutine.yield() end }
--[[
	依真實派工入口清除上一輪等待，再核對家中條件；通過才計為實際工作。
]]
local WorkerFeature = { Key = "bAutoWorkers", Interval = 300, Step = function()
	Runtime.WorkerWait = nil
	if not Engine.WorkersAllowed(Plot, Summary) then return end
	Dispatches += 1
end }
--[[
	推進指定協程，失敗時帶出實際工作錯誤。
	@param Thread 真正排程器所建立的工作。
]]
local function _Resume(Thread)
	local bOk, Reason = coroutine.resume(Thread)
	assert(bOk, Reason)
end
Engine.RunFeature(HomeFeature)
local HomeJob = Runtime.Jobs.bAutoCharacters
_Resume(HomeJob)
Engine.RunFeature(WorkerFeature)
_Resume(Runtime.Jobs.bAutoWorkers)
assert(Dispatches == 0 and Runtime.RetryAt.bAutoWorkers == 11, "前置等待只能短暫重試，不能消耗300秒間隔")
_Resume(HomeJob)
assert(Runtime.Jobs.bAutoCharacters == nil and Runtime.RetryAt.bAutoWorkers == Now, "家中工作釋放後應立即喚醒等待派工")
assert(Runtime.WorkerLabel.Message:find("準備", 1, true), "同步狀態必須顯示家中完成後即將派工")
Engine.RunFeature(WorkerFeature)
_Resume(Runtime.Jobs.bAutoWorkers)
assert(Dispatches == 1 and Runtime.RetryAt.bAutoWorkers == Now + 300 and not Runtime.WorkerWait, "真正完成一輪後才等待使用者設定的300秒")
Engine.WakeWorkers()
assert(Runtime.RetryAt.bAutoWorkers == Now + 300, "家中更新不能繞過已完成派工的正常間隔")

for Round = 1, 3 do
	Now += 300
	Engine.RunFeature(HomeFeature)
	HomeJob = Runtime.Jobs.bAutoCharacters
	_Resume(HomeJob)
	Engine.RunFeature(WorkerFeature)
	_Resume(Runtime.Jobs.bAutoWorkers)
	assert(Runtime.RetryAt.bAutoWorkers == Now + 1)
	_Resume(HomeJob)
	assert(Runtime.RetryAt.bAutoWorkers == Now)
	Engine.RunFeature(WorkerFeature)
	_Resume(Runtime.Jobs.bAutoWorkers)
	assert(Dispatches == Round + 1, "每個相同300秒週期都能接續派工，不會再次同步卡住")
end

Runtime.WorkerWait, Runtime.RetryNotBefore.bAutoWorkers = "Home", Now + 10
Engine.WakeWorkers()
assert(Runtime.RetryAt.bAutoWorkers == Now + 10, "喚醒派工不得繞過逾時冷卻")
Runtime.RetryNotBefore.bAutoWorkers = nil
Runtime.HomeReservations.bReady = false
Engine.RunFeature(WorkerFeature)
_Resume(Runtime.Jobs.bAutoWorkers)
assert(Dispatches == 4 and Runtime.WorkerWait == "Home", "等待重試不能放寬家中保留條件")
local RetryBefore = Runtime.RetryAt.bAutoWorkers
Engine.WakeWorkers()
assert(Runtime.RetryAt.bAutoWorkers == RetryBefore, "尚未確認家中配置前不能提早喚醒派工")
--[[
	模擬移動尚未結束的短暫衝突，不需要重新等待完整派工間隔。
]]
WorkerFeature.Step = function() Engine.WaitWorkers("Busy", "等待移動結束") end
Engine.RunFeature(WorkerFeature)
_Resume(Runtime.Jobs.bAutoWorkers)
assert(Runtime.RetryAt.bAutoWorkers == Now + 1 and Runtime.WorkerLabel.Message == "等待移動結束")
--[[
	等待之後若拋錯，應恢復一般錯誤重試間隔，不能留下每秒重試。
]]
WorkerFeature.Step = function() Engine.WaitWorkers("Home", "等待家中") error("派工測試錯誤") end
Engine.RunFeature(WorkerFeature)
_Resume(Runtime.Jobs.bAutoWorkers)
assert(Runtime.WorkerWait == nil and Runtime.RetryAt.bAutoWorkers == Now + 300, "失敗必須清除等待狀態且避免快速重複操作")
print("FishAnAnimeHomeReservations: all assertions passed")
