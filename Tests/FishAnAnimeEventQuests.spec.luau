local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local World = Rbx.Instance.new("Folder")
local Npc = Rbx.Instance.new("Model")
Npc.Parent = World
local PlayerGui = Rbx.Instance.new("Folder")
local MainGui = Rbx.Instance.new("Folder")
MainGui.Name, MainGui.Parent = "MainGui", PlayerGui
local QuestGui = Rbx.Instance.new("Frame")
QuestGui.Name, QuestGui.Parent, QuestGui.Visible = "AmnesiaQuestGUI", MainGui, false
local Tags = { AmnesiaQuestNpc = { Npc }, HalloweenQuestNpc = {} }
local Definitions = {
	Amnesia1 = { Chain = "Amnesia", Characters = { { Name = "Jester", Count = 2 } }, Tasks = { { Id = "AmnesiaCoins", Goal = 50 } } },
	Amnesia2 = { Chain = "Amnesia", Characters = { { Name = "Sasha", Count = 3 } }, Tasks = {} },
	Halloween1 = { Chain = "Halloween", Characters = { { Name = "Pomna", Count = 1 } }, Tasks = {} },
	Paid = { Chain = "Amnesia", GemCost = 100, Characters = { { Name = "PaidRole", Count = 1 } } },
	Evolution = { Chain = "Amnesia", Evolution = true },
	Ordinary = { Characters = { { Name = "NormalRole", Count = 1 } } },
}
local States = {
	Amnesia1 = { claimed = false, locked = false, progress = { AmnesiaCoins = 0 }, deposits = {} },
	Amnesia2 = { claimed = false, locked = true, progress = {}, deposits = {} },
	Halloween1 = { claimed = false, locked = false, progress = {}, deposits = {} },
}
local Summary = { ["C|Jester|"] = { n = "Jester", c = 2, ra = "Common" },
	["C|Jester|Demonic|L100"] = { n = "Jester", c = 1, ra = "Common" },
	["C|Sasha|"] = { n = "Sasha", c = 3, ra = "Common" },
	["C|Spare|"] = { n = "Spare", c = 5, ra = "Common" } }
