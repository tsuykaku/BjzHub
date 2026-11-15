local Fs, Luau = require("@lune/fs"), require("@lune/luau")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local Controller = { bAutoFish = false, bDisable3dRendering = false, bRenderingEnabled = true }
local Runtime = { bAlive = true, bMoving = false, Jobs = {}, StartedAt = {}, FinishedAt = {}, RetryAt = {}, RetryNotBefore = {} }
local Rendering = { bEnabled = true, Calls = 0, bFail = false }
local Now = 0
--[[
	讀取引擎目前狀態，供首次捕捉及卸載還原驗證。
	@param self 渲染服務替身。
	@return 實際狀態。
]]
function Rendering.Is3dRenderingEnabled(self) return self.bEnabled end
--[[
	記錄實際渲染切換；權限拒絕時不更動狀態。
	@param self 渲染服務替身。
	@param bEnabled 目標狀態。
]]
function Rendering.Set3dRenderingEnabled(self, bEnabled)
	assert(not self.bFail, "render unavailable")
	self.Calls += 1
	self.bEnabled = bEnabled
end
local Functions = { "local _Performance = {}" }
for _, Name in { "CaptureRendering", "SetRendering", "SyncRendering", "BeginInteraction", "BeginRequest", "EndInteraction", "RestoreRendering" } do
	table.insert(Functions, assert(Source:match("(function _Performance%." .. Name .. ".-\nend)")))
end
table.insert(Functions, assert(Source:match("(local function _Invoke%(.-\nend)")))
table.insert(Functions, assert(Source:match("(local function _RunFeature%(.-\nend)")))
local Engine = Luau.load(table.concat(Functions, "\n") .. "\n_Performance.Invoke = _Invoke\n_Performance.RunFeature = _RunFeature\nreturn _Performance", { environment = {
	Controller = Controller, _Runtime = Runtime,
	--[[
		建立真正排程器使用的工作，交由測試手動推進。
		@param Callback 工作內容。
		@return 未開始的工作協程。
	]]
	task = { defer = function(Callback) return coroutine.create(Callback) end },
	--[[ @param Key 功能鍵。 @param Message 功能結果。 ]]
	_Status = function(Key, Message) end,
	--[[ @param Key 失敗後釋放移動權；本測試不模擬場景移動。 ]]
	_RestoreMove = function(Key) end,
	--[[ 家中查詢完成後的派工喚醒，由派工測試覆蓋。 ]]
	_CharacterPairs = { WakeWorkers = function() end },
	--[[
		提供查詢／實際購買的 RemoteFunction 替身。
		@param Name 原始 Remote 名稱。
		@param ClassName 必須為 RemoteFunction。
		@return 可 yield 的遠端替身。
	]]
	_Remote = function(Name, ClassName)
		assert(ClassName == "RemoteFunction")
		return {
			--[[
				查詢不能改變渲染；真正操作則必須先開啟，並保留到回覆。
				@param self 遠端替身。
				@return 空回應。
			]]
			InvokeServer = function(self)
				if Name == "BoostsStorePurchase" or Name == "CaseOpenRequest" then
					assert(not Rendering.bEnabled, "背景請求不能讓尚未結束的自動釣魚開啟渲染")
					coroutine.yield()
				end
				return {}
			end,
		}
	end,
	--[[
		讀取可控時鐘。
		@return 現在秒數。
	]]
	os = { clock = function() return Now end },
	--[[
		提供既有渲染服務。
		@param self 遊戲替身。
		@param Name 必須為 RunService。
		@return 渲染服務。
	]]
	game = { GetService = function(self, Name) assert(Name == "RunService") return Rendering end },
} })()
assert(Engine.SyncRendering() and Rendering.bEnabled)
Controller.bAutoFish = true
assert(Engine.SyncRendering() and not Rendering.bEnabled and not Controller.bDisable3dRendering,
	"釣魚自動關閉畫面，但不能改寫保存的手動設定")
local Calls = Rendering.Calls
for _ = 1, 50 do assert(Engine.SyncRendering()) end
assert(Rendering.Calls == Calls, "穩定狀態不可每輪重複呼叫引擎")
Runtime.bMoving = true
Runtime.Move, Runtime.FishPhase = { Key = "bAutoFeed" }, "Waiting"
assert(Engine.SyncRendering() and not Rendering.bEnabled, "取得移動權但釣魚未停止時仍須關閉")
Engine.BeginInteraction("bAutoFeed")
Engine.BeginInteraction("bAutoResearch")
assert(not Rendering.bEnabled, "不能讓等待取消的工作或背景研究開啟渲染")
Runtime.Move.bInteractionReady = true
assert(Engine.SyncRendering() and not Rendering.bEnabled, "即使已標記接手，原生釣魚尚未停止仍不能開啟")
Runtime.FishPhase, Runtime.bPendingOwned = "Idle", true
assert(Engine.SyncRendering() and not Rendering.bEnabled, "尚有等待確認的拋竿時也不能開啟")
Runtime.bPendingOwned = false
assert(Engine.SyncRendering() and Rendering.bEnabled, "釣魚停止且互動確認接手後才開啟")
Engine.EndInteraction("bAutoFeed")
assert(Rendering.bEnabled, "仍在互動／載入位置時保持開啟")
Engine.EndInteraction("bAutoResearch")
Runtime.Move, Runtime.bMoving = nil, false
assert(Engine.SyncRendering() and not Rendering.bEnabled, "交還釣魚後立即關閉畫面")
Runtime.CharacterApplying = true
assert(Engine.SyncRendering() and not Rendering.bEnabled, "配置旗標本身不能在持續釣魚時開啟畫面")
Runtime.CharacterApplying = nil
assert(Engine.SyncRendering() and not Rendering.bEnabled)
Calls = Rendering.Calls
for _, Phase in { "Pending", "Waiting", "Hooked", "Reveal", "Idle", "Pending", "Waiting" } do
	Runtime.FishPhase = Phase
	Runtime.Move, Runtime.bMoving = { Key = "bAutoFish", bInteractionReady = true }, true
	Engine.BeginInteraction("bAutoFish")
	Engine.BeginInteraction("bAutoBuyPotions")
	Engine.EndInteraction("bAutoBuyPotions")
	Engine.EndInteraction("bAutoFish")
