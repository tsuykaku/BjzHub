local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Serde = require("@lune/serde")
local Source = Fs.readFile("Games/FishAnAnimeRNG/FishAnAnimeRNG_Delta_Bjz.luau")
local Fixture = Serde.decode("json", Fs.readFile("Tests/FishAnAnimeStandDiscovery.json"))
local PlannerSource = assert(Source:match("%-%- PAIR_PLANNER_START(.-)%-%- PAIR_PLANNER_END"))
local Reader = assert(Source:match("(function _CharacterPairs%.ReadPlot.-\nend)"))
local Indexer = assert(Source:match("(function _CharacterPairs%.StandIndex.-\nend)"))
local Engine = Luau.load(PlannerSource .. "\n" .. Indexer .. "\n" .. Reader .. "\nreturn _CharacterPairs", { environment = {
	Constants = { Characters = Fixture.Definitions, TypeSystem = { Multipliers = Fixture.TypeMultipliers },
		--[[ @param Level 角色等級。 @return 固定測試曲線，拓樸測試不驗證遊戲曲線。 ]]
		GetCpsCurveMultiplier = function(Level) return Level end },
} })()
local Plot = Rbx.Instance.new("Model")
local Purchases = Rbx.Instance.new("Folder")
Purchases.Name, Purchases.Parent = "Purchases", Plot
--[[
	建立具備原生 Platform 及基本屬性的展台替身。
	@param Id 原生 StandId，保留 PAID 後綴。
	@param Parent 地塊或 Purchases。
	@return 建立的展台。
]]
local function Stand(Id, Parent)
	local Value = Rbx.Instance.new("Folder")
	Value.Name, Value.Parent = Id, Parent
	local Platform = Rbx.Instance.new("Part")
	Platform.Name, Platform.Parent = "Platform", Value
	Value:SetAttribute("PaidLocked", false)
	Value:SetAttribute("RebirthLocked", false)
	return Value
end
for _, Entry in Fixture.Stands do
	local Value = Stand(Entry.Id, if Entry.Source == "Plot" then Plot else Purchases)
	Value:SetAttribute("HasCharacter", true)
	Value:SetAttribute("CharacterName", Entry.Name)
	Value:SetAttribute("CharacterType", Entry.Type)
	Value:SetAttribute("Level", Entry.Level)
	Value:SetAttribute("CPS", Entry.Cps)
end
local Stands, Slots, Current = Engine.ReadPlot(Plot)
assert(#Slots == #Fixture.Stands and #Slots > 30, "必須納入報告所有已放置展台，不能只剩根目錄的三格")
local Counts = {}
for Index, Entry in Stands do
	assert(Entry.Object.Name == Fixture.Stands[Index].Id)
	assert(Slots[Index] == tonumber(Entry.Object.Name:match("^%d+")))
	Counts[Entry.Object.Parent] = (Counts[Entry.Object.Parent] or 0) + 1
	assert(Current[Index].Name == Fixture.Stands[Index].Name)
end
assert(Counts[Plot] == 3 and Counts[Purchases] == #Slots - 3, "升級與付費展台須和根目錄一起讀取")
assert(Engine.StandIndex("5PAID") == 5 and Engine.IsAdjacent(4, Engine.StandIndex("5PAID")))
assert(not Engine.IsAdjacent(Engine.StandIndex("5PAID"), 6) and not Engine.StandIndex("4PAID"), "付費格不能跨排或把任意名稱當成格位")
local Names = {}
for _, Value in Current do table.insert(Names, Value) end
local _, Edges = Engine.Snapshot(Names, Fixture.Definitions)
for _, Pair in { "Kaneko|Riza II", "Askira II|Reia II", "Ichi Naka|Yotso Naka" } do
	assert(Edges:find(Pair, 1, true), "必須恢復先前漏掉的已裝備配對：" .. Pair)
end
local Locked = Stand("35PAID", Purchases)
Locked:SetAttribute("PaidLocked", true)
local RebirthLocked = Stand("37", Purchases)
RebirthLocked:SetAttribute("RebirthLocked", true)
local Buttons = Rbx.Instance.new("Folder")
Buttons.Name, Buttons.Parent = "UnlockButtons", Plot
Stand("39", Buttons)
local _, OpenSlots = Engine.ReadPlot(Plot)
assert(#OpenSlots == #Slots, "不可把鎖定或未購買按鈕的展台加入候選")
local Duplicate = Stand("5", Plot)
assert(not pcall(Engine.ReadPlot, Plot), "同一數字格位重複時應等待同步，不能同時計為兩個欄位")
Duplicate:Destroy()
Plot:Destroy()
print("FishAnAnimeStandDiscovery: all assertions passed (" .. #Slots .. " stands)")