local Controller = { bAutoEventQuests = true, bAutoSellCharacters = true, SellRarities = { Common = true } }
local Runtime = { bAlive = true, Jobs = {}, NpcQuests = { Quests = Definitions }, LastSellGroup = "", SellIndex = 0 }
local Event = { Protected = {}, Entries = {}, Cursor = 0 }
local Calls, Status, Items, Attempts = {}, {}, {}, {}
local bBadState, bReject, bStopOnQuery = false, false, false
local Favorites, Equipped = {}, { equipped = {} }
local Root = { Position = Rbx.Vector3.zero }
local Restored = 0
local Environment = {
	_EventQuests = Event, _Runtime = Runtime, Controller = Controller, workspace = World,
	Constants = { Characters = {} }, _RarityOptions = { "Common" }, CFrame = Rbx.CFrame,
	--[[ @param _ 玩家替身。 @param Name 屬性鍵。 @return Sell Rarity 已解鎖。 ]]
	LocalPlayer = { GetAttribute = function(_, Name) return Name == "Rsh_B10" end,
		--[[ @param _ 玩家。 @param Name 物件名稱。 @return 玩家 GUI。 ]]
		FindFirstChild = function(_, Name) return if Name == "PlayerGui" then PlayerGui else nil end },
	--[[ @param _ 遊戲替身。 @param Name 服務名稱。 @return 原生標記服務替身。 ]]
	game = { GetService = function(_, Name)
		assert(Name == "CollectionService")
		--[[ @param _ 標記服務。 @param Tag 標記名稱。 @return 測試在場物件。 ]]
		return { GetTagged = function(_, Tag) return Tags[Tag] or {} end }
	end },
	--[[ @param Key 功能鍵。 @param Text 最新狀態。 ]]
	_Status = function(Key, Text) Status[Key] = Text end,
	--[[ @return 測試角色根部。 ]]
	_Character = function() return Root end,
	--[[ @param Key 要還原的功能鍵。 ]]
	_RestoreMove = function(Key) assert(Key == "bAutoEventQuests") Restored += 1 end,
	_MapPickup = {
		--[[ @return 本輪活動與非活動混合候選。 @return 無缺少能力。 ]]
		Candidates = function() error("活動任務不得掃描地圖拾取候選") end,
		--[[ @param _ 要清理的功能鍵。 ]]
		ReleaseTouch = function(_) end,
		--[[ @param Item 目前候選。 @param RootValue 根部。 @param TagsValue 標記服務。 @param Key 執行功能。 @return 尚未確認的拾取結果。 ]]
		Attempt = function(Item, RootValue, TagsValue, Key)
			assert(Key == "bAutoEventQuests", "共用拾取必須採用活動開關，不可偷偷開啟地圖拾取")
			table.insert(Attempts, Item)
			return "Unconfirmed"
		end,
	},
}
--[[
	模擬伺服器接受／拒絕活動操作與兩種出售路徑。
	@param Name 原生 Remote 名稱。
	@param ... 原生封包參數。
	@return 遊戲原始狀態替身。
]]
Environment._Invoke = function(Name, ...)
	local Args = table.pack(...)
	table.insert(Calls, { Name = Name, Args = Args })
	if Name == "NpcQuestGetState" then
		if bStopOnQuery then Controller.bAutoEventQuests = false end
		if bBadState then return {} end
		return table.clone(assert(States[Args[1]], "不可查詢付費／進化／非活動任務"))
	elseif Name == "BackpackCharSummaryGet" then return Summary
	elseif Name == "BackpackGetFavorites" then return Favorites
	elseif Name == "BackpackGetEquippedState" then return Equipped
	elseif Name == "NpcQuestDeposit" then
		assert(Args.n == 4 and Args[3] == "all" and Args[4] == nil, "沿用指定角色 Add All 的原生形狀")
		local State = States[Args[1]]
		assert(not State.locked and not State.claimed, "鎖定或已完成階段不能提交")
		if not bReject then
			State.deposits = table.clone(State.deposits)
			State.deposits[Args[2]] = 2
		end
		return table.clone(State), if bReject then "NOT_ENOUGH" else nil
	elseif Name == "NpcQuestClaim" then
		assert(Args.n == 1)
		if not bReject then States[Args[1]].claimed = true end
		return table.clone(States[Args[1]]), if bReject then "NOT_READY" else nil
	elseif Name == "BackpackSellSelectedRequest" then
		assert(not Event.Protected[Summary[Args[1]].n], "不得賣出任何變異的任務角色")
		return { ok = true }
	elseif Name == "BackpackSellRarityRequest" then return { ok = true, sold = 1 }
	end
	error("未預期的遠端：" .. Name)
end
local Engine = Luau.load(assert(Source:match("(local function _NpcRewardReady.-\nend)")) .. "\n"
	.. assert(Source:match("%-%- EVENT_QUESTS_START(.-)%-%- EVENT_QUESTS_END")) .. "\n"
	.. assert(Source:match("(local function _SellBackpackCharacters.-\nend)")) .. "\n"
	.. assert(Source:match("(local function _SellCharacters.-\nend)")) .. "\nreturn _SellCharacters", { environment = Environment })()
--[[ @param Name 遠端名稱。 @return 最近一次相符呼叫，沒有時為 nil。 ]]
local function Last(Name)
	for Index = #Calls, 1, -1 do if Calls[Index].Name == Name then return Calls[Index] end end
	return nil
end
assert(Event.Refresh() and Event.Protected.Jester == 2 and Event.Protected.Sasha == 3 and not Event.Protected.Pomna,
	"保留當前與未解鎖後續階段，未在場活動不保留")