end
assert(not Rendering.bEnabled and Rendering.Calls == Calls, "整個釣魚週期、魚池傳送及背景操作都不得造成渲染閃爍")
Runtime.Move, Runtime.bMoving, Runtime.FishPhase = nil, false, "Idle"
--[[
	推進真正排程器所建立的工作。
	@param Job 要推進的協程。
]]
local function _Resume(Job)
	local bOk, Reason = coroutine.resume(Job)
	assert(bOk, Reason)
end
Calls = Rendering.Calls
for _ = 1, 50 do
	for _, Key in { "bAutoFeed", "bAutoResearch", "bAutoBuyPotions", "bAutoQuestRewards", "bAutoSkipTutorial", "bAutoCharacters" } do
		--[[ 查詢沒有可操作目標時直接返回，不應產生任何 3D 切換。 ]]
		Engine.RunFeature({ Key = Key, Interval = 1, Step = function()
			for _, Name in { "ResearchGetData", "BoostsStoreGetState", "QuestGetState", "CaseSummaryGet" } do Engine.Invoke(Name) end
		end })
		_Resume(Runtime.Jobs[Key])
	end
end
assert(not Rendering.bEnabled and Rendering.Calls == Calls, "重現多個背景功能反覆輪詢時，釣魚期間必須持續關閉，不能閃爍")
--[[ 連真正的背景購買也不可中斷自動釣魚的渲染關閉狀態。 ]]
Engine.RunFeature({ Key = "bAutoBuyPotions", Interval = 1, Step = function()
	Engine.Invoke("BoostsStoreGetState")
	assert(not Rendering.bEnabled)
	Engine.Invoke("BoostsStorePurchase")
end })
local PurchaseJob = Runtime.Jobs.bAutoBuyPotions
_Resume(PurchaseJob)
assert(not Rendering.bEnabled and Rendering.Calls == Calls)
--[[ 多個背景操作同時等待，仍需持續關閉畫面。 ]]
Engine.RunFeature({ Key = "bAutoBoxes", Interval = 1, Step = function() Engine.Invoke("CaseOpenRequest") end })
local BoxJob = Runtime.Jobs.bAutoBoxes
_Resume(BoxJob)
_Resume(PurchaseJob)
assert(not Rendering.bEnabled)
_Resume(BoxJob)
assert(not Rendering.bEnabled and Rendering.Calls == Calls, "背景請求完成前後都不應切換 3D")
Controller.bAutoFish = false
assert(Engine.SyncRendering() and Rendering.bEnabled, "關閉釣魚後恢復手動預設")
Controller.bDisable3dRendering = true
assert(Engine.SyncRendering() and not Rendering.bEnabled)
Engine.BeginInteraction("bAutoCollectFood")
Engine.BeginInteraction("bAutoResearch")
assert(Rendering.bEnabled and Controller.bDisable3dRendering, "即使手動關閉，互動仍應暫時開啟且保留設定")
Engine.EndInteraction("bAutoCollectFood")
assert(Rendering.bEnabled, "關閉自動釣魚後仍保留並行互動的渲染權")
Engine.EndInteraction("bAutoResearch")
assert(not Rendering.bEnabled)
Rendering.bFail = true
local bStarted, Reason = pcall(Engine.BeginInteraction, "bAutoFeed")
assert(not bStarted and tostring(Reason):find("render unavailable", 1, true), "不能在所需渲染切換失敗時假裝已準備完成")
Engine.EndInteraction("bAutoFeed")
assert(next(Engine.RenderingJobs) == nil, "失敗或取消後須釋放本工作的保留")
Rendering.bFail, Runtime.bMoving = false, true
Now += 3.1
assert(Engine.SyncRendering() and Rendering.bEnabled)
Runtime.bMoving = false
assert(Engine.SyncRendering() and not Rendering.bEnabled)
Engine.RestoreRendering()
assert(Rendering.bEnabled and not Engine.bRenderingTouched and Engine.RenderingJobs == nil,
	"卸載還原最初狀態並清理保留，不把暫時策略寫入保存設定")
print("FishAnAnimeRendering: all assertions passed (fishing, interaction priority, concurrency, failure, cleanup)")