Engine()
assert(Last("BackpackSellSelectedRequest").Args[1] == "C|Spare|" and not Last("BackpackSellRarityRequest"), "已解鎖 Sell Rarity 仍須改逐組出售以排除任務角色")
bBadState = true
table.clear(Calls)
assert(not pcall(Engine) and not Last("BackpackSellRarityRequest") and not Last("BackpackSellSelectedRequest"), "狀態讀取失敗須停止全部出售")
bBadState, bReject = false, true
States.Amnesia1.claimed = nil
assert(Event.Refresh(), "原生正常 progress／deposits 狀態省略 claimed=false 時仍應查詢成功")
States.Amnesia1.claimed = false
Runtime.bMoving = true
Runtime.Jobs.bAutoMapPickup, Runtime.Jobs.bAutoNpcRewards, Runtime.Jobs.bAutoSellCharacters = {}, {}, {}
Runtime.CharacterApplying = true
table.clear(Calls)
Event.Step()
assert(not Last("NpcQuestDeposit") and Status.bAutoEventQuests:find("等待角色配置", 1, true), "換位期間仍須保護角色交付，但要查詢並列出具體條件")
Runtime.CharacterApplying = nil
Event.Step()
assert(Last("NpcQuestDeposit") and not Last("NpcQuestClaim") and Status.bAutoEventQuests:find("尚未確認", 1, true), "被拒絕的角色交付不可假裝成功")
bReject = false
Event.Step()
assert(States.Amnesia1.deposits.Jester == 2 and not States.Amnesia1.claimed, "先交付角色，未完成硬幣條件時不得領獎")
table.clear(Calls)
Items = {
	{ Kind = "Touch", Tag = "AmneticCoin", Label = "Coin", Object = { Name = "Coin" } },
	{ Kind = "Prompt", Label = "Diary", Object = { Name = "AmnesiaPickupPrompt" } },
	{ Kind = "Touch", Tag = "HalloweenCandy", Label = "Candy", Object = { Name = "Candy" } },
	{ Kind = "Prompt", Label = "Character", Object = { Name = "CharacterPickup" } },
}
Event.Step()
assert(#Attempts == 0 and Restored == 0 and not Last("NpcQuestClaim"), "進度不足時不得掃描拾取或還原其他工作位置")
assert(Status.bAutoEventQuests:find("AmnesiaCoins 0／50", 1, true), "列出實際尚缺條件，不能停在泛用等待操作訊息")
States.Amnesia1.progress.AmnesiaCoins = 50
Runtime.CharacterApplying = true
Event.Step()
assert(States.Amnesia1.claimed, "已交付且進度達標後自動領獎")
Runtime.CharacterApplying = nil
Runtime.bMoving = false
Runtime.Jobs.bAutoMapPickup, Runtime.Jobs.bAutoNpcRewards, Runtime.Jobs.bAutoSellCharacters = nil, nil, nil
Event.Refresh()
assert(not Event.Protected.Jester and Event.Protected.Sasha, "解除已完成任務需求，同時保留下一關需求")
States.Amnesia2.claimed = true
table.clear(Calls)
Engine()
assert(next(Event.Protected) == nil and Last("BackpackSellRarityRequest"), "所有任務完成後可恢復按品質出售")
States.Amnesia2.claimed = false
Npc.Parent = nil
Event.Refresh()
assert(next(Event.Protected) == nil and #Event.Entries == 0, "NPC 消失後解除該活動角色保留")
QuestGui.Visible = true
Event.Refresh()
assert(Event.Protected.Sasha, "原生任務介面已開啟時，不可僅因 NPC 未串流而忽略活動")
QuestGui.Visible = false
Npc.Parent = World
bStopOnQuery = true
table.clear(Calls)
Event.Step()
assert(not Last("NpcQuestDeposit") and not Last("NpcQuestClaim"), "查詢期間關閉後不可再送出提交或領獎")
bStopOnQuery, Controller.bAutoEventQuests = false, true
Runtime.Jobs.bAutoEventQuests = {}
table.clear(Calls)
Engine()
assert(#Calls == 0, "活動提交期間不得啟動出售")
Runtime.Jobs.bAutoEventQuests = nil
World:Destroy()
PlayerGui:Destroy()
print("FishAnAnimeEventQuests: passed (activity, chain reservations, sales, concurrent deposit/claims, no pickups, cancellation)")
